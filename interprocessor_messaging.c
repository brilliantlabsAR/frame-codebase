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
#include <stdint.h>
#include <stdlib.h>
#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "nrfx_ipc.h"
#include "nrfx_log.h"

#ifdef NRF5340_XXAA_APPLICATION
#include "nrf_spu.h"
#endif

// Two FIFO blocks should fit neatly within the 8KiB RAM region at 0x20000000
typedef struct fifo_t
{
    uint32_t head;
    uint32_t tail;
    uint8_t buffer[4096 - 4 - 4];
} fifo_t;

typedef struct memory_t
{
    fifo_t application_to_network;
    fifo_t network_to_application;
} memory_t;

static const uint32_t memory_address = 0x20000000;

static memory_t *memory = (memory_t *)memory_address;

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

    // Unlock RAM region at 0x20000000 so the network processor can access it
    nrf_spu_ramregion_set(NRF_SPU,
                          0,
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

    check_error(nrfx_ipc_init(NRFX_IPC_DEFAULT_CONFIG_IRQ_PRIORITY,
                              ipc_handler,
                              handler));

    nrfx_ipc_send_task_channel_assign(ipc_tx_channel, ipc_tx_channel);

    nrfx_ipc_receive_event_channel_assign(ipc_rx_channel, ipc_rx_channel);
    nrfx_ipc_receive_event_enable(ipc_rx_channel);
}

void send_message(command_t command, uint8_t *payload, uint8_t payload_length)
{
    if (payload_length > 253)
    {
        error_with_message("Message payload size must be less than 254 bytes");
    }

    for (uint8_t position = 0; position < (payload_length + 2); position++)
    {
        uint8_t next = tx->head + 1;

        if (next >= sizeof(tx->buffer))
        {
            next = 0;
        }

        // TODO what do we do if the buffer overflows?
        while (next == tx->tail)
        {
            __BKPT();
            // return;
        }

        switch (position)
        {
        case 0:
            tx->buffer[tx->head] = payload_length + 2;
            break;

        case 1:
            tx->buffer[tx->head] = command;
            break;

        default:
            tx->buffer[tx->head] = payload[position - 2];
            break;
        }

        tx->head = next;
    }

    nrfx_ipc_signal(ipc_tx_channel);
}

bool message_pending(message_t *message)
{
    if (rx->head == rx->tail)
    {
        return false;
    }

    uint8_t message_length = rx->buffer[rx->tail];

    for (uint8_t position = 0; position < message_length; position++)
    {
        if (rx->tail == rx->head)
        {
            break;
        }

        uint8_t next = rx->tail + 1;

        if (next == sizeof(rx->buffer))
        {
            next = 0;
        }

        switch (position)
        {
        case 0:
            message->payload_length = rx->buffer[rx->tail] - 2;
            break;

        case 1:
            message->command = rx->buffer[rx->tail];
            break;

        default:
            message->payload[position - 2] = rx->buffer[rx->tail];
            break;
        }

        rx->tail = next;
    }

    return true;
}
