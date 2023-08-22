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

#include "error_helpers.h"
#include "nrf.h"
#include "nrfx_log.h"
#include "nrfx_twim.h"
#include "pinout.h"

static const nrfx_twim_t i2c_bus = NRFX_TWIM_INSTANCE(0);

static const uint8_t ACCELEROMETER_I2C_ADDRESS = 0x4C;
static const uint8_t CAMERA_I2C_ADDRESS = 0x6C;
static const uint8_t MAGNETOMETER_I2C_ADDRESS = 0x0C;
static const uint8_t PMIC_I2C_ADDRESS = 0x48;

static bool not_real_hardware_flag = false;

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

    // Scan for all the I2C devices
    {
        i2c_response_t accelerometer_response =
            monocle_i2c_read(ACCELEROMETER_I2C_ADDRESS, 0x03, 0xFF);

        i2c_response_t camera_response =
            monocle_i2c_read(CAMERA_I2C_ADDRESS, 0x300A, 0xFF);

        i2c_response_t magnetometer_response =
            monocle_i2c_read(MAGNETOMETER_I2C_ADDRESS, 0x0F, 0xFF);

        i2c_response_t pmic_response =
            monocle_i2c_read(PMIC_I2C_ADDRESS, 0x14, 0x0F);

        // If all chips fail to respond, we must be using a devkit
        if (accelerometer_response.fail &&
            camera_response.fail &&
            magnetometer_response.fail &&
            pmic_response.fail)
        {
            NRFX_LOG("Running on nRF5340-DK");
            not_real_hardware_flag = true;
        }

        // Otherwise if any individual chips fail, it implies bad soldering
        else
        {
            app_err(0); // TODO enable this once we have hardware
        }

        // This checks incase incorrect chips were populated
        if (camera_response.value != 0x97 ||
            magnetometer_response.value != 0x49 ||
            pmic_response.value != 0x02)
        {
            app_err(0); // TODO enable this once we have hardware
        }
    }

    // Set up PMIC
    {
    }
}

int main(void)
{
    NRFX_LOG("Starting network core");

    setup_network_core();

    while (1)
    {
    }
}