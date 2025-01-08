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

#pragma once

#define NRFX_CONFIG_H__
#include "templates/nrfx_config_common.h"

#define NRFX_GPIOTE_CONFIG_NUM_OF_EVT_HANDLERS 15
#define NRFX_GPIOTE_ENABLED 1

#define NRFX_PDM_ENABLED 1
#define NRFX_PDM_DEFAULT_CONFIG_IRQ_PRIORITY 5

#define NRFX_PWM_ENABLED 1
#define NRFX_PWM0_ENABLED 1
#define NRFX_PWM1_ENABLED 1
#define NRFX_PWM2_ENABLED 1

#define NRFX_RTC_ENABLED 1
#define NRFX_RTC1_ENABLED 1

#define NRFX_SAADC_ENABLED 1

#define NRFX_SPIM_ENABLED 1
#define NRFX_SPIM1_ENABLED 1
#define NRFX_SPIM2_ENABLED 1

#define NRFX_SYSTICK_ENABLED 1

#define NRFX_TWIM_ENABLED 1
#define NRFX_TWIM0_ENABLED 1

#define NRFX_WDT_ENABLED 1

#include "templates/nrfx_config_nrf52840.h"
