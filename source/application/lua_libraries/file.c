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
#define IO_PREFIX "_IO_"
#define IO_INPUT (IO_PREFIX "input")
#define IO_OUTPUT (IO_PREFIX "output")
#define IOPREF_LEN (sizeof(IO_PREFIX) / sizeof(char) - 1)
#define MAXARGLINE 250

typedef struct lua_File_Stream
{
  lfs_file_t *f;        /* stream (NULL for incompletely created streams) */
  lua_CFunction closef; /* to close stream (NULL for closed streams) */
} lua_File_Stream;
#define tolstream(L) ((lua_File_Stream *)luaL_checkudata(L, 1, LUA_FILEHANDLE))

static int l_checkmode(const char *m)
{
  return ((m[0] == 'r' || m[0] == 'w' || m[0] == 'a') && m[1] == '\0');
}
static lfs_file_t *getiofile(lua_State *L, const char *findex)
{
  lua_File_Stream *p;
  lua_getfield(L, LUA_REGISTRYINDEX, findex);
  p = (lua_File_Stream *)lua_touserdata(L, -1);
  if (p->closef == NULL)
    luaL_error(L, "default %s file is closed", findex + IOPREF_LEN);
  return p->f;
}

static lfs_file_t *tofile(lua_State *L)
{
  lua_File_Stream *p = tolstream(L);
  if (p->closef == NULL)
  {
    luaL_error(L, "attempt to use a closed file");
  }
  lua_assert(p->f);
  return p->f;
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
    status = status && (fs_file_write(f, s, l) == l);
    // }
  }
  if (luai_likely(status))
    return 1; /* file handle already on stack top */
  else
    return luaL_fileresult(L, status, NULL);
}
static void read_all(lua_State *L, lfs_file_t *f)
{
  size_t nr;
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  do
  { /* read file in chunks of LUAL_BUFFERSIZE bytes */
    char *p = luaL_prepbuffer(&b);
    nr = fs_file_read(f, p, LUAL_BUFFERSIZE);
    luaL_addsize(&b, nr);
  } while (nr == LUAL_BUFFERSIZE);
  luaL_pushresult(&b); /* close buffer */
}
int l_getc(lfs_file_t *f)
{
  char c[1] = {0};
  return fs_file_read(f, &c[0], sizeof(char)) > 0 ? (int)c[0] : EOF;
}
static int read_line(lua_State *L, lfs_file_t *f, int chop)
{
  luaL_Buffer b;
  int c;
  luaL_buffinit(L, &b);
  do
  {                                   /* may need to read several chunks to get whole line */
    char *buff = luaL_prepbuffer(&b); /* preallocate buffer space */
    int i = 0;
    // l_lockfile(f);  /* no memory errors can happen inside the lock */
    while (i < LUAL_BUFFERSIZE && (c = l_getc(f)) != EOF && c != '\n')
      buff[i++] = c; /* read up to end of line or buffer limit */
    // l_unlockfile(f);
    // break;
    luaL_addsize(&b, i);
    // break;
  } while (c != EOF && c != '\n'); /* repeat until end of line */
  if (!chop && c == '\n')          /* want a newline and have one? */
    luaL_addchar(&b, c);           /* add ending newline to result */
  luaL_pushresult(&b);             /* close buffer */
  /* return ok if read something (either a newline or something else) */
  return (c == '\n' || lua_rawlen(L, -1) > 0);
}

static int g_read(lua_State *L, lfs_file_t *f, int first)
{
  int nargs = lua_gettop(L) - 1;
  int n, success;
  // clearerr(f);
  if (nargs == 0)
  { /* no arguments? */
    success = read_line(L, f, 1);
    // read_all(L, f);
    // success = 1;
    n = first + 1;
  }
  else
  {
    /* ensure stack space for all results and for auxlib's buffer */
    luaL_checkstack(L, nargs + LUA_MINSTACK, "too many arguments");
    success = 1;
    for (n = first; nargs-- && success; n++)
    {
      if (lua_type(L, n) == LUA_TNUMBER)
      {
        // size_t l = (size_t)luaL_checkinteger(L, n);
        // success = (l == 0) ? test_eof(L, f) : read_chars(L, f, l);
      }
      else
      {
        const char *p = luaL_checkstring(L, n);
        if (*p == '*')
          p++; /* skip optional '*' (for compatibility) */
        switch (*p)
        {
        case 'n': /* number */
          // success = read_number(L, f);
          break;
        case 'l': /* line */
          // success = read_line(L, f, 1);
          break;
        case 'L': /* line with end-of-line */
          // success = read_line(L, f, 0);
          break;
        case 'a':         /* file */
          read_all(L, f); /* read entire file */
          success = 1;    /* always success */
          break;
        default:
          return luaL_argerror(L, n, "invalid format");
        }
      }
    }
  }
  // if (ferror(f))
  //   return luaL_fileresult(L, 0, NULL);
  if (!success)
  {
    lua_pop(L, 1);    /* remove last result */
    luaL_pushfail(L); /* push nil instead */
  }
  return n - first;
}

static int file_handler_write(lua_State *L)
{
  lua_pushvalue(L, 1); /* push file at the stack top (to be returned) */
  return g_write(L, tofile(L), 2);
}
// static int lua_file_open(lua_State *L)
// {
//     if (lua_gettop(L) > 2 || lua_gettop(L) == 0)
//     {n
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
  lua_File_Stream *p = tolstream(L);
  int res = fs_file_close(p->f);
  return luaL_fileresult(L, (res == 0), NULL);
}
static lua_File_Stream *newfile(lua_State *L)
{
  lua_File_Stream *p = (lua_File_Stream *)lua_newuserdatauv(L, sizeof(lua_File_Stream), 0);
  p->f = NULL;
  p->closef = &file_handler_close;
  luaL_setmetatable(L, LUA_FILEHANDLE);
  return p;
}
static void opencheck(lua_State *L, const char *fname, const char *mode)
{
  lua_File_Stream *p = newfile(L);
  p->f = fs_file_open(fname, LFS_O_RDONLY);
  if (p->f == NULL)
    luaL_error(L, "cannot open file '%s'", fname);
}

static int file_handler_read(lua_State *L)
{
  return g_read(L, tofile(L), 2);
}
static int lua_file_open(lua_State *L)
{
  const char *filename = luaL_checkstring(L, 1);
  const char *mode = luaL_optstring(L, 2, "r");
  lua_File_Stream *p = newfile(L);
  const char *m = mode; /* to traverse/check mode */
  int md;
  luaL_argcheck(L, l_checkmode(m), 2, "invalid mode");
  switch (m[0])
  {
  case 'a':
    md = LFS_O_APPEND | LFS_O_CREAT;
    break;
  case 'w':
    md = LFS_O_RDWR | LFS_O_CREAT;
    break;
  default:
    md = LFS_O_RDONLY;
    break;
  }
  p->f = fs_file_open(filename, md);
  if (p->f == NULL)
  {
    luaL_error(L, "cannot open file %s", filename);
    return 1;
  }
  return (p->f == NULL) ? luaL_fileresult(L, 0, filename) : 1;
}
static int g_iofile(lua_State *L, const char *f, const char *mode)
{
  if (!lua_isnoneornil(L, 1))
  {
    const char *filename = lua_tostring(L, 1);
    if (filename)
      opencheck(L, filename, mode);
    else
    {
      tofile(L); /* check that it's a valid file handle */
      lua_pushvalue(L, 1);
    }
    lua_setfield(L, LUA_REGISTRYINDEX, f);
  }
  /* return current value */
  lua_getfield(L, LUA_REGISTRYINDEX, f);
  return 1;
}

static int io_readline(lua_State *L)
{
  lua_File_Stream *p = (lua_File_Stream *)lua_touserdata(L, lua_upvalueindex(1));
  int i;
  int n = (int)lua_tointeger(L, lua_upvalueindex(2));
  if (p->closef == NULL) /* file is already closed? */
    return luaL_error(L, "file is already closed");
  lua_settop(L, 1);
  luaL_checkstack(L, n, "too many arguments");
  for (i = 1; i <= n; i++) /* push arguments to 'g_read' */
    lua_pushvalue(L, lua_upvalueindex(3 + i));
  n = g_read(L, p->f, 2);   /* 'n' is number of results */
  lua_assert(n > 0);        /* should return at least a nil */
  if (lua_toboolean(L, -n)) /* read at least one value? */
    return n;               /* return them */
  else
  { /* first result is false: EOF or error */
    if (n > 1)
    { /* is there error information? */
      /* 2nd result is error message */
      return luaL_error(L, "%s", lua_tostring(L, -n + 1));
    }
    if (lua_toboolean(L, lua_upvalueindex(3)))
    {                                        /* generator created file? */
      lua_settop(L, 0);                      /* clear stack */
      lua_pushvalue(L, lua_upvalueindex(1)); /* push file at index 1 */
      lua_File_Stream *p = tolstream(L);
      p->closef = NULL; /* close it */
    }
    return 0;
  }
}
static void aux_lines(lua_State *L, int toclose)
{
  int n = lua_gettop(L) - 1; /* number of arguments to read */
  luaL_argcheck(L, n <= MAXARGLINE, MAXARGLINE + 2, "too many arguments");
  lua_pushvalue(L, 1);         /* file */
  lua_pushinteger(L, n);       /* number of arguments to read */
  lua_pushboolean(L, toclose); /* close/not close file when finished */
  lua_rotate(L, 2, 3);         /* move the three values to their positions */
  lua_pushcclosure(L, io_readline, 3 + n);
}

static int file_handler_lines(lua_State *L)
{
  tofile(L); /* check that it's a valid file handle */
  aux_lines(L, 0);
  return 1;
}
static int file_handler_seek(lua_State *L)
{
  static const int mode[] = {SEEK_SET, SEEK_CUR, SEEK_END};
  static const char *const modenames[] = {"set", "cur", "end", NULL};
  lfs_file_t *f = tofile(L);
  int op = luaL_checkoption(L, 2, "cur", modenames);
  lua_Integer p3 = luaL_optinteger(L, 3, 0);
  long offset = (long)p3;
  luaL_argcheck(L, (lua_Integer)offset == p3, 3,
                "not an integer in proper range");
  op = fs_file_seek(f, offset, mode[op]);
  if (op < 0)
    return luaL_fileresult(L, 0, NULL); /* error */
  else
  {
    lua_pushinteger(L, (lua_Integer)op);
    return 1;
  }
}

static int lua_file_read(lua_State *L)
{
  return g_read(L, getiofile(L, IO_INPUT), 1);
}
static int lua_file_input(lua_State *L)
{
  return g_iofile(L, IO_INPUT, "r");
}
static int lua_file_close(lua_State *L)
{
  if (lua_isnone(L, 1))                            /* no argument? */
    lua_getfield(L, LUA_REGISTRYINDEX, IO_OUTPUT); /* use default output */
  tofile(L);
  return file_handler_close(L);
}
static int lua_file_remove(lua_State *L)
{
  const char *filename = luaL_checkstring(L, 1);
  return luaL_fileresult(L, fs_file_remove(filename) == 0, filename);
}
static int lua_file_rename(lua_State *L)
{
  const char *fromname = luaL_checkstring(L, 1);
  const char *toname = luaL_checkstring(L, 2);
  return luaL_fileresult(L, fs_file_raname(fromname, toname) == 0, NULL);
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
    {"read", file_handler_read},
    {"write", file_handler_write},
    {"lines", file_handler_lines},
    // {"flush", f_flush},
    {"seek", file_handler_seek},
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

  lua_pushcfunction(L, lua_file_close);
  lua_setfield(L, -2, "close");

  lua_pushcfunction(L, lua_file_remove);
  lua_setfield(L, -2, "remove");

  lua_pushcfunction(L, lua_file_rename);
  lua_setfield(L, -2, "rename");
  // lua_pushcfunction(L, lua_file_input);
  // lua_setfield(L, -2, "input");

  lua_setfield(L, -2, "file");
  lua_pop(L, 1);
}