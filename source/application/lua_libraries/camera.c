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
#include "jpeg.h"
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
    .shutter = 500.0f,
    .analog_gain = 1.0f,
    .red_gain = 1.9f,
    .green_gain = 1.0f,
    .blue_gain = 2.2f,
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

    capture_settings.resolution = resolution;
    uint8_t resolution_bytes[2] = {(uint8_t)(resolution >> 8), (uint8_t)(resolution & 0xFF)};
    spi_write(FPGA, 0x23, resolution_bytes, sizeof(resolution_bytes));

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

static int scale_mult(int q, float scale)
{
    float t = (scale * q + 50) / 100; // Round
    if (t < 1)                        // Prevent divide by 0 error
        t = 1;
    else if (t > 255) // Prevent overflow
        t = 255;
    return (int)t;
}

static void generate_jpeg_header(int resolution, int qf, uint8_t *header_data)
{
    uint8_t header[] = {255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 2, 0, 0, 100, 0, 100, 0, 0, 255, 219, 0, 67, 0, 16, 11, 12, 14, 12, 10, 16, 14, 13, 14, 18, 17, 16, 19, 24, 40, 26, 24, 22, 22, 24, 49, 35, 37, 29, 40, 58, 51, 61, 60, 57, 51, 56, 55, 64, 72, 92, 78, 64, 68, 87, 69, 55, 56, 80, 109, 81, 87, 95, 98, 103, 104, 103, 62, 77, 113, 121, 112, 100, 120, 92, 101, 103, 99, 255, 219, 0, 67, 1, 17, 18, 18, 24, 21, 24, 47, 26, 26, 47, 99, 66, 56, 66, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 255, 192, 0, 17, 8, 0, 0, 0, 0, 3, 1, 34, 0, 2, 17, 1, 3, 17, 1, 255, 196, 0, 31, 0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 255, 196, 0, 31, 1, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 255, 196, 0, 181, 16, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125, 1, 2, 3, 0, 4, 17, 5, 18, 33, 49, 65, 6, 19, 81, 97, 7, 34, 113, 20, 50, 129, 145, 161, 8, 35, 66, 177, 193, 21, 82, 209, 240, 36, 51, 98, 114, 130, 9, 10, 22, 23, 24, 25, 26, 37, 38, 39, 40, 41, 42, 52, 53, 54, 55, 56, 57, 58, 67, 68, 69, 70, 71, 72, 73, 74, 83, 84, 85, 86, 87, 88, 89, 90, 99, 100, 101, 102, 103, 104, 105, 106, 115, 116, 117, 118, 119, 120, 121, 122, 131, 132, 133, 134, 135, 136, 137, 138, 146, 147, 148, 149, 150, 151, 152, 153, 154, 162, 163, 164, 165, 166, 167, 168, 169, 170, 178, 179, 180, 181, 182, 183, 184, 185, 186, 194, 195, 196, 197, 198, 199, 200, 201, 202, 210, 211, 212, 213, 214, 215, 216, 217, 218, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 255, 196, 0, 181, 17, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 119, 0, 1, 2, 3, 17, 4, 5, 33, 49, 6, 18, 65, 81, 7, 97, 113, 19, 34, 50, 129, 8, 20, 66, 145, 161, 177, 193, 9, 35, 51, 82, 240, 21, 98, 114, 209, 10, 22, 36, 52, 225, 37, 241, 23, 24, 25, 26, 38, 39, 40, 41, 42, 53, 54, 55, 56, 57, 58, 67, 68, 69, 70, 71, 72, 73, 74, 83, 84, 85, 86, 87, 88, 89, 90, 99, 100, 101, 102, 103, 104, 105, 106, 115, 116, 117, 118, 119, 120, 121, 122, 130, 131, 132, 133, 134, 135, 136, 137, 138, 146, 147, 148, 149, 150, 151, 152, 153, 154, 162, 163, 164, 165, 166, 167, 168, 169, 170, 178, 179, 180, 181, 182, 183, 184, 185, 186, 194, 195, 196, 197, 198, 199, 200, 201, 202, 210, 211, 212, 213, 214, 215, 216, 217, 218, 226, 227, 228, 229, 230, 231, 232, 233, 234, 242, 243, 244, 245, 246, 247, 248, 249, 250, 255, 218, 0, 12, 3, 1, 0, 2, 17, 3, 17, 0, 63, 0};

    float scale;

    if (qf < 50)
        scale = 5000 / qf;
    else
        scale = 200 - 2 * qf;

    for (int i = 25; i <= 88; i++)
        header[i] = scale_mult(header[i], scale);
    for (int i = 93; i <= 156; i++)
        header[i] = scale_mult(header[i], scale);

    header[163] = (resolution >> 8) & 0xff;
    header[164] = resolution & 0xff;
    header[165] = (resolution >> 8) & 0xff;
    header[166] = resolution & 0xff;

    memcpy(header_data, header, sizeof(header));
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

    uint8_t *header = malloc(623);
    generate_jpeg_header(capture_settings.resolution, capture_settings.quality_factor, header);

    // Append JPEG header data
    if (header_bytes_sent_out < sizeof(header))
    {
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

    free(header);
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
    double shutter_limit = 1600.0;
    double analog_gain_limit = 60.0;

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

    if (red_gain > 1023.0)
    {
        red_gain = 1023.0;
    }
    if (green_gain > 1023.0)
    {
        green_gain = 1023.0;
    }
    if (blue_gain > 1023.0)
    {
        blue_gain = 1023.0;
    }
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

    uint16_t red_gain_uint16 = (uint16_t)(last.red_gain * 256.0);
    uint16_t green_gain_uint16 = (uint16_t)(last.green_gain * 256.0);
    uint16_t blue_gain_uint16 = (uint16_t)(last.blue_gain * 256.0);

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