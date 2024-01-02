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
#include "lauxlib.h"
#include "spi.h"
#include "nrfx_systick.h"

static uint32_t camera_bytes_available = 0;

static int lua_capture(lua_State *L) {
    uint8_t txbuf = 0x20;
    spi_write(FPGA, &txbuf, 1, false);
    // TODO: change this based on resolution / config
    camera_bytes_available = 200*200;
    lua_pushinteger(L, camera_bytes_available);
    return 1;
}

static int lua_read(lua_State *L) {
    luaL_checkinteger(L, 1);
    lua_Integer num_bytes = lua_tointeger(L, 1);

    uint8_t txbuf = 0x22;
    uint8_t rxbuf[128];
    spi_write(FPGA, &txbuf, 1, true);
    spi_read(FPGA, &rxbuf[0], num_bytes, false);

    lua_pushlstring(L, (char *)rxbuf, num_bytes);
    LOG("%d", strlen((char *)rxbuf));
    return 1;
}

void lua_open_camera_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_capture);
    lua_setfield(L, -2, "capture");

    lua_pushcfunction(L, lua_read);
    lua_setfield(L, -2, "read");

    lua_setfield(L, -2, "camera");

    lua_pop(L, 1);
}