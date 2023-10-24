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

#include "error_logging.h"
#include "nrfx_log.h"
#include "nrf_error.h"

static const char *lookup_error_code(uint32_t error_code)
{
    switch (error_code)
    {
    case NRFX_SUCCESS:
        return "NRFX_SUCCESS";

    case NRFX_ERROR_INTERNAL:
        return "NRFX_ERROR_INTERNAL";

    case NRFX_ERROR_NO_MEM:
        return "NRFX_ERROR_NO_MEM";

    case NRFX_ERROR_NOT_SUPPORTED:
        return "NRFX_ERROR_NOT_SUPPORTED";

    case NRFX_ERROR_INVALID_PARAM:
        return "NRFX_ERROR_INVALID_PARAM";

    case NRFX_ERROR_INVALID_STATE:
        return "NRFX_ERROR_INVALID_STATE";

    case NRFX_ERROR_INVALID_LENGTH:
        return "NRFX_ERROR_INVALID_LENGTH";

    case NRFX_ERROR_TIMEOUT:
        return "NRFX_ERROR_TIMEOUT";

    case NRFX_ERROR_FORBIDDEN:
        return "NRFX_ERROR_FORBIDDEN";

    case NRFX_ERROR_NULL:
        return "NRFX_ERROR_NULL";

    case NRFX_ERROR_INVALID_ADDR:
        return "NRFX_ERROR_INVALID_ADDR";

    case NRFX_ERROR_BUSY:
        return "NRFX_ERROR_BUSY";

    case NRFX_ERROR_ALREADY_INITIALIZED:
        return "NRFX_ERROR_ALREADY_INITIALIZED";

    case NRFX_ERROR_DRV_TWI_ERR_OVERRUN:
        return "NRFX_ERROR_DRV_TWI_ERR_OVERRUN";

    case NRFX_ERROR_DRV_TWI_ERR_ANACK:
        return "NRFX_ERROR_DRV_TWI_ERR_ANACK";

    case NRFX_ERROR_DRV_TWI_ERR_DNACK:
        return "NRFX_ERROR_DRV_TWI_ERR_DNACK";

    case NRF_ERROR_SVC_HANDLER_MISSING:
        return "NRF_ERROR_SVC_HANDLER_MISSING";

    case NRF_ERROR_SOFTDEVICE_NOT_ENABLED:
        return "NRF_ERROR_SOFTDEVICE_NOT_ENABLED";

    case NRF_ERROR_INTERNAL:
        return "NRF_ERROR_INTERNAL";

    case NRF_ERROR_NO_MEM:
        return "NRF_ERROR_NO_MEM";

    case NRF_ERROR_NOT_FOUND:
        return "NRF_ERROR_NOT_FOUND";

    case NRF_ERROR_NOT_SUPPORTED:
        return "NRF_ERROR_NOT_SUPPORTED";

    case NRF_ERROR_INVALID_PARAM:
        return "NRF_ERROR_INVALID_PARAM";

    case NRF_ERROR_INVALID_STATE:
        return "NRF_ERROR_INVALID_STATE";

    case NRF_ERROR_INVALID_LENGTH:
        return "NRF_ERROR_INVALID_LENGTH";

    case NRF_ERROR_INVALID_FLAGS:
        return "NRF_ERROR_INVALID_FLAGS";

    case NRF_ERROR_INVALID_DATA:
        return "NRF_ERROR_INVALID_DATA";

    case NRF_ERROR_DATA_SIZE:
        return "NRF_ERROR_DATA_SIZE";

    case NRF_ERROR_TIMEOUT:
        return "NRF_ERROR_TIMEOUT";

    case NRF_ERROR_NULL:
        return "NRF_ERROR_NULL";

    case NRF_ERROR_FORBIDDEN:
        return "NRF_ERROR_FORBIDDEN";

    case NRF_ERROR_INVALID_ADDR:
        return "NRF_ERROR_INVALID_ADDR";

    case NRF_ERROR_BUSY:
        return "NRF_ERROR_BUSY";

    case NRF_ERROR_CONN_COUNT:
        return "NRF_ERROR_CONN_COUNT";

    case NRF_ERROR_RESOURCES:
        return "NRF_ERROR_RESOURCES";

    default:
        return "UNKNOWN_ERROR";
    }
}

void _check_error(nrfx_err_t error_code, const char *file, const int line)
{
    if (0x00000FFF & (error_code))
    {
        if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk)
        {
            LOG("Crashed at %s:%u - %s",
                file,
                line,
                lookup_error_code(error_code));

            // Simply pause here if debugging
            __BKPT();
        }
        NVIC_SystemReset();
    }
}

void _error_with_message(const char *message, const char *file, const int line)
{
    if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk)
    {
        LOG("Crashed at %s:%u - %s", file, line, message);

        // Simply pause here if debugging
        __BKPT();
    }
    NVIC_SystemReset();
}