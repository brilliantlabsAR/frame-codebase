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

#include "nrf.h"
#include "nrf_gpio.h"
#include "nrf_oscillators.h"
#include "nrfx_clock.h"
#include "nrfx_gpiote.h"

void clock_event_handler(nrfx_clock_evt_type_t event)
{
    (void)event;
}

void gpiote_interrupt_handler(nrfx_gpiote_pin_t pin,
                              nrfx_gpiote_trigger_t trigger,
                              void *p_context)
{
    NRFX_LOG("Going to sleep");

    NRF_REGULATORS->SYSTEMOFF = 1;
    __DSB();
}

int main(void)
{
    // Start clocks
    app_err(nrfx_clock_init(clock_event_handler));
    nrfx_clock_enable();
    uint32_t capacitance_pf = 7;
    int32_t slope = NRF_FICR->XOSC32MTRIM & 0x1F;
    int32_t trim = (NRF_FICR->XOSC32MTRIM >> 5) & 0x1F;
    uint32_t reg_value = (1 + slope / 16) * (capacitance_pf * 2 - 14) + trim;
    nrf_oscillators_hfxo_cap_set(NRF_OSCILLATORS, true, reg_value);
    nrfx_clock_start(NRF_CLOCK_DOMAIN_HFCLK);
    nrfx_clock_start(NRF_CLOCK_DOMAIN_HFCLK192M);
    nrfx_clock_start(NRF_CLOCK_DOMAIN_LFCLK);

    // Configure case detect pin falling edge as wakeup
    app_err(nrfx_gpiote_init(NRFX_GPIOTE_DEFAULT_CONFIG_IRQ_PRIORITY));
    nrfx_gpiote_input_config_t input_config = {.pull = NRF_GPIO_PIN_PULLUP};
    nrfx_gpiote_trigger_config_t trigger_config = {.trigger = NRFX_GPIOTE_TRIGGER_LOTOHI, .p_in_channel = NULL};
    nrfx_gpiote_handler_config_t handler_config = {.handler = gpiote_interrupt_handler, .p_context = NULL};
    app_err(nrfx_gpiote_input_configure(30, &input_config, &trigger_config, &handler_config));

    // Turn on the network core
    NRF_SPU_S->EXTDOMAIN[0].PERM = 2 | (1 << 4);
    NRF_RESET_S->NETWORK.FORCEOFF = 0;
    nrf_gpio_pin_control_select(NRF_GPIO_PIN_MAP(0, 30), NRF_GPIO_PIN_SEL_NETWORK);

    NRFX_LOG("Hello from application core");

    // Should never return from system off. This is just for debug mode
    while (1)
    {
    }
}