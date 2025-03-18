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
#include <stdbool.h>
#include "error_logging.h"
#include "lauxlib.h"
#include "lua.h"
#include "main.h"
#include "nrf_soc.h"
#include "nrf52840.h"
#include "nrfx_saadc.h"
#include "pinout.h"
#include "spi.h"

static int lua_update(lua_State *L)
{
    int status = show_pairing_screen(false, true);
    if (status != LUA_OK)
    {
        const char *lua_error = lua_tostring(L, -1);
        luaL_error(L, "%s", lua_error);
    }
    check_error(sd_power_gpregret_set(0, 0xB1));
    NVIC_SystemReset();
    return 0;
}

static int lua_sleep(lua_State *L)
{
    if (lua_gettop(L) == 0)
    {
        shutdown(true);
        return 0;
    }

    lua_Number seconds = luaL_checknumber(L, 1);
    lua_pop(L, 1);

    // Get the current time
    int status = luaL_dostring(L, "return frame.time.utc()");
    if (status != LUA_OK)
    {
        const char *lua_error = lua_tostring(L, -1);
        luaL_error(L, "%s", lua_error);
        lua_pop(L, -1);
    }

    // Add the current time to the wait time
    lua_Number wait_until = lua_tonumber(L, 1) + seconds;

    while (true)
    {
        // Keep getting the current time
        status = luaL_dostring(L, "return frame.time.utc()");
        if (status != LUA_OK)
        {
            const char *lua_error = lua_tostring(L, -1);
            luaL_error(L, "%s", lua_error);
            lua_pop(L, -1);
        }

        lua_Number current_time = lua_tonumber(L, 2);
        lua_pop(L, 1);

        if (current_time >= wait_until)
        {
            break;
        }

        // Clear exceptions and sleep
        __set_FPSCR(__get_FPSCR() & ~(0x0000009F));
        (void)__get_FPSCR();

        NVIC_ClearPendingIRQ(FPU_IRQn);

        check_error(sd_app_evt_wait());
    }

    return 0;
}

static int lua_stay_awake(lua_State *L)
{
    if (lua_gettop(L) > 1)
    {
        return luaL_error(L, "expected 0 or 1 arguments");
    }

    if (lua_gettop(L) == 1)
    {
        luaL_checktype(L, 1, LUA_TBOOLEAN);
        stay_awake = lua_toboolean(L, 1);
        return 0;
    }

    lua_pushboolean(L, stay_awake);
    return 1;
}

static int lua_battery_level(lua_State *L)
{
    nrf_saadc_value_t result;
    check_error(nrfx_saadc_simple_mode_set(1,
                                           NRF_SAADC_RESOLUTION_10BIT,
                                           NRF_SAADC_OVERSAMPLE_DISABLED,
                                           NULL));
    check_error(nrfx_saadc_buffer_set(&result, 1));

    check_error(nrfx_saadc_mode_trigger());

    // V = (raw / 10bits) * Vref * (1/NRFgain) * AMUXgain
    float voltage = ((float)result / 1024.0f) * 0.6f * 2.0f * (4.5f / 1.25f);

    // Percentage is based on a polynomial. Details in tools/battery-model
    float percentage = roundf(-118.13699f * powf(voltage, 3.0f) +
                              1249.63556f * powf(voltage, 2.0f) -
                              4276.33059f * voltage +
                              4764.47488f);

    if (percentage < 0.0f)
    {
        percentage = 0.0f;
    }

    if (percentage > 100.0f)
    {
        percentage = 100.0f;
    }

    lua_pushnumber(L, percentage);
    return 1;
}

static int lua_fpga_read(lua_State *L)
{
    lua_Integer address = luaL_checkinteger(L, 1);
    if (address < 0x00 || address > 0xFF)
    {
        luaL_error(L, "address must be between 0x00 and 0xFF");
    }

    lua_Integer length = luaL_checkinteger(L, 2);

    uint8_t *data = malloc(length);
    if (data == NULL)
    {
        luaL_error(L, "not enough memory");
    }

    spi_read(FPGA, address, data, length);
    lua_pushlstring(L, (char *)data, length);
    free(data);

    return 1;
}

static int lua_fpga_write(lua_State *L)
{
    lua_Integer address = luaL_checkinteger(L, 1);
    if (address < 0x00 || address > 0xFF)
    {
        luaL_error(L, "address must be between 0x00 and 0xFF");
    }

    size_t length;
    const char *data = luaL_checklstring(L, 2, &length);

    spi_write(FPGA, address, (uint8_t *)data, length);

    return 0;
}

void lua_open_system_library(lua_State *L)
{
    // Configure ADC
    if (nrfx_saadc_init_check() == false)
    {
        check_error(nrfx_saadc_init(NRFX_SAADC_DEFAULT_CONFIG_IRQ_PRIORITY));

        nrfx_saadc_channel_t channel = NRFX_SAADC_DEFAULT_CHANNEL_SE(
            BATTERY_LEVEL_PIN,
            0);

        channel.channel_config.reference = NRF_SAADC_REFERENCE_INTERNAL;
        channel.channel_config.gain = NRF_SAADC_GAIN1_2;

        check_error(nrfx_saadc_channel_config(&channel));
    }

    lua_getglobal(L, "frame");

    lua_pushcfunction(L, lua_update);
    lua_setfield(L, -2, "update");

    lua_pushcfunction(L, lua_sleep);
    lua_setfield(L, -2, "sleep");

    lua_pushcfunction(L, lua_stay_awake);
    lua_setfield(L, -2, "stay_awake");

    lua_pushcfunction(L, lua_battery_level);
    lua_setfield(L, -2, "battery_level");

    lua_pushcfunction(L, lua_fpga_read);
    lua_setfield(L, -2, "fpga_read");

    lua_pushcfunction(L, lua_fpga_write);
    lua_setfield(L, -2, "fpga_write");

    lua_pop(L, 1);
}