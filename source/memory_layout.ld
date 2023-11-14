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

/*
 * Flash layout:
 * |---------------------|   0x100000 
 * | Bootloader Settings |
 * |---------------------|    0xFF000 
 * | MBR Parameters      |
 * |---------------------|    0xFE000
 * | Bootloader          |
 * |---------------------|    0xF5000
 * | File System         |
 * |---------------------|   variable
 * | Application         |
 * |---------------------|    0x27000
 * | Softdevice          |
 * |---------------------|        0x0
 * 
 * Ram layout:
 * |---------------------| 0x20040000
 * | App or Bootloader   |
 * |---------------------|   variable
 * | Softdevice          |
 * |---------------------| 0x20000000
 */

ENTRY(Reset_Handler)

MEMORY
{
    APPLICATION_FLASH (rx) :      ORIGIN = 0x27000,    LENGTH = 0xCE000
    APPLICATION_RAM (rwx) :       ORIGIN = 0x20002a08, LENGTH = 256K - 0x2a08

    BOOTLOADER_FLASH (rx) :       ORIGIN = 0xF5000,    LENGTH = 0x9000
    BOOTLOADER_RAM (rwx) :        ORIGIN = 0x20020000, LENGTH = 128k
    
    MBR_PARAMETERS (r) :          ORIGIN = 0x000FE000, LENGTH = 0x1000
    BOOTLOADER_SETTINGS (r) :     ORIGIN = 0x000FF000, LENGTH = 0x1000
    UICR_BOOTLOADER_ADDRESS (r) : ORIGIN = 0x10001014, LENGTH = 0x4
    UICR_MBR_PARAMETERS (r) :     ORIGIN = 0x10001018, LENGTH = 0x4
}

ASSERT(
    ORIGIN(APPLICATION_FLASH) + 
    LENGTH(APPLICATION_FLASH) + 
    LENGTH(BOOTLOADER_FLASH) + 
    LENGTH(MBR_PARAMETERS) + 
    LENGTH(BOOTLOADER_SETTINGS) == 1M, "Invalid flash lengths")

ASSERT(
    ORIGIN(APPLICATION_RAM) + 
    LENGTH(APPLICATION_RAM) == 0x20040000, "Invalid application ram length")

ASSERT(
    ORIGIN(BOOTLOADER_RAM) + 
    LENGTH(BOOTLOADER_RAM) == 0x20040000, "Invalid bootloader ram length")