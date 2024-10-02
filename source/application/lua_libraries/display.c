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
#include "error_logging.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrfx_systick.h"
#include "spi.h"
#include "system_font.h"
#include "nrfx_log.h"

typedef struct colors_t
{
    const char *name;
    uint8_t initial_y : 4;
    uint8_t initial_cb : 3;
    uint8_t initial_cr : 3;
} colors_t;

static colors_t colors[16] = {
    {"VOID", 0, 4, 4},
    {"WHITE", 15, 4, 4},
    {"GREY", 7, 4, 4},
    {"RED", 5, 3, 6},
    {"PINK", 9, 3, 5},
    {"DARKBROWN", 2, 2, 5},
    {"BROWN", 4, 2, 5},
    {"ORANGE", 9, 2, 5},
    {"YELLOW", 13, 2, 4},
    {"DARKGREEN", 4, 4, 3},
    {"GREEN", 6, 2, 3},
    {"LIGHTGREEN", 10, 1, 3},
    {"NIGHTBLUE", 1, 5, 2},
    {"SEABLUE", 4, 5, 2},
    {"SKYBLUE", 8, 5, 2},
    {"CLOUDBLUE", 13, 4, 3},
};

static uint32_t utf8_decode(const char *string, size_t *index)
{
    uint32_t codepoint = 0;

    // If ASCII
    if (string[*index] < 0b10000000)
    {
        codepoint = string[*index] & 0b01111111;
        *index += 1;
    }
    else if ((string[*index] & 0b11100000) == 0b11000000)
    {
        codepoint = (string[*index] & 0b00011111) << 6 |
                    (string[*index + 1] & 0b00111111);
        *index += 2;
    }
    else if ((string[*index] & 0b11110000) == 0b11100000)
    {
        codepoint = (string[*index] & 0b00001111) << 12 |
                    (string[*index + 1] & 0b00111111) << 6 |
                    (string[*index + 2] & 0b00111111);
        *index += 3;
    }
    else if ((string[*index] & 0b11111000) == 0b11110000)
    {
        codepoint = (string[*index] & 0b00000111) << 18 |
                    (string[*index + 1] & 0b00111111) << 12 |
                    (string[*index + 2] & 0b00111111) << 6 |
                    (string[*index + 3] & 0b00111111);
        *index += 4;
    }
    else
    {
        // Invalid byte. Simply skip
        *index += 1;
    }

    return codepoint;
}

static void assign_color_to_palette(uint8_t palette_index,
                                    uint8_t y,
                                    uint8_t cb,
                                    uint8_t cr)
{
    uint8_t data[4] = {palette_index, y, cb, cr};

    spi_write(FPGA, 0x11, (uint8_t *)data, sizeof(data));
}

static int lua_display_assign_color(lua_State *L)
{
    uint8_t color_palette_index;

    for (uint8_t i = 0; i <= 16; i++)
    {
        if (i == 16)
        {
            luaL_error(L, "Invalid color name");
        }

        if (strcmp(luaL_checkstring(L, 1), colors[i].name) == 0)
        {
            color_palette_index = i;
            break;
        }
    }

    lua_Integer red = luaL_checkinteger(L, 2);
    lua_Integer green = luaL_checkinteger(L, 3);
    lua_Integer blue = luaL_checkinteger(L, 4);

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

    assign_color_to_palette(color_palette_index,
                            ((uint8_t)y) >> 4,
                            ((uint8_t)cb) >> 5,
                            ((uint8_t)cr) >> 5);

    return 0;
}

static int lua_display_assign_color_ycbcr(lua_State *L)
{
    uint8_t color_palette_index;

    for (uint8_t i = 0; i <= 16; i++)
    {
        if (i == 16)
        {
            luaL_error(L, "Invalid color name");
        }

        if (strcmp(luaL_checkstring(L, 1), colors[i].name) == 0)
        {
            color_palette_index = i;
            break;
        }
    }

    lua_Integer y = luaL_checkinteger(L, 2);
    lua_Integer cb = luaL_checkinteger(L, 3);
    lua_Integer cr = luaL_checkinteger(L, 4);

    if (y < 0 || y > 15)
    {
        luaL_error(L, "Y component must be between 0 and 15");
    }

    if (cb < 0 || cb > 7)
    {
        luaL_error(L, "Cb component must be between 0 and 7");
    }

    if (cr < 0 || cr > 7)
    {
        luaL_error(L, "Cr component must be between 0 and 7");
    }

    assign_color_to_palette(color_palette_index,
                            (uint8_t)y,
                            (uint8_t)cb,
                            (uint8_t)cr);

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

    uint8_t meta_data[8] = {(uint32_t)x_position >> 8,
                            (uint32_t)x_position,
                            (uint32_t)y_position >> 8,
                            (uint32_t)y_position,
                            (uint32_t)width >> 8,
                            (uint32_t)width,
                            (uint8_t)total_colors,
                            (uint8_t)palette_offset};

    uint8_t *payload = malloc(pixel_data_length + sizeof(meta_data));
    if (payload == NULL)
    {
        error();
    }
    memcpy(payload, meta_data, sizeof(meta_data));
    memcpy(payload + sizeof(meta_data), pixel_data, pixel_data_length);
    spi_write(FPGA,
              0x12,
              payload,
              pixel_data_length + sizeof(meta_data));
    free(payload);
}

static int lua_display_bitmap(lua_State *L)
{
    size_t pixel_data_length;
    const char *pixel_data = luaL_checklstring(L, 6, &pixel_data_length);

    draw_sprite(L,
                luaL_checkinteger(L, 1),
                luaL_checkinteger(L, 2),
                luaL_checkinteger(L, 3),
                luaL_checkinteger(L, 4),
                luaL_checkinteger(L, 5),
                (uint8_t *)pixel_data,
                pixel_data_length);

    return 0;
}

static int lua_display_text(lua_State *L)
{
    const char *string = luaL_checkstring(L, 1);
    lua_Integer x_position = luaL_checkinteger(L, 2);
    lua_Integer y_position = luaL_checkinteger(L, 3);
    lua_Integer color_palette_offset = 0;
    lua_Integer character_spacing = 4;
    // TODO justification options

    if (lua_istable(L, 4))
    {
        if (lua_getfield(L, 4, "color") != LUA_TNIL)
        {
            for (size_t i = 1; i <= 16; i++)
            {
                if (i == 16)
                {
                    luaL_error(L, "Invalid color name");
                }

                if (strcmp(luaL_checkstring(L, -1), colors[i].name) == 0)
                {
                    color_palette_offset = i - 1;
                    break;
                }
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 4, "spacing") != LUA_TNIL)
        {
            character_spacing = luaL_checkinteger(L, -1);
            lua_pop(L, 1);
        }
    }

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
                                    color_palette_offset,
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
    spi_write(FPGA, 0x14, NULL, 0);
    return 0;
}

static int lua_display_set_brightness(lua_State *L)
{
    uint8_t setting = 0;

    switch (luaL_checkinteger(L, 1))
    {
    case -2:
        setting = 0xC8 | 1;
        break;
    case -1:
        setting = 0xC8 | 2;
        break;
    case 0:
        setting = 0xC8 | 0;
        break;
    case 1:
        setting = 0xC8 | 3;
        break;
    case 2:
        setting = 0xC8 | 4;
        break;
    default:
        luaL_error(L, "level must be -2, -1, 0, 1, or 2");
        break;
    }

    spi_write(DISPLAY, 0x05, &setting, 1);

    return 0;
}

static int lua_display_write_register(lua_State *L)
{
    lua_Integer address = luaL_checkinteger(L, 1);
    lua_Integer value = luaL_checkinteger(L, 2);

    if (address < 0 || address > 0xFF)
    {
        luaL_error(L, "address must be a 8 bit unsigned number");
    }

    if (value < 0 || value > 0xFF)
    {
        luaL_error(L, "value must be a 8 bit unsigned number");
    }

    spi_write(DISPLAY, address, (uint8_t *)&value, 1);

    return 0;
}

static int lua_display_power_save(lua_State *L)
{
    if (!lua_isboolean(L, 1))
    {
        luaL_error(L, "value must be true or false");
    }

    uint8_t mode = lua_toboolean(L, 1) ? 0x92 : 0x93;

    spi_write(DISPLAY, 0x00, (uint8_t *)&mode, 1);

    return 0;
}

void lua_open_display_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_newtable(L);

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

    lua_pushcfunction(L, lua_display_power_save);
    lua_setfield(L, -2, "power_save");

    lua_pushcfunction(L, lua_display_set_brightness);
    lua_setfield(L, -2, "set_brightness");

    lua_pushcfunction(L, lua_display_write_register);
    lua_setfield(L, -2, "write_register");

    lua_setfield(L, -2, "display");

    lua_pop(L, 1);

    // Assign the initial colors
    for (uint8_t i = 0; i < 16; i++)
    {
        assign_color_to_palette(i,
                                colors[i].initial_y,
                                colors[i].initial_cb,
                                colors[i].initial_cr);
    }
}