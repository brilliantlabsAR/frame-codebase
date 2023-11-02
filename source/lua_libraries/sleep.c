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

#include <stdbool.h>
#include "error_logging.h"
#include "lauxlib.h"
#include "lua.h"
#include "main.h"
#include "nrf_soc.h"
#include "nrf52840.h"

static int wait_for(lua_State *L, lua_Number seconds)
{
    // Get the current time
    int status = luaL_dostring(L, "return frame.time.utc()");

    switch (status)
    {
    case LUA_OK:
        break;

    case LUA_YIELD:
        return LUA_YIELD;
        break;

    default:
        error_with_message("lua error");
        break;
    }

    // Add the current time to the wait time
    lua_Number wait_until = lua_tonumber(L, 1) + seconds;

    while (true)
    {
        // Keep getting the current time
        status = luaL_dostring(L, "return frame.time.utc()");

        switch (status)
        {
        case LUA_OK:
            break;

        case LUA_YIELD:
            return LUA_YIELD;
            break;

        default:
            error_with_message("lua error");
            break;
        }

        lua_Number current_time = lua_tonumber(L, 2);
        lua_pop(L, 1);

        if (current_time >= wait_until)
        {
            break;
        }

        // Clear exceptions
        __set_FPSCR(__get_FPSCR() & ~(0x0000009F));
        (void)__get_FPSCR();

        NVIC_ClearPendingIRQ(FPU_IRQn);

        check_error(sd_app_evt_wait());
    }

    return LUA_OK;
}

static int frame_sleep(lua_State *L)
{
    if (lua_gettop(L) == 0)
    {
        if (wait_for(L, 3) == LUA_OK)
        {
            shutdown(true);
        }

        return 0;
    }

    lua_Number seconds = lua_tonumber(L, 1);
    lua_pop(L, 1);

    wait_for(L, seconds);
    return 0;
}

void open_frame_sleep_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_pushcfunction(L, frame_sleep);
    lua_setfield(L, -2, "sleep");

    lua_pop(L, 1);
}