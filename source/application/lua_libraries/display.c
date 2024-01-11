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

#include <math.h>
#include "lauxlib.h"
#include "lua.h"
#include "spi.h"
#include "system_font.h"
#include "error_logging.h"

static uint32_t utf8_decode(const char *string, size_t *index)
{
    uint32_t codepoint = 0;

    // If ASCII
    if ((string[*index] & 0b10000000) == 0)
    {
        codepoint = string[*index] & 0b01111111;
        *index += 1;
    }
    // TODO others

    return codepoint;
}

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
    luaL_checkinteger(L, 4);

    lua_Integer pallet_index = lua_tointeger(L, 1) - 1;
    lua_Integer red = lua_tointeger(L, 2);
    lua_Integer green = lua_tointeger(L, 3);
    lua_Integer blue = lua_tointeger(L, 4);

    if (pallet_index < 0 || pallet_index > 15)
    {
        luaL_error(L, "pallet_index must be between 1 and 16");
    }

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

    double y = floor(0.299 * red + 0.587 * green + 0.114 * blue);
    double cb = floor(-0.169 * red - 0.331 * green + 0.5 * blue + 128);
    double cr = floor(0.5 * red - 0.419 * green - 0.081 * blue + 128);

    uint8_t data[4] = {(uint8_t)pallet_index,
                       (uint8_t)y,
                       (uint8_t)cb,
                       (uint8_t)cr};

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
    luaL_checkinteger(L, 4);

    lua_Integer pallet_index = lua_tointeger(L, 1) - 1;
    lua_Integer y = lua_tointeger(L, 2);
    lua_Integer cb = lua_tointeger(L, 3);
    lua_Integer cr = lua_tointeger(L, 4);

    if (pallet_index < 0 || pallet_index > 15)
    {
        luaL_error(L, "pallet_index must be between 1 and 16");
    }

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

    uint8_t data[4] = {(uint8_t)pallet_index,
                       (uint8_t)y,
                       (uint8_t)cb,
                       (uint8_t)cr};

    spi_write(FPGA, &address, 1, true);
    spi_write(FPGA, (uint8_t *)data, sizeof(data), false);

    return 0;
}

static void draw_sprite(lua_State *L,
                        lua_Integer x_position,
                        lua_Integer y_position,
                        lua_Integer width,
                        lua_Integer total_colors,
                        lua_Integer palette_offset,
                        const uint8_t *pixel_data,
                        size_t pixel_data_length)
{
    if (x_position < 1 || x_position > 640)
    {
        luaL_error(L, "x_position must be between 1 and 640 pixels");
    }

    if (y_position < 1 || y_position > 400)
    {
        luaL_error(L, "y_position must be between 1 and 400 pixels");
    }

    if (width < 1 || width > 640)
    {
        luaL_error(L, "width must be between 1 and 640 pixels");
    }

    if (total_colors != 2 && total_colors != 4 && total_colors != 16)
    {
        luaL_error(L, "total_colors must be either 2, 4 or 16");
    }

    if (palette_offset < 0 || palette_offset > 15)
    {
        luaL_error(L, "palette_offset must be between 0 and 15");
    }

    // Remove Lua 1 based offset before sending
    x_position--;
    y_position--;

    uint8_t address = 0x12;

    uint8_t meta_data[8] = {(uint32_t)x_position >> 8,
                            (uint32_t)x_position,
                            (uint32_t)y_position >> 8,
                            (uint32_t)y_position,
                            (uint32_t)width >> 8,
                            (uint32_t)width,
                            (uint8_t)total_colors,
                            (uint8_t)palette_offset};

    LOG("Printing %llu color sprite at (%llu, %llu) with %llu width ",
        total_colors,
        x_position,
        y_position,
        width);

    spi_write(FPGA, &address, 1, true);
    spi_write(FPGA, (uint8_t *)meta_data, sizeof(meta_data), true);
    spi_write(FPGA, (uint8_t *)pixel_data, pixel_data_length, false);
}

static int lua_display_bitmap(lua_State *L)
{
    luaL_checkinteger(L, 1);
    luaL_checkinteger(L, 2);
    luaL_checkinteger(L, 3);
    luaL_checkinteger(L, 4);
    luaL_checkinteger(L, 5);
    luaL_checkstring(L, 6);

    size_t pixel_data_length;
    const char *pixel_data = lua_tolstring(L, 6, &pixel_data_length);

    draw_sprite(L,
                lua_tointeger(L, 1),
                lua_tointeger(L, 2),
                lua_tointeger(L, 3),
                lua_tointeger(L, 4),
                lua_tointeger(L, 5),
                (uint8_t *)pixel_data,
                pixel_data_length);

    return 0;
}

static int lua_display_text(lua_State *L)
{
    luaL_checkstring(L, 1);
    luaL_checkinteger(L, 2);
    luaL_checkinteger(L, 3);
    // TODO color options
    // TODO justification options
    // TODO character spacing

    const char *string = lua_tostring(L, 1);
    lua_Integer x_position = lua_tointeger(L, 2);
    lua_Integer y_position = lua_tointeger(L, 3);
    lua_Integer character_spacing = 2;

    for (size_t index = 0; index < strlen(string);)
    {
        uint32_t codepoint = utf8_decode(string, &index);

        if (codepoint != 0)
        {
            // Search for the codepoint in the font table
            for (size_t entry = 0;
                 entry < sizeof(sprite_metadata) / sizeof(sprite_metadata_t);
                 entry++)
            {
                if (codepoint == sprite_metadata[entry].utf8_codepoint)
                {
                    // Check if the glyph can fit on the screen
                    if (x_position + sprite_metadata[entry].width <= 640 &&
                        y_position + sprite_metadata[entry].height <= 400)
                    {
                        size_t data_offset = sprite_metadata[entry].data_offset;

                        size_t data_length = sprite_metadata[entry].width *
                                             sprite_metadata[entry].height;

                        switch (sprite_metadata[entry].colors)
                        {
                        case SPRITE_16_COLORS:
                            break;
                        case SPRITE_4_COLORS:
                            data_length = (size_t)ceil(data_length / 2.0);
                            break;
                        case SPRITE_2_COLORS:
                            data_length = (size_t)ceil(data_length / 8.0);
                            break;
                        }

                        draw_sprite(L,
                                    x_position,
                                    y_position,
                                    sprite_metadata[entry].width,
                                    sprite_metadata[entry].colors,
                                    0, // TODO
                                    sprite_data + data_offset,
                                    data_length);

                        x_position += sprite_metadata[entry].width;
                        x_position += character_spacing;
                    }
                }
            }
        }
    }

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

    lua_pushcfunction(L, lua_display_bitmap);
    lua_setfield(L, -2, "bitmap");

    lua_pushcfunction(L, lua_display_text);
    lua_setfield(L, -2, "text");

    lua_pushcfunction(L, lua_display_show);
    lua_setfield(L, -2, "show");

    lua_setfield(L, -2, "display");

    lua_pop(L, 1);
}