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
#include "lauxlib.h"
#include "lua.h"
#include "nrf_gpio.h"
#include "nrfx_systick.h"
#include "pinout.h"
#include "spi.h"
#include "nrfx_rtc.h"

static const nrfx_rtc_t rtc = NRFX_RTC_INSTANCE(2);

typedef enum camera_metering_mode
{
    SPOT,
    CENTER_WEIGHTED,
    AVERAGE
} camera_metering_mode_t;

static struct camera_auto
{
    bool enabled;
    camera_metering_mode_t mode;
    double exposure;
    double gain;
} camera_auto = {
    .enabled = false,
    .exposure = 0,
    .gain = 0,
};

static int lua_camera_capture(lua_State *L)
{
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
    {
        luaL_error(L, "camera is asleep");
    }

    spi_write(FPGA, 0x20, NULL, 0);
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

    uint16_t bytes_available = get_bytes_available();

    if (bytes_requested <= 0)
    {
        luaL_error(L, "bytes must be greater than 0");
    }

    if (bytes_available <= 0)
    {
        lua_pushnil(L);
        return 1;
    }

    uint16_t length = bytes_available < bytes_requested
                          ? bytes_available
                          : bytes_requested;

    uint8_t *data = malloc(length);
    if (data == NULL)
    {
        luaL_error(L, "not enough memory");
    }

    spi_read(FPGA, 0x22, data, length);

    lua_pushlstring(L, (char *)data, length);
    free(data);

    return 1;
}

static void lua_run_camera_controller(nrfx_rtc_int_type_t int_type)
{
    if (camera_auto.enabled == false)
    {
        return;
    }

    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
    {
        return;
    }

    // Configuration variables
    double setpoint_brightness = 0.686;
    double exposure_kp = 1600;
    double gain_kp = 30;

    // Get current brightness
    volatile uint8_t metering_data[6];
    spi_read(FPGA, 0x25, (uint8_t *)metering_data, sizeof(metering_data));

    double center_r = metering_data[0] / 255.0;
    double center_g = metering_data[1] / 255.0;
    double center_b = metering_data[2] / 255.0;
    double average_r = metering_data[3] / 255.0;
    double average_g = metering_data[4] / 255.0;
    double average_b = metering_data[5] / 255.0;

    double spot = (center_r + center_g + center_b) / 3.0;
    double average = (average_r + average_g + average_b) / 3.0;
    double center_weighted = (spot + spot + spot + average) / 4.0;

    // Choose error
    double error;
    switch (camera_auto.mode)
    {
    case SPOT:
        error = setpoint_brightness - spot;
        break;

    case CENTER_WEIGHTED:
        error = setpoint_brightness - center_weighted;
        break;

    default: // AVERAGE
        error = setpoint_brightness - average;
        break;
    }

    // Run the loop iteration
    if (error > 0)
    {
        // Prioritize exposure over gain when image is too dark
        camera_auto.exposure += exposure_kp * error;

        if (camera_auto.exposure >= 800.0)
        {
            camera_auto.gain += gain_kp * error;
        }
    }
    else
    {
        // When image is too bright, reduce gain first
        camera_auto.gain += gain_kp * error;

        if (camera_auto.gain <= 0)
        {
            camera_auto.exposure += exposure_kp * error;
        }
    }

    // Limit the value
    if (camera_auto.exposure > 800.0)
    {
        camera_auto.exposure = 800.0;
    }
    if (camera_auto.exposure < 20.0)
    {
        camera_auto.exposure = 20.0;
    }
    if (camera_auto.gain > 255.0)
    {
        camera_auto.gain = 255.0;
    }
    if (camera_auto.gain < 0.0)
    {
        camera_auto.gain = 0.0;
    }

    // TODO calculate and set auto white-balance

    // Set the output
    uint16_t exposure = (uint16_t)camera_auto.exposure;
    uint8_t gain = (uint8_t)camera_auto.gain;

    // TODO group hold command
    check_error(i2c_write(CAMERA, 0x3500, 0x03, exposure >> 12).fail);
    check_error(i2c_write(CAMERA, 0x3501, 0xFF, exposure >> 4).fail);
    check_error(i2c_write(CAMERA, 0x3502, 0xF0, exposure << 4).fail);
    check_error(i2c_write(CAMERA, 0x3505, 0xFF, gain).fail);
}

static int lua_camera_auto(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TBOOLEAN);
    camera_auto.enabled = lua_toboolean(L, 1);

    if (camera_auto.enabled)
    {
        if (strcmp(luaL_checkstring(L, 1), "spot") == 0)
        {
            camera_auto.mode = SPOT;
        }

        else if (strcmp(luaL_checkstring(L, 1), "center_weighted") == 0)
        {
            camera_auto.mode = CENTER_WEIGHTED;
        }

        else if (strcmp(luaL_checkstring(L, 1), "average") == 0)
        {
            camera_auto.mode = AVERAGE;
        }

        else
        {
            luaL_error(L, "mode must be spot, center_weighted or average");
        }
    }

    return 0;
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

static int lua_camera_set_exposure(lua_State *L)
{
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer exposure = luaL_checkinteger(L, 1);

    if (exposure < 20 || exposure > 0x3FFF)
    {
        return luaL_error(L, "exposure must be between 20us and 25000us");
    }

    check_error(i2c_write(CAMERA, 0x3500, 0x03, exposure >> 12).fail);
    check_error(i2c_write(CAMERA, 0x3501, 0xFF, exposure >> 4).fail);
    check_error(i2c_write(CAMERA, 0x3502, 0xF0, exposure << 4).fail);

    return 0;
}

static int lua_camera_set_gain(lua_State *L)
{
    if (nrf_gpio_pin_out_read(CAMERA_SLEEP_PIN) == false)
    {
        luaL_error(L, "camera is asleep");
    }

    lua_Integer sensor_gain = luaL_checkinteger(L, 1);

    if (sensor_gain > 0xFF)
    {
        return luaL_error(L, "gain must be less than 0xFF");
    }

    // TODO try to set the 0x350A/B registers instead
    check_error(i2c_write(CAMERA, 0x3505, 0xFF, sensor_gain).fail);

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

    if (red_gain > 0x3FF || green_gain > 0x3FF || blue_gain > 0x3FF)
    {
        return luaL_error(L, "gain values must be less than 0x3FF");
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

void lua_open_camera_library(lua_State *L)
{
    // Wake up camera in case it was asleep
    nrf_gpio_pin_write(CAMERA_SLEEP_PIN, true);
    nrfx_systick_delay_ms(10);

    // Configure the real time clock
    if (nrfx_rtc_init_check(&rtc) == false)
    {
        nrfx_rtc_config_t config = NRFX_RTC_DEFAULT_CONFIG;

        config.prescaler = NRF_RTC_FREQ_TO_PRESCALER(10);

        check_error(nrfx_rtc_init(&rtc, &config, lua_run_camera_controller));

        nrfx_rtc_tick_enable(&rtc, true);
        nrfx_rtc_enable(&rtc);
    }

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

    lua_pushcfunction(L, lua_camera_set_exposure);
    lua_setfield(L, -2, "set_exposure");

    lua_pushcfunction(L, lua_camera_set_gain);
    lua_setfield(L, -2, "set_gain");

    lua_pushcfunction(L, lua_camera_set_white_balance);
    lua_setfield(L, -2, "set_white_balance");

    lua_pushcfunction(L, lua_camera_set_register);
    lua_setfield(L, -2, "set_register");

    lua_setfield(L, -2, "camera");

    lua_pop(L, 1);
}