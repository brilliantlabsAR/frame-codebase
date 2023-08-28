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

#include "interprocessor_messaging.h"
#include "nrfx_ipc.h"
#include <stddef.h>
#include <stdint.h>

#ifdef NRF5340_XXAA_APPLICATION
#include "nrf_spu.h"
#endif

typedef struct message_buffer_t
{
    size_t head;
    size_t tail;
    uint8_t buffer[100];
} message_buffer_t;

typedef struct message_memory_t
{
    message_buffer_t application_to_network;
    message_buffer_t network_to_application;
} message_memory_t;

static const uint32_t message_memory_address = 0x20000000;

static volatile message_memory_t *message_memory =
    (message_memory_t *)message_memory_address;

#ifdef NRF5340_XXAA_APPLICATION
static const uint8_t ipc_rx_channel = 0;
static const uint8_t ipc_tx_channel = 1;
#elif NRF5340_XXAA_NETWORK
static const uint8_t ipc_rx_channel = 1;
static const uint8_t ipc_tx_channel = 0;
#endif

static void ipc_handler(uint8_t event_idx, void *p_context)
{
    ((interprocessor_message_handler_t)p_context)();
}

void setup_interprocessor_messaging(interprocessor_message_handler_t handler)
{
#ifdef NRF5340_XXAA_APPLICATION
    // Unlock the RAM region so that the network processor can access it
    nrf_spu_ramregion_set(NRF_SPU,
                          0, // TODO make this based on message_memory_address
                          false,
                          NRF_SPU_MEM_PERM_READ | NRF_SPU_MEM_PERM_WRITE,
                          false);

    message_memory->application_to_network.head = 0;
    message_memory->application_to_network.tail = 0;
#elif NRF5340_XXAA_NETWORK
    message_memory->network_to_application.head = 0;
    message_memory->network_to_application.tail = 0;
#endif

    nrfx_ipc_init(7, ipc_handler, handler);
    nrfx_ipc_send_task_channel_assign(ipc_tx_channel, ipc_tx_channel);
    nrfx_ipc_receive_event_channel_assign(ipc_rx_channel, ipc_rx_channel);
    nrfx_ipc_receive_event_enable(ipc_rx_channel);
}

void push_interprocessor_message(interprocessor_message_t message)
{
#ifdef NRF5340_XXAA_APPLICATION
// message_buffer_t buffer = message_memory->network_to_application;
#elif NRF5340_XXAA_NETWORK
// message_buffer_t buffer = message_memory->application_to_network;
#endif
    nrfx_ipc_signal(ipc_tx_channel);
}

interprocessor_message_t *pop_interprocessor_message(void)
{
#ifdef NRF5340_XXAA_APPLICATION
    // message_buffer_t buffer = message_memory->network_to_application;
#elif NRF5340_XXAA_NETWORK
    // message_buffer_t buffer = message_memory->application_to_network;
#endif
    return NULL;
}

bool interprocessor_message_pending(void)
{
#ifdef NRF5340_XXAA_APPLICATION
    message_buffer_t buffer = message_memory->network_to_application;
#elif NRF5340_XXAA_NETWORK
    message_buffer_t buffer = message_memory->application_to_network;
#endif
    if (buffer.head == buffer.tail)
    {
        return false;
    }

    return true;
}