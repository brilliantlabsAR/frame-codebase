/*
 * This file is a part https://github.com/brilliantlabsAR/frame-codebase
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

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef enum instruction_t
{
    // Network -> Application core commands
    NETWORK_CORE_READY,
    NETWORK_CORE_ERROR,

    // Application -> Network core commands
    LOG_FROM_APPLICATION_CORE,
    PREPARE_FOR_SLEEP,

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
