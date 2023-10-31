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
#include "nrfx_rtc.h"

static const nrfx_rtc_t rtc = NRFX_RTC_INSTANCE(1);

static uint64_t utc_time_ms = 0;

static void rtc_event_handler(nrfx_rtc_int_type_t int_type)
{
    utc_time_ms++;
}

static int frame_time_utc(lua_State *L)
{
    if (lua_gettop(L) == 0)
    {
        lua_pushnumber(L, (lua_Number)utc_time_ms / 1000);
        return 1;
    }

    luaL_checkinteger(L, 1);

    NRFX_IRQ_DISABLE(rtc.irq);
    utc_time_ms = lua_tointeger(L, 1) * 1000;
    NRFX_IRQ_ENABLE(rtc.irq);

    return 0;
}

static int frame_time_zone(lua_State *L)
{

    return 1;
}

static int frame_time_date(lua_State *L)
{

    return 1;
}

void open_frame_time_library(lua_State *L)
{
    // Configure the real time clock
    {
        nrfx_rtc_config_t config = NRFX_RTC_DEFAULT_CONFIG;

        // 1024Hz = >1ms resolution
        config.prescaler = NRF_RTC_FREQ_TO_PRESCALER(1024);

        check_error(nrfx_rtc_init(&rtc, &config, rtc_event_handler));

        nrfx_rtc_tick_enable(&rtc, true);
        nrfx_rtc_enable(&rtc);
    }

    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, frame_time_utc);
    lua_setfield(L, -2, "utc");

    lua_pushcfunction(L, frame_time_zone);
    lua_setfield(L, -2, "zone");

    lua_pushcfunction(L, frame_time_date);
    lua_setfield(L, -2, "date");

    lua_setfield(L, -2, "time");

    lua_pop(L, 1);
}