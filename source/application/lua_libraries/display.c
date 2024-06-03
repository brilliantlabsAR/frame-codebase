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

static int lua_display_assign_color(lua_State *L)
{
    lua_Integer pallet_index = luaL_checkinteger(L, 1) - 1;
    lua_Integer red = luaL_checkinteger(L, 2);
    lua_Integer green = luaL_checkinteger(L, 3);
    lua_Integer blue = luaL_checkinteger(L, 4);

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

    spi_write(FPGA, 0x11, (uint8_t *)data, sizeof(data));

    return 0;
}

static int lua_display_assign_color_ycbcr(lua_State *L)
{
    lua_Integer pallet_index = luaL_checkinteger(L, 1) - 1;
    lua_Integer y = luaL_checkinteger(L, 2);
    lua_Integer cb = luaL_checkinteger(L, 3);
    lua_Integer cr = luaL_checkinteger(L, 4);

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

    spi_write(FPGA, 0x11, (uint8_t *)data, sizeof(data));

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
    // TODO color options
    // TODO justification options
    // TODO character spacing

    const char *string = luaL_checkstring(L, 1);
    lua_Integer x_position = luaL_checkinteger(L, 2);
    lua_Integer y_position = luaL_checkinteger(L, 3);
    lua_Integer character_spacing = 4;

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

static void draw_line(uint32_t x_0, uint32_t y_0, uint32_t x_1, uint32_t y_1, uint32_t color) 
{
    uint8_t line_data[9] = {
        (uint32_t) x_0 >> 8,
        (uint32_t) x_0,
        (uint32_t) y_0 >> 8,
        (uint32_t) y_0,
        (uint32_t) x_1 >> 8,
        (uint32_t) x_1,
        (uint32_t) y_1 >> 8,
        (uint32_t) y_1,
        (uint8_t) color
    };

    spi_write(FPGA, 0x13, line_data, sizeof(line_data));
}

static int lua_display_line(lua_State *L)
{
    lua_Integer x_0 = luaL_checkinteger(L, 1);
    if (x_0 < 0 || x_0 > 639) {
        luaL_error(L, "x_0 must be in the range [0, 639]");
    }

    lua_Integer y_0 = luaL_checkinteger(L, 2);
    if (y_0 < 0 || y_0 > 399) {
        luaL_error(L, "y_0 must be in the range [0, 399]");
    }

    lua_Integer x_1 = luaL_checkinteger(L, 3);
    if (x_1 < 0 || x_1 > 639) {
        luaL_error(L, "x_1 must be in the range [0, 639]");
    }

    lua_Integer y_1 = luaL_checkinteger(L, 4);
    if (y_1 < 0 || y_1 > 399) {
        luaL_error(L, "y_1 must be in the range [0, 399]");
    }

    lua_Integer palette_offset = luaL_checkinteger(L, 5);
    if (palette_offset < 0 || palette_offset > 14) {
        luaL_error(L, "palette offset must be in the range [0, 14]");
    }

    draw_line(x_0, y_0, x_1, y_1, palette_offset);

    return 0;
}

static int lua_display_rectangle(lua_State *L)
{
    lua_Integer x_0 = luaL_checkinteger(L, 1);
    if (x_0 < 0 || x_0 > 639) {
        luaL_error(L, "x_0 must be in the range [0, 639]");
    }

    lua_Integer y_0 = luaL_checkinteger(L, 2);
    if (y_0 < 0 || y_0 > 399) {
        luaL_error(L, "y_0 must be in the range [0, 399]");
    }

    lua_Integer x_1 = luaL_checkinteger(L, 3);
    if (x_1 < 0 || x_1 > 639) {
        luaL_error(L, "x_1 must be in the range [0, 639]");
    }

    lua_Integer y_1 = luaL_checkinteger(L, 4);
    if (y_1 < 0 || y_1 > 399) {
        luaL_error(L, "y_1 must be in the range [0, 399]");
    }

    lua_Integer palette_offset = luaL_checkinteger(L, 5);
    if (palette_offset < 0 || palette_offset > 14) {
        luaL_error(L, "palette offset must be in the range [0, 14]");
    }

    draw_line(x_0, y_0, x_0, y_1, palette_offset);
    draw_line(x_0, y_0, x_1, y_0, palette_offset);
    draw_line(x_0, y_1, x_1, y_1, palette_offset);
    draw_line(x_1, y_0, x_1, y_1, palette_offset);

    return 0;
}

static void draw_arc(uint32_t x_centre, uint32_t y_centre, uint32_t radius, 
                        double theta_0, double theta_1, 
                        uint32_t number_of_segments, uint32_t palette_offset)
{
    uint32_t x_0, y_0, x_1, y_1;
    double angle = theta_0;
    double d_theta = (theta_1 - theta_0) / number_of_segments;

    x_1 = (uint32_t) round ((double)x_centre + (double)radius * cos(angle));
    y_1 = (uint32_t) round ((double)y_centre + (double)radius * sin(angle));

    for (uint8_t i = 1; i <= number_of_segments; i++) {
        x_0 = x_1; y_0 = y_1;
        angle = angle + d_theta;
        x_1 = (uint32_t) round ((double)x_centre + (double)radius * cos(angle));
        y_1 = (uint32_t) round ((double)y_centre + (double)radius * sin(angle));
        draw_line(x_0, y_0, x_1, y_1, palette_offset);
    }
}

static int lua_display_arc(lua_State *L)
{
    lua_Integer x_centre = luaL_checkinteger(L, 1);
    if (x_centre < 0 || x_centre > 399) {
        luaL_error(L, "x_centre must be in the range [0, 399]");
    }

    lua_Integer y_centre = luaL_checkinteger(L, 2);
    if (y_centre < 0 || y_centre > 639) {
        luaL_error(L, "y_centre must be in the range [0, 639]");
    }

    lua_Integer radius = luaL_checkinteger(L, 3);
    if (radius < 0 || radius > 639) {
        luaL_error(L, "radius must be in the range [0, 639]");
    }

    lua_Number theta_0 = luaL_checknumber(L, 4);
    if (theta_0 < 0 || theta_0 > 2*M_PI) {
        luaL_error(L, "theta_0 must be in the range [0, %d]", 2*M_PI);
    }

    lua_Number theta_1 = luaL_checknumber(L, 5);
    if (theta_1 < 0 || theta_1 > 2*M_PI) {
        luaL_error(L, "theta_1 must be in the range [0, %d]", 2*M_PI);
    }

    lua_Integer number_of_segments = luaL_checkinteger(L, 6);
    if (number_of_segments < 1 || number_of_segments > 16) {
        luaL_error(L, "number of segments must be in the range [1, 16]");
    }

    lua_Integer palette_offset = luaL_checkinteger(L, 7);
    if (palette_offset < 0 || palette_offset > 14) {
        luaL_error(L, "palette offset must be in the range [0, 14]");
    }

    draw_arc(x_centre, y_centre, radius, theta_0, theta_1, 
                number_of_segments, palette_offset);

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

static int lua_display_set_register(lua_State *L)
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

    lua_pushcfunction(L, lua_display_line);
    lua_setfield(L, -2, "line");

    lua_pushcfunction(L, lua_display_rectangle);
    lua_setfield(L, -2, "rectangle");

    lua_pushcfunction(L, lua_display_arc);
    lua_setfield(L, -2, "arc");

    lua_pushcfunction(L, lua_display_show);
    lua_setfield(L, -2, "show");

    lua_pushcfunction(L, lua_display_set_brightness);
    lua_setfield(L, -2, "set_brightness");

    lua_pushcfunction(L, lua_display_set_register);
    lua_setfield(L, -2, "set_register");

    lua_setfield(L, -2, "display");

    lua_pop(L, 1);
}