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

#include "lfs.h"
#include "filesystem.h"
#include "lua.h"
#include "lauxlib.h"
#include "frame_lua_libraries.h"
#include "luaconf.h"

typedef struct lua_file_Stream
{
  lfs_file_t *f;        /* stream (NULL for incompletely created streams) */
  lua_CFunction closef; /* to close stream (NULL for closed streams) */
} lua_file_Stream;
#define tolstream(L) ((lua_file_Stream *)luaL_checkudata(L, 1, LUA_FILEHANDLE))

static int l_checkmode(const char *m)
{
  return ((m[0] == 'r' || m[0] == 'w') && m[1] == '\0');
}

static int lua_file_read(lua_State *L)
{

  return 0;
}
static int g_write(lua_State *L, lfs_file_t *f, int arg)
{
  int nargs = lua_gettop(L) - arg;
  int status = 1;
  for (; nargs--; arg++)
  {
    // if (lua_type(L, arg) == LUA_TNUMBER)
    // {
    //   /* optimization: could be done exactly as for strings */
    //   // int len = lua_isinteger(L, arg)
    //   //               ? fprintf(f, LUA_INTEGER_FMT,
    //   //                         (LUAI_UACINT)lua_tointeger(L, arg))
    //   //               : fprintf(f, LUA_NUMBER_FMT,
    //   //                         (LUAI_UACNUMBER)lua_tonumber(L, arg));
    //   // status = status && (len > 0);
    // }
    // else
    // {
    size_t l;
    const char *s = luaL_checklstring(L, arg, &l);
    LOG("content %s", s);
    status = status && (fs_file_write(f, s, l) == l);
    // }
  }
  if (luai_likely(status))
    return 1; /* file handle already on stack top */
  else
    return luaL_fileresult(L, status, NULL);
}
// static int g_read(lua_State *L, lfs_file_t *f, int first)
// {
//   int nargs = lua_gettop(L) - 1;
//   int n, success;
//   clearerr(f);
//   if (nargs == 0)
//   { /* no arguments? */
//     // success = read_line(L, f, 1);
//     // n = first + 1; /* to return 1 result */
//   }
//   else
//   {
//     /* ensure stack space for all results and for auxlib's buffer */
//     luaL_checkstack(L, nargs + LUA_MINSTACK, "too many arguments");
//     success = 1;
//     for (n = first; nargs-- && success; n++)
//     {
//       if (lua_type(L, n) == LUA_TNUMBER)
//       {
//         size_t l = (size_t)luaL_checkinteger(L, n);
//         success = (l == 0) ? test_eof(L, f) : read_chars(L, f, l);
//       }
//       else
//       {
//         const char *p = luaL_checkstring(L, n);
//         if (*p == '*')
//           p++; /* skip optional '*' (for compatibility) */
//         switch (*p)
//         {
//         case 'n': /* number */
//           success = read_number(L, f);
//           break;
//         case 'l': /* line */
//           success = read_line(L, f, 1);
//           break;
//         case 'L': /* line with end-of-line */
//           success = read_line(L, f, 0);
//           break;
//         case 'a':         /* file */
//           read_all(L, f); /* read entire file */
//           success = 1;    /* always success */
//           break;
//         default:
//           return luaL_argerror(L, n, "invalid format");
//         }
//       }
//     }
//   }
//   if (ferror(f))
//     return luaL_fileresult(L, 0, NULL);
//   if (!success)
//   {
//     lua_pop(L, 1);    /* remove last result */
//     luaL_pushfail(L); /* push nil instead */
//   }
//   return n - first;
// }

static int file_handler_write(lua_State *L)
{
  lua_file_Stream *p = tolstream(L);
  if (p->closef == NULL)
  {

    luaL_error(L, "attempt to use a closed file");
  }
  lua_assert(p->f);
  lua_pushvalue(L, 1); /* push file at the stack top (to be returned) */
  return g_write(L, p->f, 2);
}
// static int lua_file_open(lua_State *L)
// {
//     if (lua_gettop(L) > 2 || lua_gettop(L) == 0)
//     {
//         return luaL_error(L, "expected 1 or 2 arguments");
//     }
//     luaL_checkstring(L, 1);
//     if (lua_gettop(L) == 2)
//     {
//         luaL_checkstring(L, 2);
//     }
//     char file_name[FS_NAME_MAX];
//     sscanf(lua_tostring(L, 1), "%s", &file_name[0]);
//     lua_settop(L, 2);
//     fs_file_write(&file_name[0]);
//     lua_pushcfunction(L, lua_file_write);
//     return 1;
// }
static int file_handler_close(lua_State *L)
{
  lua_file_Stream *p = tolstream(L);
  int res = fs_file_close(p->f);
  return luaL_fileresult(L, (res == 0), NULL);
}
static lua_file_Stream *newfile(lua_State *L)
{
  lua_file_Stream *p = (lua_file_Stream *)lua_newuserdatauv(L, sizeof(lua_file_Stream), 0);
  p->f = NULL;
  p->closef = &file_handler_close;
  luaL_setmetatable(L, LUA_FILEHANDLE);
  return p;
}
// static int file_handler_read(lua_State *L)
// {
//   return g_read(L, tofile(L), 2);
// }
static int lua_file_open(lua_State *L)
{
  const char *filename = luaL_checkstring(L, 1);
  const char *mode = luaL_optstring(L, 2, "r");
  lua_file_Stream *p = newfile(L);
  const char *md = mode; /* to traverse/check mode */
  luaL_argcheck(L, l_checkmode(md), 2, "invalid mode");
  p->f = fs_file_open(filename);
  return (p->f == NULL) ? luaL_fileresult(L, 0, filename) : 1;
}
/*
** metamethods for file handles
*/
static const luaL_Reg metameth[] = {
    {"__index", NULL}, /* place holder */
    // {"__gc", f_gc},
    // {"__close", f_gc},
    // {"__tostring", f_tostring},
    {NULL, NULL}};
/*
** methods for file handles
*/
static const luaL_Reg meth[] = {
    // {"read", file_handler_read},
    {"write", file_handler_write},
    // {"lines", f_lines},
    // {"flush", f_flush},
    // {"seek", f_seek},
    {"close", file_handler_close},
    // {"setvbuf", f_setvbuf},
    {NULL, NULL}};
void lua_open_file_library(lua_State *L)
{

  // file handlers
  luaL_newmetatable(L, LUA_FILEHANDLE); /* metatable for file handles */
  luaL_setfuncs(L, metameth, 0);        /* add metamethods to new metatable */
  luaL_newlibtable(L, meth);            /* create method table */
  luaL_setfuncs(L, meth, 0);            /* add file methods to method table */
  lua_setfield(L, -2, "__index");       /* metatable.__index = method table */
  lua_pop(L, 1);                        /* pop metatable */

  lua_getglobal(L, "frame");
  lua_newtable(L);
  lua_pushcfunction(L, lua_file_open);
  lua_setfield(L, -2, "open");

  lua_pushcfunction(L, lua_file_read);
  lua_setfield(L, -2, "read");

  lua_pushcfunction(L, lua_file_read);
  lua_setfield(L, -2, "write");

  lua_setfield(L, -2, "file");
  lua_pop(L, 1);
}