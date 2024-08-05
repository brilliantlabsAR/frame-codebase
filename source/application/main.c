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
#include "compression.h"
#include "display_configuration.h"
#include "error_logging.h"
#include "fpga_application.h"
#include "i2c.h"
#include "luaport.h"
#include "nrf_clock.h"
#include "nrf_gpio.h"
#include "nrf_sdm.h"
#include "nrf.h"
#include "nrfx_gpiote.h"
#include "nrfx_log.h"
#include "nrfx_rtc.h"
#include "nrfx_systick.h"
#include "pinout.h"
#include "spi.h"

bool not_real_hardware = false;
bool stay_awake = false;

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

    // Turn off LDO0 (1.2V rail)
    check_error(i2c_write(PMIC, 0x39, 0x0F, 0x0C).fail);

    // Turn off SBB0 (1.0V rail) with active discharge resistor on
    check_error(i2c_write(PMIC, 0x2A, 0x0F, 0x0C).fail);
}

void shutdown(bool enable_imu_wakeup)
{
    nrfx_gpiote_trigger_disable(CASE_DETECT_PIN);

    if (stay_awake)
    {
        LOG("Staying awake");
        // Debounce and avoid the interrupt being called multiple times
        nrfx_systick_delay_ms(100);
        nrfx_gpiote_trigger_enable(CASE_DETECT_PIN, true);
        return;
    }

    uint8_t display_power_save[1] = {0x92};
    spi_write(DISPLAY, 0x00, display_power_save, sizeof(display_power_save));

    nrf_gpio_pin_write(CAMERA_SLEEP_PIN, false);

    // Put magnetometer into standby
    check_error(i2c_write(MAGNETOMETER, 0x1B, 0x80, 0x00).fail);

    // Put accelerometer into standby if not needed for wakeup
    if (!enable_imu_wakeup)
    {
        check_error(i2c_write(ACCELEROMETER, 0x07, 0xFF, 0x00).fail);
    }

    nrf_gpio_pin_clear(FPGA_PROGRAM_PIN);
    nrfx_systick_delay_ms(100);

    check_error(sd_softdevice_disable());

    set_power_rails(false);
    nrfx_systick_delay_ms(100);

    // Disconnect AMUX
    check_error(i2c_write(PMIC, 0x28, 0x0F, 0x00).fail);

    // Put PMIC main bias into low power mode
    check_error(i2c_write(PMIC, 0x10, 0x20, 0x20).fail);

    // Set ICHGIN_LIM to 285mA
    check_error(i2c_write(PMIC, 0x21, 0x1C, 0x08).fail);

    for (uint8_t pin = 0; pin < 16; pin++)
    {
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(0, pin));
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(0, pin + 16));
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(1, pin));
    }

    nrf_gpio_cfg_sense_input(CASE_DETECT_PIN,
                             NRF_GPIO_PIN_NOPULL,
                             NRF_GPIO_PIN_SENSE_LOW);

    if (enable_imu_wakeup)
    {
        nrf_gpio_cfg_sense_input(IMU_INTERRUPT_PIN,
                                 NRF_GPIO_PIN_NOPULL,
                                 NRF_GPIO_PIN_SENSE_LOW);
    }

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

void case_detect_pin_interrupt_handler(nrfx_gpiote_pin_t unused_gptiote_pin,
                                       nrfx_gpiote_trigger_t unused_gptiote_trigger,
                                       void *unused_gptiote_context_pointer)
{
    shutdown(false);
}

static void fpga_send_bitstream_bytes(void *context,
                                      void *data,
                                      size_t data_size)
{
    spi_write_raw(FPGA, data, data_size);
}

static void hardware_setup(bool *factory_reset)
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

        // Charge termination current to 10%, and top-off timer to 0mins
        check_error(i2c_write(PMIC, 0x22, 0x1F, 0x10).fail);

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
            .pull = NRF_GPIO_PIN_NOPULL,
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
        i2c_response_t charger_status = i2c_read(PMIC, 0x03, 0x0C);
        check_error(charger_status.fail);
        bool charging = charger_status.value;

        if (charging)
        {
            // Just go to sleep if the case detect pin is high
            if (case_detect_pin == true)
            {
                shutdown(false);
            }

            // Otherwise it means the button was pressed. Un-pair
            else
            {
                LOG("Factory reset");
                *factory_reset = true;
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

        uint8_t activation_key[4] = {0xA4, 0xC6, 0xF4, 0x8A};
        spi_write(FPGA, 0xFF, activation_key, sizeof(activation_key));
        nrf_gpio_pin_set(FPGA_PROGRAM_PIN);
        nrfx_systick_delay_ms(1);

        uint8_t enable_programming[3] = {0x00, 0x00, 0x00};
        spi_write(FPGA, 0xC6, enable_programming, sizeof(enable_programming));
        nrfx_systick_delay_ms(1);

        uint8_t erase_device[3] = {0x00, 0x00, 0x00};
        spi_write(FPGA, 0x0E, erase_device, sizeof(erase_device));
        nrfx_systick_delay_ms(200);

        uint8_t initialise_address[3] = {0x00, 0x00, 0x00};
        spi_write(FPGA, 0x46, initialise_address, sizeof(initialise_address));

        uint8_t bitstream_burst[4] = {0x7A, 0x00, 0x00, 0x00};
        spi_write_raw(FPGA, bitstream_burst, sizeof(bitstream_burst));

        int status = compression_decompress(4096,
                                            fpga_application,
                                            sizeof(fpga_application),
                                            fpga_send_bitstream_bytes,
                                            NULL);

        if (status)
        {
            LOG("%d", status);
            error_with_message("Error decompressing bitstream");
        }

        nrf_gpio_pin_set(FPGA_SPI_SELECT_PIN);
        nrfx_systick_delay_ms(10);

        uint8_t exit_programming[3] = {0x00, 0x00, 0x00};
        spi_write(FPGA, 0x26, exit_programming, sizeof(exit_programming));
        nrfx_systick_delay_ms(200);

        uint8_t fpga_chip_id[1] = {0x00};
        spi_read(FPGA, 0xDB, fpga_chip_id, sizeof(fpga_chip_id));

        if (not_real_hardware == false)
        {
            if (fpga_chip_id[0] != 0x81)
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
            uint8_t data[1] = {display_config[i].value};
            spi_write(DISPLAY, display_config[i].address, data, sizeof(data));
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
    }
}

int main(void)
{
    LOG("Frame firmware " BUILD_VERSION " (" GIT_COMMIT ")");

    bool factory_reset = false;

    hardware_setup(&factory_reset);

    bluetooth_setup(factory_reset);

    while (1)
    {
        run_lua(factory_reset);

        factory_reset = false;
    }
}