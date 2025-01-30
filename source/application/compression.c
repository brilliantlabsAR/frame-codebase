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

#include <stdlib.h>
#include "compression.h"
#include "lz4.h"
#include "nrfx_log.h"

#define LZ4F_MAGICNUMBER 0x184D2204U
#define LZ4F_MAGIC_SKIPPABLE_START 0x184D2A50U
#define LZ4F_MIN_SIZE_TO_KNOW_HEADER_LENGTH 5
#define LZ4F_HEADER_SIZE_MIN 7

static uint32_t LZ4F_readLE32(const void *src)
{
    const uint8_t *const srcPtr = (const uint8_t *)src;
    uint32_t value32 = srcPtr[0];
    value32 |= ((uint32_t)srcPtr[1]) << 8;
    value32 |= ((uint32_t)srcPtr[2]) << 16;
    value32 |= ((uint32_t)srcPtr[3]) << 24;
    return value32;
}

size_t LZ4F_headerSize(const void *src, size_t srcSize)
{
    /* minimal srcSize to determine header size */
    if (srcSize < LZ4F_MIN_SIZE_TO_KNOW_HEADER_LENGTH)
        return -20;

    /* special case : skippable frames */
    if ((LZ4F_readLE32(src) & 0xFFFFFFF0U) == LZ4F_MAGIC_SKIPPABLE_START)
        return 8;

    /* control magic number */
    if (LZ4F_readLE32(src) != LZ4F_MAGICNUMBER)
        return -21;

    /* Frame Header Size */
    {
        uint8_t const FLG = ((const uint8_t *)src)[4];
        uint32_t const contentSizeFlag = (FLG >> 3) & 0x01;
        uint32_t const dictIDFlag = FLG & 0x01;
        return LZ4F_HEADER_SIZE_MIN + (contentSizeFlag ? 8 : 0) + (dictIDFlag ? 4 : 0);
    }
}

int compression_decompress(size_t destination_size,
                           const void *source,
                           size_t source_size,
                           process_function process_function,
                           void *process_function_context)
{
    int status = 0;

    size_t header_size = LZ4F_headerSize(source, source_size);

    if (header_size < 0)
    {
        return header_size;
    }

    char *output_buffer = malloc(destination_size);

    if (output_buffer == NULL)
    {
        return -1;
    }

    char *block_pointer = (char *)source + header_size;

    while (1)
    {
        int current_block_size = ((uint8_t)block_pointer[0]) +
                                 ((uint8_t)block_pointer[1] << 8) +
                                 ((uint8_t)block_pointer[2] << 16) +
                                 ((uint8_t)block_pointer[3] << 24);

        if (current_block_size == 0)
        {
            status = 0;
            break;
        }

        status = LZ4_decompress_safe(block_pointer + 4,
                                     output_buffer,
                                     current_block_size,
                                     destination_size);

        if (status <= 0)
        {
            break;
        }

        process_function(process_function_context,
                         output_buffer,
                         status);

        block_pointer += current_block_size + 4;
    }

    free(output_buffer);

    return status;
}