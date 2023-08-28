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
#include "nrfx_ipc.h"

#ifdef NRF5340_XXAA_APPLICATION
#include "nrf_spu.h"
#endif

typedef struct interprocessor_buffer_t
{
    size_t head;
    size_t tail;
    uint8_t buffer[100];
} interprocessor_buffer_t;

typedef struct interprocessor_memory_t
{
    interprocessor_buffer_t application_to_network;
    interprocessor_buffer_t network_to_application;
} interprocessor_memory_t;

static volatile interprocessor_memory_t *interprocessor_memory =
    (interprocessor_memory_t *)0x20000000;

static void setup_interprocessor_memory(void)
{
#ifdef NRF5340_XXAA_APPLICATION
    // Unlock the RAM region so that the network processor can access it
    nrf_spu_ramregion_set(NRF_SPU,
                          0,
                          false,
                          NRF_SPU_MEM_PERM_READ | NRF_SPU_MEM_PERM_WRITE,
                          false);

    interprocessor_memory->application_to_network.head = 0;
    interprocessor_memory->application_to_network.tail = 0;
#elif NRF5340_XXAA_NETWORK
    interprocessor_memory->network_to_application.head = 0;
    interprocessor_memory->network_to_application.tail = 0;
#endif
}

typedef enum interprocessor_instruction_t
{
    RESET_CHIP = 0xF0,
    RESET_FOR_FIRMWARE_UPDATE = 0xF1,
    GET_FPGA_ID = 0x00,
} interprocessor_instruction_t;

typedef struct interprocessor_message_t
{
    interprocessor_instruction_t instruction;
    uint8_t *operand_list;
    size_t operand_length;
} interprocessor_message_t;

// static void push_interprocessor_instruction(interprocessor_message_t message)
// {
// }

// static bool pop_interprocessor_message