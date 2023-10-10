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

/*
** Prompt the user, read a line, and push it into the Lua stack.
*/
static int pushline(lua_State *L, int firstline)
{
    if (firstline)
    {
        lua_writestring("> ", sizeof("> "));
    }
    else
    {
        lua_writestring(">> ", sizeof(">> "));
    }

    while (repl.new_data == false)
    {
        // Wait for input
    }

    int status = luaL_dostring(L, "function fib(x) if x<=1 then return x end return fib(x-1)+fib(x-2) end print(fib(20)) print(fib(20)) print(fib(20)) print(fib(20)) print(fib(20))");
    // int status = luaL_dostring(L, (char *)repl.buffer);

    repl.new_data = false;

    if (status == LUA_OK)
    {
        int printables = lua_gettop(L);

        if (printables > 0)
        {
            luaL_checkstack(L, LUA_MINSTACK, "too many results to print");

            lua_getglobal(L, "print");
            lua_insert(L, 1);

            if (lua_pcall(L, printables, 0, 0) != LUA_OK)
            {
                const char *msg = lua_pushfstring(L,
                                                  "error calling 'print' (%s)",
                                                  lua_tostring(L, -1));

                lua_writestringerror("%s\n", msg);
            }
        }
    }

    else
    {
        const char *msg = lua_tostring(L, -1);
        lua_writestringerror("%s\n", msg);
        lua_pop(L, 1);
    }

    return 1;
}

void run_lua(void)
{
    lua_State *L = luaL_newstate();

    if (L == NULL)
    {
        error_with_message("Cannot create lua state: not enough memory");
    }

    luaL_openlibs(L);

    char *version_string = LUA_RELEASE " on Brilliant Frame";
    lua_writestring((uint8_t *)version_string, strlen(version_string));
    lua_writeline();

    while (true)
    {
        pushline(L, 1);
    }

    lua_close(L);

    while (1)
    {
    }
}
