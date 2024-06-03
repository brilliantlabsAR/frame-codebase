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

#define PDM_BUFFER_SIZE 128
static int16_t pdm_buffers[2][PDM_BUFFER_SIZE];
static bool sampling_active = false;
static lua_Integer sample_rate = 8000;
static lua_Integer bit_depth = 8;

#define FIFO_TOTAL_SIZE 32768
static struct fifo
{
    int16_t buffer[FIFO_TOTAL_SIZE];
    size_t head;
    size_t tail;
} fifo;

#if (FIFO_TOTAL_SIZE % PDM_BUFFER_SIZE)
#error "chunks don't fit evenly into fifo"
#endif

static void pdm_event_handler(nrfx_pdm_evt_t const *p_evt)
{
    if (p_evt->buffer_released != NULL)
    {
        memcpy(fifo.buffer + fifo.head,
               p_evt->buffer_released,
               PDM_BUFFER_SIZE * sizeof(int16_t));

        fifo.head += PDM_BUFFER_SIZE;

        if (fifo.head == FIFO_TOTAL_SIZE)
        {
            fifo.head = 0;
        }
    }

    if (p_evt->buffer_requested)
    {
        if (p_evt->buffer_released == pdm_buffers[1])
        {
            check_error(nrfx_pdm_buffer_set(pdm_buffers[0], PDM_BUFFER_SIZE));
        }
        else
        {
            check_error(nrfx_pdm_buffer_set(pdm_buffers[1], PDM_BUFFER_SIZE));
        }
    }
}

static int lua_microphone_start(lua_State *L)
{
    if (sampling_active)
    {
        luaL_error(L, "already started");
    }

    lua_Integer set_sample_rate = 8000;
    lua_Integer set_bit_depth = 8;

    if (lua_istable(L, 1))
    {
        if (lua_getfield(L, 1, "sample_rate") != LUA_TNIL)
        {
            set_sample_rate = luaL_checkinteger(L, -1);
            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "bit_depth") != LUA_TNIL)
        {
            set_bit_depth = luaL_checkinteger(L, -1);
            lua_pop(L, 1);
        }
    }

    if (set_sample_rate != 8000 && set_sample_rate != 16000)
    {
        luaL_error(L, "sample rate must be 8000 or 16000");
    }

    if (set_bit_depth != 16 && set_bit_depth != 8)
    {
        luaL_error(L, "bit depth must be 8 or 16");
    }

    sample_rate = set_sample_rate;
    bit_depth = set_bit_depth;
    fifo.head = 0;
    fifo.tail = 0;
    sampling_active = true;

    check_error(nrfx_pdm_start());

    return 0;
}

static int lua_microphone_stop(lua_State *L)
{
    check_error(nrfx_pdm_stop());
    sampling_active = false;
    return 0;
}

static int lua_microphone_read(lua_State *L)
{
    lua_Integer bytes = luaL_checkinteger(L, 1);

    if (bytes % 2 != 0)
    {
        luaL_error(L, "bytes must be a multiple of 2");
    }

    if (fifo.tail == fifo.head)
    {
        if (sampling_active)
        {
            lua_pushstring(L, "");
            return 1;
        }

        lua_pushnil(L);
        return 1;
    }

    char *samples = malloc(bytes);
    if (samples == NULL)
    {
        luaL_error(L, "not enough memory");
    }

    size_t i = 0;
    while (true)
    {
        if (fifo.tail == fifo.head || i == bytes)
        {
            break;
        }

        int16_t raw_sample = fifo.buffer[fifo.tail++];
        if (fifo.tail == FIFO_TOTAL_SIZE)
        {
            fifo.tail = 0;
        }

        // 8khz simply throws away a sample
        // TODO 8khz is missing an anti-aliasing filter

        if (sample_rate == 16000 || (sample_rate == 8000 && fifo.tail % 2))
        {
            if (bit_depth == 16)
            {
                samples[i++] = raw_sample;
                samples[i++] = raw_sample >> 8;
            }

            if (bit_depth == 8)
            {
                samples[i++] = raw_sample >> 8;
            }
        }
    }

    lua_pushlstring(L, samples, i);
    free(samples);

    return 1;
}

void lua_open_microphone_library(lua_State *L)
{

    nrfx_pdm_config_t config = NRFX_PDM_DEFAULT_CONFIG(MICROPHONE_CLOCK_PIN,
                                                       MICROPHONE_DATA_PIN);

    config.edge = NRF_PDM_EDGE_LEFTRISING;
    config.clock_freq = NRF_PDM_FREQ_1280K;
    config.ratio = NRF_PDM_RATIO_80X;

    if (nrfx_pdm_init_check() == false)
    {
        check_error(nrfx_pdm_init(&config, pdm_event_handler));
    }

    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_microphone_start);
    lua_setfield(L, -2, "start");

    lua_pushcfunction(L, lua_microphone_stop);
    lua_setfield(L, -2, "stop");

    lua_pushcfunction(L, lua_microphone_read);
    lua_setfield(L, -2, "read");

    lua_setfield(L, -2, "microphone");

    lua_pop(L, 1);
}
