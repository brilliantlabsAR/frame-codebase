/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
 *              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
 *
 * ISC Licence
 *
 * Copyright © 2025 Brilliant Labs Ltd.
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

#include "compression.h"
#include "frame_lua_libraries.h"
#include "lauxlib.h"
#include "lua.h"
#include "watchdog.h"

static int registered_function = 0;

static void decompression_lua_handler(lua_State *L, lua_Debug *ar)
{
    sethook_watchdog(L);

    if (registered_function != 0)
    {
        lua_rawgeti(L, LUA_REGISTRYINDEX, registered_function);

        // TODO: Add the data to the function call if it's not already added

        if (lua_pcall(L, 0, 0, 0) != LUA_OK)
        {
            luaL_error(L, "%s", lua_tostring(L, -1));
        }
    }
}

static void process_function_callback(void *context,
                                      void *data,
                                      size_t data_size)
{
    // TODO copy the data to a buffer

    lua_sethook(L_global,
                decompression_lua_handler,
                LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT,
                1);
}

static int lua_compression_register_process_function(lua_State *L)
{
    if (lua_isnil(L, 1))
    {
        registered_function = 0;
        return 0;
    }

    if (lua_isfunction(L, 1))
    {
        registered_function = luaL_ref(L, LUA_REGISTRYINDEX);
        return 0;
    }

    luaL_error(L, "expected nil or function");

    return 0;
}

static int lua_compression_decompress(lua_State *L)
{
    int status = compression_decompress(4096,      // TODO figure out destination size
                                        NULL,      // TODO pass the source data to the decompression function
                                        sizeof(0), // TODO set the source data size
                                        process_function_callback,
                                        NULL);

    if (status != 0)
    {
        luaL_error(L, "decompression failed");
    }

    return 0;
}

void lua_open_compression_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_compression_register_process_function);
    lua_setfield(L, -2, "process_function");

    lua_pushcfunction(L, lua_compression_decompress);
    lua_setfield(L, -2, "decompress");

    lua_setfield(L, -2, "compression");

    lua_pop(L, 1);
}