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

#include "camera_configuration.h"
#include "display_configuration.h"
#include "error_helpers.h"
#include "nrf.h"
#include "nrfx_log.h"
#include "nrfx_rtc.h"
#include "nrfx_spim.h"
#include "nrfx_twim.h"
#include "pinout.h"

static const nrfx_twim_t i2c_bus = NRFX_TWIM_INSTANCE(0);
static const nrfx_spim_t spi_bus = NRFX_SPIM_INSTANCE(0);

// static const uint8_t ACCELEROMETER_I2C_ADDRESS = 0x4C;
static const uint8_t CAMERA_I2C_ADDRESS = 0x6C;
static const uint8_t MAGNETOMETER_I2C_ADDRESS = 0x0C;
static const uint8_t PMIC_I2C_ADDRESS = 0x48;

static bool not_real_hardware_flag = false;

void unused_rtc_event_handler(nrfx_rtc_int_type_t int_type) {}

typedef struct i2c_response_t
{
    bool fail;
    uint8_t value;
} i2c_response_t;

i2c_response_t i2c_read(uint8_t device_address_7bit,
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

i2c_response_t i2c_write(uint8_t device_address_7bit,
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

void spi_read(uint8_t *data, size_t length, uint32_t cs_pin, bool hold_down_cs)
{
    nrf_gpio_pin_clear(cs_pin);

    nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_RX(data, length);
    app_err(nrfx_spim_xfer(&spi_bus, &xfer, 0));

    if (!hold_down_cs)
    {
        nrf_gpio_pin_set(cs_pin);
    }
}

void spi_write(uint8_t *data, size_t length, uint32_t cs_pin, bool hold_down_cs)
{
    nrf_gpio_pin_clear(cs_pin);

    if (!nrfx_is_in_ram(data))
    {
        uint8_t *m_data = malloc(length);
        memcpy(m_data, data, length);
        nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_TX(m_data, length);
        app_err(nrfx_spim_xfer(&spi_bus, &xfer, 0));
        free(m_data);
    }
    else
    {
        nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_TX(data, length);
        app_err(nrfx_spim_xfer(&spi_bus, &xfer, 0));
    }

    if (!hold_down_cs)
    {
        nrf_gpio_pin_set(cs_pin);
    }
}

// static void power_down_network_core(void)
// {
// }

static void setup_network_core(void)
{
    // Start the RTC
    {
        nrfx_rtc_t rtc = NRFX_RTC_INSTANCE(0);
        nrfx_rtc_config_t config = NRFX_RTC_DEFAULT_CONFIG;

        // 1024Hz = >1ms resolution
        config.prescaler = NRF_RTC_FREQ_TO_PRESCALER(1024);

        app_err(nrfx_rtc_init(&rtc, &config, unused_rtc_event_handler));
        nrfx_rtc_enable(&rtc);

        // Call tick interrupt every ms to wake up the core
        nrfx_rtc_tick_enable(&rtc, true);
    }

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

    // Scan PMIC & IMU for their chip IDs. Camera is checked later
    {
        i2c_response_t magnetometer_response =
            i2c_read(MAGNETOMETER_I2C_ADDRESS, 0x0F, 0xFF);

        i2c_response_t pmic_response =
            i2c_read(PMIC_I2C_ADDRESS, 0x14, 0x0F);

        // If both chips fail to respond, it likely that we're using a devkit
        if (magnetometer_response.fail && pmic_response.fail)
        {
            NRFX_LOG("Running on nRF5340-DK");
            not_real_hardware_flag = true;
        }

        if (not_real_hardware_flag == false)
        {
            if (magnetometer_response.value != 0x49)
            {
                app_err(HARDWARE_ERROR);
            }

            if (pmic_response.value != 0x02)
            {
                app_err(HARDWARE_ERROR);
            }
        }
    }

    // Set up PMIC
    {
        // Set the SBB drive strength
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2F, 0x03, 0x01).fail);

        // Set SBB0 to 1.0V
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x29, 0x7F, 0x04).fail);

        // Set SBB2 to 2.7V
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2D, 0x7F, 0x26).fail);

        // Set LDO0 to 1.2V
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x38, 0x7F, 0x10).fail);

        // Turn on SBB0 (1.0V rail) with 500mA limit
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2A, 0x37, 0x26).fail);

        // Turn on LDO0 (1.2V rail)
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x39, 0x07, 0x06).fail);

        // Turn on SBB2 (2.7V rail) with 333mA limit
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2E, 0x37, 0x36).fail);

        // Vhot & Vwarm = 45 degrees. Vcool = 15 degrees. Vcold = 0 degrees
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x20, 0xFF, 0x2E).fail);

        // Set CHGIN limit to 475mA
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x21, 0x1C, 0x10).fail);

        // Charge termination current to 5%, and top-off timer to 30mins
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x22, 0x1F, 0x06).fail);

        // Set junction regulation temperature to 70 degrees
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x23, 0xE0, 0x20).fail);

        // Set the fast charge current value to 225mA
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x24, 0xFC, 0x74).fail);

        // Set the Vcool & Vwarm current to 112.5mA, and enable the thermistor
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x25, 0xFE, 0x3A).fail);

        // Set constant voltage to 4.3V for both fast charge and JEITA
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x26, 0xFC, 0x70).fail);
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x27, 0xFC, 0x70).fail);

        // Connect AMUX to battery voltage
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x28, 0x0F, 0x03).fail);

        nrfx_twim_uninit(&i2c_bus);
    }

    // Configure the display
    {
        nrf_gpio_cfg_output(DISPLAY_SPI_SELECT_PIN);
        nrf_gpio_pin_set(DISPLAY_SPI_SELECT_PIN);

        nrfx_spim_config_t spi_config = NRFX_SPIM_DEFAULT_CONFIG(
            DISPLAY_SPI_CLOCK_PIN,
            DISPLAY_SPI_DATA_PIN,
            NRF_SPIM_PIN_NOT_CONNECTED,
            NRF_SPIM_PIN_NOT_CONNECTED);

        spi_config.mode = NRF_SPIM_MODE_3;
        spi_config.bit_order = NRF_SPIM_BIT_ORDER_LSB_FIRST;

        app_err(nrfx_spim_init(&spi_bus, &spi_config, NULL, NULL));

        for (size_t i = 0;
             i < sizeof(display_config) / sizeof(display_config_t);
             i++)
        {
            uint8_t command[2] = {display_config[i].address,
                                  display_config[i].value};

            spi_write(command, sizeof(command), DISPLAY_SPI_SELECT_PIN, false);
        }

        nrfx_spim_uninit(&spi_bus);
    }

    // Configure the FPGA
    {
        nrf_gpio_cfg_output(FPGA_SPI_SELECT_PIN);
        nrf_gpio_pin_set(FPGA_SPI_SELECT_PIN);

        nrfx_spim_config_t spi_config = NRFX_SPIM_DEFAULT_CONFIG(
            FPGA_SPI_CLOCK_PIN,
            FPGA_SPI_IO0_PIN,
            NRF_SPIM_PIN_NOT_CONNECTED,
            NRF_SPIM_PIN_NOT_CONNECTED);

        app_err(nrfx_spim_init(&spi_bus, &spi_config, NULL, NULL));

        // Program the FPGA

        // Wait until FPGA has started

        // Check the chip ID
        uint8_t id_register[1] = {0x00};
        uint8_t id_value[1];

        spi_write(id_register, sizeof(id_register), FPGA_SPI_SELECT_PIN, true);
        spi_read(id_value, sizeof(id_value), FPGA_SPI_SELECT_PIN, false);

        if (not_real_hardware_flag == false)
        {
            if (id_value[0] != 0x0A)
            {
                app_err(HARDWARE_ERROR);
            }
        }

        nrfx_spim_uninit(&spi_bus);
    }

    // Configure the camera
    {
        // Wake up the camera
        nrf_gpio_pin_write(CAMERA_SLEEP_PIN, false);

        // Check the chip ID
        i2c_response_t camera_response =
            i2c_read(CAMERA_I2C_ADDRESS, 0x300A, 0xFF);

        if (not_real_hardware_flag == false)
        {
            if (camera_response.value != 0x97)
            {
                app_err(HARDWARE_ERROR);
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

    // TODO re-init the I2C

    // Inform the application processor that the hardware is configured
}

int main(void)
{
    NRFX_LOG(RTT_CTRL_CLEAR);
    NRFX_LOG("MicroPython on Frame - " BUILD_VERSION " (" GIT_COMMIT ")");
    NRFX_LOG("Logging from network core");

    setup_network_core();

    while (1)
    {
    }
}