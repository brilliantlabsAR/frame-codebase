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

static int lua_display_assign_color(lua_State *L)
{
    uint8_t address = 0x11;

    luaL_checkinteger(L, 1);
    luaL_checkinteger(L, 2);
    luaL_checkinteger(L, 3);

    lua_Number red = lua_tointeger(L, 1);
    lua_Number green = lua_tointeger(L, 2);
    lua_Number blue = lua_tointeger(L, 3);

    if (red < 0 || red > 255)
    {
        luaL_error(L, "red component must be between 0 and 255");
    }

    if (green < 0 || green > 255)
    {
        luaL_error(L, "green component must be between 0 and 255");
    }

    if (blue < 0 || blue > 255)
    {
        luaL_error(L, "blue component must be between 0 and 255");
    }

    // TODO convert RGB to Ycbcr
    uint8_t y = (uint8_t)red;
    uint8_t cb = (uint8_t)green;
    uint8_t cr = (uint8_t)blue;

    uint8_t data[3] = {y, cb, cr};

    spi_write(FPGA, &address, 1, true);
    spi_write(FPGA, (uint8_t *)data, sizeof(data), false);

    return 0;
}

static int lua_display_assign_color_ycbcr(lua_State *L)
{
    uint8_t address = 0x11;

    luaL_checkinteger(L, 1);
    luaL_checkinteger(L, 2);
    luaL_checkinteger(L, 3);

    lua_Number y = lua_tointeger(L, 1);
    lua_Number cb = lua_tointeger(L, 2);
    lua_Number cr = lua_tointeger(L, 3);

    // TODO figure out the scaling and range og Ycbcr
    if (y < 0 || y > 255)
    {
        luaL_error(L, "Y component must be between 0 and 255");
    }

    if (cb < 0 || cb > 255)
    {
        luaL_error(L, "Cb component must be between 0 and 255");
    }

    if (cr < 0 || cr > 255)
    {
        luaL_error(L, "Cr component must be between 0 and 255");
    }

    uint8_t data[3] = {(uint8_t)y, (uint8_t)cb, (uint8_t)cr};

    spi_write(FPGA, &address, 1, true);
    spi_write(FPGA, (uint8_t *)data, sizeof(data), false);

    return 0;
}

static int lua_display_sprite_draw(lua_State *L)
{
    uint8_t address = 0x12;

    luaL_checkinteger(L, 1);
    luaL_checkinteger(L, 2);
    luaL_checkinteger(L, 3);
    luaL_checkinteger(L, 4);
    luaL_checkinteger(L, 5);
    luaL_checkstring(L, 6);

    lua_Number x_position = lua_tointeger(L, 1) - 1;
    lua_Number y_position = lua_tointeger(L, 2) - 1;
    lua_Number width = lua_tointeger(L, 3);
    lua_Number colors = lua_tointeger(L, 4);
    lua_Number offset = lua_tointeger(L, 5);

    if (x_position < 0 || x_position > 639)
    {
        luaL_error(L, "cursor x position must be between 1 and 640 pixels");
    }

    if (y_position < 0 || y_position > 399)
    {
        luaL_error(L, "cursor y position must be between 1 and 400 pixels");
    }

    if (width < 1 || width > 640)
    {
        luaL_error(L, "sprite width must be between 1 and 640 pixels");
    }

    if (colors != 1 && colors != 4 && colors != 16)
    {
        luaL_error(L, "colors must be either 1, 4 or 16");
    }

    if (offset < 0 || offset > 15)
    {
        luaL_error(L, "offset must be between 0 and 15");
    }

    uint8_t meta_data[8] = {(uint32_t)x_position >> 8,
                            (uint32_t)x_position,
                            (uint32_t)y_position >> 8,
                            (uint32_t)y_position,
                            (uint32_t)width >> 8,
                            (uint32_t)width,
                            (uint8_t)colors,
                            (uint8_t)offset};

    size_t pixel_data_length;
    const char *pixel_data = lua_tolstring(L, 6, &pixel_data_length);

    spi_write(FPGA, &address, 1, true);
    spi_write(FPGA, (uint8_t *)meta_data, sizeof(meta_data), true);
    spi_write(FPGA, (uint8_t *)pixel_data, pixel_data_length, false);

    return 0;
}

static int lua_display_show(lua_State *L)
{
    uint8_t address = 0x14;
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

    lua_pushcfunction(L, lua_display_assign_color_ycbcr);
    lua_setfield(L, -2, "assign_color_ycbcr");

    lua_pushcfunction(L, lua_display_sprite_draw);
    lua_setfield(L, -2, "sprite_draw");

    lua_pushcfunction(L, lua_display_show);
    lua_setfield(L, -2, "show");

    lua_setfield(L, -2, "display");

    lua_pop(L, 1);
}