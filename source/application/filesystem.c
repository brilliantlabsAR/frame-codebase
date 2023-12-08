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
#include "filesystem.h"
#include "lfs.h"
#include "main.h"
#include "nrf_soc.h"
#include "nrfx_log.h"

extern uint32_t __empty_flash_start;
extern uint32_t __empty_flash_end;

static uint32_t empty_flash_start = (uint32_t)&__empty_flash_start;
static uint32_t empty_flash_end = (uint32_t)&__empty_flash_end;

static volatile bool flash_is_busy = false;

static lfs_t little_fs;

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

static int lfs_api_read_blk(const struct lfs_config *c,
                            lfs_block_t block,
                            lfs_off_t off,
                            void *buffer,
                            lfs_size_t size)
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

static int lfs_api_prog_blk(const struct lfs_config *c,
                            lfs_block_t block,
                            lfs_off_t off,
                            const void *buffer,
                            lfs_size_t size)
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

    //  Write remaining unaligned bytes.
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
    return 0;
}

lfs_file_t *fs_file_open(const char *file_name, int mode)
{
    static lfs_file_t f;
    int err = lfs_file_open(&little_fs, &f, file_name, mode);
    return err == 0 ? &f : NULL;
}

int fs_file_close(lfs_file_t *file)
{
    return lfs_file_close(&little_fs, file);
}

int32_t fs_file_write(lfs_file_t *file, const char *content)
{
    int32_t err = lfs_file_write(&little_fs, file, content, strlen(content));

    return err;
}

int32_t fs_file_read(lfs_file_t *file, char *buff, size_t l)
{
    return lfs_file_read(&little_fs, file, buff, l);
}

int32_t fs_file_seek(lfs_file_t *file, long off, int whence)
{
    return lfs_file_seek(&little_fs, file, off, whence);
}

int fs_file_remove(const char *path)
{
    return lfs_remove(&little_fs, path);
}

int fs_file_raname(const char *oldpath, const char *newpath)
{
    return lfs_rename(&little_fs, oldpath, newpath);
}

int fs_dir_mkdir(const char *path)
{
    int err = lfs_mkdir(&little_fs, path);
    if (err >= 0)
    {
        // check_error(lfs_fo(&little_fs, file));
    }
    return err;
}

lfs_dir_t *fs_dir_open(const char *path)
{
    static lfs_dir_t dir;
    int err = lfs_dir_open(&little_fs, &dir, path);
    return err >= 0 ? &dir : NULL;
}

int fs_dir_close(lfs_dir_t *dir)
{
    return lfs_dir_close(&little_fs, dir);
}

int fs_dir_read(lfs_dir_t *dir, struct lfs_info *info)
{
    return lfs_dir_read(&little_fs, dir, info);
}

void filesystem_setup(bool factory_reset)
{
    struct lfs_config config = {
        .read = lfs_api_read_blk,
        .prog = lfs_api_prog_blk,
        .erase = lfs_api_erase_blk,
        .sync = lfs_api_sync_blk,
        .read_size = 8,
        .prog_size = 8,
        .cache_size = 32,
        .lookahead_size = 8,
        .block_cycles = 100,
        .name_max = FS_NAME_MAX,
        .file_max = FS_FILE_MAX,
    };

    config.block_size = NRF_FICR->CODEPAGESIZE;
    config.block_count = ((empty_flash_end - empty_flash_start) / NRF_FICR->CODEPAGESIZE) - 1;
    int file_mount_error = lfs_mount(&little_fs, &config);

    if (factory_reset || file_mount_error != 0)
    {
        check_error(lfs_format(&little_fs, &config));
        check_error(lfs_mount(&little_fs, &config));
    }
}