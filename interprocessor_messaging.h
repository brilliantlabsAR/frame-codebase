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

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef enum interprocessor_instruction_t
{
    RESET_CHIP,
    RESET_FOR_FIRMWARE_UPDATE,
    GET_FPGA_ID,
    LOG_FROM_APPLICATION_CORE,
} interprocessor_instruction_t;

typedef struct interprocessor_message_t
{
    interprocessor_instruction_t instruction;
    uint8_t *payload;
    size_t payload_length;
} interprocessor_message_t;

#define INTERPROCESSOR_MESSAGE(INSTRUCTION, PAYLOAD) \
    {                                                \
        .instruction = INSTRUCTION,                  \
        .payload = PAYLOAD,                          \
        .payload_length = sizeof(PAYLOAD)            \
    }

typedef void (*interprocessor_message_handler_t)(void);

void setup_interprocessor_messaging(interprocessor_message_handler_t handler);

void push_interprocessor_message(interprocessor_message_t message);

interprocessor_message_t *pop_interprocessor_message(void);

bool interprocessor_message_pending(void);