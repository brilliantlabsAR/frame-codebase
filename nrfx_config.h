/*
 * This file is part of the MicroPython for Frame project:
 *      https://github.com/brilliantlabsAR/frame-micropython
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
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

#define NRFX_CONFIG_H__
#include "nrfx/templates/nrfx_config_common.h"

#ifdef NRF5340_XXAA_APPLICATION
#define NRFX_CLOCK_ENABLED 1
#define NRFX_CLOCK_CONFIG_HFCLK192M_SRC 1
#define NRFX_GPIOTE_ENABLED 1
#define NRFX_SAADC_ENABLED 1
#define NRFX_IPC_ENABLED 1
#include "nrfx/templates/nrfx_config_nrf5340_application.h"
#endif

#ifdef NRF5340_XXAA_NETWORK
#define NRFX_RTC_ENABLED 1
#define NRFX_RTC0_ENABLED 1
#define NRFX_TWIM_ENABLED 1
#define NRFX_TWIM0_ENABLED 1
#define NRFX_SPIM_ENABLED 1
#define NRFX_SPIM0_ENABLED 1
#define NRFX_IPC_ENABLED 1
#include "nrfx/templates/nrfx_config_nrf5340_network.h"
#endif