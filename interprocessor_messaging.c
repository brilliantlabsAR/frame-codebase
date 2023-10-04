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

#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "nrfx_ipc.h"
#include "nrfx_log.h"

#ifdef NRF5340_XXAA_APPLICATION
#include "nrf_spu.h"
#endif

typedef struct fifo_t
{
    size_t head;
    size_t tail;
    uint8_t buffer[512];
} fifo_t;

typedef struct memory_t
{
    fifo_t application_to_network;
    fifo_t network_to_application;
} memory_t;

static const uint32_t memory_address = 0x20000000;

static volatile memory_t memory __attribute__((section(".ipc_ram"))); //= (memory_t *)memory_address;

static volatile fifo_t *tx;
static volatile fifo_t *rx;

static uint8_t ipc_tx_channel;
static uint8_t ipc_rx_channel;

static void ipc_handler(uint8_t event_idx, void *p_context)
{
    ((message_handler_t)p_context)();
}

void setup_messaging(message_handler_t handler)
{
#ifdef NRF5340_XXAA_APPLICATION

    // RAM starts at 0x20000000 and there are 64 regions in total
    float ram_region_id = floorf((float)(memory_address - 0x20000000) / 0x2000);

    // Unlock the RAM region so that the network processor can access it
    nrf_spu_ramregion_set(NRF_SPU,
                          (uint8_t)ram_region_id,
                          false,
                          NRF_SPU_MEM_PERM_READ | NRF_SPU_MEM_PERM_WRITE,
                          false);

    tx = &memory.application_to_network;
    rx = &memory.network_to_application;

    ipc_rx_channel = 0;
    ipc_tx_channel = 1;

#elif NRF5340_XXAA_NETWORK

    tx = &memory.network_to_application;
    rx = &memory.application_to_network;

    ipc_rx_channel = 1;
    ipc_tx_channel = 0;

#endif

    tx->head = 0;
    rx->tail = 0;

    check_error(nrfx_ipc_init(NRFX_IPC_DEFAULT_CONFIG_IRQ_PRIORITY,
                              ipc_handler,
                              handler));

    nrfx_ipc_send_task_channel_assign(ipc_tx_channel, ipc_tx_channel);

    nrfx_ipc_receive_event_channel_assign(ipc_rx_channel, ipc_rx_channel);
    nrfx_ipc_receive_event_enable(ipc_rx_channel);
}

void _send_message(message_t message, uint8_t *payload, uint8_t payload_length)
{
    // Message size is currently limited to 255
    if (payload_length > 253)
    {
        return;
    }

    for (size_t position = 0; position < (payload_length + 2); position++)
    {
        size_t next = tx->head + 1;

        if (next >= sizeof(tx->buffer))
        {
            next = 0;
        }

        // Throw away messages whenever the buffer is full
        while (next == tx->tail)
        {
            // return;
        }

        switch (position)
        {
        case 0:
            // Message length includes length byte and message type
            tx->buffer[tx->head] = payload_length + 2;
            break;

        case 1:
            tx->buffer[tx->head] = message;
            break;

        default:
            tx->buffer[tx->head] = payload[position - 2];
            break;
        }

        tx->head = next;
    }

    nrfx_ipc_signal(ipc_tx_channel);
}

bool message_pending(void)
{
    if (rx->head == rx->tail)
    {
        return false;
    }

    return true;
}

uint8_t pending_message_payload_length()
{
    // Payload length is the message length - 2
    return rx->buffer[rx->tail] - 2;
}

message_t retrieve_message(uint8_t *payload)
{
    message_t message;

    size_t message_length = rx->buffer[rx->tail];

    for (size_t position = 0; position < message_length; position++)
    {
        if (rx->tail == rx->head)
        {
            break;
        }

        size_t next = rx->tail + 1;

        if (next == sizeof(rx->buffer))
        {
            next = 0;
        }

        switch (position)
        {
        case 0:
            // We don't need the message length value so we skip this
            break;

        case 1:
            message = rx->buffer[rx->tail];
            break;

        default:
            payload[position - 2] = rx->buffer[rx->tail];
            break;
        }

        rx->tail = next;
    }

    return message;
}
