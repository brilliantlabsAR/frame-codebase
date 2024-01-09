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

#include <stdbool.h>
#include <stdint.h>
#include "lua.h"
#include "lauxlib.h"
#include "spi.h"
#include "error_logging.h"

// TODO: Add logic to put camera to sleep
static bool camera_awake = true;

static int lua_camera_capture(lua_State *L)
{
    if (camera_awake == false)
    {
        luaL_error(L, "camera is asleep");
    }

    uint8_t address = 0x20;
    spi_write(FPGA, &address, 1, false);
    return 0;
}

static uint16_t get_bytes_available(void)
{
    uint8_t address = 0x21;
    uint8_t data[2] = {0, 0};

    spi_write(FPGA, &address, 1, true);
    spi_read(FPGA, (uint8_t *)data, sizeof(data), false);

    uint16_t bytes_available = (uint16_t)data[0] << 8 |
                               (uint16_t)data[1];

    return bytes_available;
}

static int lua_camera_read(lua_State *L)
{
    luaL_checkinteger(L, 1);

    lua_Integer bytes_requested = lua_tointeger(L, 1);
    uint16_t bytes_available = get_bytes_available();

    if (bytes_requested <= 0)
    {
        luaL_error(L, "bytes must be greater than 0");
    }

    if (bytes_available <= 0)
    {
        lua_pushnil(L);
        return 1;
    }

    uint8_t address = 0x22;

    uint16_t length = bytes_available < bytes_requested
                          ? bytes_available
                          : bytes_requested;

    uint8_t *data = malloc(length);
    if (data == NULL)
    {
        error();
    }

    spi_write(FPGA, &address, 1, true);
    spi_read(FPGA, data, length, false);

    lua_pushlstring(L, (char *)data, length);
    free(data);

    return 1;
}

void lua_open_camera_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_camera_capture);
    lua_setfield(L, -2, "capture");

    lua_pushcfunction(L, lua_camera_read);
    lua_setfield(L, -2, "read");

    lua_setfield(L, -2, "camera");

    lua_pop(L, 1);
}