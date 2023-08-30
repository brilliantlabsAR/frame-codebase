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

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef enum instruction_t
{
    RESET_CHIP,
    RESET_FOR_FIRMWARE_UPDATE,
    NETWORK_CORE_READY,
    GET_FPGA_ID,
    LOG_FROM_APPLICATION_CORE,
} instruction_t;

typedef struct message_t
{
    uint8_t size;
    instruction_t instruction;
    uint8_t *payload;
} message_t;

#define MESSAGE(INSTRUCTION, PAYLOAD)  \
    {                                  \
        .size = sizeof(PAYLOAD) + 2,   \
        .instruction = INSTRUCTION,    \
        .payload = (uint8_t *)PAYLOAD, \
    }

#define MESSAGE_WITHOUT_PAYLOAD(INSTRUCTION) \
    {                                        \
        .size = 2,                           \
        .instruction = INSTRUCTION,          \
        .payload = NULL,                     \
    }

typedef void (*message_handler_t)(void);

void setup_messaging(message_handler_t handler);

void push_message(message_t message);

void pop_message(message_t *message);

uint8_t pending_message_length(void);

struct message_t *new_message(uint8_t length);

void free_message(struct message_t *message);
