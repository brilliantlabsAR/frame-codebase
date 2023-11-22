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

#pragma once

#include <stdio.h>
#include "SEGGER_RTT.h"

/**
 * @brief Logging macros.
 */

#define LOG(string, ...) printf(string "\r\n", ##__VA_ARGS__)

#define NRFX_LOG_ERROR(string, ...)
#define NRFX_LOG_WARNING(string, ...)
#define NRFX_LOG_INFO(string, ...)
#define NRFX_LOG_DEBUG(string, ...)

#define NRFX_LOG_HEXDUMP_ERROR(p_memory, length)
#define NRFX_LOG_HEXDUMP_WARNING(p_memory, length)
#define NRFX_LOG_HEXDUMP_INFO(p_memory, length)                                                 \
    do                                                                                          \
    {                                                                                           \
        printf("Hexdump Info: Address=%p, Length=%zu\n", (void *)(p_memory), (size_t)(length)); \
        size_t i, j;                                                                            \
        for (i = 0; i < (length); i += 16)                                                      \
        {                                                                                       \
            printf("%04zx: ", i);                                                               \
            for (j = 0; j < 16; ++j)                                                            \
            {                                                                                   \
                if (i + j < (length))                                                           \
                    printf("%02x ", ((unsigned char *)(p_memory))[i + j]);                      \
                else                                                                            \
                    printf("   ");                                                              \
            }                                                                                   \
            printf(" | ");                                                                      \
            for (j = 0; j < 16 && i + j < (length); ++j)                                        \
            {                                                                                   \
                char c = ((unsigned char *)(p_memory))[i + j];                                  \
                printf("%c", (c >= 32 && c < 127) ? c : '.');                                   \
            }                                                                                   \
            printf("\n");                                                                       \
        }                                                                                       \
    } while (0)
#define NRFX_LOG_HEXDUMP_DEBUG(p_memory, length)
#define NRFX_LOG_ERROR_STRING_GET(error_code)