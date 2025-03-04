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
#include <stdbool.h>
#include <stdint.h>
#include "error_logging.h"
#include "i2c.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrfx_systick.h"
#include "spi.h"
#include "nrfx_log.h"

static bool camera_is_asleep = false;

typedef enum camera_metering_mode
{
    SPOT,
    CENTER_WEIGHTED,
    AVERAGE
} camera_metering_mode_t;

static struct camera_auto_last_values
{
    double shutter;
    double analog_gain;
    double red_gain;
    double green_gain;
    double blue_gain;
} last = {
    .shutter = 4096.0f,
    .analog_gain = 1.0f,
    .red_gain = 121.6f,
    .green_gain = 64.0f,
    .blue_gain = 140.8f,
};

static struct camera_capture_settings
{
    uint16_t resolution;
    uint8_t quality_factor;
} capture_settings;

static size_t header_bytes_sent_out;
static size_t data_bytes_remaining;
static size_t data_bytes_sent_out;
static size_t footer_bytes_sent_out;

static int lua_camera_capture(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    uint16_t resolution = 512;

    if (lua_getfield(L, 1, "resolution") != LUA_TNIL)
    {
        resolution = luaL_checkinteger(L, -1);

        if (resolution < 100 || resolution > 720 || resolution % 2 != 0)
        {
            luaL_error(L, "resolution value must be a multiple of 2 between 100 and 720");
        }
    }

    int16_t pan = 0;

    if (lua_getfield(L, 1, "pan") != LUA_TNIL)
    {
        pan = luaL_checkinteger(L, -1) * 2;

        if (pan < -280 || pan > 280)
        {
            luaL_error(L, "pan value must be value between -140 and 140");
        }
    }

    uint8_t quality_level = 6;

    if (lua_getfield(L, 1, "quality") != LUA_TNIL)
    {
        const char *string = luaL_checkstring(L, -1);

        if (strcmp(string, "VERY_HIGH") == 0)
        {
            if (resolution <= 256)
            {
                quality_level = 7;
            }
            else if (resolution <= 512)
            {
                quality_level = 6;
            }
            else
            {
                quality_level = 5;
            }
        }
        else if (strcmp(string, "HIGH") == 0)
        {
            if (resolution <= 256)
            {
                quality_level = 6;
            }
            else if (resolution <= 512)
            {
                quality_level = 5;
            }
            else
            {
                quality_level = 4;
            }
        }
        else if (strcmp(string, "MEDIUM") == 0)
        {
            if (resolution <= 256)
            {
                quality_level = 5;
            }
            else if (resolution <= 512)
            {
                quality_level = 4;
            }
            else
            {
                quality_level = 3;
            }
        }
        else if (strcmp(string, "LOW") == 0)
        {
            if (resolution <= 256)
            {
                quality_level = 4;
            }
            else if (resolution <= 512)
            {
                quality_level = 3;
            }
            else
            {
                quality_level = 2;
            }
        }
        else if (strcmp(string, "VERY_LOW") == 0)
        {
            if (resolution <= 256)
            {
                quality_level = 3;
            }
            else if (resolution <= 512)
            {
                quality_level = 2;
            }
            else
            {
                quality_level = 1;
            }
        }
        else
        {
            luaL_error(L, "quality must be either VERY_HIGH, HIGH, MEDIUM, LOW or VERY_LOW");
        }
    }

    header_bytes_sent_out = 0;
    data_bytes_remaining = 0;
    data_bytes_sent_out = 0;
    footer_bytes_sent_out = 0;

    // Apply resolution
    capture_settings.resolution = resolution;
    uint8_t resolution_bytes[2] = {(uint8_t)(resolution >> 8), (uint8_t)(resolution & 0xFF)};
    spi_write(FPGA, 0x23, resolution_bytes, sizeof(resolution_bytes));

    // Apply pan
    // Normalize pan to center of sensor with correct offset for 720 native resolution
    pan += (1280 / 2) - (720 / 2);
    check_error(i2c_write(CAMERA, 0x3810, 0xFF, pan >> 8).fail);
    check_error(i2c_write(CAMERA, 0x3811, 0xFF, pan).fail);

    // Apply quality
    // These should match the indexed tables in quant_tables.sv
    switch (quality_level)
    {
    case 7:
        capture_settings.quality_factor = 60;
        break;
    case 6:
        capture_settings.quality_factor = 50;
        break;
    case 5:
        capture_settings.quality_factor = 40;
        break;
    case 4:
        capture_settings.quality_factor = 35;
        break;
    case 3:
        capture_settings.quality_factor = 30;
        break;
    case 2:
        capture_settings.quality_factor = 25;
        break;
    case 1:
        capture_settings.quality_factor = 20;
        break;
    case 0:
        capture_settings.quality_factor = 15;
        break;
    }

    spi_write(FPGA, 0x26, &quality_level, sizeof(quality_level));

    // Start capture
    spi_write(FPGA, 0x20, NULL, 0);

    return 0;
}

static int lua_camera_image_ready(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    uint8_t data[2];

    spi_read(FPGA, 0x30, (uint8_t *)data, sizeof(data));

    if (data[0] != 0)
    {
        spi_read(FPGA, 0x31, (uint8_t *)data, sizeof(data));

        data_bytes_remaining = (size_t)data[1] << 8 | (size_t)data[0];

        lua_pushboolean(L, true);
        return 1;
    }

    lua_pushboolean(L, false);
    return 1;
}

static int lua_camera_read(lua_State *L)
{
    lua_Integer bytes_requested = luaL_checkinteger(L, 1);

    if (bytes_requested <= 0)
    {
        luaL_error(L, "bytes must be greater than 0");
    }

    size_t remaining = bytes_requested;

    uint8_t *payload = malloc(bytes_requested);

    if (payload == NULL)
    {
        luaL_error(L, "bytes requested is too large");
    }

    uint8_t header[] = {
        0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46,
        0x49, 0x46, 0x00, 0x01, 0x02, 0x00, 0x00, 0x64,
        0x00, 0x64, 0x00, 0x00, 0xff, 0xdb, 0x00, 0x43,
        0x00, 0x10, 0x0b, 0x0c, 0x0e, 0x0c, 0x0a, 0x10,
        0x0e, 0x0d, 0x0e, 0x12, 0x11, 0x10, 0x13, 0x18,
        0x28, 0x1a, 0x18, 0x16, 0x16, 0x18, 0x31, 0x23,
        0x25, 0x1d, 0x28, 0x3a, 0x33, 0x3d, 0x3c, 0x39,
        0x33, 0x38, 0x37, 0x40, 0x48, 0x5c, 0x4e, 0x40,
        0x44, 0x57, 0x45, 0x37, 0x38, 0x50, 0x6d, 0x51,
        0x57, 0x5f, 0x62, 0x67, 0x68, 0x67, 0x3e, 0x4d,
        0x71, 0x79, 0x70, 0x64, 0x78, 0x5c, 0x65, 0x67,
        0x63, 0xff, 0xdb, 0x00, 0x43, 0x01, 0x11, 0x12,
        0x12, 0x18, 0x15, 0x18, 0x2f, 0x1a, 0x1a, 0x2f,
        0x63, 0x42, 0x38, 0x42, 0x63, 0x63, 0x63, 0x63,
        0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
        0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
        0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
        0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
        0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
        0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0xff, 0xc0,
        0x00, 0x11, 0x08, 0x00, 0x00, 0x00, 0x00, 0x03,
        0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11,
        0x01, 0xff, 0xc4, 0x00, 0x1f, 0x00, 0x00, 0x01,
        0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
        0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
        0x0a, 0x0b, 0xff, 0xc4, 0x00, 0x1f, 0x01, 0x00,
        0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0a, 0x0b, 0xff, 0xc4, 0x00, 0xb5, 0x10,
        0x00, 0x02, 0x01, 0x03, 0x03, 0x02, 0x04, 0x03,
        0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7d,
        0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
        0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
        0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
        0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
        0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16,
        0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
        0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
        0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
        0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
        0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
        0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
        0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
        0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
        0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
        0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
        0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
        0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4,
        0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
        0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
        0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
        0xf9, 0xfa, 0xff, 0xc4, 0x00, 0xb5, 0x11, 0x00,
        0x02, 0x01, 0x02, 0x04, 0x04, 0x03, 0x04, 0x07,
        0x05, 0x04, 0x04, 0x00, 0x01, 0x02, 0x77, 0x00,
        0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21, 0x31,
        0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71, 0x13,
        0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91, 0xa1,
        0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0, 0x15,
        0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34, 0xe1,
        0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26, 0x27,
        0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38, 0x39,
        0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
        0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
        0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
        0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
        0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88,
        0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
        0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6,
        0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5,
        0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4,
        0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3,
        0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe2,
        0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
        0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9,
        0xfa, 0xff, 0xda, 0x00, 0x0c, 0x03, 0x01, 0x00,
        0x02, 0x11, 0x03, 0x11, 0x00, 0x3f, 0x00};

    // Append JPEG header data
    if (header_bytes_sent_out < sizeof(header))
    {
        // Generate header data
        float scale;

        if (capture_settings.quality_factor < 50)
        {
            scale = 5000 / capture_settings.quality_factor;
        }
        else
        {
            scale = 200 - 2 * capture_settings.quality_factor;
        }

        for (int i = 25; i <= 88; i++)
        {
            float t = (scale * header[i] + 50) / 100;

            if (t < 1)
            {
                t = 1;
            }

            else if (t > 255)
            {
                t = 255;
            }

            header[i] = (uint8_t)t;
        }

        for (int i = 94; i <= 157; i++)
        {
            float t = (scale * header[i] + 50) / 100;

            if (t < 1)
            {
                t = 1;
            }

            else if (t > 255)
            {
                t = 255;
            }

            header[i] = (uint8_t)t;
        }

        header[163] = (capture_settings.resolution >> 8) & 0xff;
        header[164] = capture_settings.resolution & 0xff;
        header[165] = (capture_settings.resolution >> 8) & 0xff;
        header[166] = capture_settings.resolution & 0xff;

        size_t length =
            sizeof(header) - header_bytes_sent_out < bytes_requested
                ? sizeof(header) - header_bytes_sent_out
                : bytes_requested;

        memcpy(payload, header + header_bytes_sent_out, length);

        header_bytes_sent_out += length;
        remaining -= length;
    }

    // Append image data
    else
    {
        if (data_bytes_remaining > 0)
        {
            if (remaining > 0)
            {
                size_t length = remaining < data_bytes_remaining
                                    ? remaining
                                    : data_bytes_remaining;

                spi_read(FPGA,
                         0x22,
                         payload + bytes_requested - remaining,
                         length);

                remaining -= length;
                data_bytes_remaining -= length;
            }
        }

        // Append footer
        else
        {
            if (remaining > 0 && footer_bytes_sent_out == 0)
            {
                payload[bytes_requested - remaining] = 0xFF;
                footer_bytes_sent_out++;
                remaining--;
            }

            if (remaining > 0 && footer_bytes_sent_out == 1)
            {
                payload[bytes_requested - remaining] = 0xD9;
                footer_bytes_sent_out++;
                remaining--;
            }
        }
    }

    // Return nil if nothing was written to payload
    if (remaining == bytes_requested)
    {
        lua_pushnil(L);
    }

    // Otherwise return payload
    else
    {
        lua_pushlstring(L, (char *)payload, bytes_requested - remaining);
    }

    free(payload);
    return 1;
}

static int lua_camera_read_raw(lua_State *L)
{
    lua_Integer bytes_requested = luaL_checkinteger(L, 1);
    if (bytes_requested <= 0)
    {
        luaL_error(L, "bytes must be greater than 0");
    }

    size_t remaining = bytes_requested;

    uint8_t *payload = malloc(bytes_requested);
    if (payload == NULL)
    {
        luaL_error(L, "bytes requested is too large");
    }

    // Append image data
    if (data_bytes_remaining > 0)
    {
        if (remaining > 0)
        {
            size_t length = remaining < data_bytes_remaining
                                ? remaining
                                : data_bytes_remaining;

            spi_read(FPGA,
                     0x22,
                     payload + bytes_requested - remaining,
                     length);

            remaining -= length;
            data_bytes_remaining -= length;
        }
    }

    // Append footer
    else
    {
        if (remaining > 0 && footer_bytes_sent_out == 0)
        {
            payload[bytes_requested - remaining] = 0xFF;
            footer_bytes_sent_out++;
            remaining--;
        }

        if (remaining > 0 && footer_bytes_sent_out == 1)
        {
            payload[bytes_requested - remaining] = 0xD9;
            footer_bytes_sent_out++;
            remaining--;
        }
    }

    // Return nil if nothing was written to payload
    if (remaining == bytes_requested)
    {
        lua_pushnil(L);
    }

    // Otherwise return payload
    else
    {
        lua_pushlstring(L, (char *)payload, bytes_requested - remaining);
    }

    free(payload);
    return 1;
}

static int lua_camera_auto(lua_State *L)
{
    if (camera_is_asleep)
    {
        return 0;
    }

    // Default auto exposure settings
    camera_metering_mode_t metering = AVERAGE;
    double target_exposure = 0.18;
    double exposure_speed = 0.50;
    double shutter_limit = 8192.0;
    double analog_gain_limit = 16.0;
    double rgb_gain_limit = 141.0;

    // Default white balance settings
    double white_balance_speed = 0.5;
    double brightness_constant = 4166400.0;
    double white_balance_min_activation = 50;
    double white_balance_max_activation = 200;

    // Allow user to over-ride these if desired
    if (lua_istable(L, 1))
    {
        if (lua_getfield(L, 1, "metering") != LUA_TNIL)
        {
            if (strcmp(luaL_checkstring(L, -1), "SPOT") == 0)
            {
                metering = SPOT;
            }

            else if (strcmp(luaL_checkstring(L, -1), "CENTER_WEIGHTED") == 0)
            {
                metering = CENTER_WEIGHTED;
            }

            else if (strcmp(luaL_checkstring(L, -1), "AVERAGE") == 0)
            {
                metering = AVERAGE;
            }

            else
            {
                luaL_error(L, "metering must be SPOT, CENTER_WEIGHTED or AVERAGE");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "exposure") != LUA_TNIL)
        {
            target_exposure = luaL_checknumber(L, -1);
            if (target_exposure < 0.0 || target_exposure > 1.0)
            {
                luaL_error(L, "exposure must be between 0 and 1");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "exposure_speed") != LUA_TNIL)
        {
            exposure_speed = luaL_checknumber(L, -1);
            if (exposure_speed < 0.0 || exposure_speed > 1.0)
            {
                luaL_error(L, "exposure_speed must be between 0 and 1");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "shutter_limit") != LUA_TNIL)
        {
            shutter_limit = luaL_checknumber(L, -1);
            if (shutter_limit < 4.0 || shutter_limit > 16383.0)
            {
                luaL_error(L, "shutter_limit must be between 4 and 16383");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "analog_gain_limit") != LUA_TNIL)
        {
            analog_gain_limit = luaL_checknumber(L, -1);
            if (analog_gain_limit < 1.0 || analog_gain_limit > 248.0)
            {
                luaL_error(L, "analog_gain_limit must be between 1 and 248");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "white_balance_speed") != LUA_TNIL)
        {
            white_balance_speed = luaL_checknumber(L, -1);
            if (white_balance_speed < 0.0 || white_balance_speed > 1.0)
            {
                luaL_error(L, "white_balance_speed must be between 0 and 1");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "rgb_gain_limit") != LUA_TNIL)
        {
            rgb_gain_limit = luaL_checknumber(L, -1);
            if (rgb_gain_limit < 0.0 || rgb_gain_limit > 1023.0)
            {
                luaL_error(L, "rgb_gain_limit must be between 0 and 1023");
            }

            lua_pop(L, 1);
        }
    }

    // Get current brightness from FPGA
    volatile uint8_t metering_data[6];
    spi_read(FPGA, 0x25, (uint8_t *)metering_data, sizeof(metering_data));

    double spot_r = metering_data[0] / 255.0f;
    double spot_g = metering_data[1] / 255.0f;
    double spot_b = metering_data[2] / 255.0f;
    double matrix_r = metering_data[3] / 255.0f;
    double matrix_g = metering_data[4] / 255.0f;
    double matrix_b = metering_data[5] / 255.0f;

    if (spot_r == 0.0) {
        spot_r = 0.0001;
    }
    if (spot_g == 0.0) {
        spot_g = 0.0001;
    }
    if (spot_b == 0.0) {
        spot_b = 0.0001;
    }
    if (matrix_r == 0.0) {
        matrix_r = 0.0001;
    }
    if (matrix_g == 0.0) {
        matrix_g = 0.0001;
    }
    if (matrix_b == 0.0) {
        matrix_b = 0.0001;
    }

    double spot_average = (spot_r + spot_g + spot_b) / 3.0;
    double matrix_average = (matrix_r + matrix_g + matrix_b) / 3.0;
    double center_weighted_average = (spot_average +
                                      spot_average +
                                      matrix_average) /
                                     3.0;

    // Auto exposure based on metering mode
    double error;

    switch (metering)
    {
    case SPOT:
        error = exposure_speed * ((target_exposure / spot_average) - 1) + 1;
        break;

    case CENTER_WEIGHTED:
        error = exposure_speed * ((target_exposure / center_weighted_average) - 1) + 1;
        break;

    case AVERAGE:
        error = exposure_speed * ((target_exposure / matrix_average) - 1) + 1;
        break;
    }

    if (error > 1)
    {
        double shutter = last.shutter;

        last.shutter *= error;

        if (last.shutter > shutter_limit)
        {
            last.shutter = shutter_limit;
        }

        error *= shutter / last.shutter;

        if (error > 1)
        {
            last.analog_gain *= error;

            if (last.analog_gain > analog_gain_limit)
            {
                last.analog_gain = analog_gain_limit;
            }
        }
    }
    else
    {
        double analog_gain = last.analog_gain;

        last.analog_gain *= error;

        if (last.analog_gain < 1.0)
        {
            last.analog_gain = 1.0;
        }

        error *= analog_gain / last.analog_gain;

        if (error < 1)
        {
            last.shutter *= error;

            if (last.shutter < 4.0)
            {
                last.shutter = 4.0;
            }
        }
    }

    uint16_t shutter = (uint16_t)rint(last.shutter);
    uint8_t analog_gain = (uint8_t)rint(last.analog_gain);

    // If shutter is longer than frame length (VTS register)
    if (shutter > 0x32A)
    {
        check_error(i2c_write(CAMERA, 0x380E, 0xFF, shutter >> 8).fail);
        check_error(i2c_write(CAMERA, 0x380F, 0xFF, shutter).fail);
    }
    else
    {
        check_error(i2c_write(CAMERA, 0x380E, 0xFF, 0x03).fail);
        check_error(i2c_write(CAMERA, 0x380F, 0xFF, 0x22).fail);
    }

    check_error(i2c_write(CAMERA, 0x3500, 0x03, shutter >> 12).fail);
    check_error(i2c_write(CAMERA, 0x3501, 0xFF, shutter >> 4).fail);
    check_error(i2c_write(CAMERA, 0x3502, 0xF0, shutter << 4).fail);
    check_error(i2c_write(CAMERA, 0x350B, 0xFF, analog_gain).fail);

    // Auto white balance based on full scene matrix
    double max_rgb = matrix_r / last.red_gain > matrix_g / last.green_gain
                         ? (matrix_r / last.red_gain > matrix_b / last.blue_gain
                                ? matrix_r / last.red_gain
                                : matrix_b / last.blue_gain)
                         : (matrix_g / last.green_gain > matrix_b / last.blue_gain
                                ? matrix_g / last.green_gain
                                : matrix_b / last.blue_gain);

    double red_gain = max_rgb / matrix_r * last.red_gain;
    double green_gain = max_rgb / matrix_g * last.green_gain;
    double blue_gain = max_rgb / matrix_b * last.blue_gain;
    double scene_brightness = brightness_constant * matrix_average /
                              (last.shutter * last.analog_gain);
    double blending_factor = (scene_brightness - white_balance_min_activation) /
                             (white_balance_max_activation -
                              white_balance_min_activation);
    if (blending_factor > 1.0)
    {
        blending_factor = 1.0;
    }
    if (blending_factor < 0.0)
    {
        blending_factor = 0.0;
    }

    last.red_gain = blending_factor * white_balance_speed *
                        (red_gain - last.red_gain) +
                    last.red_gain;

    last.green_gain = blending_factor * white_balance_speed *
                          (green_gain - last.green_gain) +
                      last.green_gain;

    last.blue_gain = blending_factor * white_balance_speed *
                         (blue_gain - last.blue_gain) +
                     last.blue_gain;

    double max_rgb_gain = last.red_gain > last.green_gain
                            ? (last.red_gain > last.blue_gain
                                ? last.red_gain
                                : last.blue_gain)
                            : (last.green_gain > last.blue_gain
                                ? last.green_gain
                                : last.blue_gain);

    // Scale per-channel gains so the largest channel is at most rgb_gain_limit
    if (max_rgb_gain > rgb_gain_limit)
    {
        double scale_factor = rgb_gain_limit / max_rgb_gain;
        last.red_gain *= scale_factor;
        last.green_gain *= scale_factor;
        last.blue_gain *= scale_factor;
    }

    if (last.red_gain > 1023.0)
    {
        last.red_gain = 1023.0;
    }
    if (last.red_gain <= 0.0)
    {
        last.red_gain = 0.0001;
    }
    if (last.green_gain > 1023.0)
    {
        last.green_gain = 1023.0;
    }
    if (last.green_gain <= 0.0)
    {
        last.green_gain = 0.0001;
    }
    if (last.blue_gain > 1023.0)
    {
        last.blue_gain = 1023.0;
    }
    if (last.blue_gain <= 0.0)
    {
        last.blue_gain = 0.0001;
    }

    uint16_t red_gain_uint16 = (uint16_t)(last.red_gain);
    uint16_t green_gain_uint16 = (uint16_t)(last.green_gain);
    uint16_t blue_gain_uint16 = (uint16_t)(last.blue_gain);

    check_error(i2c_write(CAMERA, 0x5180, 0x03, red_gain_uint16 >> 8).fail);
    check_error(i2c_write(CAMERA, 0x5181, 0xFF, red_gain_uint16).fail);
    check_error(i2c_write(CAMERA, 0x5182, 0x03, green_gain_uint16 >> 8).fail);
    check_error(i2c_write(CAMERA, 0x5183, 0xFF, green_gain_uint16).fail);
    check_error(i2c_write(CAMERA, 0x5184, 0x03, blue_gain_uint16 >> 8).fail);
    check_error(i2c_write(CAMERA, 0x5185, 0xFF, blue_gain_uint16).fail);

    lua_newtable(L);

    {
        lua_newtable(L);

        {
            lua_newtable(L);

            lua_pushnumber(L, spot_r);
            lua_setfield(L, -2, "r");

            lua_pushnumber(L, spot_g);
            lua_setfield(L, -2, "g");

            lua_pushnumber(L, spot_b);
            lua_setfield(L, -2, "b");

            lua_pushnumber(L, spot_average);
            lua_setfield(L, -2, "average");

            lua_setfield(L, -2, "spot");
        }

        {
            lua_newtable(L);

            lua_pushnumber(L, matrix_r);
            lua_setfield(L, -2, "r");

            lua_pushnumber(L, matrix_g);
            lua_setfield(L, -2, "g");

            lua_pushnumber(L, matrix_b);
            lua_setfield(L, -2, "b");

            lua_pushnumber(L, matrix_average);
            lua_setfield(L, -2, "average");

            lua_setfield(L, -2, "matrix");
        }

        lua_pushnumber(L, center_weighted_average);
        lua_setfield(L, -2, "center_weighted_average");

        lua_pushnumber(L, scene_brightness);
        lua_setfield(L, -2, "scene");

        lua_setfield(L, -2, "brightness");
    }

    lua_pushnumber(L, error);
    lua_setfield(L, -2, "error");

    lua_pushnumber(L, last.shutter);
    lua_setfield(L, -2, "shutter");

    lua_pushnumber(L, last.analog_gain);
    lua_setfield(L, -2, "analog_gain");

    lua_pushnumber(L, last.red_gain);
    lua_setfield(L, -2, "red_gain");

    lua_pushnumber(L, last.green_gain);
    lua_setfield(L, -2, "green_gain");

    lua_pushnumber(L, last.blue_gain);
    lua_setfield(L, -2, "blue_gain");

    return 1;
}

static int lua_camera_power_save(lua_State *L)
{
    if (!lua_isboolean(L, 1))
    {
        luaL_error(L, "value must be true or false");
    }

    if (lua_toboolean(L, 1))
    {
        camera_is_asleep = true;
        check_error(i2c_write(CAMERA, 0x0100, 0xFF, 0x00).fail);
        check_error(i2c_write(CAMERA, 0x3658, 0xFF, 0xFF).fail);
        check_error(i2c_write(CAMERA, 0x3659, 0xFF, 0xFF).fail);
        check_error(i2c_write(CAMERA, 0x365A, 0xFF, 0xFF).fail);
        check_error(i2c_write(CAMERA, 0x308B, 0xFF, 0x01).fail);
        spi_write(FPGA, 0x28, (uint8_t *)"\x01", 1);
    }
    else
    {
        check_error(i2c_write(CAMERA, 0x3658, 0xFF, 0x22).fail);
        check_error(i2c_write(CAMERA, 0x3659, 0xFF, 0x22).fail);
        check_error(i2c_write(CAMERA, 0x365A, 0xFF, 0x02).fail);
        check_error(i2c_write(CAMERA, 0x308B, 0xFF, 0x00).fail);
        check_error(i2c_write(CAMERA, 0x0100, 0xFF, 0x01).fail);
        spi_write(FPGA, 0x28, (uint8_t *)"\x00", 1);
        camera_is_asleep = false;
    }

    return 0;
}

static int lua_camera_set_shutter(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer shutter = luaL_checkinteger(L, 1);

    if (shutter < 4 || shutter > 0x3FFF)
    {
        return luaL_error(L, "shutter must be between 4 and 16383");
    }

    // If shutter is longer than frame length (VTS register)
    if (shutter > 0x32A)
    {
        check_error(i2c_write(CAMERA, 0x380E, 0xFF, shutter >> 8).fail);
        check_error(i2c_write(CAMERA, 0x380F, 0xFF, shutter).fail);
    }
    else
    {
        check_error(i2c_write(CAMERA, 0x380E, 0xFF, 0x03).fail);
        check_error(i2c_write(CAMERA, 0x380F, 0xFF, 0x22).fail);
    }

    check_error(i2c_write(CAMERA, 0x3500, 0x03, shutter >> 12).fail);
    check_error(i2c_write(CAMERA, 0x3501, 0xFF, shutter >> 4).fail);
    check_error(i2c_write(CAMERA, 0x3502, 0xF0, shutter << 4).fail);

    return 0;
}

static int lua_camera_set_gain(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer sensor_gain = luaL_checkinteger(L, 1);

    if (sensor_gain < 0 || sensor_gain > 0xF8)
    {
        return luaL_error(L, "gain must be between 0 and 248");
    }

    check_error(i2c_write(CAMERA, 0x350B, 0xFF, sensor_gain).fail);

    return 0;
}

static int lua_camera_set_white_balance(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer red_gain = luaL_checkinteger(L, 1);
    lua_Integer green_gain = luaL_checkinteger(L, 2);
    lua_Integer blue_gain = luaL_checkinteger(L, 3);

    if (red_gain < 0 || green_gain < 0 || blue_gain < 0 ||
        red_gain > 0x3FF || green_gain > 0x3FF || blue_gain > 0x3FF)
    {
        return luaL_error(L, "gains must be between 0 and 1023");
    }

    check_error(i2c_write(CAMERA, 0x5180, 0x0F, red_gain >> 8).fail);
    check_error(i2c_write(CAMERA, 0x5181, 0xFF, red_gain).fail);
    check_error(i2c_write(CAMERA, 0x5182, 0x0F, green_gain >> 8).fail);
    check_error(i2c_write(CAMERA, 0x5183, 0xFF, green_gain).fail);
    check_error(i2c_write(CAMERA, 0x5184, 0x0F, blue_gain >> 8).fail);
    check_error(i2c_write(CAMERA, 0x5185, 0xFF, blue_gain).fail);

    return 0;
}

static int lua_camera_write_register(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer address = luaL_checkinteger(L, 1);
    lua_Integer value = luaL_checkinteger(L, 2);

    if (address < 0 || address > 0xFFFF)
    {
        luaL_error(L, "address must be a 16 bit unsigned number");
    }

    if (value < 0 || value > 0xFF)
    {
        luaL_error(L, "value must be an 8 bit unsigned number");
    }

    check_error(i2c_write(CAMERA, (uint16_t)address, 0xFF, (uint8_t)value).fail);

    return 0;
}

static int lua_camera_read_register(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer address = luaL_checkinteger(L, 1);

    if (address < 0 || address > 0xFFFF)
    {
        luaL_error(L, "address must be a 16 bit unsigned number");
    }

    i2c_response_t response = i2c_read(CAMERA, (uint16_t)address, 0xFF);

    if (response.fail)
    {
        error();
    }

    lua_pushinteger(L, response.value);

    return 1;
}

void lua_open_camera_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_camera_capture);
    lua_setfield(L, -2, "capture");

    lua_pushcfunction(L, lua_camera_image_ready);
    lua_setfield(L, -2, "image_ready");

    lua_pushcfunction(L, lua_camera_read);
    lua_setfield(L, -2, "read");

    lua_pushcfunction(L, lua_camera_read_raw);
    lua_setfield(L, -2, "read_raw");

    lua_pushcfunction(L, lua_camera_auto);
    lua_setfield(L, -2, "auto");

    lua_pushcfunction(L, lua_camera_power_save);
    lua_setfield(L, -2, "power_save");

    lua_pushcfunction(L, lua_camera_set_shutter);
    lua_setfield(L, -2, "set_shutter");

    lua_pushcfunction(L, lua_camera_set_gain);
    lua_setfield(L, -2, "set_gain");

    lua_pushcfunction(L, lua_camera_set_white_balance);
    lua_setfield(L, -2, "set_white_balance");

    lua_pushcfunction(L, lua_camera_write_register);
    lua_setfield(L, -2, "write_register");

    lua_pushcfunction(L, lua_camera_read_register);
    lua_setfield(L, -2, "read_register");

    lua_setfield(L, -2, "camera");

    lua_pop(L, 1);
}
