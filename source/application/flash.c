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
#include "error_logging.h"
#include "lfs.h"
#include "main.h"
#include "nrf_sdm.h"
#include "nrf_soc.h"
#include "nrfx_log.h"

extern uint32_t __empty_flash_start;
extern uint32_t __empty_flash_end;

static uint32_t empty_flash_start = (uint32_t)&__empty_flash_start;
static uint32_t empty_flash_end = (uint32_t)&__empty_flash_end;

static volatile bool flash_is_busy = false;

void flash_event_handler(bool success)
{
    flash_is_busy = false;
}

void flash_erase_page(uint32_t address)
{
    if (address % NRF_FICR->CODEPAGESIZE)
    {
        error_with_message("Address not aligned to page boundary");
    }

    check_error(sd_flash_page_erase(address / NRF_FICR->CODEPAGESIZE));
    flash_is_busy = true;
}

void flash_write(uint32_t address, const uint32_t *data, size_t length)
{
    check_error(sd_flash_write((uint32_t *)address, data, length));
    flash_is_busy = true;
}

void flash_wait_until_complete(void)
{
    uint8_t sd_is_enabled = false;
    sd_softdevice_is_enabled(&sd_is_enabled);

    if (sd_is_enabled == 1)
    {
        while (flash_is_busy)
        {
        }
    }
}

void flash_get_info(size_t *page_size, size_t *total_size)
{
    *page_size = NRF_FICR->CODEPAGESIZE;
    *total_size = empty_flash_end - empty_flash_start;
}

uint32_t flash_base_address(void)
{
    return empty_flash_start;
}