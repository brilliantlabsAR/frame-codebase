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

static lua_State *globalL = NULL;

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
static void lstop(lua_State *L, lua_Debug *ar)
{
    (void)ar;                   /* unused arg. */
    lua_sethook(L, NULL, 0, 0); /* reset hook */
    luaL_error(L, "interrupted!");
}

/*
** Function to be called at a C signal. Because a C signal cannot
** just change a Lua state (as there is no proper synchronization),
** this function only sets a hook that, when called, will stop the
** interpreter.
*/
static void laction(int i)
{
    int flag = LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT;
    // signal(i, SIG_DFL); /* if another SIGINT happens, terminate process */
    lua_sethook(globalL, lstop, flag, 1);
}

/*
** Message handler used to run all chunks
*/
static int msghandler(lua_State *L)
{
    const char *msg = lua_tostring(L, 1);
    if (msg == NULL)
    {                                            /* is error object not a string? */
        if (luaL_callmeta(L, 1, "__tostring") && /* does it have a metamethod */
            lua_type(L, -1) == LUA_TSTRING)      /* that produces a string? */
            return 1;                            /* that is the message */
        else
            msg = lua_pushfstring(L, "(error object is a %s value)",
                                  luaL_typename(L, 1));
    }
    luaL_traceback(L, L, msg, 1); /* append a standard traceback */
    return 1;                     /* return the traceback */
}

/*
** Interface to 'lua_pcall', which sets appropriate message function
** and C-signal handler. Used to run all chunks.
*/
static int docall(lua_State *L, int narg, int nres)
{
    int status;
    int base = lua_gettop(L) - narg;  /* function index */
    lua_pushcfunction(L, msghandler); /* push message handler */
    lua_insert(L, base);              /* put it under function and args */
    globalL = L;                      /* to be available to 'laction' */
    // signal(SIGINT, laction);          /* set C-signal handler */
    status = lua_pcall(L, narg, nres, base);
    // signal(SIGINT, SIG_DFL); /* reset C-signal handler */
    lua_remove(L, base); /* remove message handler from the stack */
    return status;
}

/* mark in error messages for incomplete statements */
#define EOFMARK "<eof>"
#define marklen (sizeof(EOFMARK) / sizeof(char) - 1)

/*
** Check whether 'status' signals a syntax error and the error
** message at the top of the stack ends with the above mark for
** incomplete statements.
*/
static int incomplete(lua_State *L, int status)
{
    if (status == LUA_ERRSYNTAX)
    {
        size_t lmsg;
        const char *msg = lua_tolstring(L, -1, &lmsg);
        if (lmsg >= marklen && strcmp(msg + lmsg - marklen, EOFMARK) == 0)
        {
            lua_pop(L, 1);
            return 1;
        }
    }
    return 0; /* else... */
}

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

    int status = luaL_dostring(L, repl.buffer);

    repl.new_data = false;

    if (status == LUA_OK)
    {
        int printables = lua_gettop(L);

        if (printables > 0)
        {
            LOG("Printing %d results", printables);

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
        // lua_writestringerror("%s\n", msg);
        LOG("Error: ");
        lua_pop(L, 1);
    }

    return 1;
}

/*
** Try to compile line on the stack as 'return <line>;'; on return, stack
** has either compiled chunk or original line (if compilation failed).
*/
static int addreturn(lua_State *L)
{
    const char *line = lua_tostring(L, -1); /* original line */
    const char *retline = lua_pushfstring(L, "return %s;", line);
    int status = luaL_loadbuffer(L, retline, strlen(retline), "=stdin");
    if (status == LUA_OK)
    {
        lua_remove(L, -2); /* remove modified line */
    }
    else
        lua_pop(L, 2); /* pop result from 'luaL_loadbuffer' and modified line */
    return status;
}

/*
** Read multiple lines until a complete Lua statement
*/
static int multiline(lua_State *L)
{
    for (;;)
    { /* repeat until gets a complete statement */
        size_t len;
        const char *line = lua_tolstring(L, 1, &len);         /* get what it has */
        int status = luaL_loadbuffer(L, line, len, "=stdin"); /* try it */
        if (!incomplete(L, status) || !pushline(L, 0))
        {
            return status; /* cannot or should not try to add continuation line */
        }
        lua_pushliteral(L, "\n"); /* add newline... */
        lua_insert(L, -2);        /* ...between the two lines */
        lua_concat(L, 3);         /* join them */
    }
}

/*
** Read a line and try to load (compile) it first as an expression (by
** adding "return " in front of it) and second as a statement. Return
** the final status of load/call with the resulting function (if any)
** in the top of the stack.
*/
static int loadline(lua_State *L)
{
    int status;
    lua_settop(L, 0);
    if (!pushline(L, 1))
        return -1;                         /* no input */
    if ((status = addreturn(L)) != LUA_OK) /* 'return ...' did not work? */
        status = multiline(L);             /* try as command, maybe with continuation lines */
    lua_remove(L, 1);                      /* remove line from the stack */
    lua_assert(lua_gettop(L) == 1);
    return status;
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
