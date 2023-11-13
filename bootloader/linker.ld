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

ENTRY(Reset_Handler)

MEMORY
{
    FLASH (rx) : 						ORIGIN = 0xF5000, 			LENGTH = 0x9000
    bootloader_settings_page (r) : 		ORIGIN = 0x000FF000, 		LENGTH = 0x1000
    mbr_params_page (r) :				ORIGIN = 0x000FE000, 		LENGTH = 0x1000

    RAM (rwx) :  						ORIGIN = 0x20000000 + 128k, LENGTH = 128k
    uicr_bootloader_start_address (r) : ORIGIN = 0x10001014, 		LENGTH = 0x4
    uicr_mbr_params_page (r) : 			ORIGIN = 0x10001018,		LENGTH = 0x4
}

SECTIONS
{
    /* Program code and other data goes into FLASH */

    .text :
    {
        . = ALIGN(4);
        __isr_vector = .;
        KEEP(*(.isr_vector)) /* Startup code */
        *(.text)             /* .text sections (code) */
        *(.text*)            /* .text* sections (code) */
        *(.rodata)           /* .rodata sections (constants, strings, etc.) */
        *(.rodata*)          /* .rodata* sections (constants, strings, etc.) */
        
        . = ALIGN(4);
        _etext = .;          /* define a global symbol at end of code */
    } > FLASH

    .ARM.exidx :
    {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > FLASH

    /* This is used by the startup to initialize data */
    
    _sidata = LOADADDR(.data);

    /* This is the initialized data section. The program executes knowing that 
       the data is in the RAM but the loader puts the initial values in the 
       FLASH (inidata). It is one task of the startup to copy the initial values 
       from FLASH to RAM. */
    
    .data :
    {
        . = ALIGN(4);
        _sdata = .;        /* create a global symbol at data start; used by startup code in order to initialize the .data section in RAM */
        __data_start__ = .;
        _ram_start = .;    /* create a global symbol at ram start for garbage collector */
        *(.data)           /* .data sections */
        *(.data*)          /* .data* sections */

        . = ALIGN(4);
        _edata = .;        /* define a global symbol at data end; used by startup code in order to initialize the .data section in RAM */
    } > RAM AT> FLASH

    .fs_data :
    {
        PROVIDE(__start_fs_data = .);
        KEEP(*(.fs_data))
        PROVIDE(__stop_fs_data = .);
    } > RAM

    /* Uninitialized data section */

    .bss :
    {
        . = ALIGN(4);
        _sbss = .;         /* define a global symbol at bss start; used by startup code */
        *(.bss)
        *(.bss*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;         /* define a global symbol at bss end; used by startup code and GC */

        PROVIDE(end = .);

    } > RAM

    .ARM.attributes 0 : 
    { 
        *(.ARM.attributes) 
    }
}

SECTIONS
{
    .mem_section_dummy_rom :
    {
    }

    .crypto_data :
    {
        PROVIDE(__start_crypto_data = .);
        KEEP(*(SORT(.crypto_data*)))
        PROVIDE(__stop_crypto_data = .);
    } > FLASH

    .nrf_queue :
    {
        PROVIDE(__start_nrf_queue = .);
        KEEP(*(.nrf_queue))
        PROVIDE(__stop_nrf_queue = .);
    } > FLASH

    .dfu_trans :
    {
        PROVIDE(__start_dfu_trans = .);
        KEEP(*(SORT(.dfu_trans*)))
        PROVIDE(__stop_dfu_trans = .);
    } > FLASH

    .svc_data :
    {
        PROVIDE(__start_svc_data = .);
        KEEP(*(.svc_data))
        PROVIDE(__stop_svc_data = .);
    } > FLASH

    .log_const_data :
    {
        PROVIDE(__start_log_const_data = .);
        KEEP(*(SORT(.log_const_data*)))
        PROVIDE(__stop_log_const_data = .);
    } > FLASH

    .nrf_balloc :
    {
        PROVIDE(__start_nrf_balloc = .);
        KEEP(*(.nrf_balloc))
        PROVIDE(__stop_nrf_balloc = .);
    } > FLASH

    .sdh_ble_observers :
    {
        PROVIDE(__start_sdh_ble_observers = .);
        KEEP(*(SORT(.sdh_ble_observers*)))
        PROVIDE(__stop_sdh_ble_observers = .);
    } > FLASH

    .log_backends :
    {
        PROVIDE(__start_log_backends = .);
        KEEP(*(SORT(.log_backends*)))
        PROVIDE(__stop_log_backends = .);
    } > FLASH

    .sdh_req_observers :
    {
        PROVIDE(__start_sdh_req_observers = .);
        KEEP(*(SORT(.sdh_req_observers*)))
        PROVIDE(__stop_sdh_req_observers = .);
    } > FLASH

    .sdh_state_observers :
    {
        PROVIDE(__start_sdh_state_observers = .);
        KEEP(*(SORT(.sdh_state_observers*)))
        PROVIDE(__stop_sdh_state_observers = .);
    } > FLASH

    .sdh_stack_observers :
    {
        PROVIDE(__start_sdh_stack_observers = .);
        KEEP(*(SORT(.sdh_stack_observers*)))
        PROVIDE(__stop_sdh_stack_observers = .);
    } > FLASH

    .sdh_soc_observers :
    {
        PROVIDE(__start_sdh_soc_observers = .);
        KEEP(*(SORT(.sdh_soc_observers*)))
        PROVIDE(__stop_sdh_soc_observers = .);
    } > FLASH
}

SECTIONS
{
    . = ALIGN(4);
    .uicr_bootloader_start_address :
    {
        PROVIDE(__start_uicr_bootloader_start_address = .);
        KEEP(*(SORT(.uicr_bootloader_start_address*)))
        PROVIDE(__stop_uicr_bootloader_start_address = .);
    } > uicr_bootloader_start_address

    . = ALIGN(4);
    .bootloader_settings_page(NOLOAD) :
    {
        PROVIDE(__start_bootloader_settings_page = .);
        KEEP(*(SORT(.bootloader_settings_page*)))
        PROVIDE(__stop_bootloader_settings_page = .);
    } > bootloader_settings_page

    . = ALIGN(4);
    .uicr_mbr_params_page :
    {
        PROVIDE(__start_uicr_mbr_params_page = .);
        KEEP(*(SORT(.uicr_mbr_params_page*)))
        PROVIDE(__stop_uicr_mbr_params_page = .);
    } > uicr_mbr_params_page

    . = ALIGN(4);
    .mbr_params_page(NOLOAD) :
    {
        PROVIDE(__start_mbr_params_page = .);
        KEEP(*(SORT(.mbr_params_page*)))
        PROVIDE(__stop_mbr_params_page = .);
    } > mbr_params_page
}

_stack_top = ORIGIN(RAM) + LENGTH(RAM);
