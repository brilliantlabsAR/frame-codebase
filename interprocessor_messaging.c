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
#include "messaging.h"
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
    NRFX_LOG("New interrupt on channel: %u", event_idx);

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

    nrfx_ipc_init(7, ipc_handler, handler);
    nrfx_ipc_send_task_channel_assign(ipc_tx_channel, ipc_tx_channel);
    nrfx_ipc_receive_event_channel_assign(ipc_rx_channel, ipc_rx_channel);
    nrfx_ipc_receive_event_enable(ipc_rx_channel);
}

void push_message(message_t message)
{
    NRFX_LOG("Pushing message. Ins: %u, Len: %u, Payload: %s", message.instruction, message.size, message.payload);

    for (size_t position = 0; position < message.size; position++)
    {
        size_t next = tx->head;

        if (next >= sizeof(tx->buffer))
        {
            next = 0;
        }

        while (next == tx->tail)
        {
            NRFX_LOG("TX Buffer is full");
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

    NRFX_LOG("Message written. TX head = %u, RX tail = %u", tx->head, rx->tail);

    NRFX_LOG("Generating interrupt on channel: %u", ipc_tx_channel);

    nrfx_ipc_signal(ipc_tx_channel);
}

void pop_message(message_t *message)
{
    for (size_t position = 0;; position++)
    {
        if (rx->tail == rx->head)
        {
            // app_err(MESSAGING_ERROR);
        }

        if (position == 0)
        {
            message->size = rx->buffer[rx->tail++];
        }

        else if (position == 1)
        {
            message->instruction = rx->buffer[rx->tail++];
        }

        else
        {
            message->payload[position - 2] = rx->buffer[rx->tail++];
        }

        if (rx->tail == sizeof(rx->buffer))
        {
            rx->tail = 0;
        }

        if (position - 2 == message->size)
        {
            return;
        }
    }
}

uint8_t message_pending_length(void)
{
    NRFX_LOG("Checking for message");

    if (rx->head == rx->tail)
    {
        NRFX_LOG("No messages");
        return 0;
    }

    NRFX_LOG("Message length = %u", rx->buffer[rx->tail]);
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