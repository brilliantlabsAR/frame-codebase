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
#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "lua.h"
#include "lualib.h"
#include "nrfx_log.h"

#define lua_writestring(s, l) send_message(BLUETOOTH_DATA_TO_SEND, s, l)
#define lua_writeline() send_message(BLUETOOTH_DATA_TO_SEND, "\n", 1)
#define lua_writestringerror(s, p) LOG(s, p)

#include "lauxlib.h"

// extern uint32_t __heap_start;
// extern uint32_t __heap_end;

void run_lua(void)
{
    char buff[256] = "6 + 7";

    lua_State *L = luaL_newstate();

    if (L == NULL)
    {
        error_with_message("Cannot create lua state: not enough memory");
    }

    luaL_openlibs(L);

    char *version_string = LUA_RELEASE " on Brilliant Frame";
    lua_writestring((uint8_t *)version_string, strlen(version_string));
    lua_writeline();

    int error = luaL_loadstring(L, buff) || lua_pcall(L, 0, 0, 0);
    if (error)
    {
        lua_writestring(lua_tostring(L, -1), strlen(lua_tostring(L, -1)));
        lua_writeline();
        lua_pop(L, 1);
    }
    else
    {
        int n = lua_gettop(L);
        if (n > 0)
        { /* any result to be printed? */
            luaL_checkstack(L, LUA_MINSTACK, "too many results to print");
            lua_getglobal(L, "print");
            lua_insert(L, 1);
            lua_pcall(L, n, 0, 0);
        }
    }

    lua_close(L);

    while (1)
    {
    }
}