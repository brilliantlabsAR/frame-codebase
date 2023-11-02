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

#include <stdbool.h>
#include <math.h>
#include <stdint.h>
#include "bluetooth.h"
#include "camera_configuration.h"
#include "display_configuration.h"
#include "error_logging.h"
#include "fpga_application.h"
#include "i2c.h"
#include "luaport.h"
#include "nrf_clock.h"
#include "nrf_gpio.h"
#include "nrf.h"
#include "nrf_sdm.h"
#include "nrfx_gpiote.h"
#include "nrfx_log.h"
#include "nrfx_rtc.h"
#include "nrfx_systick.h"
#include "pinout.h"
#include "spi.h"

bool not_real_hardware = false;
bool stay_awake = false;
bool force_sleep = false;
bool unpair = false;

static void set_power_rails(bool enable)
{
    if (enable)
    {
        // Turn on SBB0 (1.0V rail) with 500mA limit
        check_error(i2c_write(PMIC, 0x2A, 0x37, 0x26).fail);

        // Turn on LDO0 (1.2V rail)
        check_error(i2c_write(PMIC, 0x39, 0x07, 0x06).fail);

        // Turn on SBB2 (2.7V rail) with 333mA limit
        check_error(i2c_write(PMIC, 0x2E, 0x37, 0x36).fail);

        return;
    }

    // Turn off SBB2 (2.7V rail) with active discharge resistor on
    check_error(i2c_write(PMIC, 0x2E, 0x0F, 0x0C).fail);

    // Turn off Turn on LDO0 (1.2V rail)
    check_error(i2c_write(PMIC, 0x39, 0x0F, 0x0C).fail);

    // Turn off SBB0 (1.0V rail) with active discharge resistor on
    check_error(i2c_write(PMIC, 0x2A, 0x0F, 0x0C).fail);
}

void shutdown(nrfx_gpiote_pin_t unused_gptiote_pin,
              nrfx_gpiote_trigger_t unused_gptiote_trigger,
              void *unused_gptiote_context_pointer)
{
    // This helps to debounce and stops the interrupt being called too often
    nrfx_gpiote_trigger_disable(CASE_DETECT_PIN);
    nrfx_systick_delay_ms(100);

    if (stay_awake)
    {
        LOG("Staying awake");
        nrfx_gpiote_trigger_enable(CASE_DETECT_PIN, true);
        return;
    }

    check_error(sd_softdevice_disable());

    set_power_rails(false);

    // Disconnect AMUX
    check_error(i2c_write(PMIC, 0x28, 0x0F, 0x00).fail);

    // Put PMIC main bias into low power mode
    check_error(i2c_write(PMIC, 0x10, 0x20, 0x20).fail);

    // TODO deinit IMU interrupt

    for (uint8_t pin = 0; pin < 32; pin++)
    {
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(0, pin));
    }

    for (uint8_t pin = 0; pin < 16; pin++)
    {
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(1, pin));
    }

    nrf_gpio_cfg_sense_input(CASE_DETECT_PIN,
                             NRF_GPIO_PIN_PULLDOWN,
                             NRF_GPIO_PIN_SENSE_LOW);

    // Clear the reset reasons
    NRF_POWER->RESETREAS = 0xF000F;

    LOG("Going to sleep");

    NRF_POWER->SYSTEMOFF = 1;
    __DSB();

    // Only required for debug mode where core doesn't actually sleep
    while (1)
    {
    }
}

static void hardware_setup()
{
    // Configure systick so we can use it for simple delays
    {
        nrfx_systick_init();
    }

    // Configure the I2C and SPI drivers
    {
        i2c_configure();
        spi_configure();
    }

    // Scan the PMIC & IMU for their chip IDs. Camera is checked later
    {
        i2c_response_t magnetometer_id = i2c_read(MAGNETOMETER, 0x0F, 0xFF);
        i2c_response_t pmic_id = i2c_read(PMIC, 0x14, 0x0F);

        if (magnetometer_id.fail && pmic_id.fail)
        {
            LOG("Running on fake hardware");
            not_real_hardware = true;
        }

        else
        {
            if (magnetometer_id.value != 0x49)
            {
                error_with_message("Magnetometer not found");
            }

            if (pmic_id.value != 0x02)
            {
                error_with_message("PMIC not found");
            }
        }
    }

    // Configure the PMIC registers
    {
        // Set the SBB drive strength
        check_error(i2c_write(PMIC, 0x2F, 0x03, 0x01).fail);

        // Set SBB0 to 1.0V
        check_error(i2c_write(PMIC, 0x29, 0x7F, 0x04).fail);

        // Set SBB2 to 2.7V
        check_error(i2c_write(PMIC, 0x2D, 0x7F, 0x26).fail);

        // Set LDO0 to 1.2V
        check_error(i2c_write(PMIC, 0x38, 0x7F, 0x10).fail);

        // Turn/keep off FPGA before FPGA configuration
        set_power_rails(false);

        // Vhot & Vwarm = 45 degrees. Vcool = 15 degrees. Vcold = 0 degrees
        check_error(i2c_write(PMIC, 0x20, 0xFF, 0x2E).fail);

        // Set CHGIN limit to 475mA
        check_error(i2c_write(PMIC, 0x21, 0x1C, 0x10).fail);

        // Charge termination current to 5%, and top-off timer to 30mins
        check_error(i2c_write(PMIC, 0x22, 0x1F, 0x06).fail);

        // Set junction regulation temperature to 70 degrees
        check_error(i2c_write(PMIC, 0x23, 0xE0, 0x20).fail);

        // Set the fast charge current value to 225mA
        check_error(i2c_write(PMIC, 0x24, 0xFC, 0x74).fail);

        // Set the Vcool & Vwarm current to 112.5mA, and enable the thermistor
        check_error(i2c_write(PMIC, 0x25, 0xFE, 0x3A).fail);

        // Set constant voltage to 4.3V for both fast charge and JEITA
        check_error(i2c_write(PMIC, 0x26, 0xFC, 0x70).fail);
        check_error(i2c_write(PMIC, 0x27, 0xFC, 0x70).fail);

        // Connect AMUX to battery voltage
        check_error(i2c_write(PMIC, 0x28, 0x0F, 0x03).fail);
    }

    // Configure case detect pin interrupt and check the starting state
    {
        check_error(nrfx_gpiote_init(NRFX_GPIOTE_DEFAULT_CONFIG_IRQ_PRIORITY));

        nrfx_gpiote_input_config_t input_config = {
            .pull = NRF_GPIO_PIN_PULLDOWN, // TODO make this no pull once we get real hardware
        };

        nrfx_gpiote_trigger_config_t trigger_config = {
            .trigger = NRFX_GPIOTE_TRIGGER_LOTOHI,
            .p_in_channel = NULL,
        };

        nrfx_gpiote_handler_config_t handler_config = {
            .handler = shutdown,
            .p_context = NULL,
        };

        check_error(nrfx_gpiote_input_configure(CASE_DETECT_PIN,
                                                &input_config,
                                                &trigger_config,
                                                &handler_config));

        bool case_detect_pin = nrf_gpio_pin_read(CASE_DETECT_PIN);

        // Check if the device is docked by reading STAT_CHG_B
        i2c_response_t charger_status = i2c_read(PMIC, 0x03, 0x0C);
        check_error(charger_status.fail);
        bool charging = charger_status.value;

        // if (charging)
        {
            // Just go to sleep if the case detect pin is high
            if (case_detect_pin == true)
            {
                shutdown(0, 0, NULL);
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

    // Load and start the FPGA image
    {
        nrf_gpio_cfg_output(FPGA_PROGRAM_PIN);
        nrf_gpio_pin_clear(FPGA_PROGRAM_PIN);

        set_power_rails(true);
        nrfx_systick_delay_ms(5);

        uint8_t fpga_activation_key[5] = {0xFF, 0xA4, 0xC6, 0xF4, 0x8A};
        spi_write(FPGA, fpga_activation_key, 5, false);
        nrf_gpio_pin_set(FPGA_PROGRAM_PIN);
        nrfx_systick_delay_ms(1);

        uint8_t fpga_enable_programming_mode[4] = {0xC6, 0x00, 0x00, 0x00};
        spi_write(FPGA, fpga_enable_programming_mode, 4, false);
        nrfx_systick_delay_ms(1);

        uint8_t fpga_erase_device[4] = {0x0E, 0x00, 0x00, 0x00};
        spi_write(FPGA, fpga_erase_device, 4, false);
        nrfx_systick_delay_ms(200);

        uint8_t fpga_initialise_address[4] = {0x46, 0x00, 0x00, 0x00};
        spi_write(FPGA, fpga_initialise_address, 4, false);

        uint8_t fpga_bitstream_burst[4] = {0x7A, 0x00, 0x00, 0x00};
        spi_write(FPGA, fpga_bitstream_burst, 4, true);

        size_t chunk_size = 16384;
        size_t chunks = (size_t)ceilf((float)sizeof(fpga_application) /
                                      (float)chunk_size);

        uint8_t *fpga_bitstream_buffer = malloc(chunk_size);
        if (fpga_bitstream_buffer == NULL)
        {
            error_with_message("Couldn't allocate FPGA SPI buffer");
        }

        for (size_t chunk = 0; chunk < chunks; chunk++)
        {
            size_t buffer_size = chunk_size;

            // Buffer size will be smaller for the last payload
            if (chunk == chunks - 1)
            {
                buffer_size = sizeof(fpga_application) % chunk_size;
            }

            memcpy(fpga_bitstream_buffer,
                   fpga_application + (chunk * chunk_size),
                   buffer_size);
            spi_write(FPGA, fpga_bitstream_buffer, buffer_size, true);
        }

        free(fpga_bitstream_buffer);

        nrf_gpio_pin_set(FPGA_SPI_SELECT_PIN);
        nrfx_systick_delay_ms(10);

        uint8_t fpga_exit_programming_mode[4] = {0x26, 0x00, 0x00, 0x00};
        spi_write(FPGA, fpga_exit_programming_mode, 4, false);
        nrfx_systick_delay_ms(200);

        uint8_t fpga_chip_id[1] = {0x00};
        spi_write(FPGA, fpga_chip_id, 1, true);
        spi_read(FPGA, fpga_chip_id, 1, false);

        if (not_real_hardware == false)
        {
            if (fpga_chip_id[0] != 0xAA)
            {
                error_with_message("FPGA not found");
            }
        }
    }

    // Initialize the SPI and configure the display
    {
        for (size_t i = 0;
             i < sizeof(display_config) / sizeof(display_config_t);
             i++)
        {
            uint8_t command[2] = {display_config[i].address,
                                  display_config[i].value};

            spi_write(DISPLAY, command, sizeof(command), false);
        }
    }

    // Configure the camera
    {
        // Wake up the camera
        nrf_gpio_cfg_output(CAMERA_SLEEP_PIN);
        nrf_gpio_pin_write(CAMERA_SLEEP_PIN, true);
        nrfx_systick_delay_ms(1);

        // Check the chip ID
        i2c_response_t camera_id = i2c_read(CAMERA, 0x300A, 0xFF);

        if (not_real_hardware == false)
        {
            if (camera_id.value != 0x97)
            {
                error_with_message("Camera not found");
            }
        }

        // Program the configuration
        for (size_t i = 0;
             i < sizeof(camera_config) / sizeof(camera_config_t);
             i++)
        {
            i2c_write(CAMERA,
                      camera_config[i].address,
                      0xFF,
                      camera_config[i].value);
        }

        // Put the camera to sleep
        // nrf_gpio_pin_write(CAMERA_SLEEP_PIN, false);
    }
}

int main(void)
{
    LOG(RTT_CTRL_CLEAR);

    hardware_setup();

    bluetooth_setup();

    while (1)
    {
        run_lua();
    }
}