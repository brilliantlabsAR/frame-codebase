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

#pragma once

#include "nrfx_log.h"

/**
 * @brief These error codes extend the standard nrfx_err_t.
 */
typedef enum extended_error_codes_t
{
    HARDWARE_ERROR = 0x0BAC0001,
    ASSERT,
    HARD_FAULT
} extended_error_codes_t;

const char *lookup_error_code(uint32_t error_code);

#ifdef NRF5340_XXAA_APPLICATION
#define app_err(eval)                                             \
    do                                                            \
    {                                                             \
        if (0xF000FFFF & (eval))                                  \
        {                                                         \
            if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk) \
            {                                                     \
                NRFX_LOG("Network core crashed: %s at %s:%u",     \
                         lookup_error_code(eval),                 \
                         __FILE__,                                \
                         __LINE__);                               \
                __BKPT();                                         \
            }                                                     \
            NVIC_SystemReset();                                   \
        }                                                         \
    } while (0)
#endif

#ifdef NRF5340_XXAA_NETWORK
#define app_err(eval)                                                    \
    do                                                                   \
    {                                                                    \
        if (0xF000FFFF & (eval))                                         \
        {                                                                \
            if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk)        \
            {                                                            \
                NRFX_LOG("Network core crashed: %s at %s:%u",            \
                         lookup_error_code(eval),                        \
                         __FILE__,                                       \
                         __LINE__);                                      \
                __BKPT();                                                \
            }                                                            \
            NVIC_SystemReset(); /* TODO: Notify application processor */ \
        }                                                                \
    } while (0)
#endif
