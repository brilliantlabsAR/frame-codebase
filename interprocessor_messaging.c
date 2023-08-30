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

#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "nrfx_ipc.h"
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include "nrfx_log.h"

#ifdef NRF5340_XXAA_APPLICATION
#include "nrf_spu.h"
#endif

typedef struct fifo_t
{
    size_t head;
    size_t tail;
    uint8_t buffer[100];
} fifo_t;

typedef struct memory_t
{
    fifo_t application_to_network;
    fifo_t network_to_application;
} memory_t;

static const uint32_t memory_address = 0x20000000;

static memory_t *memory = (memory_t *)memory_address;

static fifo_t *tx;
static fifo_t *rx;

static uint8_t ipc_tx_channel;
static uint8_t ipc_rx_channel;

static void ipc_handler(uint8_t event_idx, void *p_context)
{
    ((message_handler_t)p_context)();
}

void setup_messaging(message_handler_t handler)
{
#ifdef NRF5340_XXAA_APPLICATION

    // Unlock the RAM region so that the network processor can access it
    nrf_spu_ramregion_set(NRF_SPU,
                          0, // TODO make this based on memory_address
                          false,
                          NRF_SPU_MEM_PERM_READ | NRF_SPU_MEM_PERM_WRITE,
                          false);

    tx = &memory->application_to_network;
    rx = &memory->network_to_application;

    ipc_rx_channel = 0;
    ipc_tx_channel = 1;

#elif NRF5340_XXAA_NETWORK

    tx = &memory->network_to_application;
    rx = &memory->application_to_network;

    ipc_rx_channel = 1;
    ipc_tx_channel = 0;

#endif

    tx->head = 0;
    rx->tail = 0;

    app_err(nrfx_ipc_init(NRFX_IPC_DEFAULT_CONFIG_IRQ_PRIORITY,
                          ipc_handler,
                          handler));

    nrfx_ipc_send_task_channel_assign(ipc_tx_channel, ipc_tx_channel);

    nrfx_ipc_receive_event_channel_assign(ipc_rx_channel, ipc_rx_channel);
    nrfx_ipc_receive_event_enable(ipc_rx_channel);
}

void push_message(message_t message)
{
    for (size_t position = 0; position < message.size; position++)
    {
        size_t next = tx->head + 1;

        if (next >= sizeof(tx->buffer))
        {
            next = 0;
        }

        while (next == tx->tail)
        {
            // Buffer is full. Do nothing
        }

        switch (position)
        {
        case 0:
            tx->buffer[tx->head] = message.size;
            break;

        case 1:
            tx->buffer[tx->head] = message.instruction;
            break;

        default:
            tx->buffer[tx->head] = message.payload[position - 2];
            break;
        }

        tx->head = next;
    }

    nrfx_ipc_signal(ipc_tx_channel);
}

void pop_message(message_t *message)
{
    for (size_t position = 0; position < message->size; position++)
    {
        if (rx->tail == rx->head)
        {
            return;
        }

        size_t next = rx->tail + 1;

        if (next == sizeof(rx->buffer))
        {
            next = 0;
        }

        switch (position)
        {
        case 0:
            // message->size should already be populated, so we skip this
            break;

        case 1:
            message->instruction = rx->buffer[rx->tail];
            break;

        default:
            message->payload[position - 2] = rx->buffer[rx->tail];
            break;
        }

        rx->tail = next;
    }
}

uint8_t pending_message_length(void)
{
    if (rx->head == rx->tail)
    {
        return 0;
    }

    return rx->buffer[rx->tail];
}

struct message_t *new_message(uint8_t size)
{
    struct message_t *message =
        malloc(sizeof(struct message_t));
    if (message == NULL)
        return NULL;

    message->payload = malloc(size);
    if (message->payload == NULL)
    {
        free(message);
        return NULL;
    }

    message->size = size;
    return message;
}

void free_message(struct message_t *message)
{
    if (message != NULL)
    {
        free(message->payload);
        free(message);
    }
}