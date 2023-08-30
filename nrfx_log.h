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

#include "interprocessor_messaging.h"
#include "SEGGER_RTT.h"
#include <stdio.h>

/**
 * @brief Logging macros.
 */

#ifdef NRF5340_XXAA_APPLICATION

#define NRFX_LOG(format, ...)                                                   \
    {                                                                           \
        char log_string[50];                                                    \
        sprintf(log_string, "\x1B[93m" format, ##__VA_ARGS__);                  \
        message_t log_message = MESSAGE(LOG_FROM_APPLICATION_CORE, log_string); \
        push_message(log_message);                                              \
    }

#elif NRF5340_XXAA_NETWORK

#define NRFX_LOG(format, ...) \
    SEGGER_RTT_printf(0, "\x1B[92m" format "\r\n", ##__VA_ARGS__)

#endif

#define NRFX_LOG_ERROR(format, ...)
#define NRFX_LOG_WARNING(format, ...)
#define NRFX_LOG_INFO(format, ...)
#define NRFX_LOG_DEBUG(format, ...)

#define NRFX_LOG_HEXDUMP_ERROR(p_memory, length)
#define NRFX_LOG_HEXDUMP_WARNING(p_memory, length)
#define NRFX_LOG_HEXDUMP_INFO(p_memory, length)
#define NRFX_LOG_HEXDUMP_DEBUG(p_memory, length)
#define NRFX_LOG_ERROR_STRING_GET(error_code)