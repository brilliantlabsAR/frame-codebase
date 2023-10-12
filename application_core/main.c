/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
 *              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
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

#include "camera_configuration.h"
#include "display_configuration.h"
#include "fpga_application.h"
#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "luaport.h"
#include "nrf_clock.h"
#include "nrf_gpio.h"
#include "nrf_oscillators.h"
#include "nrf.h"
#include "nrfx_gpiote.h"
#include "nrfx_log.h"
#include "nrfx_qspi.h"
#include "nrfx_rtc.h"
#include "nrfx_spim.h"
#include "nrfx_systick.h"
#include "nrfx_twim.h"
#include "pinout.h"

static const nrfx_rtc_t rtc = NRFX_RTC_INSTANCE(0);
static const nrfx_spim_t display_spi = NRFX_SPIM_INSTANCE(0);
static const nrfx_spim_t fpga_spi = NRFX_SPIM_INSTANCE(1);
static const nrfx_twim_t i2c = NRFX_TWIM_INSTANCE(2);

// static const uint8_t ACCELEROMETER_I2C_ADDRESS = 0x4C;
static const uint8_t CAMERA_I2C_ADDRESS = 0x6C;
static const uint8_t MAGNETOMETER_I2C_ADDRESS = 0x0C;
static const uint8_t PMIC_I2C_ADDRESS = 0x48;

static bool prevent_sleep = false;
static bool not_real_hardware = false;
static bool unpair = false;

typedef struct i2c_response_t
{
    bool fail;
    uint8_t value;
} i2c_response_t;

i2c_response_t i2c_read(uint8_t device_address_7bit,
                        uint16_t register_address,
                        uint8_t register_mask)
{
    if (not_real_hardware)
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
        nrfx_err_t tx_err = nrfx_twim_xfer(&i2c, &i2c_tx, 0);

        if (tx_err == NRFX_ERROR_NOT_SUPPORTED ||
            tx_err == NRFX_ERROR_INTERNAL ||
            tx_err == NRFX_ERROR_INVALID_ADDR ||
            tx_err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            check_error(tx_err);
        }

        nrfx_err_t rx_err = nrfx_twim_xfer(&i2c, &i2c_rx, 0);

        if (rx_err == NRFX_ERROR_NOT_SUPPORTED ||
            rx_err == NRFX_ERROR_INTERNAL ||
            rx_err == NRFX_ERROR_INVALID_ADDR ||
            rx_err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            check_error(rx_err);
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

i2c_response_t i2c_write(uint8_t device_address_7bit,
                         uint16_t register_address,
                         uint8_t register_mask,
                         uint8_t set_value)
{
    i2c_response_t resp = {.fail = false, .value = 0x00};

    if (not_real_hardware)
    {
        return resp;
    }

    if (register_mask != 0xFF)
    {
        resp = i2c_read(device_address_7bit, register_address, 0xFF);

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
        nrfx_err_t err = nrfx_twim_xfer(&i2c, &i2c_tx, 0);

        if (err == NRFX_ERROR_BUSY ||
            err == NRFX_ERROR_NOT_SUPPORTED ||
            err == NRFX_ERROR_INTERNAL ||
            err == NRFX_ERROR_INVALID_ADDR ||
            err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            check_error(err);
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

void spi_read(nrfx_spim_t const *instance, uint8_t *data, size_t length, uint32_t cs_pin, bool hold_down_cs)
{
    nrf_gpio_pin_clear(cs_pin);

    nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_RX(data, length);
    check_error(nrfx_spim_xfer(instance, &xfer, 0));

    if (!hold_down_cs)
    {
        nrf_gpio_pin_set(cs_pin);
    }
}

void spi_write(nrfx_spim_t const *instance, uint8_t *data, size_t length, uint32_t cs_pin, bool hold_down_cs)
{
    nrf_gpio_pin_clear(cs_pin);

    if (!nrfx_is_in_ram(data))
    {
        uint8_t *m_data = malloc(length);
        memcpy(m_data, data, length);
        nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_TX(m_data, length);
        check_error(nrfx_spim_xfer(instance, &xfer, 0));
        free(m_data);
    }
    else
    {
        nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_TX(data, length);
        check_error(nrfx_spim_xfer(instance, &xfer, 0));
    }

    if (!hold_down_cs)
    {
        nrf_gpio_pin_set(cs_pin);
    }
}

static void set_power_rails(bool enable)
{
    if (enable)
    {
        // Turn on SBB0 (1.0V rail) with 500mA limit
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x2A, 0x37, 0x26).fail);

        // Turn on LDO0 (1.2V rail)
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x39, 0x07, 0x06).fail);

        // Turn on SBB2 (2.7V rail) with 333mA limit
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x2E, 0x37, 0x36).fail);

        return;
    }

    // Turn off SBB2 (2.7V rail) with active discharge resistor on
    check_error(i2c_write(PMIC_I2C_ADDRESS, 0x2E, 0x0F, 0x0C).fail);

    // Turn off Turn on LDO0 (1.2V rail)
    check_error(i2c_write(PMIC_I2C_ADDRESS, 0x39, 0x0F, 0x0C).fail);

    // Turn off SBB0 (1.0V rail) with active discharge resistor on
    check_error(i2c_write(PMIC_I2C_ADDRESS, 0x2A, 0x0F, 0x0C).fail);
}

static void unused_rtc_event_handler(nrfx_rtc_int_type_t int_type) {}

static void case_detect_pin_interrupt_handler(nrfx_gpiote_pin_t pin,
                                              nrfx_gpiote_trigger_t trigger,
                                              void *p_context)
{
    // Disable interrupts to prevent too many triggers from pin bounces
    nrfx_gpiote_trigger_disable(CASE_DETECT_PIN);
    LOG("Going to sleep");

    // Ignore high to low interrupt. It's only used to wake up the device
    if (prevent_sleep)
    {
        LOG("Sleep prevented");

        // Short delay to prevent too many messages clogging things up
        nrfx_systick_delay_ms(100);

        // Re-enable interrupts before exiting
        nrfx_gpiote_trigger_enable(CASE_DETECT_PIN, true);
        return;
    }

    // Shutdown devices
    set_power_rails(false);
    // TODO, do we need a decay time like we had for Monocle?

    // Disable busses
    // nrfx_spim_uninit(&display_spi);
    // nrfx_spim_uninit(&fpga_spi);
    // nrfx_twim_uninit(&i2c);

    // Deinitialize all the pins
    for (uint8_t pin = 0; pin < 32; pin++)
    {
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(0, pin));
        // nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(1, pin));
    }

    // Set the wakeup pin to be the touch input
    nrf_gpio_cfg_sense_input(CASE_DETECT_PIN,
                             NRF_GPIO_PIN_PULLDOWN, // TODO remove this once we have a resistor
                             NRF_GPIO_PIN_SENSE_LOW);

    // Power off until the next pin interrupt
    NRF_REGULATORS->SYSTEMOFF = 1;
    __DSB();

    // Only required for debug mode where core doesn't actually sleep
    while (1)
    {
    }
}

static void network_core_message_handler(void)
{
    message_t message;

    while (message_pending(&message))
    {
        switch (message.command)
        {
        case RESET_REQUEST_FROM_NETWORK_CORE:
            NVIC_SystemReset();
            break;

        case BLUETOOTH_DATA_RECEIVED:
            bool success = lua_write_to_repl(message.payload,
                                             message.payload_length);

            if (success == false)
            {
                // Respond with error
            }

            break;

        default:
            error_with_message("Unhandled interprocessor message");
            break;
        }
    }
}

static void frame_setup_application_core(void)
{
    // Initialize the inter-processor communication for logging and bluetooth
    {
        setup_messaging(network_core_message_handler);
    }

    // Configure the clock sources
    {
        // // High frequency crystal uses internally configurable capacitors
        uint32_t capacitance_pf = 8;
        int32_t slope = NRF_FICR->XOSC32MTRIM & 0x1F;
        int32_t trim = (NRF_FICR->XOSC32MTRIM >> 5) & 0x1F;

        nrf_oscillators_hfxo_cap_set(
            NRF_OSCILLATORS,
            true,
            (1 + slope / 16) * (capacitance_pf * 2 - 14) + trim);

        nrf_clock_lf_src_set(NRF_CLOCK, NRF_CLOCK_LFCLK_SYNTH);
        nrf_clock_hf_src_set(NRF_CLOCK, NRF_CLOCK_HFCLK_HIGH_ACCURACY);
        nrf_clock_hfclk_div_set(NRF_CLOCK, NRF_CLOCK_HFCLK_DIV_1);
        nrf_clock_hfclk192m_src_set(NRF_CLOCK, NRF_CLOCK_HFCLK_HIGH_ACCURACY);

        nrf_clock_task_trigger(NRF_CLOCK, NRF_CLOCK_TASK_LFCLKSTART);
        nrf_clock_task_trigger(NRF_CLOCK, NRF_CLOCK_TASK_HFCLKSTART);
        nrf_clock_task_trigger(NRF_CLOCK, NRF_CLOCK_TASK_HFCLK192MSTART);
    }

    // Configure systick so we can use it for simple delays
    {
        SystemCoreClockUpdate();
        nrfx_systick_init();
    }

    // Configure the RTC
    {
        nrfx_rtc_config_t config = NRFX_RTC_DEFAULT_CONFIG;

        // 1024Hz = >1ms resolution
        config.prescaler = NRF_RTC_FREQ_TO_PRESCALER(1024);

        check_error(nrfx_rtc_init(&rtc,
                                  &config,
                                  unused_rtc_event_handler));
        nrfx_rtc_enable(&rtc);

        // Call tick interrupt every ms to wake up the core when in light sleep
        // TODO we can remove this if using nRF52 with Softdevice S140
        nrfx_rtc_tick_enable(&rtc, true);
    }

    // Configure the I2C driver
    {
        nrfx_twim_config_t i2c_config = {
            .scl_pin = I2C_SCL_PIN,
            .sda_pin = I2C_SDA_PIN,
            .frequency = NRF_TWIM_FREQ_100K,
            .interrupt_priority = NRFX_TWIM_DEFAULT_CONFIG_IRQ_PRIORITY,
            .hold_bus_uninit = false,
        };

        check_error(nrfx_twim_init(&i2c, &i2c_config, NULL, NULL));

        nrfx_twim_enable(&i2c);
    }

    // Scan the PMIC & IMU for their chip IDs. Camera is checked later
    {
        i2c_response_t magnetometer_response =
            i2c_read(MAGNETOMETER_I2C_ADDRESS, 0x0F, 0xFF);

        i2c_response_t pmic_response =
            i2c_read(PMIC_I2C_ADDRESS, 0x14, 0x0F);

        // If both chips fail to respond, it likely that we're using a devkit
        if (magnetometer_response.fail && pmic_response.fail)
        {
            LOG("Running on nRF5340-DK");
            not_real_hardware = true;
        }

        if (not_real_hardware == false)
        {
            if (magnetometer_response.value != 0x49)
            {
                error_with_message("Magnetometer not found");
            }

            if (pmic_response.value != 0x02)
            {
                error_with_message("PMIC not found");
            }
        }
    }

    // Configure the PMIC registers
    {
        // Set the SBB drive strength
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x2F, 0x03, 0x01).fail);

        // Set SBB0 to 1.0V
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x29, 0x7F, 0x04).fail);

        // Set SBB2 to 2.7V
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x2D, 0x7F, 0x26).fail);

        // Set LDO0 to 1.2V
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x38, 0x7F, 0x10).fail);

        // Turn/keep off FPGA before FPGA configuration
        set_power_rails(false);

        // Vhot & Vwarm = 45 degrees. Vcool = 15 degrees. Vcold = 0 degrees
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x20, 0xFF, 0x2E).fail);

        // Set CHGIN limit to 475mA
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x21, 0x1C, 0x10).fail);

        // Charge termination current to 5%, and top-off timer to 30mins
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x22, 0x1F, 0x06).fail);

        // Set junction regulation temperature to 70 degrees
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x23, 0xE0, 0x20).fail);

        // Set the fast charge current value to 225mA
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x24, 0xFC, 0x74).fail);

        // Set the Vcool & Vwarm current to 112.5mA, and enable the thermistor
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x25, 0xFE, 0x3A).fail);

        // Set constant voltage to 4.3V for both fast charge and JEITA
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x26, 0xFC, 0x70).fail);
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x27, 0xFC, 0x70).fail);

        // Connect AMUX to battery voltage
        check_error(i2c_write(PMIC_I2C_ADDRESS, 0x28, 0x0F, 0x03).fail);
    }

    // Configure case detect pin interrupt and check the starting state
    {
        check_error(nrfx_gpiote_init(NRFX_GPIOTE_DEFAULT_CONFIG_IRQ_PRIORITY));

        nrfx_gpiote_input_config_t input_config = {
            .pull = NRF_GPIO_PIN_PULLDOWN, // TODO remove this once we have a real resistor
        };

        nrfx_gpiote_trigger_config_t trigger_config = {
            .trigger = NRFX_GPIOTE_TRIGGER_LOTOHI,
            .p_in_channel = NULL,
        };

        nrfx_gpiote_handler_config_t handler_config = {
            .handler = case_detect_pin_interrupt_handler,
            .p_context = NULL,
        };

        check_error(nrfx_gpiote_input_configure(CASE_DETECT_PIN,
                                                &input_config,
                                                &trigger_config,
                                                &handler_config));

        bool case_detect_pin = nrf_gpio_pin_read(CASE_DETECT_PIN);

        // Check if the device is docked by reading STAT_CHG_B
        i2c_response_t charger_status = i2c_read(PMIC_I2C_ADDRESS, 0x03, 0x0C);
        check_error(charger_status.fail);
        bool charging = charger_status.value;

        if (charging)
        {
            // Just go to sleep if the case detect pin is high
            if (case_detect_pin == true)
            {
                case_detect_pin_interrupt_handler(CASE_DETECT_PIN,
                                                  NRFX_GPIOTE_TRIGGER_HIGH,
                                                  NULL);
            }

            // Otherwise it means the button was pressed. Un-pair
            else
            {
                LOG("Un-pairing");
                unpair = true;
            }
        }

        // Enable the interrupt for catching the next docking event
        nrfx_gpiote_trigger_enable(CASE_DETECT_PIN, true);
    }

    // Set up ADC for battery level monitoring
    {
        // TODO
    }

    // Read the PMIC status pin. If on charge, go to sleep right away
    {
        // TODO
    }

    // Load and start the FPGA image
    {
        nrf_gpio_cfg_output(FPGA_PROGRAM_PIN);
        nrf_gpio_cfg_output(FPGA_SPI_SELECT_PIN);

        nrf_gpio_pin_clear(FPGA_PROGRAM_PIN);
        nrf_gpio_pin_set(FPGA_SPI_SELECT_PIN);

        set_power_rails(true);
        nrfx_systick_delay_ms(5);

        nrfx_spim_config_t fpga_spi_config = NRFX_SPIM_DEFAULT_CONFIG(
            FPGA_SPI_CLOCK_PIN,
            FPGA_SPI_IO0_PIN,
            FPGA_SPI_IO1_PIN,
            NRF_SPIM_PIN_NOT_CONNECTED);

        fpga_spi_config.frequency = NRFX_MHZ_TO_HZ(8);

        check_error(nrfx_spim_init(&fpga_spi,
                                   &fpga_spi_config,
                                   NULL,
                                   NULL));

        uint8_t fpga_magic_word[5] = {0xFF, 0xA4, 0xC6, 0xF4, 0x8A};
        spi_write(&fpga_spi, fpga_magic_word, 5, FPGA_SPI_SELECT_PIN, false);

        nrf_gpio_pin_set(FPGA_PROGRAM_PIN);

        nrfx_systick_delay_ms(1);

        uint8_t fpga_id_code[4] = {0xE0, 0x00, 0x00, 0x00};
        uint8_t fpga_response[8];
        spi_write(&fpga_spi, fpga_id_code, 4, FPGA_SPI_SELECT_PIN, true);
        spi_read(&fpga_spi, fpga_response, 4, FPGA_SPI_SELECT_PIN, false);
        LOG("FPGA ID: 0x%02hhX%02hhX%02hhX%02hhX", fpga_response[0], fpga_response[1], fpga_response[2], fpga_response[3]);

        uint8_t fpga_prog_enable[4] = {0xC6, 0x00, 0x00, 0x00};
        spi_write(&fpga_spi, fpga_prog_enable, 4, FPGA_SPI_SELECT_PIN, false);

        nrfx_systick_delay_ms(1);

        uint8_t fpga_erase[4] = {0x0E, 0x00, 0x00, 0x00};
        spi_write(&fpga_spi, fpga_erase, 4, FPGA_SPI_SELECT_PIN, false);

        nrfx_systick_delay_ms(200);

        uint8_t fpga_init[4] = {0x46, 0x00, 0x00, 0x00};
        spi_write(&fpga_spi, fpga_init, 4, FPGA_SPI_SELECT_PIN, false);

        uint8_t fpga_bitstream_start[4] = {0x7A, 0x00, 0x00, 0x00};
        spi_write(&fpga_spi, fpga_bitstream_start, 4, FPGA_SPI_SELECT_PIN, true);

        LOG("Writing FPGA binary");
        for (uint32_t i = 0; i < build_fpga_rtl_bit_len; i++)
        {
            spi_write(&fpga_spi, &build_fpga_rtl_bit[i], 1, FPGA_SPI_SELECT_PIN, true);
        }
        nrf_gpio_pin_set(FPGA_SPI_SELECT_PIN);

        nrfx_systick_delay_ms(20);

        uint8_t fpga_read_status[4] = {0x3C, 0x00, 0x00, 0x00};
        spi_write(&fpga_spi, fpga_read_status, 4, FPGA_SPI_SELECT_PIN, true);
        spi_read(&fpga_spi, fpga_response, 4, FPGA_SPI_SELECT_PIN, false);
        LOG("FPGA status: 0x%02hhX%02hhX%02hhX%02hhX", fpga_response[0], fpga_response[1], fpga_response[2], fpga_response[3]);

        uint8_t fpga_prog_exit[4] = {0x26, 0x00, 0x00, 0x00};
        spi_write(&fpga_spi, fpga_prog_exit, 4, FPGA_SPI_SELECT_PIN, false);

        nrfx_systick_delay_ms(200);

        uint8_t fpga_no_op[4] = {0xFF, 0xFF, 0xFF, 0xFF};
        spi_write(&fpga_spi, fpga_no_op, 4, FPGA_SPI_SELECT_PIN, false);

        LOG("Done");

        // Attempt to read FPGA ID from the running application
        if (not_real_hardware == false)
        {
            // if (id_value[0] != 0x0A)
            {
                // error_with_message("FPGA not found");
            }
        }
    }

    // Initialize the SPI and configure the display
    {
        nrf_gpio_pin_set(DISPLAY_SPI_SELECT_PIN);
        nrf_gpio_cfg_output(DISPLAY_SPI_SELECT_PIN);

        nrfx_spim_config_t display_spi_config = NRFX_SPIM_DEFAULT_CONFIG(
            DISPLAY_SPI_CLOCK_PIN,
            DISPLAY_SPI_DATA_PIN,
            NRF_SPIM_PIN_NOT_CONNECTED,
            NRF_SPIM_PIN_NOT_CONNECTED);

        display_spi_config.mode = NRF_SPIM_MODE_3;
        display_spi_config.bit_order = NRF_SPIM_BIT_ORDER_LSB_FIRST;

        check_error(nrfx_spim_init(&display_spi,
                                   &display_spi_config,
                                   NULL,
                                   NULL));

        for (size_t i = 0;
             i < sizeof(display_config) / sizeof(display_config_t);
             i++)
        {
            uint8_t command[2] = {display_config[i].address,
                                  display_config[i].value};

            spi_write(&display_spi, command, sizeof(command), DISPLAY_SPI_SELECT_PIN, false);
        }
    }

    // Configure the camera
    {
        // Wake up the camera
        nrf_gpio_pin_write(CAMERA_SLEEP_PIN, false);

        // Check the chip ID
        i2c_response_t camera_response =
            i2c_read(CAMERA_I2C_ADDRESS, 0x300A, 0xFF);

        if (not_real_hardware == false)
        {
            if (camera_response.value != 0x97)
            {
                // error_with_message("Camera not found");
            }
        }

        // Program the configuration
        for (size_t i = 0;
             i < sizeof(camera_config) / sizeof(camera_config_t);
             i++)
        {
            i2c_write(CAMERA_I2C_ADDRESS,
                      camera_config[i].address,
                      0xFF,
                      camera_config[i].value);
        }

        // Put the camera to sleep
        nrf_gpio_pin_write(CAMERA_SLEEP_PIN, true);
    }

    // Turn on the network core
    {
        NRF_RESET->NETWORK.FORCEOFF = 0;
    }

    LOG("Application core configured");
}

int main(void)
{
    frame_setup_application_core();

    LOG("Lua on Frame - " BUILD_VERSION "(" GIT_COMMIT ")");

    while (1)
    {
        run_lua();
    }
}