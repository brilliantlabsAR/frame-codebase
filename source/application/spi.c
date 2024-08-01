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
#include <stdint.h>
#include <stdlib.h>
#include "error_logging.h"
#include "nrfx_spim.h"
#include "pinout.h"
#include "spi.h"

static const nrfx_spim_t display_spi = NRFX_SPIM_INSTANCE(1);
static const nrfx_spim_t fpga_spi = NRFX_SPIM_INSTANCE(2);

void spi_configure(void)
{
    nrf_gpio_cfg_output(DISPLAY_SPI_SELECT_PIN);
    nrf_gpio_cfg_output(FPGA_SPI_SELECT_PIN);

    nrf_gpio_pin_set(DISPLAY_SPI_SELECT_PIN);
    nrf_gpio_pin_set(FPGA_SPI_SELECT_PIN);

    nrfx_spim_config_t display_spi_config = NRFX_SPIM_DEFAULT_CONFIG(
        DISPLAY_SPI_CLOCK_PIN,
        DISPLAY_SPI_DATA_PIN,
        NRF_SPIM_PIN_NOT_CONNECTED,
        NRF_SPIM_PIN_NOT_CONNECTED);

    display_spi_config.mode = NRF_SPIM_MODE_3;
    display_spi_config.bit_order = NRF_SPIM_BIT_ORDER_LSB_FIRST;

    nrfx_spim_config_t fpga_spi_config = NRFX_SPIM_DEFAULT_CONFIG(
        FPGA_SPI_CLOCK_PIN,
        FPGA_SPI_COPI_PIN,
        FPGA_SPI_CIPO_PIN,
        NRF_SPIM_PIN_NOT_CONNECTED);

    fpga_spi_config.frequency = NRFX_MHZ_TO_HZ(8);

    check_error(nrfx_spim_init(&display_spi,
                               &display_spi_config,
                               NULL,
                               NULL));

    check_error(nrfx_spim_init(&fpga_spi,
                               &fpga_spi_config,
                               NULL,
                               NULL));
}

void spi_read(spi_device_t device,
              uint8_t address,
              uint8_t *data,
              size_t length)
{
    nrfx_spim_t instance;
    uint32_t cs_pin = 0xFF;

    switch (device)
    {
    case DISPLAY:
        instance = display_spi;
        cs_pin = DISPLAY_SPI_SELECT_PIN;
        break;

    case FPGA:
        instance = fpga_spi;
        cs_pin = FPGA_SPI_SELECT_PIN;
        break;

    default:
        error_with_message("Invalid SPI device selected");
        break;
    }

    nrf_gpio_pin_clear(cs_pin);

    nrfx_spim_xfer_desc_t tx = NRFX_SPIM_XFER_TX(&address, 1);
    check_error(nrfx_spim_xfer(&instance, &tx, 0));

    nrfx_spim_xfer_desc_t rx = NRFX_SPIM_XFER_RX(data, length);
    check_error(nrfx_spim_xfer(&instance, &rx, 0));

    nrf_gpio_pin_set(cs_pin);
}

static void _spi_write(spi_device_t device,
                       uint8_t address,
                       uint8_t *data,
                       size_t length,
                       bool raw_mode)
{
    nrfx_spim_t instance;
    uint32_t cs_pin = 0xFF;

    switch (device)
    {
    case DISPLAY:
        instance = display_spi;
        cs_pin = DISPLAY_SPI_SELECT_PIN;
        break;

    case FPGA:
        instance = fpga_spi;
        cs_pin = FPGA_SPI_SELECT_PIN;
        break;

    default:
        error_with_message("Invalid SPI device selected");
        break;
    }

    nrf_gpio_pin_clear(cs_pin);

    // If address is 0, don't send an address, and don't clear CS pin
    if (!raw_mode)
    {
        nrfx_spim_xfer_desc_t tx_address = NRFX_SPIM_XFER_TX(&address, 1);
        check_error(nrfx_spim_xfer(&instance, &tx_address, 0));
    }

    if (!nrfx_is_in_ram(data))
    {
        uint8_t *m_data = malloc(length);
        if (m_data == NULL)
        {
            error();
        }
        memcpy(m_data, data, length);
        nrfx_spim_xfer_desc_t tx_data = NRFX_SPIM_XFER_TX(m_data, length);
        check_error(nrfx_spim_xfer(&instance, &tx_data, 0));
        free(m_data);
    }
    else
    {
        nrfx_spim_xfer_desc_t tx_data = NRFX_SPIM_XFER_TX(data, length);
        check_error(nrfx_spim_xfer(&instance, &tx_data, 0));
    }

    if (!raw_mode)
    {
        nrf_gpio_pin_set(cs_pin);
    }
}

void spi_write(spi_device_t device,
               uint8_t address,
               uint8_t *data,
               size_t length)
{
    _spi_write(device, address, data, length, false);
}

void spi_write_raw(spi_device_t device,
                   uint8_t *data,
                   size_t length)
{
    _spi_write(device, 0x00, data, length, true);
}