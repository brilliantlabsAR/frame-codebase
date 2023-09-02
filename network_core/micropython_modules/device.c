/*
 * This file is part of the MicroPython for Monocle project:
 *      https://github.com/brilliantlabsAR/monocle-micropython
 *
 * Authored by: Josuah Demangeon (me@josuah.net)
 *              Raj Nakarja / Brilliant Labs Ltd. (raj@itsbrilliant.co)
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

#include <stdio.h>
#include <math.h>
#include "genhdr/mpversion.h"
#include "py/mphal.h"
#include "py/objstr.h"
#include "py/runtime.h"
#include "nrfx_saadc.h"

STATIC const MP_DEFINE_STR_OBJ(device_name_obj, "monocle");

STATIC const MP_DEFINE_STR_OBJ(device_version_obj, BUILD_VERSION);

STATIC const MP_DEFINE_STR_OBJ(device_git_tag_obj, MICROPY_GIT_HASH);

STATIC const MP_DEFINE_STR_OBJ(
    device_git_repo_obj, "https://github.com/brilliantlabsAR/monocle-micropython");

STATIC mp_obj_t device_mac_address(void)
{
    ble_gap_addr_t addr;
    app_err(sd_ble_gap_addr_get(&addr));

    char mac_addr_string[18];
    sprintf(mac_addr_string, "%02x:%02x:%02x:%02x:%02x:%02x",
            addr.addr[0], addr.addr[1], addr.addr[2],
            addr.addr[3], addr.addr[4], addr.addr[5]);

    return mp_obj_new_str(mac_addr_string, 17);
}
MP_DEFINE_CONST_FUN_OBJ_0(device_mac_address_obj, device_mac_address);

STATIC mp_obj_t device_battery_level(void)
{
    nrf_saadc_value_t result;
    app_err(nrfx_saadc_simple_mode_set(1,
                                       NRF_SAADC_RESOLUTION_10BIT,
                                       NRF_SAADC_OVERSAMPLE_DISABLED,
                                       NULL));
    app_err(nrfx_saadc_buffer_set(&result, 1));

    app_err(nrfx_saadc_mode_trigger());

    // V = (raw / 10bits) * Vref * (1/NRFgain) * AMUXgain
    float voltage = ((float)result / 1024.0f) * 0.6f * 2.0f * (4.5f / 1.25f);

    // Percentage is based on a polynomial. Details in tools/battery-model
    float percentage = roundf(-118.13699f * powf(voltage, 3.0f) +
                              1249.63556f * powf(voltage, 2.0f) -
                              4276.33059f * voltage +
                              4764.47488f);

    if (percentage < 0.0f)
    {
        percentage = 0.0f;
    }

    if (percentage > 100.0f)
    {
        percentage = 100.0f;
    }

    return mp_obj_new_int_from_uint((uint8_t)percentage);
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(device_battery_level_obj, device_battery_level);

STATIC mp_obj_t device_reset(void)
{
    // Never reset if not connected to prevent locking out the user
    if (!ble_are_tx_notifications_enabled(REPL_TX))
    {
        return mp_const_none;
    }

    // Delay so the user can cancel a reset if this runs from main.py
    mp_printf(&mp_plat_print, "Resetting");
    mp_hal_delay_ms(1000);
    mp_printf(&mp_plat_print, ".");
    mp_hal_delay_ms(1000);
    mp_printf(&mp_plat_print, ".");
    mp_hal_delay_ms(1000);

    // Clear the reset reasons
    NRF_POWER->RESETREAS = 0xF000F;

    NVIC_SystemReset();
}
MP_DEFINE_CONST_FUN_OBJ_0(device_reset_obj, &device_reset);

STATIC mp_obj_t device_reset_cause(void)
{
    uint32_t reset_reason = NRF_POWER->RESETREAS;

    if (reset_reason & (POWER_RESETREAS_DOG_Msk | POWER_RESETREAS_LOCKUP_Msk))
    {
        return MP_OBJ_NEW_QSTR(MP_QSTR_CRASHED);
    }

    if (reset_reason & POWER_RESETREAS_SREQ_Msk)
    {
        return MP_OBJ_NEW_QSTR(MP_QSTR_SOFTWARE_RESET);
    }

    // TODO this will never happen because of our logic
    return MP_OBJ_NEW_QSTR(MP_QSTR_POWERON);
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(device_reset_cause_obj, device_reset_cause);

STATIC mp_obj_t device_prevent_sleep(size_t n_args, const mp_obj_t *args)
{
    if (n_args == 0)
    {
        return mp_obj_new_bool(prevent_sleep_flag);
    }

    prevent_sleep_flag = mp_obj_is_true(args[0]);

    if (prevent_sleep_flag)
    {
        mp_printf(&mp_plat_print,
                  "WARNING: Running monocle for prolonged periods may result in"
                  " display burn in, as well as reduced lifetime of components."
                  "\n");
    }

    return mp_const_none;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_VAR_BETWEEN(device_prevent_sleep_obj, 0, 1, device_prevent_sleep);

STATIC mp_obj_t device_force_sleep(void)
{
    // Never force sleep if not connected to prevent locking out the user
    if (!ble_are_tx_notifications_enabled(REPL_TX))
    {
        return mp_const_none;
    }

    // Delay so the user can cancel force sleep if this runs from main.py
    mp_printf(&mp_plat_print, "Going to sleep");
    mp_hal_delay_ms(1000);
    mp_printf(&mp_plat_print, ".");
    mp_hal_delay_ms(1000);
    mp_printf(&mp_plat_print, ".");
    mp_hal_delay_ms(1000);

    prevent_sleep_flag = false;

    force_sleep_flag = true;

    return mp_const_none;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(device_force_sleep_obj, device_force_sleep);

STATIC mp_obj_t device_is_charging(void)
{
    // Get the CHG value from STAT_CHG_B
    i2c_response_t charging_response = monocle_i2c_read(PMIC_I2C_ADDRESS, 0x03, 0x0C);
    app_err(charging_response.fail);

    return charging_response.value ? mp_const_true : mp_const_false;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(device_is_charging_obj, device_is_charging);

extern const struct _mp_obj_type_t device_storage_type;

STATIC const mp_rom_map_elem_t device_module_globals_table[] = {

    {MP_ROM_QSTR(MP_QSTR_NAME), MP_ROM_PTR(&device_name_obj)},
    {MP_ROM_QSTR(MP_QSTR_mac_address), MP_ROM_PTR(&device_mac_address_obj)},
    {MP_ROM_QSTR(MP_QSTR_VERSION), MP_ROM_PTR(&device_version_obj)},
    {MP_ROM_QSTR(MP_QSTR_GIT_TAG), MP_ROM_PTR(&device_git_tag_obj)},
    {MP_ROM_QSTR(MP_QSTR_GIT_REPO), MP_ROM_PTR(&device_git_repo_obj)},
    {MP_ROM_QSTR(MP_QSTR_battery_level), MP_ROM_PTR(&device_battery_level_obj)},
    {MP_ROM_QSTR(MP_QSTR_reset), MP_ROM_PTR(&device_reset_obj)},
    {MP_ROM_QSTR(MP_QSTR_reset_cause), MP_ROM_PTR(&device_reset_cause_obj)},
    {MP_ROM_QSTR(MP_QSTR_prevent_sleep), MP_ROM_PTR(&device_prevent_sleep_obj)},
    {MP_ROM_QSTR(MP_QSTR_force_sleep), MP_ROM_PTR(&device_force_sleep_obj)},
    {MP_ROM_QSTR(MP_QSTR_is_charging), MP_ROM_PTR(&device_is_charging_obj)},
    {MP_ROM_QSTR(MP_QSTR_Storage), MP_ROM_PTR(&device_storage_type)},
};
STATIC MP_DEFINE_CONST_DICT(device_module_globals, device_module_globals_table);

const mp_obj_module_t device_module = {
    .base = {&mp_type_module},
    .globals = (mp_obj_dict_t *)&device_module_globals,
};

MP_REGISTER_MODULE(MP_QSTR_device, device_module);
