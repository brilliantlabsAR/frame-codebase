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
#include <time.h>
#include "error_logging.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrfx_rtc.h"

#include "nrfx_log.h"

static const nrfx_rtc_t rtc = NRFX_RTC_INSTANCE(1);

static uint64_t utc_time_ms = 0;
static int8_t time_zone_offset_hours;
static uint8_t time_zone_offset_minutes;

static void rtc_event_handler(nrfx_rtc_int_type_t int_type)
{
    utc_time_ms++;
}

static int lua_time_utc(lua_State *L)
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

static int lua_time_zone(lua_State *L)
{
    if (lua_gettop(L) == 0)
    {
        char time_zone_string[10] = "";
        sprintf(time_zone_string,
                "%c%02d:%02u",
                time_zone_offset_hours >= 0 ? '+' : '-',
                abs(time_zone_offset_hours),
                time_zone_offset_minutes);

        lua_pushstring(L, time_zone_string);

        return 1;
    }

    int hour = 0;
    int minute = 0;

    luaL_checkstring(L, 1);

    if (sscanf(lua_tostring(L, 1), "%d:%d", &hour, &minute) != 2)
    {
        luaL_error(L, "must be '+hh:mm' or '-hh:mm'");
    }

    if (hour < -12.0 || hour > 14.0)
    {
        luaL_error(L, "hour value must be between -12 and +14");
    }

    if (minute != 0 && minute != 30 && minute != 45)
    {
        luaL_error(L, "minute value must be either 00, 30, or 45");
    }

    if ((hour == -12.0 || hour == 14.0) && minute != 0.0)
    {
        luaL_error(L, "when hour is -12 or 14, minutes must be 0");
    }

    time_zone_offset_hours = hour;
    time_zone_offset_minutes = minute;

    return 0;
}

static void table_from_time(lua_State *L, time_t time)
{
    struct tm local_time_now_table;

    gmtime_r(&time, &local_time_now_table);

    lua_newtable(L);

    lua_pushinteger(L, local_time_now_table.tm_sec);
    lua_setfield(L, -2, "second");

    lua_pushinteger(L, local_time_now_table.tm_min);
    lua_setfield(L, -2, "minute");

    lua_pushinteger(L, local_time_now_table.tm_hour);
    lua_setfield(L, -2, "hour");

    lua_pushinteger(L, local_time_now_table.tm_mday);
    lua_setfield(L, -2, "day");

    lua_pushinteger(L, local_time_now_table.tm_mon + 1);
    lua_setfield(L, -2, "month");

    lua_pushinteger(L, local_time_now_table.tm_year + 1900);
    lua_setfield(L, -2, "year");

    lua_pushinteger(L, local_time_now_table.tm_wday);
    lua_setfield(L, -2, "weekday");

    lua_pushinteger(L, local_time_now_table.tm_yday);
    lua_setfield(L, -2, "day of year");

    lua_pushboolean(L, local_time_now_table.tm_isdst);
    lua_setfield(L, -2, "is daylight saving");
}

static int lua_time_date(lua_State *L)
{
    // Get local time as table
    if (lua_gettop(L) == 0)
    {
        time_t local_time_now_s = (utc_time_ms / 1000) +
                                  (time_zone_offset_minutes * 60) +
                                  (time_zone_offset_hours * 60 * 60);

        table_from_time(L, local_time_now_s);

        return 1;
    }

    // Return table from epoch timestamp
    if (lua_isinteger(L, 1))
    {

        time_t local_time_from_stamp_s = lua_tointeger(L, 1) +
                                         (time_zone_offset_minutes * 60) +
                                         (time_zone_offset_hours * 60 * 60);

        table_from_time(L, local_time_from_stamp_s);

        return 1;
    }

    luaL_error(L, "expected a utc timestamp");

    return 0;
}

void lua_open_time_library(lua_State *L)
{
    // Configure the real time clock
    if (nrfx_rtc_init_check(&rtc) == false)
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

    lua_pushcfunction(L, lua_time_utc);
    lua_setfield(L, -2, "utc");

    lua_pushcfunction(L, lua_time_zone);
    lua_setfield(L, -2, "zone");

    lua_pushcfunction(L, lua_time_date);
    lua_setfield(L, -2, "date");

    lua_setfield(L, -2, "time");

    lua_pop(L, 1);
}