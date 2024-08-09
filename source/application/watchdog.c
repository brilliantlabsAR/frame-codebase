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

#include "lua.h"
#include "nrfx_wdt.h"

static nrfx_wdt_t watchdog = NRFX_WDT_INSTANCE(0);

void init_watchdog(void)
{
    nrfx_wdt_config_t watchdog_config = {
        .behaviour = NRF_WDT_BEHAVIOUR_RUN_SLEEP_MASK,
        .reload_value = 6000,
    };

    nrfx_wdt_channel_id watchdog_channel = NRF_WDT_RR0;

    check_error(nrfx_wdt_init(&watchdog, &watchdog_config, NULL));
    check_error(nrfx_wdt_channel_alloc(&watchdog, &watchdog_channel));

    nrfx_wdt_enable(&watchdog);
    nrfx_wdt_feed(&watchdog);
}

void reload_watchdog(lua_State *L, lua_Debug *ar)
{
    nrfx_wdt_channel_feed(&watchdog, NRF_WDT_RR0);
}

void sethook_watchdog(lua_State *L)
{
    lua_sethook(L, reload_watchdog, LUA_MASKCOUNT, 2000);
}