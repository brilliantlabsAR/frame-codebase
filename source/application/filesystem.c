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

#include <stdbool.h>
#include <stdint.h>
#include "error_logging.h"
#include "main.h"
#include "nrfx_log.h"
#include "nrf_soc.h"
#include "lfs.h"
#include "filesystem.h"

lfs_t lfs;
lfs_file_t file;
#define FILE_OPEN_MAX (10)
extern uint32_t __empty_flash_start;
extern uint32_t __empty_flash_end;
static uint32_t empty_flash_start = (uint32_t)&__empty_flash_start;
static uint32_t empty_flash_end = (uint32_t)&__empty_flash_end;
static int current_opened_file_index = 0;
static lfs_file_t file_handlers[FILE_OPEN_MAX];
static volatile bool flash_is_busy = false;

void filesystem_flash_event_handler(bool success)
{
    flash_is_busy = false;
}

void filesystem_flash_erase_page(uint32_t address)
{
    if (address % NRF_FICR->CODEPAGESIZE)
    {
        error_with_message("Address not aligned to page boundary");
    }

    check_error(sd_flash_page_erase(address / NRF_FICR->CODEPAGESIZE));
    flash_is_busy = true;
}

void filesystem_flash_write(uint32_t address,
                            const uint32_t *data,
                            size_t length)
{
    check_error(sd_flash_write((uint32_t *)address, data, length));
    flash_is_busy = true;
}

void filesystem_flash_wait_until_complete(void)
{
    // TODO add a timeout
    while (flash_is_busy)
    {
    }
}

static int lfs_api_read_blk(const struct lfs_config *c, lfs_block_t block,
                            lfs_off_t off, void *buffer, lfs_size_t size)
{
    uint32_t addr = empty_flash_start + (block * c->block_size) + off;
    memcpy(buffer, (void *)addr, size);
    return 0;
}
static inline uint32_t rotate_left(uint32_t value, uint32_t shift)
{
    return (value << shift) | (value >> (32 - shift));
}
void flash_write_byte(uint32_t address, uint8_t b)
{
    uint32_t address_aligned = address & ~3;

    // Value to write - leave all bits that should not change at 0xff.
    uint32_t value = 0xffffff00 | b;

    // Rotate bits in value to an aligned position.
    value = rotate_left(value, (address & 3) * 8);

    check_error(sd_flash_write((uint32_t *)address_aligned, &value, 1));
    flash_is_busy = true;
}
static int lfs_api_prog_blk(const struct lfs_config *c, lfs_block_t block,
                            lfs_off_t off, const void *buffer, lfs_size_t size)
{
    uint32_t addr = empty_flash_start + (block * c->block_size) + off;
    const uint8_t *src = buffer;
    const uint8_t *src_end = src + size;

    while (src != src_end && (addr & 0b11))
    {

        flash_write_byte(addr, *src);
        filesystem_flash_wait_until_complete();
        addr++;
        src++;
    }
    while (src_end - src >= 4)
    {
        uint8_t buf[4] __attribute__((aligned(4)));
        for (int i = 0; i < 4; i++)
        {
            buf[i] = ((uint8_t *)src)[i];
        }

        filesystem_flash_write(addr, (const uint32_t *)&buf, 1);
        filesystem_flash_wait_until_complete();
        src += 4;
        addr += 4;
    }

    // // Write remaining unaligned bytes.
    while (src != src_end)
    {

        flash_write_byte(addr, *src);
        filesystem_flash_wait_until_complete();

        addr++;
        src++;
    }
    return 0;
}

static int lfs_api_sync_blk(const struct lfs_config *c)
{
    return 0;
}
static int lfs_api_erase_blk(const struct lfs_config *c, lfs_block_t block)
{
    uint32_t addr = empty_flash_start + (block * c->block_size);
    filesystem_flash_erase_page(addr);
    filesystem_flash_wait_until_complete();
    // LOG(" erase addr complete  %08lx", addr);
    return 0;
}
// configuration of the filesystem is provided by this struct
static struct lfs_config cfg = {
    // block device operations
    .read = lfs_api_read_blk,
    .prog = lfs_api_prog_blk,
    .erase = lfs_api_erase_blk,
    .sync = lfs_api_sync_blk,

    // block device configuration
    .read_size = 8,
    .prog_size = 8,
    .cache_size = 32,
    .lookahead_size = 8,
    .block_cycles = 100,
    .name_max = FS_NAME_MAX,
    .file_max = FS_FILE_MAX};

int fs_file_write(const char *file_name)
{
    if (current_opened_file_index >= FILE_OPEN_MAX)
    {
        return 0;
    }
    lfs_file_t f;
    lfs_file_open(&lfs, &f, file_name, LFS_O_RDWR | LFS_O_CREAT);

    file_handlers[current_opened_file_index] = f;
    current_opened_file_index++;
    return current_opened_file_index;
}
// entry point
void filesystem_setup(bool factory_reset)
{

    cfg.block_size = NRF_FICR->CODEPAGESIZE;
    cfg.block_count = (empty_flash_end - empty_flash_start) / NRF_FICR->CODEPAGESIZE;
    // mount the filesystem
    int file_mount_error = lfs_mount(&lfs, &cfg);
    // reformat if we can't mount the filesystem
    // this should only happen on the first boot
    if (factory_reset || file_mount_error != 0)
    {
        check_error(lfs_format(&lfs, &cfg));
        check_error(lfs_mount(&lfs, &cfg));
    }
    // read current count
    uint32_t boot_count = 0;
    lfs_file_open(&lfs, &file, "boot_count", LFS_O_RDWR | LFS_O_CREAT);
    lfs_file_read(&lfs, &file, &boot_count, sizeof(boot_count));

    // update boot count
    boot_count += 1;
    lfs_file_rewind(&lfs, &file);
    lfs_file_write(&lfs, &file, &boot_count, sizeof(boot_count));

    // remember the storage is not updated until the file is closed successfully
    lfs_file_close(&lfs, &file);

    // release any resources we were using
    lfs_unmount(&lfs);

    // print the boot count
    LOG("boot_count: %02lx\n", boot_count);
}