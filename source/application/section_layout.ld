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

__min_heap_size = 8K;
__stack_size = 8K;

SECTIONS
{
    .text : {
        . = ALIGN(4);
        KEEP(*(.isr_vector))
        *(.text .text* .gnu.linkonce.t.*)
        *(.rodata .rodata* .gnu.linkonce.r.*)
        . = ALIGN(4);
    } > APPLICATION_FLASH

    .ARM.extab : {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > APPLICATION_FLASH

    .ARM.exidx : {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > APPLICATION_FLASH

    .data : {
        . = ALIGN(4);
        __data_start = .;
        __data_start__ = .;
        __ram_start = .;
        *(.ramfunc .ramfunc.*);
        *(.data .data.*);
        . = ALIGN(4);
        __data_end = .;
    } > APPLICATION_RAM AT> APPLICATION_FLASH

    __init_data_start = LOADADDR(.data);

    .bss : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss .bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > APPLICATION_RAM

	.stack (NOLOAD) : {
        . = ALIGN(8);
        __stack_bottom = .;
		. += __stack_size;
        . = ALIGN(8);
        __stack_top = .;
	} > APPLICATION_RAM

    . = ALIGN(4);
    PROVIDE(__heap_start = .);
    PROVIDE(__heap_end = ORIGIN(APPLICATION_RAM) + LENGTH(APPLICATION_RAM));
}

ASSERT(__heap_end - __heap_start >= __min_heap_size, "heap has become too small")
