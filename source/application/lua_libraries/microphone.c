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
#include <haly/nrfy_pdm.h>
#include <haly/nrfy_gpio.h>

#define PDM_BUFFER_SIZE 128
static bool sampling_active = false;
static lua_Integer sample_rate = 8000;
static lua_Integer bit_depth = 8;

#define FIFO_TOTAL_SIZE 4096
static struct fifo
{
    int16_t buffer[FIFO_TOTAL_SIZE];
    size_t head;
    size_t tail;
} fifo;

#if (FIFO_TOTAL_SIZE % PDM_BUFFER_SIZE)
#error "chunks don't fit evenly into fifo"
#endif

void PDM_IRQHandler(void)
{
    uint32_t evt_mask = nrfy_pdm_events_process(
        NRF_PDM0,
        NRFY_EVENT_TO_INT_BITMASK(NRF_PDM_EVENT_STARTED),
        NULL);

    if (evt_mask & NRFY_EVENT_TO_INT_BITMASK(NRF_PDM_EVENT_STARTED))
    {
        fifo.head += PDM_BUFFER_SIZE;

        if (fifo.head == FIFO_TOTAL_SIZE)
        {
            fifo.head = 0;
        }

        nrfy_pdm_buffer_t buffer = {
            .length = PDM_BUFFER_SIZE,
            .p_buff = fifo.buffer + fifo.head,
        };

        nrfy_pdm_buffer_set(NRF_PDM0, &buffer);
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

    nrfy_pdm_buffer_t buffer = {
        .length = PDM_BUFFER_SIZE,
        .p_buff = fifo.buffer};

    nrfy_pdm_buffer_set(NRF_PDM0, &buffer);
    nrfy_pdm_start(NRF_PDM0, NULL);

    sampling_active = true;

    return 0;
}

static int lua_microphone_stop(lua_State *L)
{
    nrfy_pdm_abort(NRF_PDM0, NULL);
    sampling_active = false;
    return 0;
}

static int lua_microphone_read(lua_State *L)
{
    lua_Integer bytes = luaL_checkinteger(L, 1);

    if (bytes > 512)
    {
        luaL_error(L, "too many bytes requested");
    }

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
    nrfy_pdm_int_init(NRF_PDM0,
                      NRF_PDM_INT_STARTED,
                      NRFX_PDM_DEFAULT_CONFIG_IRQ_PRIORITY,
                      true);

    nrfy_pdm_config_t config = {
        .mode = NRF_PDM_MODE_MONO,
        .edge = NRF_PDM_EDGE_LEFTRISING,
        .pins =
            {
                .clk_pin = MICROPHONE_CLOCK_PIN,
                .din_pin = MICROPHONE_DATA_PIN,
            },
        .clock_freq = NRF_PDM_FREQ_1280K,
        .gain_l = NRF_PDM_GAIN_DEFAULT,
        .gain_r = NRF_PDM_GAIN_DEFAULT,
        .ratio = NRF_PDM_RATIO_80X,
        .skip_psel_cfg = false,
    };

    nrfy_gpio_pin_clear(config.pins.clk_pin);
    nrfy_gpio_cfg_output(config.pins.clk_pin);
    nrfy_gpio_cfg_input(config.pins.din_pin, NRF_GPIO_PIN_NOPULL);

    nrfy_pdm_periph_configure(NRF_PDM0, &config);
    nrfy_pdm_enable(NRF_PDM0);

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
