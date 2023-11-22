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

#include "lua.h"
#include "lfs.h"
#include "lauxlib.h"
#include "frame_lua_libraries.h"
#include "filesystem.h"

static int lua_file_read(lua_State *L)
{

    return 0;
}
static int lua_file_write(lua_State *L)
{

    return 0;
}
static int lua_file_open(lua_State *L)
{
    if (lua_gettop(L) > 2 || lua_gettop(L) == 0)
    {
        return luaL_error(L, "expected 1 or 2 arguments");
    }
    luaL_checkstring(L, 1);
    if (lua_gettop(L) == 2)
    {
        luaL_checkstring(L, 2);
    }
    char file_name[FS_NAME_MAX];
    sscanf(lua_tostring(L, 1), "%s", &file_name[0]);
    fs_file_write(&file_name[0]);
    lua_pushcfunction(L, lua_file_write);
    return 1;
}

void lua_open_file_library(lua_State *L)
{

    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_file_open);
    lua_setfield(L, -2, "open");

    lua_pushcfunction(L, lua_file_read);
    lua_setfield(L, -2, "read");

    lua_pushcfunction(L, lua_file_write);
    lua_setfield(L, -2, "write");

    lua_setfield(L, -2, "file");
    lua_pop(L, 1);
}