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
#include "error_logging.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrfx_config.h"
#include "nrfx_log.h"
#include "nrfx_pdm.h"
#include "pinout.h"

static lua_Number seconds;
static lua_Integer sample_rate;
static lua_Integer bit_depth = 16;

static struct fifo
{
    int16_t buffer[100000];
    size_t chunk_size;
    size_t head;
    size_t target_head;
    size_t tail;
} fifo = {
    .head = 0,
    .chunk_size = 1,
    .target_head = 0,
    .tail = 0,
};

static nrfx_pdm_config_t config = NRFX_PDM_DEFAULT_CONFIG(MICROPHONE_CLOCK_PIN,
                                                          MICROPHONE_DATA_PIN);

static void pdm_event_handler(nrfx_pdm_evt_t const *p_evt)
{
    bool stopping = false;

    if (p_evt->error)
    {
        error_with_message("overflow");
    }

    if (p_evt->buffer_requested)
    {
        // After a buffer is written
        if (p_evt->buffer_released != NULL)
        {
            fifo.head += fifo.chunk_size;

            if (fifo.head > 100000)
            {
                fifo.head = 0;
            }

            if (fifo.head == fifo.tail)
            {
                LOG("FIFO write overflow");
                check_error(nrfx_pdm_stop());
                // Move the target head back to match head
                return;
            }

            if (fifo.head == fifo.target_head - fifo.chunk_size) //  TODO roll this over properly
            {
                LOG("FIFO done after this frame");
                stopping = true;
            }

            if (fifo.head == fifo.target_head)
            {
                LOG("Done!");
                return;
            }
        }

        else
        {
            LOG("New buffer");
        }

        if (fifo.head % 1000 == 0)
            LOG("Setting buffer to: fifo.buffer[%u]", fifo.head);

        check_error(nrfx_pdm_buffer_set(fifo.buffer + fifo.head,
                                        fifo.chunk_size));

        if (stopping)
        {
            check_error(nrfx_pdm_stop());
        }
    }

    else
    {
        LOG("Buffer not requested");
    }
}

static int frame_microphone_record(lua_State *L)
{
    check_error(nrfx_pdm_stop());

    luaL_checknumber(L, 1);
    seconds = lua_tonumber(L, 1);

    luaL_checkinteger(L, 2);
    sample_rate = lua_tointeger(L, 2);
    switch (sample_rate)
    {
    case 20000:
    case 10000:
    case 5000:
        config.clock_freq = NRF_PDM_FREQ_1280K;
        config.ratio = NRF_PDM_RATIO_64X;
        break;

    case 16000:
    case 8000:
    case 4000:
        config.clock_freq = NRF_PDM_FREQ_1280K;
        config.ratio = NRF_PDM_RATIO_80X;
        break;

    case 12500:
        config.clock_freq = NRF_PDM_FREQ_1000K;
        config.ratio = NRF_PDM_RATIO_80X;
        break;

    default:
        luaL_error(L, "invalid sample rate");
        break;
    }

    if (lua_gettop(L) > 2)
    {
        luaL_checkinteger(L, 3);
        bit_depth = lua_tointeger(L, 3);
        if (bit_depth != 16 && bit_depth != 8 && bit_depth != 4)
        {
            luaL_error(L, "invalid bit depth");
        }
    }

    size_t requested_samples = (size_t)ceil(seconds * sample_rate);

    if (requested_samples > 100000)
    {
        luaL_error(L, "exceeded maximum buffer size of %d samples", 100000);
    }

    fifo.target_head += requested_samples;

    if (fifo.target_head > 100000)
    {
        fifo.target_head -= 100000;
    }

    LOG("New target head at: %d", fifo.target_head);

    check_error(nrfx_pdm_reconfigure(&config));
    check_error(nrfx_pdm_start());

    return 0;
}

static int frame_microphone_read(lua_State *L)
{

    lua_createtable(L, 10, 0);

    for (int i = 0; i < 10; i++)
    {
        lua_pushinteger(L, i);
        lua_seti(L, -2, i);
    }
    return 1;
}

void open_frame_microphone_library(lua_State *L)
{
    config.edge = NRF_PDM_EDGE_LEFTRISING;

    if (nrfx_pdm_init_check())
    {
        return;
    }

    check_error(nrfx_pdm_init(&config, pdm_event_handler));

    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, frame_microphone_record);
    lua_setfield(L, -2, "record");

    lua_pushcfunction(L, frame_microphone_read);
    lua_setfield(L, -2, "read");

    lua_setfield(L, -2, "microphone");

    lua_pop(L, 1);
}
