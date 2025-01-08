/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
 *              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
 *
 * ISC Licence
 *
 * Copyright © 2024 Brilliant Labs Ltd.
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

#include "error_logging.h"
#include "lauxlib.h"
#include "lua.h"
#include "nrfx_log.h"
#include "nrfx_pwm.h"
#include "pinout.h"

static const nrfx_pwm_t pwm = NRFX_PWM_INSTANCE(0);

static int lua_led_set_color(lua_State *L)
{
    lua_Integer red = luaL_checkinteger(L, 1);
    lua_Integer green = luaL_checkinteger(L, 2);
    lua_Integer blue = luaL_checkinteger(L, 3);

    if (red < 0 || red > 100 || green < 0 || green > 100 || blue < 0 || blue > 100)
    {
        luaL_error(L, "led color must be between 0 and 100");
    }

    static nrf_pwm_values_individual_t seq_values;

    seq_values.channel_0 = (uint16_t)red;
    seq_values.channel_1 = (uint16_t)green;
    seq_values.channel_2 = (uint16_t)blue;

    nrf_pwm_sequence_t const seq = {
        .values.p_individual = &seq_values,
        .length = NRF_PWM_VALUES_LENGTH(seq_values),
        .repeats = 0,
        .end_delay = 0,
    };

    nrfx_pwm_simple_playback(&pwm, &seq, 1, NRFX_PWM_FLAG_LOOP);

    return 0;
}

void lua_open_led_library(lua_State *L)
{
    nrfx_pwm_config_t config = NRFX_PWM_DEFAULT_CONFIG(
        FRAME_LITE_LED_RED_PIN,
        FRAME_LITE_LED_GREEN_PIN,
        FRAME_LITE_LED_BLUE_PIN,
        NRF_PWM_PIN_NOT_CONNECTED);

    config.pin_inverted[0] = true;
    config.pin_inverted[1] = true;
    config.pin_inverted[2] = true;

    config.load_mode = NRF_PWM_LOAD_INDIVIDUAL;
    config.top_value = 100;

    if (nrfx_pwm_init_check(&pwm) == false)
    {
        nrfx_pwm_init(&pwm, &config, NULL, NULL);
    }

    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_led_set_color);
    lua_setfield(L, -2, "set_color");

    lua_setfield(L, -2, "led");

    lua_pop(L, 1);
}