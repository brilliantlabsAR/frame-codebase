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

static lua_Integer bit_depth = 16;

// Main FIFO where PDM data is written to
#define FIFO_TOTAL_SIZE 80000
static struct fifo
{
    int16_t buffer[FIFO_TOTAL_SIZE];
    size_t chunk_size;
    size_t head;
    size_t tail;
    size_t remaining_samples;
} fifo = {
    .chunk_size = 100,
    .head = 0,
    .tail = 0,
    .remaining_samples = 0,
};

// Averaging FIFO that's used to down convert samples during microphone.read()
static struct moving_average
{
    int16_t buffer[4];
    size_t head;
    size_t window_size;
} moving_average = {
    .head = 0,
};

static nrfy_pdm_config_t config = {
    .mode = NRF_PDM_MODE_MONO,
    .edge = NRF_PDM_EDGE_LEFTRISING,
    .pins =
        {
            .clk_pin = MICROPHONE_CLOCK_PIN,
            .din_pin = MICROPHONE_DATA_PIN,
        },
    .clock_freq = NRF_PDM_FREQ_1032K,
    .gain_l = NRF_PDM_GAIN_DEFAULT,
    .gain_r = NRF_PDM_GAIN_DEFAULT,
    .ratio = NRF_PDM_RATIO_64X,
    .skip_psel_cfg = false,
};

void PDM_IRQHandler(void)
{
    uint32_t evt_mask = nrfy_pdm_events_process(
        NRF_PDM0,
        NRFY_EVENT_TO_INT_BITMASK(NRF_PDM_EVENT_STARTED),
        NULL);

    if (evt_mask & NRFY_EVENT_TO_INT_BITMASK(NRF_PDM_EVENT_STARTED))
    {
        fifo.head += fifo.chunk_size;
        fifo.remaining_samples -= fifo.chunk_size;

        if (fifo.head == FIFO_TOTAL_SIZE)
        {
            fifo.head = 0;
        }

        nrfy_pdm_buffer_t buffer = {
            .length = fifo.chunk_size,
            .p_buff = fifo.buffer + fifo.head};

        nrfy_pdm_buffer_set(NRF_PDM0, &buffer);

        // If the next cycle will cause an overflow, abort early to avoid
        // corrupting the existing data at the tail
        if ((fifo.head == fifo.tail - fifo.chunk_size) ||
            (fifo.tail == 0 && fifo.head + fifo.chunk_size == FIFO_TOTAL_SIZE))
        {
            nrfy_pdm_abort(NRF_PDM0, NULL);
        }

        // Stop after the last sample is taken
        if (fifo.remaining_samples == 0)
        {
            nrfy_pdm_abort(NRF_PDM0, NULL);
        }
    }
}

static int lua_microphone_record(lua_State *L)
{
    nrfy_pdm_disable(NRF_PDM0);

    luaL_checknumber(L, 1);
    lua_Number seconds = lua_tonumber(L, 1);
    if (seconds <= 0)
    {
        luaL_error(L, "seconds must be greater than 0");
    }

    luaL_checkinteger(L, 2);
    lua_Integer sample_rate = lua_tointeger(L, 2);

    // Set the PDM clock and ratio
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

    // Set the moving average window
    switch (sample_rate)
    {
    case 20000:
    case 16000:
    case 12500:
        moving_average.window_size = 1;
        break;

    case 10000:
    case 8000:
        moving_average.window_size = 2;
        break;

    case 5000:
    case 4000:
        moving_average.window_size = 4;
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

    // TODO do we want to add a gain control?

    // Figure out total samples, and round up to nearest chunksize
    fifo.remaining_samples =
        (size_t)ceil(seconds * sample_rate / fifo.chunk_size) *
        fifo.chunk_size *
        moving_average.window_size;

    // Reset head and tail
    fifo.head = 0;
    fifo.tail = 0;

    nrfy_pdm_periph_configure(NRF_PDM0, &config);

    nrfy_pdm_buffer_t buffer = {
        .length = fifo.chunk_size,
        .p_buff = fifo.buffer + fifo.head};

    nrfy_pdm_buffer_set(NRF_PDM0, &buffer);
    nrfy_pdm_enable(NRF_PDM0);
    nrfy_pdm_start(NRF_PDM0, NULL);

    return 0;
}

static int16_t averaged_sample()
{
    for (size_t i = 0; i < moving_average.window_size; i++)
    {
        // Pop from main fifo
        int16_t raw_sample = fifo.buffer[fifo.tail];

        fifo.tail++;

        if (fifo.tail == FIFO_TOTAL_SIZE)
        {
            fifo.tail = 0;
        }

        // Push into averaging fifo
        moving_average.buffer[moving_average.head] = raw_sample;

        moving_average.head++;

        if (moving_average.head == moving_average.window_size)
        {
            moving_average.head = 0;
        }
    }

    int32_t sum = 0.0f;
    for (size_t i = 0; i < moving_average.window_size; i++)
    {
        sum += moving_average.buffer[i];
    }

    float average = roundf((float)sum / moving_average.window_size);

    return (int16_t)average;
}

static int lua_microphone_read(lua_State *L)
{
    luaL_checkinteger(L, 1);
    lua_Integer bytes = lua_tointeger(L, 1);
    if (bytes > 512)
    {
        luaL_error(L, "too many bytes requested");
    }

    if (bytes % 4 != 0)
    {
        luaL_error(L, "bytes must be a multiple of 4");
    }

    // Return nil if the fifo is empty
    if (fifo.tail == fifo.head)
    {
        lua_pushnil(L);
        return 1;
    }

    size_t i = 0;
    char *samples = malloc(bytes);
    if (samples == NULL)
    {
        luaL_error(L, "not enough memory");
    }

    while (true)
    {
        if (fifo.tail == fifo.head)
        {
            break;
        }

        switch (bit_depth)
        {
        case 16:
            int16_t sample16 = averaged_sample();
            samples[i++] = sample16 >> 8;
            samples[i++] = sample16 & 0xFF;
            break;

        case 8:
            int16_t sample8 = averaged_sample() >> 8;
            samples[i++] = sample8;
            break;

        case 4:
            int16_t sample4_top = (averaged_sample() >> 12) & 0x0F;
            int16_t sample4_bot = (averaged_sample() >> 12) & 0x0F;
            int8_t combined_sample = (sample4_top << 4) | sample4_bot;
            samples[i++] = combined_sample;
            break;
        }

        if (i == bytes)
        {
            break;
        }
    }

    lua_pushlstring(L, samples, i);
    free(samples);

    return 1;
}

void lua_open_microphone_library(lua_State *L)
{
    if (FIFO_TOTAL_SIZE % fifo.chunk_size)
    {
        error_with_message("chunks don't fit evenly into fifo");
    }

    nrfy_gpio_pin_clear(config.pins.clk_pin);
    nrfy_gpio_cfg_output(config.pins.clk_pin);
    nrfy_gpio_cfg_input(config.pins.din_pin, NRF_GPIO_PIN_NOPULL);

    nrfy_pdm_int_init(NRF_PDM0,
                      NRF_PDM_INT_STARTED,
                      NRFX_PDM_DEFAULT_CONFIG_IRQ_PRIORITY,
                      true);

    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_microphone_record);
    lua_setfield(L, -2, "record");

    lua_pushcfunction(L, lua_microphone_read);
    lua_setfield(L, -2, "read");

    lua_setfield(L, -2, "microphone");

    lua_pop(L, 1);
}
