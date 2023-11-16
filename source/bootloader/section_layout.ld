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

__min_heap_size = 4K;
__stack_size = 4K;

SECTIONS
{
    .uicr_bootloader_start_address : {
        . = ALIGN(4);
        PROVIDE(__start_uicr_bootloader_start_address = .);
        KEEP(*(SORT(.uicr_bootloader_start_address*)))
        PROVIDE(__stop_uicr_bootloader_start_address = .);
    } > UICR_BOOTLOADER_ADDRESS

    .bootloader_settings_page (NOLOAD) : {
        . = ALIGN(4);
        PROVIDE(__start_bootloader_settings_page = .);
        KEEP(*(SORT(.bootloader_settings_page*)))
        PROVIDE(__stop_bootloader_settings_page = .);
    } > BOOTLOADER_SETTINGS

    .uicr_mbr_params_page : {
        . = ALIGN(4);
        PROVIDE(__start_uicr_mbr_params_page = .);
        KEEP(*(SORT(.uicr_mbr_params_page*)))
        PROVIDE(__stop_uicr_mbr_params_page = .);
    } > UICR_MBR_PARAMETERS

    .mbr_params_page (NOLOAD) : {
        . = ALIGN(4);
        PROVIDE(__start_mbr_params_page = .);
        KEEP(*(SORT(.mbr_params_page*)))
        PROVIDE(__stop_mbr_params_page = .);
    } > MBR_PARAMETERS
}

SECTIONS
{
    .mem_section_dummy_ram : {
        . = ALIGN(4);
    }

    .log_dynamic_data : {
        PROVIDE(__start_log_dynamic_data = .);
        KEEP(*(SORT(.log_dynamic_data*)))
        PROVIDE(__stop_log_dynamic_data = .);
    } > BOOTLOADER_RAM
    
    .log_filter_data : {
        PROVIDE(__start_log_filter_data = .);
        KEEP(*(SORT(.log_filter_data*)))
        PROVIDE(__stop_log_filter_data = .);
    } > BOOTLOADER_RAM

    .fs_data : {
        PROVIDE(__start_fs_data = .);
        KEEP(*(.fs_data))
        PROVIDE(__stop_fs_data = .);
    } > BOOTLOADER_RAM
} INSERT AFTER .data;

SECTIONS
{
    .mem_section_dummy_rom : {
    }

    .crypto_data : {
        PROVIDE(__start_crypto_data = .);
        KEEP(*(SORT(.crypto_data*)))
        PROVIDE(__stop_crypto_data = .);
    } > BOOTLOADER_FLASH

    .nrf_queue : {
        PROVIDE(__start_nrf_queue = .);
        KEEP(*(.nrf_queue))
        PROVIDE(__stop_nrf_queue = .);
    } > BOOTLOADER_FLASH

    .dfu_trans : {
        PROVIDE(__start_dfu_trans = .);
        KEEP(*(SORT(.dfu_trans*)))
        PROVIDE(__stop_dfu_trans = .);
    } > BOOTLOADER_FLASH

    .svc_data : {
        PROVIDE(__start_svc_data = .);
        KEEP(*(.svc_data))
        PROVIDE(__stop_svc_data = .);
    } > BOOTLOADER_FLASH

    .log_const_data : {
        PROVIDE(__start_log_const_data = .);
        KEEP(*(SORT(.log_const_data*)))
        PROVIDE(__stop_log_const_data = .);
    } > BOOTLOADER_FLASH

    .nrf_balloc : {
        PROVIDE(__start_nrf_balloc = .);
        KEEP(*(.nrf_balloc))
        PROVIDE(__stop_nrf_balloc = .);
    } > BOOTLOADER_FLASH

    .sdh_ble_observers : {
        PROVIDE(__start_sdh_ble_observers = .);
        KEEP(*(SORT(.sdh_ble_observers*)))
        PROVIDE(__stop_sdh_ble_observers = .);
    } > BOOTLOADER_FLASH

    .log_backends : {
        PROVIDE(__start_log_backends = .);
        KEEP(*(SORT(.log_backends*)))
        PROVIDE(__stop_log_backends = .);
    } > BOOTLOADER_FLASH

    .sdh_req_observers : {
        PROVIDE(__start_sdh_req_observers = .);
        KEEP(*(SORT(.sdh_req_observers*)))
        PROVIDE(__stop_sdh_req_observers = .);
    } > BOOTLOADER_FLASH

    .sdh_state_observers : {
        PROVIDE(__start_sdh_state_observers = .);
        KEEP(*(SORT(.sdh_state_observers*)))
        PROVIDE(__stop_sdh_state_observers = .);
    } > BOOTLOADER_FLASH

    .sdh_stack_observers : {
        PROVIDE(__start_sdh_stack_observers = .);
        KEEP(*(SORT(.sdh_stack_observers*)))
        PROVIDE(__stop_sdh_stack_observers = .);
    } > BOOTLOADER_FLASH

    .sdh_soc_observers : {
        PROVIDE(__start_sdh_soc_observers = .);
        KEEP(*(SORT(.sdh_soc_observers*)))
        PROVIDE(__stop_sdh_soc_observers = .);
    } > BOOTLOADER_FLASH
} INSERT AFTER .text

SECTIONS
{
    .text : {
        . = ALIGN(4);
        __isr_vector = .;
        KEEP(*(.isr_vector))
        *(.text .text* .gnu.linkonce.t.*)
        *(.rodata .rodata* .gnu.linkonce.r.*)
        . = ALIGN(4);
    } > BOOTLOADER_FLASH

    .ARM.extab : {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > BOOTLOADER_FLASH

    .ARM.exidx : {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > BOOTLOADER_FLASH

    .data : {
        . = ALIGN(4);
        __data_start = .;
        __data_start__ = .;
        __ram_start = .;
        *(.ramfunc .ramfunc.*);
        *(.data .data.*);
        . = ALIGN(4);
        __data_end = .;
    } > BOOTLOADER_RAM AT> BOOTLOADER_FLASH

    __init_data_start = LOADADDR(.data);

    .bss : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss .bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > BOOTLOADER_RAM

	.stack (NOLOAD) : {
        . = ALIGN(8);
        __stack_bottom = .;
		. += __stack_size;
        . = ALIGN(8);
        __stack_top = .;
	} > BOOTLOADER_RAM

    . = ALIGN(4);
    PROVIDE(__heap_start = .);
    PROVIDE(__heap_end = ORIGIN(BOOTLOADER_RAM) + LENGTH(BOOTLOADER_RAM));
}

ASSERT(__heap_end - __heap_start >= __min_heap_size, "heap has become too small")
