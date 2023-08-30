/*
 * This file is part of the MicroPython for Frame project:
 *      https://github.com/brilliantlabsAR/frame-micropython
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
 *
 * ISC Licence
 *
 * Copyright © 2023 Brilliant Labs Ltd.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#include "genhdr/mpversion.h"
#include "mpconfigport.h"
#include "mphalport.h"
#include "py/builtin.h"
#include "py/compile.h"
#include "py/gc.h"
#include "py/mphal.h"
#include "py/mperrno.h"
#include "py/repl.h"
#include "py/runtime.h"
#include "py/stackctrl.h"
#include "py/stream.h"
#include "shared/readline/readline.h"
#include "shared/runtime/interrupt_char.h"
#include "shared/runtime/pyexec.h"

#include "error_helpers.h"
#include "nrf.h"
#include "nrfx_log.h"
#include "nrfx_twim.h"
#include "nrfx_spim.h"
#include "pinout.h"

static const nrfx_twim_t i2c_bus = NRFX_TWIM_INSTANCE(0);
static const nrfx_spim_t spi_bus = NRFX_SPIM_INSTANCE(0);

static const uint8_t ACCELEROMETER_I2C_ADDRESS = 0x4C;
static const uint8_t CAMERA_I2C_ADDRESS = 0x6C;
static const uint8_t MAGNETOMETER_I2C_ADDRESS = 0x0C;
static const uint8_t PMIC_I2C_ADDRESS = 0x48;
// extern uint32_t _ram_start;
// static uint32_t ram_start = (uint32_t)&_ram_start;
static uint32_t _stack_top;
// static uint32_t _stack_bot;
// static uint32_t _heap_start;
// static uint32_t _heap_end;
static bool not_real_hardware_flag = true;

typedef struct i2c_response_t
{
    bool fail;
    uint8_t value;
} i2c_response_t;

i2c_response_t monocle_i2c_read(uint8_t device_address_7bit,
                                uint16_t register_address,
                                uint8_t register_mask)
{
    if (not_real_hardware_flag)
    {
        return (i2c_response_t){.fail = false, .value = 0x00};
    }

    // Populate the default response in case of failure
    i2c_response_t i2c_response = {
        .fail = true,
        .value = 0x00,
    };

    // Create the tx payload, bus handle and transfer descriptors
    uint8_t tx_payload[2] = {(uint8_t)(register_address), 0};

    nrfx_twim_xfer_desc_t i2c_tx = NRFX_TWIM_XFER_DESC_TX(device_address_7bit,
                                                          tx_payload,
                                                          1);

    // Switch bus and use 16-bit addressing if the camera is requested
    if (device_address_7bit == CAMERA_I2C_ADDRESS)
    {
        tx_payload[0] = (uint8_t)(register_address >> 8);
        tx_payload[1] = (uint8_t)register_address;
        i2c_tx.primary_length = 2;
    }

    nrfx_twim_xfer_desc_t i2c_rx = NRFX_TWIM_XFER_DESC_RX(device_address_7bit,
                                                          &i2c_response.value,
                                                          1);

    // Try several times
    for (uint8_t i = 0; i < 3; i++)
    {
        nrfx_err_t tx_err = nrfx_twim_xfer(&i2c_bus, &i2c_tx, 0);

        if (tx_err == NRFX_ERROR_NOT_SUPPORTED ||
            tx_err == NRFX_ERROR_INTERNAL ||
            tx_err == NRFX_ERROR_INVALID_ADDR ||
            tx_err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            app_err(tx_err);
        }

        nrfx_err_t rx_err = nrfx_twim_xfer(&i2c_bus, &i2c_rx, 0);

        if (rx_err == NRFX_ERROR_NOT_SUPPORTED ||
            rx_err == NRFX_ERROR_INTERNAL ||
            rx_err == NRFX_ERROR_INVALID_ADDR ||
            rx_err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            app_err(rx_err);
        }

        if (tx_err == NRFX_SUCCESS && rx_err == NRFX_SUCCESS)
        {
            i2c_response.fail = false;
            break;
        }
    }

    i2c_response.value &= register_mask;

    return i2c_response;
}

i2c_response_t monocle_i2c_write(uint8_t device_address_7bit,
                                 uint16_t register_address,
                                 uint8_t register_mask,
                                 uint8_t set_value)
{
    i2c_response_t resp = {.fail = false, .value = 0x00};

    if (not_real_hardware_flag)
    {
        return resp;
    }

    if (register_mask != 0xFF)
    {
        resp = monocle_i2c_read(device_address_7bit, register_address, 0xFF);

        if (resp.fail)
        {
            return resp;
        }
    }

    // Create a combined value with the existing data and the new value
    uint8_t updated_value = (resp.value & ~register_mask) |
                            (set_value & register_mask);

    // Create the tx payload, bus handle and transfer descriptor
    uint8_t tx_payload[3] = {(uint8_t)register_address, updated_value, 0};

    nrfx_twim_xfer_desc_t i2c_tx = NRFX_TWIM_XFER_DESC_TX(device_address_7bit,
                                                          tx_payload,
                                                          2);

    // Switch bus and use 16-bit addressing if the camera is requested
    if (device_address_7bit == CAMERA_I2C_ADDRESS)
    {
        tx_payload[0] = (uint8_t)(register_address >> 8);
        tx_payload[1] = (uint8_t)register_address;
        tx_payload[2] = updated_value;
        i2c_tx.primary_length = 3;
    }

    // Try several times
    for (uint8_t i = 0; i < 3; i++)
    {
        nrfx_err_t err = nrfx_twim_xfer(&i2c_bus, &i2c_tx, 0);

        if (err == NRFX_ERROR_BUSY ||
            err == NRFX_ERROR_NOT_SUPPORTED ||
            err == NRFX_ERROR_INTERNAL ||
            err == NRFX_ERROR_INVALID_ADDR ||
            err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            app_err(err);
        }

        if (err == NRFX_SUCCESS)
        {
            break;
        }

        // If the last try failed. Don't continue
        if (i == 2)
        {
            resp.fail = true;
            return resp;
        }
    }

    return resp;
}

// static void power_down_network_core(void)
// {
// }

static void setup_network_core(void)
{
    // Start I2C driver
    {
        nrfx_twim_config_t i2c_config = {
            .scl_pin = I2C_SCL_PIN,
            .sda_pin = I2C_SDA_PIN,
            .frequency = NRF_TWIM_FREQ_100K,
            .interrupt_priority = NRFX_TWIM_DEFAULT_CONFIG_IRQ_PRIORITY,
            .hold_bus_uninit = false,
        };

        app_err(nrfx_twim_init(&i2c_bus, &i2c_config, NULL, NULL));

        nrfx_twim_enable(&i2c_bus);
    }

    // Scan all the I2C devices for their chip IDs
    {
        i2c_response_t accelerometer_response =
            monocle_i2c_read(ACCELEROMETER_I2C_ADDRESS, 0x03, 0xFF);

        i2c_response_t camera_response =
            monocle_i2c_read(CAMERA_I2C_ADDRESS, 0x300A, 0xFF);

        i2c_response_t magnetometer_response =
            monocle_i2c_read(MAGNETOMETER_I2C_ADDRESS, 0x0F, 0xFF);

        i2c_response_t pmic_response =
            monocle_i2c_read(PMIC_I2C_ADDRESS, 0x14, 0x0F);

        // If all chips fail to respond, it means that we're using a devkit
        if (accelerometer_response.fail && camera_response.fail &&
            magnetometer_response.fail && pmic_response.fail)
        {
            NRFX_LOG("Running on nRF5340-DK");
            not_real_hardware_flag = true;
        }

        if (not_real_hardware_flag == false)
        {
            // Otherwise, if any chip fails to respond, it's an error
            if (accelerometer_response.fail || camera_response.fail ||
                magnetometer_response.fail || pmic_response.fail)
            {
                // app_err(HARDWARE_ERROR); // TODO enable this
            }

            // If the PMIC returns the wrong chip ID, it's also an error
            if (pmic_response.value != 0x02)
            {
                // app_err(HARDWARE_ERROR); // TODO enable this
            }
        }
    }

    // Set up PMIC
    {
        // Set the SBB drive strength
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x2F, 0x03, 0x01).fail);

        // Set SBB0 to 1.0V
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x29, 0x7F, 0x04).fail);

        // Set SBB2 to 2.7V
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x2D, 0x7F, 0x26).fail);

        // Set LDO0 to 1.2V
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x38, 0x7F, 0x10).fail);

        // Turn on SBB0 (1.0V rail) with 500mA limit
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x2A, 0x37, 0x26).fail);

        // Turn on LDO0 (1.2V rail)
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x39, 0x07, 0x06).fail);

        // Turn on SBB2 (2.7V rail) with 333mA limit
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x2E, 0x37, 0x36).fail);

        // Vhot & Vwarm = 45 degrees. Vcool = 15 degrees. Vcold = 0 degrees
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x20, 0xFF, 0x2E).fail);

        // Set CHGIN limit to 475mA
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x21, 0x1C, 0x10).fail);

        // Charge termination current to 5%, and top-off timer to 30mins
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x22, 0x1F, 0x06).fail);

        // Set junction regulation temperature to 70 degrees
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x23, 0xE0, 0x20).fail);

        // Set the fast charge current value to 225mA
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x24, 0xFC, 0x74).fail);

        // Set the Vcool & Vwarm current to 112.5mA, and enable the thermistor
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x25, 0xFE, 0x3A).fail);

        // Set constant voltage to 4.3V for both fast charge and JEITA
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x26, 0xFC, 0x70).fail);
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x27, 0xFC, 0x70).fail);

        // Connect AMUX to battery voltage
        app_err(monocle_i2c_write(PMIC_I2C_ADDRESS, 0x28, 0x0F, 0x03).fail);
    }

    // Start the SPI drivers so deinit doesn't fail during shutdown
    {
        nrfx_spim_config_t spi_config = NRFX_SPIM_DEFAULT_CONFIG(
            DISPLAY_SPI_CLOCK_PIN,
            DISPLAY_SPI_DATA_PIN,
            NRF_SPIM_PIN_NOT_CONNECTED,
            NRF_SPIM_PIN_NOT_CONNECTED);

        spi_config.mode = NRF_SPIM_MODE_3;
        spi_config.bit_order = NRF_SPIM_BIT_ORDER_LSB_FIRST;

        app_err(nrfx_spim_init(&spi_bus, &spi_config, NULL, NULL));
    }

    // Check the case detect pin and set up interrupt
    {
    }
}
void mp_hal_stdout_tx_strn(const char *str, mp_uint_t len)
{
    for (uint16_t position = 0; position < len; position++)
    {
        // while (repl_tx.head == repl_tx.tail - 1)
        // {
        //     MICROPY_EVENT_POLL_HOOK;
        // }

        // repl_tx.buffer[repl_tx.head++] = str[position];

        // if (repl_tx.head == sizeof(repl_tx.buffer))
        // {
        //     repl_tx.head = 0;
        // }
    }
}

int mp_hal_stdin_rx_chr(void)
{
    // while (repl_rx.head == repl_rx.tail)
    // {
    //     MICROPY_EVENT_POLL_HOOK;
    // }

    // uint16_t next = repl_rx.tail + 1;

    // if (next == sizeof(repl_rx.buffer))
    // {
    //     next = 0;
    // }

    // int character = repl_rx.buffer[repl_rx.tail];

    // repl_rx.tail = next;

    return 03;
}
uintptr_t mp_hal_stdio_poll(uintptr_t poll_flags)
{
    // return (repl_rx.head == repl_rx.tail) ? poll_flags & MP_STREAM_POLL_RD : 0;
    return 0 ? poll_flags & MP_STREAM_POLL_RD : 0;
}

int main(void)
{
    NRFX_LOG(RTT_CTRL_CLEAR);
    NRFX_LOG("MicroPython on Frame - " BUILD_VERSION " (" GIT_COMMIT ")");
    NRFX_LOG("Logging from network core");

    setup_network_core();

    // TODO inform the application processor that the network has started

    while (1)
    {
    }
    // Soft resets will always restart micropython,
    // while (true)
    // {
    //     //     // Initialise the stack pointer for the main thread
    //     mp_stack_set_top(&_stack_top);

    //     //     // Set the stack limit as smaller than the real stack so we can recover
    //     mp_stack_set_limit((char *)&_stack_top - (char *)&_stack_bot - 512);

    //     //     // Start garbage collection, micropython and the REPL
    //     gc_init(&_heap_start, &_heap_end);
    //     mp_init();
    //     // readline_init0();
    //     pyexec_friendly_repl();
    //     //     // Mount the filesystem, or format if needed
    //     //     // pyexec_frozen_module("_mountfs.py", false);
    //     //     // pyexec_frozen_module("_splashscreen.py", false);

    //     //     // If safe mode is not enabled, run the user's main.py file
    //     //     // monocle_started_in_safe_mode() ? NRFX_LOG("Starting in safe mode")
    //     //     //                                : pyexec_file_if_exists("main.py");

    //     //     // Stay in the friendly or raw REPL until a reset is called
    //     //     for (;;)
    //     //     {
    //     //         if (pyexec_mode_kind == PYEXEC_MODE_RAW_REPL)
    //     //         {
    //     //             if (pyexec_raw_repl() != 0)
    //     //             {
    //     //                 break;
    //     //             }
    //     //         }
    //     //         else
    //     //         {
    //     //             if (pyexec_friendly_repl() != 0)
    //     //             {
    //     //                 break;
    //     //             }
    //     //         }
    //     //     }

    //     //     // On exit, clean up before reset
    //     // gc_sweep_all();
    //     // mp_deinit();

    //     // mp_hal_stdout_tx_str("MPY: soft reboot\r\n");
    // }
}

void gc_collect(void)
{
    // start the GC
    gc_collect_start();

    // Get stack pointer
    uintptr_t sp;
    __asm__("mov %0, sp\n"
            : "=r"(sp));

    // Trace the stack, including the registers
    // (since they live on the stack in this function)
    gc_collect_root((void **)sp, ((uint32_t)&_stack_top - sp) / sizeof(uint32_t));

    // end the GC
    gc_collect_end();
}

void nlr_jump_fail(void *val)
{
    app_err((uint32_t)val);
    NVIC_SystemReset();
}
mp_lexer_t *mp_lexer_new_from_file(const char *filename)
{
    mp_raise_OSError(MP_ENOENT);
}

mp_import_stat_t mp_import_stat(const char *path)
{
    return MP_IMPORT_STAT_NO_EXIST;
}

mp_obj_t mp_builtin_open(uint n_args, const mp_obj_t *args, mp_map_t *kwargs)
{
    return mp_const_none;
}
