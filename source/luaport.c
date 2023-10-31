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
#include "error_logging.h"
#include "frame_lua_libraries.h"
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
#include "nrfx_log.h"

// static lua_State *globalL = NULL;

static volatile struct repl_t
{
    char buffer[253];
    bool new_data;
} repl = {
    .new_data = false,
};

bool lua_write_to_repl(uint8_t *buffer, uint8_t length)
{
    if (length >= sizeof(repl.buffer))
    {
        return false;
    }

    if (repl.new_data)
    {
        return false;
    }

    // Naive copy because memcpy isn't compatible with volatile
    for (size_t buffer_index = 0; buffer_index < length; buffer_index++)
    {
        repl.buffer[buffer_index] = buffer[buffer_index];
    }

    // Null terminate the string
    repl.buffer[length] = 0;

    repl.new_data = true;

    return true;
}

/*
** Hook set by signal function to stop the interpreter.
*/
// static void lstop(lua_State *L, lua_Debug *ar)
// {
//     (void)ar;                   /* unused arg. */
//     lua_sethook(L, NULL, 0, 0); /* reset hook */
//     luaL_error(L, "interrupted!");
// }

// void lua_interrupt(void)
// {
//     int flag = LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT;
//     lua_sethook(globalL, lstop, flag, 1);
// }

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

    // Create a global frame table where the frame libraries will be placed
    lua_newtable(L);
    lua_setglobal(L, "frame");

    // Open the frame specific libraries
    open_frame_version_library(L);
    open_frame_bluetooth_library(L);
    // open_frame_display_library(L);
    // open_frame_camera_library(L);
    open_frame_microphone_library(L);
    // open_frame_imu_library(L);
    open_frame_time_library(L);
    open_frame_sleep_library(L);
    open_frame_misc_library(L);
    // open_frame_file_library(L);

    // Make sure the above functions cleared up the stack correctly
    if (lua_gettop(L) != 0)
    {
        error_with_message("Lua stack not cleared");
    }

    // TODO attempt to run main.lua

    while (true)
    {
        // Wait for input
        while (repl.new_data == false)
        {
            // TODO sleep
        }

        // If we get a reset command
        if (repl.buffer[0] == 0x04)
        {
            repl.new_data = false;
            break;
        }

        int status = luaL_dostring(L, (char *)repl.buffer);

        if (status != LUA_OK)
        {
            const char *lua_error = lua_tostring(L, -1);
            lua_writestring(lua_error, strlen(lua_error));
            lua_pop(L, 1);
        }

        repl.new_data = false;
    }

    lua_close(L);
}
