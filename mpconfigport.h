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

#pragma once

#include <alloca.h>
#include "mphalport.h"
#define MICROPY_BANNER_MACHINE "Monocle on nRF52832"

// #define MICROPY_CONFIG_ROM_LEVEL (MICROPY_CONFIG_ROM_LEVEL_CORE_FEATURES)

#define MICROPY_NLR_SETJMP (1)
#define MICROPY_GCREGS_SETJMP (1)

// File handling isn't used so we can path strings short
#define MICROPY_ALLOC_PATH_MAX (64)

#define MICROPY_QSTR_BYTES_IN_HASH (2)

#define MICROPY_PERSISTENT_CODE_LOAD (1)

#define MICROPY_MODULE_BUILTIN_INIT (1)

#define MICROPY_ENABLE_SCHEDULER (1)

#define MICROPY_COMP_MODULE_CONST (1)
#define MICROPY_COMP_TRIPLE_TUPLE_ASSIGN (1)
#define MICROPY_COMP_RETURN_IF_EXPR (1)

#define MICROPY_ERROR_REPORTING (MICROPY_ERROR_REPORTING_DETAILED)

#define MICROPY_PY_ASYNCIO (1)
#define MICROPY_PY_IO_IOBASE (1)

#define MICROPY_MODULE_WEAK_LINKS (1)

#define MICROPY_PY_SELECT (1)

#define MICROPY_PY_FSTRINGS (1)

#define MICROPY_ENABLE_FINALISER (1)

#define MICROPY_STACK_CHECK (1)

#define MICROPY_KBD_EXCEPTION (1)

#define MICROPY_USE_READLINE (1)
#define MICROPY_USE_READLINE_HISTORY (1)
#define MICROPY_READLINE_HISTORY_SIZE (10)
#define MICROPY_HELPER_REPL (1)
#define MICROPY_REPL_AUTO_INDENT (1)

#define MICROPY_PY_BUILTINS_STR_UNICODE (1)
#define MICROPY_PY_BUILTINS_STR_CENTER (1)
#define MICROPY_PY_BUILTINS_STR_PARTITION (1)
#define MICROPY_PY_BUILTINS_STR_SPLITLINES (1)
#define MICROPY_PY_BUILTINS_ROUND_INT (1)
#define MICROPY_PY_BUILTINS_NOTIMPLEMENTED (1)
#define MICROPY_PY_BUILTINS_HELP (1)
#define MICROPY_PY_BUILTINS_HELP_TEXT help_text
#define MICROPY_PY_BUILTINS_HELP_MODULES (1)
#define MICROPY_PY_BUILTINS_INPUT (1)

// #define MICROPY_QSTR_EXTRA_POOL mp_qstr_frozen_const_pool
#define MICROPY_PY_BUILTINS_FROZENSET (1)

#define MICROPY_ENABLE_GC (1)

#define MICROPY_PY_BUILTINS_COMPLEX (0)
#define MICROPY_FLOAT_IMPL (MICROPY_FLOAT_IMPL_FLOAT)
#define MICROPY_LONGINT_IMPL (MICROPY_LONGINT_IMPL_MPZ)
#define MP_NEED_LOG2 (1)

#define MICROPY_PY_BINASCII (1)
#define MICROPY_PY_BINASCII_CRC32 (1)

#define MICROPY_PY_SYS_STDFILES (1)

#define MICROPY_PY_ERRNO (1)

#define MICROPY_PY_HASHLIB (1)

#define MICROPY_PY_JSON (1)

#define MICROPY_PY_OS (1)
// #define MICROPY_VFS (1)
// #define MICROPY_VFS_LFS2 (1)
// #define MICROPY_READER_VFS (1)

#define MICROPY_PY_RANDOM (1)
#define MICROPY_PY_RANDOM_EXTRA_FUNCS (1)
#define MICROPY_PY_RANDOM_SEED_INIT_FUNC (mp_hal_generate_random_seed())

#define MICROPY_PY_RE (1)
#define MICROPY_PY_RE_SUB (1)
#define MICROPY_PY_HEAPQ (1)

#define MICROPY_PY_TIME (1)
// #define MICROPY_PY_TIME_INCLUDEFILE "../modules/time.c"

#define MICROPY_MAKE_POINTER_CALLABLE(p) ((void *)((mp_uint_t)(p) | 1))

#define MICROPY_EPOCH_IS_1970 (1)

#define MP_SSIZE_MAX (0x7fffffff)
// const char *readline_hist[(10)];
#define MP_STATE_PORT MP_STATE_VM
void mp_event_poll_hook(void);
#define MICROPY_EVENT_POLL_HOOK mp_event_poll_hook();