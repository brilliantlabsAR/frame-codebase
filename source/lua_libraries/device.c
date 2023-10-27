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
#include "ble_gap.h"
#include "error_logging.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrfx_log.h"
#include "nrfx_saadc.h"
#include "pinout.h"

extern bool stay_awake;
extern bool force_sleep;

static int device_mac_address(lua_State *L)
{
    ble_gap_addr_t addr;
    check_error(sd_ble_gap_addr_get(&addr));

    char mac_addr_string[18];
    sprintf(mac_addr_string, "%02x:%02x:%02x:%02x:%02x:%02x",
            addr.addr[0], addr.addr[1], addr.addr[2],
            addr.addr[3], addr.addr[4], addr.addr[5]);

    lua_pushstring(L, mac_addr_string);
    return 1;
}

static int device_battery_level(lua_State *L)
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

static int device_stay_awake(lua_State *L)
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

static int device_sleep(lua_State *L)
{
    // TODO wait 3 seconds before actually sleeping
    force_sleep = true;
    return 0;
}

void device_open_library(lua_State *L)
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

    // Add device table to frame library
    lua_newtable(L);

    lua_pushstring(L, "frame");
    lua_setfield(L, -2, "NAME");

    lua_pushstring(L, BUILD_VERSION);
    lua_setfield(L, -2, "FIRMWARE_VERSION");

    lua_pushstring(L, GIT_COMMIT);
    lua_setfield(L, -2, "GIT_TAG");

    lua_pushcfunction(L, device_mac_address);
    lua_setfield(L, -2, "mac_address");

    lua_pushcfunction(L, device_battery_level);
    lua_setfield(L, -2, "battery_level");

    lua_pushcfunction(L, device_stay_awake);
    lua_setfield(L, -2, "stay_awake");

    lua_pushcfunction(L, device_sleep);
    lua_setfield(L, -2, "sleep");

    lua_setglobal(L, "device");
}