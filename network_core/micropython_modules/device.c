/*
 * This file is a part https://github.com/brilliantlabsAR/frame-micropython
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

#include <stdio.h>
#include <math.h>
#include "genhdr/mpversion.h"
#include "py/mphal.h"
#include "py/objstr.h"
#include "py/runtime.h"

STATIC const MP_DEFINE_STR_OBJ(device_name_obj, "frame");

STATIC const MP_DEFINE_STR_OBJ(device_version_obj, BUILD_VERSION);

STATIC const MP_DEFINE_STR_OBJ(device_git_tag_obj, GIT_COMMIT);

STATIC const MP_DEFINE_STR_OBJ(
    device_git_repo_obj, "https://github.com/brilliantlabsAR/frame-micropython");

STATIC mp_obj_t device_mac_address(void)
{
    return mp_const_notimplemented;
}
MP_DEFINE_CONST_FUN_OBJ_0(device_mac_address_obj, device_mac_address);

STATIC mp_obj_t device_battery_level(void)
{
    return mp_const_notimplemented;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(device_battery_level_obj, device_battery_level);

STATIC mp_obj_t device_reset(void)
{
    return mp_const_notimplemented;
}
MP_DEFINE_CONST_FUN_OBJ_0(device_reset_obj, &device_reset);

STATIC mp_obj_t device_reset_cause(void)
{
    return mp_const_notimplemented;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(device_reset_cause_obj, device_reset_cause);

STATIC mp_obj_t device_prevent_sleep(size_t n_args, const mp_obj_t *args)
{
    return mp_const_notimplemented;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_VAR_BETWEEN(device_prevent_sleep_obj, 0, 1, device_prevent_sleep);

STATIC mp_obj_t device_force_sleep(void)
{
    return mp_const_notimplemented;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(device_force_sleep_obj, device_force_sleep);

STATIC mp_obj_t device_is_charging(void)
{
    return mp_const_notimplemented;
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
    // {MP_ROM_QSTR(MP_QSTR_Storage), MP_ROM_PTR(&device_storage_type)},
};
STATIC MP_DEFINE_CONST_DICT(device_module_globals, device_module_globals_table);

const mp_obj_module_t device_module = {
    .base = {&mp_type_module},
    .globals = (mp_obj_dict_t *)&device_module_globals,
};

MP_REGISTER_MODULE(MP_QSTR_device, device_module);
