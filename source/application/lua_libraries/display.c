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

#include "lauxlib.h"
#include "lua.h"
#include "spi.h"

static int lua_display_clear(lua_State *L)
{
    uint8_t address = 0x10;
    spi_write(FPGA, &address, 1, false);
    return 0;
}

static int lua_display_assign_color(lua_State *L) {}
static int lua_display_move_cursor(lua_State *L) {}
static int lua_display_sprite_draw_width(lua_State *L) {}
static int lua_display_sprite_color_mode(lua_State *L) {}
static int lua_display_sprite_pallet_offset(lua_State *L) {}

static int lua_display_sprite_draw(lua_State *L)
{
    uint8_t address = 0x16;

    luaL_checkstring(L, 1);
    size_t length;
    const char *data = lua_tolstring(L, 1, &length);

    spi_write(FPGA, &address, 1, true);
    spi_write(FPGA, (uint8_t *)data, length, false);

    return 0;
}

static int lua_display_show(lua_State *L)
{
    uint8_t address = 0x19;
    spi_write(FPGA, &address, 1, false);
    return 0;
}

void lua_open_display_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_display_clear);
    lua_setfield(L, -2, "clear");

    lua_pushcfunction(L, lua_display_assign_color);
    lua_setfield(L, -2, "assign_color");

    lua_pushcfunction(L, lua_display_move_cursor);
    lua_setfield(L, -2, "move_cursor");

    lua_pushcfunction(L, lua_display_sprite_draw_width);
    lua_setfield(L, -2, "sprite_draw_width");

    lua_pushcfunction(L, lua_display_sprite_color_mode);
    lua_setfield(L, -2, "sprite_color_mode");

    lua_pushcfunction(L, lua_display_sprite_pallet_offset);
    lua_setfield(L, -2, "sprite_pallet_offset");

    lua_pushcfunction(L, lua_display_sprite_draw);
    lua_setfield(L, -2, "sprite_draw");

    lua_pushcfunction(L, lua_display_show);
    lua_setfield(L, -2, "show");

    lua_setfield(L, -2, "display");

    lua_pop(L, 1);
}