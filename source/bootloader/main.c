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

void app_error_fault_handler(uint32_t id, uint32_t pc, uint32_t info)
{
    if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk)
    {
        switch (id)
        {
        case NRF_FAULT_ID_SD_ASSERT:
            LOG("Softdevice assertion failed");
            break;

        case NRF_FAULT_ID_APP_MEMACC:
            LOG("Softdevice invalid memory address");
            break;

        case NRF_FAULT_ID_SDK_ASSERT:

            assert_info_t *assert_info = (assert_info_t *)info;
            LOG("Crashed at %s:%lu",
                assert_info->p_file_name,
                assert_info->line_num);
            break;

        case NRF_FAULT_ID_SDK_ERROR:

            error_info_t *error_info = (error_info_t *)info;
            LOG("Crashed at %s:%lu - Error code: %lu",
                error_info->p_file_name,
                error_info->line_num,
                error_info->err_code);
            break;

        default:
            LOG("Unknown fault 0x%08lX", pc);
            break;
        }

        __BKPT();
    }

    NVIC_SystemReset();
}

void app_error_handler_bare(ret_code_t error_code)
{
    error_info_t error_info =
        {
            .line_num = 0,
            .p_file_name = NULL,
            .err_code = error_code,
        };

    app_error_fault_handler(NRF_FAULT_ID_SDK_ERROR, 0, (uint32_t)(&error_info));
}

static void dfu_observer(nrf_dfu_evt_type_t evt_type)
{
    LOG("DFU event: %u", evt_type);
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