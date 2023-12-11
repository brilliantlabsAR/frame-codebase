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

#include "error_logging.h"
#include "flash.h"
#include "frame_lua_libraries.h"
#include "lauxlib.h"
#include "lfs.h"
#include "lua.h"
#include "luaconf.h"

static int lfs_api_read_block(const struct lfs_config *c,
                              lfs_block_t block,
                              lfs_off_t off,
                              void *buffer,
                              lfs_size_t size)
{
    uint32_t address = flash_base_address() + (block * c->block_size) + off;

    memcpy(buffer, (void *)address, size);

    return 0;
}

static void write_byte(uint32_t address, uint8_t b)
{
    uint32_t address_aligned = address & ~3;

    // Value to write - leave all bits that should not change at 0xff.
    uint32_t value = 0xffffff00 | b;

    // Rotate bits in value to an aligned position.
    value = (value << (address & 3) * 8) | (value >> (32 - (address & 3) * 8));

    flash_write(address_aligned, &value, 1);
}

static int lfs_api_program_block(const struct lfs_config *c,
                                 lfs_block_t block,
                                 lfs_off_t off,
                                 const void *buffer,
                                 lfs_size_t size)
{
    uint32_t address = flash_base_address() + (block * c->block_size) + off;

    const uint8_t *source = buffer;
    const uint8_t *source_end = source + size;

    while (source != source_end && (address & 0b11))
    {

        write_byte(address, *source);
        flash_wait_until_complete();
        address++;
        source++;
    }

    while (source_end - source >= 4)
    {
        uint8_t buf[4] __attribute__((aligned(4)));
        for (int i = 0; i < 4; i++)
        {
            buf[i] = ((uint8_t *)source)[i];
        }

        flash_write(address, (const uint32_t *)&buf, 1);
        flash_wait_until_complete();
        source += 4;
        address += 4;
    }

    //  Write remaining unaligned bytes.
    while (source != source_end)
    {

        write_byte(address, *source);
        flash_wait_until_complete();

        address++;
        source++;
    }

    return 0;
}

static int lfs_api_sync_block(const struct lfs_config *c)
{
    return 0;
}

static int lfs_api_erase_block(const struct lfs_config *c, lfs_block_t block)
{
    uint32_t address = flash_base_address() + (block * c->block_size);

    LOG("Erasing block %u at 0x%x", block, address);
    flash_erase_page(address);
    flash_wait_until_complete();

    return 0;
}

static struct lfs_config filesystem_config = {
    .read = lfs_api_read_block,
    .prog = lfs_api_program_block,
    .erase = lfs_api_erase_block,
    .sync = lfs_api_sync_block,
    .read_size = 8,
    .prog_size = 8,
    .cache_size = 32,
    .lookahead_size = 8,
    .block_cycles = 100,
    .name_max = 0x100,
    .file_max = 0x10000,
};

static lfs_t filesystem;

typedef struct file_stream_t
{
    lfs_file_t file;
    lua_CFunction close_function;
} file_stream_t;

static int lua_file_close(lua_State *L)
{
    file_stream_t *stream = (file_stream_t *)luaL_checkudata(L,
                                                             1,
                                                             LUA_FILEHANDLE);

    int error = lfs_file_close(&filesystem, &stream->file);

    if (error)
    {
        LOG("file close error %d", error);
        // TODO
    }

    return 0;
}

static int lua_file_open(lua_State *L)
{
    const char *filename = luaL_checkstring(L, 1);
    const char *mode = luaL_optstring(L, 2, "r");

    LOG("Opening %s, in %s mode", filename, mode);

    file_stream_t *stream =
        (file_stream_t *)lua_newuserdatauv(L, sizeof(file_stream_t), 0);

    stream->close_function = &lua_file_close;
    luaL_setmetatable(L, LUA_FILEHANDLE);

    int lfs_mode_flag = 0;

    switch (mode[0])
    {
    case 'r':
        lfs_mode_flag = LFS_O_RDONLY;
        break;
    case 'w':
        lfs_mode_flag = LFS_O_RDWR | LFS_O_CREAT;
        break;
    case 'a':
        lfs_mode_flag = LFS_O_APPEND | LFS_O_CREAT;
        break;
    default:
        luaL_error(L, "mode must be 'r', 'w', or 'a'");
        break;
    }

    int error = lfs_file_open(&filesystem,
                              &stream->file,
                              filename,
                              lfs_mode_flag);

    if (error)
    {
        luaL_error(L, "cannot open file %s", filename);
        return 1;
    }

    return 1;
}

static int lua_file_read(lua_State *L)
{
    return 0;
}

static int lua_file_write(lua_State *L)
{
    return 0;
}

static int lua_file_remove(lua_State *L)
{
    return 0;
}

static int lua_file_rename(lua_State *L)
{
    return 0;
}

static int lua_file_mkdir(lua_State *L)
{
    return 0;
}

static int lua_file_listdir(lua_State *L)
{
    return 0;
}

///

// #define IO_PREFIX "_IO_"
// #define IO_INPUT (IO_PREFIX "input")
// #define IO_OUTPUT (IO_PREFIX "output")
// #define IOPREF_LEN (sizeof(IO_PREFIX) / sizeof(char) - 1)
// #define MAXARGLINE 250

// static lfs_file_t *getiofile(lua_State *L, const char *findex)
// {
//     lua_File_Stream *p;
//     lua_getfield(L, LUA_REGISTRYINDEX, findex);
//     p = (lua_File_Stream *)lua_touserdata(L, -1);
//     if (p->close_function == NULL)
//         luaL_error(L, "default %s file is closed", findex + IOPREF_LEN);
//     return p->f;
// }

// static lfs_file_t *tofile(lua_State *L)
// {
//     lua_File_Stream *p = tolstream(L);
//     if (p->close_function == NULL)
//     {
//         luaL_error(L, "attempt to use a closed file");
//     }
//     lua_assert(p->f);
//     return p->f;
// }

// static int g_write(lua_State *L, lfs_file_t *f, int arg)
// {
//     int nargs = lua_gettop(L) - arg;
//     int status = 1;
//     for (; nargs--; arg++)
//     {
//         size_t l;
//         const char *s = luaL_checklstring(L, arg, &l);
//         status = status && (lfs_file_write(&filesystem, f, s, strlen(s)) == l);
//     }
//     if (luai_likely(status))
//         return 1; /* file handle already on stack top */
//     else
//         return luaL_fileresult(L, status, NULL);
// }

// static void read_all(lua_State *L, lfs_file_t *f)
// {
//     size_t nr;
//     luaL_Buffer b;
//     luaL_buffinit(L, &b);
//     do
//     { /* read file in chunks of LUAL_BUFFERSIZE bytes */
//         char *p = luaL_prepbuffer(&b);
//         nr = lfs_file_read(&filesystem, f, p, LUAL_BUFFERSIZE);
//         luaL_addsize(&b, nr);
//     } while (nr == LUAL_BUFFERSIZE);
//     luaL_pushresult(&b); /* close buffer */
// }

// int l_getc(lfs_file_t *f)
// {
//     char c[1] = {0};
//     return lfs_file_read(&filesystem, f, &c[0], sizeof(char)) > 0 ? (int)c[0] : EOF;
// }

// static int read_line(lua_State *L, lfs_file_t *f, int chop)
// {
//     luaL_Buffer b;
//     int c;
//     luaL_buffinit(L, &b);
//     do
//     {                                     /* may need to read several chunks to get whole line */
//         char *buff = luaL_prepbuffer(&b); /* preallocate buffer space */
//         int i = 0;
//         // l_lockfile(f);  /* no memory errors can happen inside the lock */
//         while (i < LUAL_BUFFERSIZE && (c = l_getc(f)) != EOF && c != '\n')
//             buff[i++] = c; /* read up to end of line or buffer limit */
//         // l_unlockfile(f);
//         // break;
//         luaL_addsize(&b, i);
//         // break;
//     } while (c != EOF && c != '\n'); /* repeat until end of line */
//     if (!chop && c == '\n')          /* want a newline and have one? */
//         luaL_addchar(&b, c);         /* add ending newline to result */
//     luaL_pushresult(&b);             /* close buffer */
//     /* return ok if read something (either a newline or something else) */
//     return (c == '\n' || lua_rawlen(L, -1) > 0);
// }

// static int g_read(lua_State *L, lfs_file_t *f, int first)
// {
//     int nargs = lua_gettop(L) - 1;
//     int n, success;
//     // clearerr(f);
//     if (nargs == 0)
//     { /* no arguments? */
//         success = read_line(L, f, 1);
//         // read_all(L, f);
//         // success = 1;
//         n = first + 1;
//     }
//     else
//     {
//         /* ensure stack space for all results and for auxlib's buffer */
//         luaL_checkstack(L, nargs + LUA_MINSTACK, "too many arguments");
//         success = 1;
//         for (n = first; nargs-- && success; n++)
//         {
//             if (lua_type(L, n) == LUA_TNUMBER)
//             {
//                 // size_t l = (size_t)luaL_checkinteger(L, n);
//                 // success = (l == 0) ? test_eof(L, f) : read_chars(L, f, l);
//             }
//             else
//             {
//                 const char *p = luaL_checkstring(L, n);
//                 if (*p == '*')
//                     p++; /* skip optional '*' (for compatibility) */
//                 switch (*p)
//                 {
//                 case 'n': /* number */
//                     // success = read_number(L, f);
//                     break;
//                 case 'l': /* line */
//                     // success = read_line(L, f, 1);
//                     break;
//                 case 'L': /* line with end-of-line */
//                     // success = read_line(L, f, 0);
//                     break;
//                 case 'a':           /* file */
//                     read_all(L, f); /* read entire file */
//                     success = 1;    /* always success */
//                     break;
//                 default:
//                     return luaL_argerror(L, n, "invalid format");
//                 }
//             }
//         }
//     }
//     // if (ferror(f))
//     //   return luaL_fileresult(L, 0, NULL);
//     if (!success)
//     {
//         lua_pop(L, 1);    /* remove last result */
//         luaL_pushfail(L); /* push nil instead */
//     }
//     return n - first;
// }

// static int lua_file_write(lua_State *L)
// {
//     lua_pushvalue(L, 1); /* push file at the stack top (to be returned) */
//     return g_write(L, tofile(L), 2);
// }

// static int lua_file_read(lua_State *L)
// {
//     return g_read(L, tofile(L), 2);
// }

// int create_dir_recursive(const char *path)
// {
//     char *dir;
//     int err = 0;
//     char *pathCopy = strdup(path);
//     dir = strtok(pathCopy, "/");
//     char currentPath[256] = "/";
//     while (dir != NULL)
//     {
//         strcat(currentPath, dir);

//         err = lfs_mkdir(&filesystem, currentPath);
//         if (err >= 0)
//         {
//             // check_error(lfs_fo(&filesystem, file));
//         }

//         strcat(currentPath, "/");
//         dir = strtok(NULL, "/");
//     }
//     return err;
// }

// static int io_readline(lua_State *L)
// {
//     lua_File_Stream *p = (lua_File_Stream *)lua_touserdata(L, lua_upvalueindex(1));
//     int i;
//     int n = (int)lua_tointeger(L, lua_upvalueindex(2));
//     if (p->close_function == NULL) /* file is already closed? */
//         return luaL_error(L, "file is already closed");
//     lua_settop(L, 1);
//     luaL_checkstack(L, n, "too many arguments");
//     for (i = 1; i <= n; i++) /* push arguments to 'g_read' */
//         lua_pushvalue(L, lua_upvalueindex(3 + i));
//     n = g_read(L, p->f, 2);   /* 'n' is number of results */
//     lua_assert(n > 0);        /* should return at least a nil */
//     if (lua_toboolean(L, -n)) /* read at least one value? */
//         return n;             /* return them */
//     else
//     { /* first result is false: EOF or error */
//         if (n > 1)
//         { /* is there error information? */
//             /* 2nd result is error message */
//             return luaL_error(L, "%s", lua_tostring(L, -n + 1));
//         }
//         if (lua_toboolean(L, lua_upvalueindex(3)))
//         {                                          /* generator created file? */
//             lua_settop(L, 0);                      /* clear stack */
//             lua_pushvalue(L, lua_upvalueindex(1)); /* push file at index 1 */
//             lua_File_Stream *p = tolstream(L);
//             p->close_function = NULL; /* close it */
//         }
//         return 0;
//     }
// }

// static void aux_lines(lua_State *L, int toclose)
// {
//     int n = lua_gettop(L) - 1; /* number of arguments to read */
//     luaL_argcheck(L, n <= MAXARGLINE, MAXARGLINE + 2, "too many arguments");
//     lua_pushvalue(L, 1);         /* file */
//     lua_pushinteger(L, n);       /* number of arguments to read */
//     lua_pushboolean(L, toclose); /* close/not close file when finished */
//     lua_rotate(L, 2, 3);         /* move the three values to their positions */
//     lua_pushcclosure(L, io_readline, 3 + n);
// }

// static int lua_file_remove(lua_State *L)
// {
//     const char *filename = luaL_checkstring(L, 1);
//     return luaL_fileresult(L, lfs_remove(&filesystem, filename) == 0, filename);
// }

// static int lua_file_rename(lua_State *L)
// {
//     const char *fromname = luaL_checkstring(L, 1);
//     const char *toname = luaL_checkstring(L, 2);
//     return luaL_fileresult(L, lfs_rename(&filesystem, fromname, toname) == 0, NULL);
// }

// static int lua_file_mkdir(lua_State *L)

// {
//     const char *path = luaL_checkstring(L, 1);
//     return luaL_fileresult(L, create_dir_recursive(path) == 0, NULL);
// }

// static int lua_file_listdir(lua_State *L)
// {
//     const char *path = luaL_checkstring(L, 1);
//     lfs_dir_t *dir;

//     int err = lfs_dir_open(&filesystem, dir, path);

//     if (dir == NULL || err)
//     {
//         // TODO
//     }

//     struct lfs_info info;
//     int i = 0;
//     lua_newtable(L);
//     while (lfs_dir_read(&filesystem, dir, &info) > 0)
//     {
//         lua_newtable(L);

//         lua_pushinteger(L, info.size);
//         lua_rawseti(L, -2, 0);

//         lua_pushinteger(L, info.type);
//         lua_rawseti(L, -2, 1);

//         lua_pushstring(L, info.name);
//         lua_rawseti(L, -2, 2);

//         lua_rawseti(L, -2, ++i);
//     }
//     lfs_dir_close(&filesystem, dir);
//     return 1;
// }

static const luaL_Reg meta_methods[] = {
    {"__index", NULL},
    // {"__gc", f_gc},
    // {"__close", f_gc},
    // {"__tostring", f_tostring},
    {NULL, NULL}};

static const luaL_Reg file_methods[] = {
    {"read", lua_file_read},
    {"write", lua_file_write},
    {"close", lua_file_close},
    {NULL, NULL}};

void lua_open_file_library(lua_State *L, bool reformat)
{
    size_t page_size;
    size_t total_size;
    flash_get_info(&page_size, &total_size);

    filesystem_config.block_size = page_size;
    filesystem_config.block_count = (total_size / page_size) - 1;

    int file_mount_error = lfs_mount(&filesystem, &filesystem_config);

    if (reformat || file_mount_error)
    {
        check_error(lfs_format(&filesystem, &filesystem_config));
        check_error(lfs_mount(&filesystem, &filesystem_config));
    }

    // file handlers
    luaL_newmetatable(L, LUA_FILEHANDLE);
    luaL_setfuncs(L, meta_methods, 0);
    luaL_newlibtable(L, file_methods);
    luaL_setfuncs(L, file_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pop(L, 1);

    lua_getglobal(L, "frame");
    lua_newtable(L);

    lua_pushcfunction(L, lua_file_open);
    lua_setfield(L, -2, "open");

    lua_pushcfunction(L, lua_file_remove);
    lua_setfield(L, -2, "remove");

    lua_pushcfunction(L, lua_file_rename);
    lua_setfield(L, -2, "rename");

    lua_pushcfunction(L, lua_file_listdir);
    lua_setfield(L, -2, "listdir");

    lua_pushcfunction(L, lua_file_mkdir);
    lua_setfield(L, -2, "mkdir");

    lua_setfield(L, -2, "file");
    lua_pop(L, 1);
}
