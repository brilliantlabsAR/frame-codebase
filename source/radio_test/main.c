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
#include "radio_test.h"
#include "error_logging.h"
#include "nrf.h"
#include "nrfx_log.h"

int main(void)
{
    LOG(RTT_CTRL_CLEAR);
    LOG("Starting radio test firmware");

    // Start 64 MHz crystal oscillator.
    NRF_CLOCK->EVENTS_HFCLKSTARTED = 0;
    NRF_CLOCK->TASKS_HFCLKSTART = 1;

    // Wait for the external oscillator to start up.
    while (NRF_CLOCK->EVENTS_HFCLKSTARTED == 0)
    {
    }

    // Configure test mode
    radio_test_config_t radio_test_config;
    memset(&radio_test_config, 0, sizeof(radio_test_config));

    radio_test_config.type = MODULATED_TX;
    radio_test_config.mode = NRF_RADIO_MODE_BLE_1MBIT;

    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_0DBM;
    radio_test_config.params.modulated_tx.pattern = TRANSMIT_PATTERN_RANDOM;
    radio_test_config.params.modulated_tx.channel = 80;
    radio_test_config.params.modulated_tx.packets_num = 0;
    radio_test_config.params.modulated_tx.cb = NULL;

    // Start test
    radio_test_init(&radio_test_config);
    radio_test_start(&radio_test_config);

    LOG("Running");

    while (1)
    {
        __WFE();
    }
}