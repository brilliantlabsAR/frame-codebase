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
#include "error_logging.h"
#include "i2c.h"
#include "jpeg.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrf_gpio.h"
#include "nrfx_systick.h"
#include "pinout.h"
#include "spi.h"

typedef enum camera_metering_mode
{
    SPOT,
    CENTER_WEIGHTED,
    AVERAGE
} camera_metering_mode_t;

static struct camera_auto_last_values
{
    double shutter;
    double gain;
} last = {
    .shutter = 4,
    .gain = 1,
};

static size_t jpeg_header_bytes_sent_out = 0;
static size_t jpeg_footer_bytes_sent_out = 0;

static int lua_camera_capture(lua_State *L)
{
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
    {
        luaL_error(L, "camera is asleep");
    }

    spi_write(FPGA, 0x20, NULL, 0);
    jpeg_header_bytes_sent_out = 0;
    jpeg_footer_bytes_sent_out = 0;
    return 0;
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

    // LOG("Requested: %llu bytes", bytes_requested);

    uint8_t *payload = malloc(bytes_requested);
    if (payload == NULL)
    {
        luaL_error(L, "bytes requested is too large");
    }

    // Append JPEG header data
    if (jpeg_header_bytes_sent_out < sizeof(jpeg_header))
    {
        size_t length =
            sizeof(jpeg_header) - jpeg_header_bytes_sent_out < bytes_requested
                ? sizeof(jpeg_header) - jpeg_header_bytes_sent_out
                : bytes_requested;

        // LOG("  written %u bytes of header", length);
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

                // LOG("  written %u bytes of image data", length);
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
                // LOG("  written 0xFF of footer");
            }

            // append footer 0xD9
            if (bytes_remaining > 0 && jpeg_footer_bytes_sent_out == 1)
            {
                payload[bytes_requested - bytes_remaining] = 0xD9;
                jpeg_footer_bytes_sent_out++;
                bytes_remaining--;
                // LOG("  written 0xD9 of footer");
            }
        }
    }

    // Return nill if nothing was written to payload
    if (bytes_remaining == bytes_requested)
    {
        lua_pushnil(L);
        // LOG("  all done");
    }

    // Otherwise return payload
    else
    {
        lua_pushlstring(L, (char *)payload, bytes_requested - bytes_remaining);
        // LOG("  sent");
    }

    free(payload);
    return 1;
}

static int lua_camera_auto(lua_State *L)
{
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
    {
        return 0;
    }

    camera_metering_mode_t metering = AVERAGE;
    double target_exposure = 0.6;
    double shutter_fast_kp = 600;
    double shutter_slow_kp = 50;
    double gain_kp = 30;
    double shutter_limit = 6000;
    double shutter_fast_slow_threshold = 800;

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
                luaL_error(L,
                           "metering must be spot, center_weighted or average");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "target_exposure") != LUA_TNIL)
        {
            target_exposure = luaL_checknumber(L, -1);
            if (target_exposure < 0.0 || target_exposure > 1.0)
            {
                luaL_error(L, "target_exposure must be between 0 and 1");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "shutter_fast_kp") != LUA_TNIL)
        {
            shutter_fast_kp = luaL_checknumber(L, -1);
            if (shutter_fast_kp < 0.0)
            {
                luaL_error(L, "shutter_fast_kp must be greater than 0");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "shutter_slow_kp") != LUA_TNIL)
        {
            shutter_slow_kp = luaL_checknumber(L, -1);
            if (shutter_slow_kp < 0.0)
            {
                luaL_error(L, "shutter_slow_kp must be greater than 0");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "gain_kp") != LUA_TNIL)
        {
            gain_kp = luaL_checknumber(L, -1);
            if (gain_kp < 0.0)
            {
                luaL_error(L, "gain_kp must be greater than 0");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "shutter_limit") != LUA_TNIL)
        {
            shutter_limit = luaL_checknumber(L, -1);
            if (shutter_limit < 0.0 || shutter_limit > 16383.0)
            {
                luaL_error(L, "shutter_limit must be between 0 and 16383");
            }

            lua_pop(L, 1);
        }

        if (lua_getfield(L, 1, "shutter_fast_slow_threshold") != LUA_TNIL)
        {
            shutter_fast_slow_threshold = luaL_checknumber(L, -1);
            if (shutter_fast_slow_threshold < 0.0 ||
                shutter_fast_slow_threshold > 16383.0)
            {
                luaL_error(L, "shutter_fast_slow_threshold must be between 0 and 16383");
            }

            lua_pop(L, 1);
        }
    }

    // Get current brightness
    volatile uint8_t metering_data[6];
    spi_read(FPGA, 0x25, (uint8_t *)metering_data, sizeof(metering_data));

    double spot_r = metering_data[0] / 255.0;
    double spot_g = metering_data[1] / 255.0;
    double spot_b = metering_data[2] / 255.0;
    double matrix_r = metering_data[3] / 255.0;
    double matrix_g = metering_data[4] / 255.0;
    double matrix_b = metering_data[5] / 255.0;

    double spot_average = (spot_r + spot_g + spot_b) / 3.0;
    double matrix_average = (matrix_r + matrix_g + matrix_b) / 3.0;
    double center_weighted_average = (spot_average +
                                      spot_average +
                                      spot_average +
                                      matrix_average) /
                                     4.0;

    // Choose error
    double error;
    switch (metering)
    {
    case SPOT:
        error = target_exposure - spot_average;
        break;

    case CENTER_WEIGHTED:
        error = target_exposure - center_weighted_average;
        break;

    default: // AVERAGE
        error = target_exposure - matrix_average;
        break;
    }

    // Run the loop iteration
    if (error > 0)
    {
        // Use different kp for fast and slow shutters as it's non-linear
        if (last.shutter < shutter_fast_slow_threshold)
        {
            last.shutter += shutter_fast_kp * error;
        }
        else
        {
            last.shutter += shutter_slow_kp * error;
        }

        // Prioritize shutter over gain when image is too dark
        if (last.shutter >= shutter_limit)
        {
            last.gain += gain_kp * error;
        }
    }
    else
    {
        // When image is too bright, reduce gain first
        last.gain += gain_kp * error;

        if (last.gain <= 0)
        {
            // Use different kp for fast and slow shutters as it's non-linear
            if (last.shutter < shutter_fast_slow_threshold)
            {
                last.shutter += shutter_fast_kp * error;
            }
            else
            {
                last.shutter += shutter_slow_kp * error;
            }
        }
    }

    // Limit the outputs
    if (last.shutter > shutter_limit)
    {
        last.shutter = shutter_limit;
    }
    if (last.shutter < 4.0)
    {
        last.shutter = 4.0;
    }
    if (last.gain > 248.0)
    {
        last.gain = 248.0;
    }
    if (last.gain < 0.0)
    {
        last.gain = 0.0;
    }

    // TODO calculate and set auto white-balance

    // Set the output
    uint16_t shutter = (uint16_t)last.shutter;
    uint8_t gain = (uint8_t)last.gain;

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
    check_error(i2c_write(CAMERA, 0x350B, 0xFF, gain).fail);

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

        lua_setfield(L, -2, "brightness");
    }

    lua_pushnumber(L, error);
    lua_setfield(L, -2, "error");

    lua_pushnumber(L, last.shutter);
    lua_setfield(L, -2, "shutter");

    lua_pushnumber(L, last.gain);
    lua_setfield(L, -2, "gain");

    return 1;
}

static int lua_camera_sleep(lua_State *L)
{
    nrf_gpio_pin_write(CAMERA_SLEEP_PIN, false);
    return 0;
}

static int lua_camera_wake(lua_State *L)
{
    nrf_gpio_pin_write(CAMERA_SLEEP_PIN, true);
    return 0;
}

static int lua_camera_set_shutter(lua_State *L)
{
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
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
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
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
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
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

static int lua_camera_set_register(lua_State *L)
{
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
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

    i2c_response_t response = i2c_write(CAMERA,
                                        (uint16_t)address,
                                        0xFF,
                                        (uint8_t)value);

    if (response.fail)
    {
        error();
    }

    return 0;
}

static int lua_camera_histogram(lua_State *L)
{
    uint8_t data[24];
    spi_read(FPGA, 0x27, data, 24);

    lua_newtable(L);

    lua_newtable(L);
    lua_newtable(L);
    for (int i=0; i<8; i++) {
        lua_pushnumber(L, data[i]);
        lua_seti(L, -2, i);
    }
    lua_setfield(L, -2, "r");

    lua_newtable(L);
    for (int i=0; i<8; i++) {
        lua_pushnumber(L, data[i+8]);
        lua_seti(L, -2, i);
    }
    lua_setfield(L, -2, "g");

    lua_newtable(L);
    for (int i=0; i<8; i++) {
        lua_pushnumber(L, data[i+16]);
        lua_seti(L, -2, i);
    }
    lua_setfield(L, -2, "b");

    lua_newtable(L);
    uint16_t avg;
    for (int i=0; i<8; i++) {
        avg = (data[i] + data[i+8] + data[i+16]) / 3;
        lua_pushnumber(L, avg);
        lua_seti(L, -2, i);
    }
    lua_setfield(L, -2, "a");

    // Pick the last bin colour with maximum value
    uint16_t last_bin;
    if (data[7] >= data[15] && data[7] >= data[23])
        last_bin = data[7];
    else if (data[15] >= data[7] && data[15] >= data[23])
        last_bin = data[15];
    else
        last_bin = data[23];

    int16_t error = 128 - last_bin;
    if (error < -20) {
        if (error < -50) {
            if (last.gain > 1) {
                last.gain += 0.05 * error;
            }
            else {
                last.shutter += last.shutter * 0.02 * error;
            }
        }
        else {
            if (last.gain > 1) {
                last.gain += 0.01 * error;
            }
            else {
                last.shutter += 0.05 * error;
            }
        }
    }

    else if (error > 20) {
        if (error > 50) {
            if (last.shutter < 16000) {
                last.shutter += last.shutter * 0.02 * error;
            }
            else {
                last.gain += 0.05 * error;
            }
        }
        else {
            if (last.shutter < 16000) {
                last.shutter += 0.05 * error;
            }
            else {
                last.gain += 0.01 * error;
            }
        }
    }

    else LOG("STOP");

    // Limit the outputs
    if (last.shutter > 16000)
    {
        last.shutter = 16000;
    }
    if (last.shutter < 4.0)
    {
        last.shutter = 4.0;
    }
    if (last.gain > 248.0)
    {
        last.gain = 248.0;
    }
    if (last.gain < 1.0)
    {
        last.gain = 1.0;
    }

    // TODO calculate and set auto white-balance

    // Set the output
    uint16_t shutter = (uint16_t)last.shutter;
    uint8_t gain = (uint8_t)last.gain;

    LOG("error %d  gain %d  shutter %d", error, gain, shutter);

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
    check_error(i2c_write(CAMERA, 0x350B, 0xFF, gain).fail);

    return 1;
}

void lua_open_camera_library(lua_State *L)
{
    // Wake up camera in case it was asleep
    nrf_gpio_pin_write(CAMERA_SLEEP_PIN, true);
    nrfx_systick_delay_ms(10);

    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_camera_capture);
    lua_setfield(L, -2, "capture");

    lua_pushcfunction(L, lua_camera_read);
    lua_setfield(L, -2, "read");

    lua_pushcfunction(L, lua_camera_auto);
    lua_setfield(L, -2, "auto");

    lua_pushcfunction(L, lua_camera_sleep);
    lua_setfield(L, -2, "sleep");

    lua_pushcfunction(L, lua_camera_wake);
    lua_setfield(L, -2, "wake");

    lua_pushcfunction(L, lua_camera_set_shutter);
    lua_setfield(L, -2, "set_shutter");

    lua_pushcfunction(L, lua_camera_set_gain);
    lua_setfield(L, -2, "set_gain");

    lua_pushcfunction(L, lua_camera_set_white_balance);
    lua_setfield(L, -2, "set_white_balance");

    lua_pushcfunction(L, lua_camera_set_register);
    lua_setfield(L, -2, "set_register");

    lua_pushcfunction(L, lua_camera_histogram);
    lua_setfield(L, -2, "histogram");

    lua_setfield(L, -2, "camera");

    lua_pop(L, 1);
}