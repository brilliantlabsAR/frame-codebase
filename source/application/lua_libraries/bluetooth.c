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

#include <stdint.h>
#include "ble_gap.h"
#include "bluetooth.h"
#include "error_logging.h"
#include "frame_lua_libraries.h"
#include "lauxlib.h"
#include "lua.h"
#include "luaport.h"

static int lua_bluetooth_address(lua_State *L)
{
    ble_gap_addr_t addr;
    check_error(sd_ble_gap_addr_get(&addr));

    char mac_addr_string[18];
    sprintf(mac_addr_string, "%02x:%02x:%02x:%02x:%02x:%02x",
            addr.addr[0], addr.addr[1], addr.addr[2],
            addr.addr[3], addr.addr[4], addr.addr[5]);

    lua_pushstring(L, mac_addr_string);
    return 1;
}

static int lua_bluetooth_max_length(lua_State *L)
{
    // -1 because we need to add the data flag at the start
    lua_pushinteger(L, ble_negotiated_mtu - 1);
    return 1;
}

static int lua_bluetooth_send(lua_State *L)
{
    luaL_checkstring(L, 1);

    size_t length;
    const char *string = lua_tolstring(L, 1, &length);

    if (length + 1 > ble_negotiated_mtu)
    {
        return luaL_error(L, "string length is greater than max_length()");
    }

    uint8_t data[length + 1];
    memset(data, 1, 0x01);
    memcpy(data + 1, string, length);

    bool fail = bluetooth_send_data(data, length + 1);

    if (fail)
    {
        return luaL_error(L, "bluetooth is busy");
    }

    return 0;
}

static struct lua_bluetooth_callback
{
    int function;
    uint8_t data[BLE_PREFERRED_MAX_MTU];
    size_t length;
} lua_bluetooth_callback = {
    .function = 0,
};

static void lua_bluetooth_receive_callback_handler(lua_State *L, lua_Debug *ar)
{
    lua_sethook(L, NULL, 0, 0);

    lua_rawgeti(L, LUA_REGISTRYINDEX, lua_bluetooth_callback.function);

    lua_pushlstring(L,
                    (char *)lua_bluetooth_callback.data,
                    lua_bluetooth_callback.length);

    lua_pcall(L, 1, 0, 0);
}

void lua_bluetooth_data_interrupt(uint8_t *data, size_t length)
{
    if (lua_bluetooth_callback.function == 0)
    {
        return;
    }

    memcpy(lua_bluetooth_callback.data, data, length);
    lua_bluetooth_callback.length = length;

    lua_sethook(L_global,
                lua_bluetooth_receive_callback_handler,
                LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT,
                1);
}

static int lua_bluetooth_receive_callback(lua_State *L)
{
    if (lua_isnil(L, 1))
    {
        lua_bluetooth_callback.function = 0;
        return 0;
    }

    if (lua_isfunction(L, 1))
    {
        lua_bluetooth_callback.function = luaL_ref(L, LUA_REGISTRYINDEX);
        return 0;
    }

    luaL_error(L, "expected nil or function");

    return 0;
}

void lua_open_bluetooth_library(lua_State *L)
{
    lua_getglobal(L, "frame");

    lua_newtable(L);

    lua_pushcfunction(L, lua_bluetooth_address);
    lua_setfield(L, -2, "address");

    lua_pushcfunction(L, lua_bluetooth_max_length);
    lua_setfield(L, -2, "max_length");

    lua_pushcfunction(L, lua_bluetooth_send);
    lua_setfield(L, -2, "send");

    lua_pushcfunction(L, lua_bluetooth_receive_callback);
    lua_setfield(L, -2, "receive_callback");

    lua_setfield(L, -2, "bluetooth");

    lua_pop(L, 1);
}