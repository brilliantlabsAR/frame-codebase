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

static void check_if_file_closed(lua_State *L, file_stream_t *stream)
{
    if (stream->close_function == NULL)
    {
        luaL_error(L, "attempt to use a closed file");
    }
}

static int lua_file_close(lua_State *L)
{
    file_stream_t *stream = (file_stream_t *)luaL_checkudata(L,
                                                             1,
                                                             LUA_FILEHANDLE);

    check_if_file_closed(L, stream);

    check_error(lfs_file_close(&filesystem, &stream->file));

    stream->close_function = NULL;

    return 0;
}

static int lua_file_open(lua_State *L)
{
    const char *filename = luaL_checkstring(L, 1);
    const char *mode = luaL_optstring(L, 2, "r");

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
        lfs_mode_flag = LFS_O_RDWR | LFS_O_CREAT | LFS_O_TRUNC;
        break;
    case 'a':
        lfs_mode_flag = LFS_O_RDWR | LFS_O_APPEND | LFS_O_CREAT;
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
    }

    return 1;
}

static int lua_file_read(lua_State *L)
{
    file_stream_t *stream = (file_stream_t *)luaL_checkudata(L,
                                                             1,
                                                             LUA_FILEHANDLE);

    check_if_file_closed(L, stream);

    luaL_Buffer buffer;
    luaL_buffinit(L, &buffer);

    char character;

    for (size_t i = 0; i < LUAL_BUFFERSIZE; i++)
    {
        lfs_ssize_t result = lfs_file_read(&filesystem,
                                           &stream->file,
                                           &character,
                                           1);

        if (result < 0)
        {
            luaL_error(L, "error reading file");
        }

        if (result == 0 || character == '\n')
        {
            // Reading empty file or line
            if (i == 0)
            {
                if (character == '\n')
                {
                    lua_pushstring(L, "");
                }
                else
                {
                    lua_pushnil(L);
                }
                return 1;
            }

            break;
        }

        luaL_addchar(&buffer, character);
    }

    luaL_pushresult(&buffer);
    return 1;
}

static int lua_file_write(lua_State *L)
{
    file_stream_t *stream = (file_stream_t *)luaL_checkudata(L,
                                                             1,
                                                             LUA_FILEHANDLE);

    check_if_file_closed(L, stream);

    if ((stream->file.flags & LFS_O_RDWR) == LFS_O_RDONLY)
    {
        luaL_error(L, "file opened in read-only mode");
    }

    size_t expected_length;
    const char *string = luaL_checklstring(L, 2, &expected_length);

    lfs_ssize_t result = lfs_file_write(&filesystem,
                                        &stream->file,
                                        string,
                                        strlen(string));

    if (result != expected_length)
    {
        luaL_error(L, "error writing to file");
    }

    return 0;
}

static int lua_file_remove(lua_State *L)
{
    const char *filename = luaL_checkstring(L, 1);

    int error = lfs_remove(&filesystem, filename);

    if (error)
    {
        luaL_error(L, "error deleting file/directory");
    }

    return 0;
}

static int lua_file_rename(lua_State *L)
{
    const char *from_name = luaL_checkstring(L, 1);
    const char *to_name = luaL_checkstring(L, 2);

    int error = lfs_rename(&filesystem, from_name, to_name);

    if (error)
    {
        luaL_error(L, "error renaming file/directory");
    }

    return 0;
}

static int lua_file_mkdir(lua_State *L)
{
    size_t path_length;
    const char *full_path = luaL_checklstring(L, 1, &path_length);

    if (path_length > filesystem.name_max)
    {
        luaL_error(L, "path too long");
    }

    char *remaining_path = (char *)full_path;

    while (remaining_path++ != NULL)
    {
        remaining_path = strchr(remaining_path, '/');

        char current_path[filesystem.name_max];
        memset(current_path, 0, filesystem.name_max);

        if (remaining_path == NULL)
        {
            strcpy(current_path, full_path);
        }

        else
        {
            size_t current_path_length = (size_t)(remaining_path - full_path);
            strncpy(current_path, full_path, current_path_length);
        }

        int error = lfs_mkdir(&filesystem, current_path);

        if (error)
        {
            luaL_error(L, "error creating directory");
        }
    }

    return 0;
}

static int lua_file_listdir(lua_State *L)
{
    const char *full_path = luaL_checkstring(L, 1);

    lfs_dir_t directory;
    int error = lfs_dir_open(&filesystem, &directory, full_path);

    if (error)
    {
        luaL_error(L, "directory not found");
    }

    lua_newtable(L);
    lua_Integer i = 1;

    struct lfs_info info;

    while (true)
    {
        error = lfs_dir_read(&filesystem, &directory, &info);

        if (error == 0)
        {
            break;
        }

        if (error < 0)
        {
            luaL_error(L, "error reading from directory");
        }

        // TODO why do we need this?
        char temp_name[filesystem.name_max];
        strcpy(temp_name, info.name);

        lua_newtable(L);

        lua_pushinteger(L, info.size);
        lua_setfield(L, -2, "size");

        lua_pushinteger(L, info.type);
        lua_setfield(L, -2, "type");

        lua_pushstring(L, temp_name);
        lua_setfield(L, -2, "name");

        lua_seti(L, -2, i++);
    }

    lfs_dir_close(&filesystem, &directory);

    return 1;
}

static int lua_file_require(lua_State *L)
{
    file_stream_t stream;

    const char *module_name = luaL_checkstring(L, 1);
    const char *filename = lua_pushfstring(L, "%s.lua", module_name);

    int error = lfs_file_open(&filesystem,
                              &stream.file,
                              filename,
                              LFS_O_RDONLY);

    if (error)
    {
        luaL_error(L, "cannot open file: %s", filename);
    }

    size_t size = 0;
    char *buffer = NULL;
    char character;

    while (true)
    {
        lfs_ssize_t result = lfs_file_read(&filesystem,
                                           &stream.file,
                                           &character,
                                           1);

        if (result < 0)
        {
            free(buffer);
            luaL_error(L, "error reading file: %s", filename);
        }

        if (result == 0)
        {
            break;
        }

        buffer = (char *)realloc(buffer, size + 1);
        buffer[size++] = character;
    };

    check_error(lfs_file_close(&filesystem, &stream.file));

    int status = luaL_loadbuffer(L, buffer, size, filename);
    free(buffer);

    if (status || lua_pcall(L, 0, LUA_MULTRET, 0))
    {
        luaL_error(L,
                   "exiting module '%s': %s",
                   module_name,
                   lua_tostring(L, -1));
    }

    return 1;
}

static const luaL_Reg meta_methods[] = {
    {"__index", NULL},
    // TODO do we need garbage collection?
    // {"__gc", f_gc},
    // {"__close", f_gc},
    {NULL, NULL},
};

static const luaL_Reg file_methods[] = {
    {"read", lua_file_read},
    {"write", lua_file_write},
    {"close", lua_file_close},
    {NULL, NULL},
};

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
        LOG("Reformatting filesystem");
        check_error(lfs_format(&filesystem, &filesystem_config));
        check_error(lfs_mount(&filesystem, &filesystem_config));
    }

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

    lua_pushcfunction(L, lua_file_require);
    lua_setglobal(L, "require");
}

void lua_close_file_library(void)
{
    check_error(lfs_unmount(&filesystem));
}