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

int compression_decompress(size_t destination_size,
                           const void *source,
                           size_t source_size,
                           process_function process_function,
                           void *process_function_context)
{
    int status = 0;

    char *output_buffer = malloc(destination_size);
    if (output_buffer == NULL)
    {
        return -1;
    }

    // TODO the frame header might not be 7
    char *block_pointer = (char *)source + 7;

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