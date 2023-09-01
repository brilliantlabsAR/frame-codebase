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
#include "error_helpers.h"

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
    return 0;
}

mp_uint_t mp_hal_ticks_cpu(void)
{
    return 0;
}

void mp_hal_delay_us(mp_uint_t us)
{
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

mp_import_stat_t mp_import_stat(const char *path)
{
    // TODO
    return MP_IMPORT_STAT_NO_EXIST;
}

mp_lexer_t *mp_lexer_new_from_file(const char *filename)
{
    // TODO
    mp_raise_OSError(MP_ENOENT);
}

int mp_hal_stdin_rx_chr(void)
{
    // TODO
    return 0;
}

void mp_hal_stdout_tx_strn(const char *str, mp_uint_t len)
{
    // TODO
    NRFX_LOG("Micropython output:\n%s", str);
}

uintptr_t mp_hal_stdio_poll(uintptr_t poll_flags)
{
    // TODO
    // return (repl_rx.head == repl_rx.tail) ? poll_flags & MP_STREAM_POLL_RD : 0;
}

void mp_event_poll_hook(void)
{
    // TODO Keep sending REPL data. Then if no more data is pending
    // if (ble_send_repl_data())
    {
        extern void mp_handle_pending(bool);
        mp_handle_pending(true);
        // TODO __WFI()
    }
}

void gc_collect(void)
{
    gc_collect_start();

    // TODO run the garbage collector

    gc_collect_end();
}

void nlr_jump_fail(void *val)
{
    app_err((uint32_t)val);
}

void run_micropython(void)
{
    mp_stack_set_top(&_stack_top);

    // Set the stack limit as smaller than the real stack so we can recover
    mp_stack_set_limit((char *)&_stack_top - (char *)&_stack_bot - 512);

    gc_init(&_heap_start, &_heap_end);
    mp_init();
    readline_init0();
    pyexec_friendly_repl();

    // // Mount the filesystem, or format if needed
    // pyexec_frozen_module("_mountfs.py", false);
    // pyexec_frozen_module("_splashscreen.py", false);

    // // If safe mode is not enabled, run the user's main.py file
    // monocle_started_in_safe_mode() ? NRFX_LOG("Starting in safe mode")
    //                                : pyexec_file_if_exists("main.py");

    // Stay in the friendly or raw REPL until a reset is called
    for (;;)
    {
        if (pyexec_mode_kind == PYEXEC_MODE_RAW_REPL)
        {
            if (pyexec_raw_repl() != 0)
            {
                break;
            }
        }
        else
        {
            if (pyexec_friendly_repl() != 0)
            {
                break;
            }
        }
    }

    // On exit, clean up before reset
    gc_sweep_all();
    mp_deinit();

    mp_hal_stdout_tx_str("MPY: soft reboot\r\n");
}