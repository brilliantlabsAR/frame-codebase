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

#include "py/builtin.h"
#include "py/mperrno.h"
#include "py/lexer.h"
#include "py/runtime.h"
#include "mpconfigport.h"
// #include "nrfx_rtc.h"

const char help_text[] = {
    "Welcome to MicroPython!\n\n"
    "For full documentation, visit: https://docs.brilliant.xyz\n"
    "Control commands:\n"
    "  Ctrl-A - enter raw REPL mode\n"
    "  Ctrl-B - enter normal REPL mode\n"
    "  Ctrl-C - interrupt a running program\n"
    "  Ctrl-D - reset the device\n"
    "  Ctrl-E - enter paste mode\n\n"
    "To list available modules, type help('modules')\n"
    "For details on a specific module, import it, and then type "
    "help(module_name)\n"};

// static nrfx_rtc_t rtc = NRFX_RTC_INSTANCE(1);

uint64_t mp_hal_time_ns(void)
{
    return 0;
}

mp_uint_t mp_hal_ticks_us(void)
{
    return 0;
}

mp_uint_t mp_hal_ticks_ms(void)
{
    // uint32_t value = nrfx_rtc_counter_get(&rtc);

    // Correct for the slightly faster tick frequency of 1024Hz
    float ms = 1024 * 1000;

    return (mp_uint_t)ms;
}

mp_uint_t mp_hal_ticks_cpu(void)
{
    // This doesn't seem to be used by anything so it's not implemented
    return 0;
}

void mp_hal_delay_us(mp_uint_t us)
{
    (void)us;
    return;
}

void mp_hal_delay_ms(mp_uint_t ms)
{
    uint32_t start_time = mp_hal_ticks_ms();

    while (mp_hal_ticks_ms() - start_time < ms)
    {
        MICROPY_EVENT_POLL_HOOK;
    }
}

int mp_hal_generate_random_seed(void)
{
    return 0;
}
