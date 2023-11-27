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

#include <stdio.h>
#include <sys/cdefs.h>
#include <sys/times.h>
#include <sys/types.h>
#include <sys/time.h>
#include "SEGGER_RTT.h"

clock_t times(struct tms *buf)
{
    buf->tms_stime = buf->tms_cstime = buf->tms_cutime = 0;
    return buf->tms_utime = (clock_t)NULL;
}

int gettimeofday(struct timeval *restrict tv, void *restrict tz)
{
    return 0;
}

int open(const char *pathname, int flags, ...)
{
    return 0;
}

int close(int fd)
{
    return 0;
}

ssize_t write(int fd, const void *buf, size_t count)
{
    (void)fd; /* Not used, avoid warning */
    SEGGER_RTT_Write(0, buf, count);
    return count;
}

ssize_t read(int fd, void *buf, size_t count)
{
    return 0;
}

off_t lseek(int fd, off_t offset, int whence)
{
    return 0;
}

int rename(const char *old, const char *new)
{
    return 0;
}

int unlink(const char *pathname)
{
    return 0;
}

void _ATTRIBUTE((__noreturn__)) _exit(int code)
{
    (void)code;
    for (;;)
        ;
}

static int dummy_putc(char c, FILE *file)
{
    SEGGER_RTT_Write(0, &c, 1);
    return (unsigned char)c;
}

static int dummy_getc(FILE *file)
{
    (void)file;
    return EOF;
}

static int dummy_flush(FILE *file)
{
    (void)file;
    return 0;
}

static FILE __stdio = FDEV_SETUP_STREAM(dummy_putc, dummy_getc, dummy_flush, _FDEV_SETUP_RW);

FILE *const stdin = &__stdio;
FILE *const stdout = &__stdio;
FILE *const stderr = &__stdio;
