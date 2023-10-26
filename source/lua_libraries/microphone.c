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

#include <stdint.h>
#include "error_logging.h"
#include "lua.h"
#include "nrfx_config.h"
#include "nrfx_pdm.h"
#include "pinout.h"

static void pdm_event_handler(nrfx_pdm_evt_t const *p_evt)
{
}

void microphone_open_library(lua_State *L)
{
    nrfx_pdm_config_t config = NRFX_PDM_DEFAULT_CONFIG(MICROPHONE_CLOCK_PIN,
                                                       MICROPHONE_DATA_PIN);
    config.edge = NRF_PDM_EDGE_LEFTRISING;

    if (nrfx_pdm_init_check())
    {
        return;
    }

    check_error(nrfx_pdm_init(&config, pdm_event_handler));
}

void microphone_read(int16_t *buffer, uint32_t samples)
{
    // TODO read multiple samples

    check_error(nrfx_pdm_buffer_set(buffer, samples));

    check_error(nrfx_pdm_start());
}