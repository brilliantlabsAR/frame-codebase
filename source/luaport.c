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

#include <string.h>
#include "bluetooth.h"
#include "error_logging.h"
#include "frame_lua_libraries.h"
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
#include "nrf_soc.h"
#include "nrfx_log.h"

lua_State *globalL = NULL;

static volatile char repl_buffer[BLE_PREFERRED_MAX_MTU];

void lua_write_to_repl(uint8_t *buffer, uint8_t length)
{
    // Loop copy because memcpy isn't compatible with volatile
    for (size_t buffer_index = 0; buffer_index < length; buffer_index++)
    {
        repl_buffer[buffer_index] = buffer[buffer_index];
    }

    // Null terminate the string
    repl_buffer[length] = 0;
}

static void lua_interrupt_hook(lua_State *L, lua_Debug *ar)
{
    lua_sethook(L, NULL, 0, 0);
    luaL_error(L, "interrupted!");
}

void lua_interrupt(void)
{
    int flag = LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT;
    lua_sethook(globalL, lua_interrupt_hook, flag, 1);
}

void run_lua(void)
{
    lua_State *L = luaL_newstate();

    if (L == NULL)
    {
        error_with_message("Cannot create lua state: not enough memory");
    }

    // Open the standard libraries
    luaL_requiref(L, LUA_GNAME, luaopen_base, 1);
    luaL_requiref(L, LUA_LOADLIBNAME, luaopen_package, 1);
    luaL_requiref(L, LUA_COLIBNAME, luaopen_coroutine, 1);
    luaL_requiref(L, LUA_TABLIBNAME, luaopen_table, 1);
    luaL_requiref(L, LUA_STRLIBNAME, luaopen_string, 1);
    luaL_requiref(L, LUA_MATHLIBNAME, luaopen_math, 1);
    luaL_requiref(L, LUA_UTF8LIBNAME, luaopen_utf8, 1);
    luaL_requiref(L, LUA_DBLIBNAME, luaopen_debug, 1);
    lua_pop(L, 8);

    // Create a global frame table and load the libraries
    lua_newtable(L);
    lua_setglobal(L, "frame");

    lua_open_version_library(L);
    lua_open_power_library(L);
    lua_open_bluetooth_library(L);
    // lua_open_display_library(L);
    // lua_open_camera_library(L);
    lua_open_microphone_library(L);
    // lua_open_imu_library(L);
    lua_open_time_library(L);
    // lua_open_file_library(L);

    // Make sure the above functions cleared up the stack correctly
    if (lua_gettop(L) != 0)
    {
        error_with_message("Lua stack not cleared");
    }

    // TODO attempt to run main.lua

    while (true)
    {
        // If we get a reset command
        if (repl_buffer[0] == 0x04)
        {
            break;
        }

        globalL = L; // TODO can we move this?
        int status;

        if (repl_buffer[0] != 0)
        {
            NRFX_IRQ_DISABLE(SD_EVT_IRQn);
            char local_repl_buffer[BLE_PREFERRED_MAX_MTU];
            strcpy(local_repl_buffer, (char *)repl_buffer);
            repl_buffer[0] = 0;
            NRFX_IRQ_ENABLE(SD_EVT_IRQn);

            status = luaL_dostring(L, (char *)local_repl_buffer);
        }
        else
        {
            status = luaL_dostring(L, "frame.sleep(0.1)");
        }

        if (status != LUA_OK)
        {
            const char *lua_error = lua_tostring(L, -1);
            lua_writestring(lua_error, strlen(lua_error));
            lua_pop(L, 1);
        }
    }

    lua_close(L);
}
