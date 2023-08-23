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

#include "nrfx.h"

void HardFault_Handler(void)
{
    app_err(HARD_FAULT);
}

const char *lookup_error_code(uint32_t error_code)
{
    switch (error_code)
    {
    case ASSERT:
        return "NRFX_ASSERT";

    case HARDWARE_ERROR:
        return "HARDWARE_ERROR";

    case HARD_FAULT:
        return "HARD_FAULT";

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

    default:
        return "UNKOWN_ERROR";
    }
}