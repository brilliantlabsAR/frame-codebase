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
#include "frame_lua_libraries.h"
#include "i2c.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrfx_gpiote.h"
#include "nrfx_systick.h"
#include "pinout.h"

#define PI 3.14159265

static int lua_imu_callback_function = 0;

static void lua_imu_tap_callback_handler(lua_State *L, lua_Debug *ar)
{
    lua_sethook(L, NULL, 0, 0);

    lua_rawgeti(L, LUA_REGISTRYINDEX, lua_imu_callback_function);

    lua_pcall(L, 0, 0, 0);
}

void imu_tap_interrupt_handler(nrfx_gpiote_pin_t unused_gptiote_pin,
                               nrfx_gpiote_trigger_t unused_gptiote_trigger,
                               void *unused_gptiote_context_pointer)
{
    if (lua_imu_callback_function != 0)
    {
        int flag = LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT;
        lua_sethook(globalL, lua_imu_tap_callback_handler, flag, 1);
    }

    // Clear the interrupt by reading the status register
    check_error(i2c_read(ACCELEROMETER, 0x03, 0xFF).fail);
}

static int lua_imu_tap_callback(lua_State *L)
{
    if (lua_isnil(L, 1))
    {
        lua_imu_callback_function = 0;
        return 0;
    }

    if (lua_isfunction(L, 1))
    {
        lua_imu_callback_function = luaL_ref(L, LUA_REGISTRYINDEX);
        return 0;
    }

    luaL_error(L, "expected nil or function");

    return 0;
}

static int lua_imu_direction(lua_State *L)
{
    // Set PC to wake up magnetometer, and set FORCE to start a conversion
    check_error(i2c_write(MAGNETOMETER, 0x1B, 0x80, 0x80).fail);
    check_error(i2c_write(MAGNETOMETER, 0x1D, 0x40, 0x40).fail);

    // Wait until data is ready
    while (true)
    {
        if (i2c_read(MAGNETOMETER, 0x18, 0x40).value)
        {
            break;
        }

        nrfx_systick_delay_ms(1);
    }

    // Read magnetometer (14 bit signed integers)
    int16_t x_mag_lsb = i2c_read(MAGNETOMETER, 0x10, 0xFF).value;
    int16_t x_mag_msb = i2c_read(MAGNETOMETER, 0x11, 0xFF).value;
    int16_t y_mag_lsb = i2c_read(MAGNETOMETER, 0x12, 0xFF).value;
    int16_t y_mag_msb = i2c_read(MAGNETOMETER, 0x13, 0xFF).value;
    int16_t z_mag_lsb = i2c_read(MAGNETOMETER, 0x14, 0xFF).value;
    int16_t z_mag_msb = i2c_read(MAGNETOMETER, 0x15, 0xFF).value;

    // Combine bytes and swap the axis to match the worn orientation
    int16_t x_mag = z_mag_msb << 8 | z_mag_lsb;
    int16_t y_mag = y_mag_msb << 8 | y_mag_lsb;
    int16_t z_mag = x_mag_msb << 8 | x_mag_lsb;

    LOG("mag: x = %d, y = %d, z = %d", x_mag, y_mag, z_mag);

    // Clear PC to put magnetometer back to sleep
    check_error(i2c_write(MAGNETOMETER, 0x1B, 0x80, 0x80).fail);

    // Accelerometer data is always available, so just read it
    int16_t x_accel_lsb = i2c_read(ACCELEROMETER, 0x0D, 0xFF).value;
    int16_t x_accel_msb = i2c_read(ACCELEROMETER, 0x0E, 0xFF).value;
    int16_t y_accel_lsb = i2c_read(ACCELEROMETER, 0x0F, 0xFF).value;
    int16_t y_accel_msb = i2c_read(ACCELEROMETER, 0x10, 0xFF).value;
    int16_t z_accel_lsb = i2c_read(ACCELEROMETER, 0x11, 0xFF).value;
    int16_t z_accel_msb = i2c_read(ACCELEROMETER, 0x12, 0xFF).value;

    // Combine bytes and swap the axis to match the worn orientation
    int16_t x_accel = z_accel_msb << 8 | z_accel_lsb;
    int16_t y_accel = y_accel_msb << 8 | y_accel_lsb;
    int16_t z_accel = x_accel_msb << 8 | x_accel_lsb;

    LOG("accel: x = %d, y = %d, z = %d", x_accel, y_accel, z_accel);

    // Calculate heading, roll and pitch
    double roll = atan2((double)y_accel, (double)z_accel) * (180.0 / PI);
    double pitch = atan2((double)x_accel, (double)z_accel) * (180.0 / PI);

    double xM2 = x_mag * cos(pitch) + z_mag * sin(pitch);
    double yM2 = x_mag * sin(roll) * sin(pitch) + y_mag * cos(roll) - z_mag * sin(roll) * cos(pitch);
    double heading = (atan2(yM2, xM2) * 180 / PI);
    if (heading < 0)
    {
        heading = 360 + heading;
    }
    LOG("heading: %f", heading);

    lua_newtable(L);

    lua_pushnumber(L, pitch);
    lua_setfield(L, -2, "pitch");

    lua_pushnumber(L, roll);
    lua_setfield(L, -2, "roll");

    lua_pushinteger(L, 0);
    lua_setfield(L, -2, "heading");
    return 1;
}

void lua_open_imu_library(lua_State *L)
{
    // NOTE: IMU must be repowered after changing these settings

    // Enable tap interrupt on -Y axis
    check_error(i2c_write(ACCELEROMETER, 0x06, 0xFF, 0x08).fail);

    // Ignore multiple taps and set sample rate to 256Hz
    check_error(i2c_write(ACCELEROMETER, 0x08, 0xFF, 0x8A).fail);

    // Enable tap interrupts on -Y axis in threshold mode
    check_error(i2c_write(ACCELEROMETER, 0x09, 0xFF, 0xC8).fail);

    // Configure tap threshold on Y axis
    check_error(i2c_write(ACCELEROMETER, 0x0B, 0xFF, 0x07).fail);

    // Configure 14bit mode
    check_error(i2c_write(ACCELEROMETER, 0x20, 0xFF, 0x05).fail);

    // Set INTA as push-pull active-high and come out of standby
    check_error(i2c_write(ACCELEROMETER, 0x07, 0xFF, 0xC1).fail);

    // Clear interrupts
    check_error(i2c_read(ACCELEROMETER, 0x03, 0xFF).fail);

    // Configure tap pin interrupt
    nrfx_gpiote_input_config_t input_config = {
        .pull = NRF_GPIO_PIN_NOPULL,
    };

    nrfx_gpiote_trigger_config_t trigger_config = {
        .trigger = NRFX_GPIOTE_TRIGGER_LOTOHI,
        .p_in_channel = NULL,
    };

    nrfx_gpiote_handler_config_t handler_config = {
        .handler = imu_tap_interrupt_handler,
        .p_context = NULL,
    };

    check_error(nrfx_gpiote_input_configure(IMU_INTERRUPT_PIN,
                                            &input_config,
                                            &trigger_config,
                                            &handler_config));

    nrfx_gpiote_trigger_enable(IMU_INTERRUPT_PIN, true);

    // Add functions to the frame lua library
    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_imu_tap_callback);
    lua_setfield(L, -2, "tap_callback");

    lua_pushcfunction(L, lua_imu_direction);
    lua_setfield(L, -2, "direction");

    lua_setfield(L, -2, "imu");

    lua_pop(L, 1);
}