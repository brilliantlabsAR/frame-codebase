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

static lua_Integer camera_quality_factor = 50;
static size_t jpeg_header_bytes_sent_out = 0;
static size_t jpeg_footer_bytes_sent_out = 0;

static int lua_camera_capture(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer quality_factor = 50;

    if (lua_getfield(L, 1, "quality_factor") != LUA_TNIL)
    {
        quality_factor = luaL_checkinteger(L, -1);

        switch (quality_factor)
        {
        case 100:
            spi_write(FPGA, 0x26, (uint8_t *)"\x01", 1);
            break;

        case 50:
            spi_write(FPGA, 0x26, (uint8_t *)"\x00", 1);
            break;

        case 25:
            spi_write(FPGA, 0x26, (uint8_t *)"\x03", 1);
            break;

        case 10:
            spi_write(FPGA, 0x26, (uint8_t *)"\x02", 1);
            break;

        default:
            luaL_error(L, "quality_factor must be either 100, 50, 25 or 10");
            break;
        }
    }

    spi_write(FPGA, 0x20, NULL, 0);
    camera_quality_factor = quality_factor;
    jpeg_header_bytes_sent_out = 0;
    jpeg_footer_bytes_sent_out = 0;
    return 0;
}

static int lua_camera_image_ready(lua_State *L)
{
    if (camera_is_asleep)
    {
        luaL_error(L, "camera is asleep");
    }

    uint8_t data[1] = {0};

    spi_read(FPGA, 0x27, (uint8_t *)data, sizeof(data));

    lua_pushboolean(L, data[0] == 1);
    return 1;
}

static uint16_t get_bytes_available(void)
{
    uint8_t data[2] = {0, 0};

    spi_read(FPGA, 0x21, (uint8_t *)data, sizeof(data));

    uint16_t bytes_available = (uint16_t)data[0] << 8 |
                               (uint16_t)data[1];

    return bytes_available;
}

static int lua_camera_read(lua_State *L)
{
    lua_Integer bytes_requested = luaL_checkinteger(L, 1);
    if (bytes_requested <= 0)
    {
        luaL_error(L, "bytes must be greater than 0");
    }

    size_t bytes_remaining = bytes_requested;

    uint8_t *payload = malloc(bytes_requested);
    if (payload == NULL)
    {
        luaL_error(L, "bytes requested is too large");
    }

    // TODO this ends up placing the arrays in RAM. Make it static somehow
    uint8_t *jpeg_header = NULL;
    size_t jpeg_header_length = 0;

    switch (camera_quality_factor)
    {
    case 100:
        jpeg_header = (uint8_t *)jpeg_header_qf_100;
        jpeg_header_length = sizeof(jpeg_header_qf_100);
        break;

    case 50:
        jpeg_header = (uint8_t *)jpeg_header_qf_50;
        jpeg_header_length = sizeof(jpeg_header_qf_50);
        break;

    case 25:
        jpeg_header = (uint8_t *)jpeg_header_qf_25;
        jpeg_header_length = sizeof(jpeg_header_qf_25);
        break;

    case 10:
        jpeg_header = (uint8_t *)jpeg_header_qf_10;
        jpeg_header_length = sizeof(jpeg_header_qf_10);
        break;

    default:
        error_with_message("Invalid camera_quality_factor");
        break;
    }

    // Append JPEG header data
    if (jpeg_header_bytes_sent_out < jpeg_header_length)
    {
        size_t length =
            jpeg_header_length - jpeg_header_bytes_sent_out < bytes_requested
                ? jpeg_header_length - jpeg_header_bytes_sent_out
                : bytes_requested;

        memcpy(payload, jpeg_header + jpeg_header_bytes_sent_out, length);

        jpeg_header_bytes_sent_out += length;
        bytes_remaining -= length;
    }

    else
    {
        uint16_t image_bytes_available = get_bytes_available();

        // Append image data
        if (image_bytes_available > 0)
        {
            if (bytes_remaining > 0)
            {

                // append image data
                size_t length = bytes_remaining < image_bytes_available
                                    ? bytes_remaining
                                    : image_bytes_available;

                spi_read(FPGA,
                         0x22,
                         payload + bytes_requested - bytes_remaining,
                         length);

                bytes_remaining -= length;
            }
        }

        else
        {
            // append footer 0xFF
            if (bytes_remaining > 0 && jpeg_footer_bytes_sent_out == 0)
            {
                payload[bytes_requested - bytes_remaining] = 0xFF;
                jpeg_footer_bytes_sent_out++;
                bytes_remaining--;
            }

            // append footer 0xD9
            if (bytes_remaining > 0 && jpeg_footer_bytes_sent_out == 1)
            {
                payload[bytes_requested - bytes_remaining] = 0xD9;
                jpeg_footer_bytes_sent_out++;
                bytes_remaining--;
            }
        }
    }

    // Return nill if nothing was written to payload
    if (bytes_remaining == bytes_requested)
    {
        lua_pushnil(L);
    }

    // Otherwise return payload
    else
    {
        lua_pushlstring(L, (char *)payload, bytes_requested - bytes_remaining);
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

    size_t bytes_remaining = bytes_requested;

    uint8_t *payload = malloc(bytes_requested);
    if (payload == NULL)
    {
        luaL_error(L, "bytes requested is too large");
    }

    uint16_t image_bytes_available = get_bytes_available();

    // Append image data
    if (image_bytes_available > 0)
    {
        if (bytes_remaining > 0)
        {

            // append image data
            size_t length = bytes_remaining < image_bytes_available
                                ? bytes_remaining
                                : image_bytes_available;

            spi_read(FPGA,
                     0x22,
                     payload + bytes_requested - bytes_remaining,
                     length);

            bytes_remaining -= length;
        }
    }

    else
    {
        // append footer 0xFF
        if (bytes_remaining > 0 && jpeg_footer_bytes_sent_out == 0)
        {
            payload[bytes_requested - bytes_remaining] = 0xFF;
            jpeg_footer_bytes_sent_out++;
            bytes_remaining--;
        }

        // append footer 0xD9
        if (bytes_remaining > 0 && jpeg_footer_bytes_sent_out == 1)
        {
            payload[bytes_requested - bytes_remaining] = 0xD9;
            jpeg_footer_bytes_sent_out++;
            bytes_remaining--;
        }
    }

    // Return nill if nothing was written to payload
    if (bytes_remaining == bytes_requested)
    {
        lua_pushnil(L);
    }

    // Otherwise return payload
    else
    {
        lua_pushlstring(L, (char *)payload, bytes_requested - bytes_remaining);
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
                luaL_error(L, "analog_gain_limit must be between 0 and 248");
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