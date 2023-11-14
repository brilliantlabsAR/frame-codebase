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

#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "nrf.h"
#include "error_logging.h"
#include "nrfx_log.h"
#include "nrf_bootloader.h"
#include "nrf_bootloader_info.h"
#include "nrf_bootloader_app_start.h"

static void on_error(void)
{
    // NRF_LOG_FINAL_FLUSH();

    // #if NRF_MODULE_ENABLED(NRF_LOG_BACKEND_RTT)
    //     // To allow the buffer to be flushed by the host.
    //     nrf_delay_ms(100);
    // #endif
    // #ifdef NRF_DFU_DEBUG_VERSION
    //     NRF_BREAKPOINT_COND;
    // #endif
    NVIC_SystemReset();
}

void app_error_handler(uint32_t error_code, uint32_t line_num, const uint8_t *p_file_name)
{
    // NRF_LOG_ERROR("%s:%d", p_file_name, line_num);
    on_error();
}

void app_error_fault_handler(uint32_t id, uint32_t pc, uint32_t info)
{
    // NRF_LOG_ERROR("Received a fault! id: 0x%08x, pc: 0x%08x, info: 0x%08x", id, pc, info);
    on_error();
}

void app_error_handler_bare(uint32_t error_code)
{
    // NRF_LOG_ERROR("Received an error: 0x%08x!", error_code);
    on_error();
}

static void dfu_observer(nrf_dfu_evt_type_t evt_type)
{
    switch (evt_type)
    {
    case NRF_DFU_EVT_DFU_FAILED:
    case NRF_DFU_EVT_DFU_ABORTED:
    case NRF_DFU_EVT_DFU_INITIALIZED:
        break;
    case NRF_DFU_EVT_TRANSPORT_ACTIVATED:
        break;
    case NRF_DFU_EVT_DFU_STARTED:
        break;
    default:
        break;
    }
}

int main(void)
{
    LOG(RTT_CTRL_CLEAR);
    LOG("Starting bootloader");

    // Must happen before flash protection is applied
    nrf_bootloader_mbr_addrs_populate();

    check_error(nrf_bootloader_flash_protect(0, MBR_SIZE));
    check_error(nrf_bootloader_flash_protect(BOOTLOADER_START_ADDR,
                                             BOOTLOADER_SIZE));

    check_error(nrf_bootloader_init(dfu_observer));
}