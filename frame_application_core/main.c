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

#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "nrf_gpio.h"
#include "nrf_oscillators.h"
#include "nrf.h"
#include "nrfx_clock.h"
#include "nrfx_gpiote.h"
#include "nrfx_log.h"
#include "pinout.h"

static void unused_clock_event_handler(nrfx_clock_evt_type_t event) {}

static void case_detect_pin_interrupt_handler(nrfx_gpiote_pin_t pin,
                                              nrfx_gpiote_trigger_t trigger,
                                              void *p_context)
{
    // Inform the network core that we're about to sleep

    // Wait for network core to complete the shutdown process

    NRFX_LOG("Going to sleep");

    NRF_REGULATORS->SYSTEMOFF = 1;
    __DSB();

    // Only required for debug mode where core doesn't actually sleep
    while (1)
    {
    }
}

static void interprocessor_message_handler(void)
{
}

static void frame_setup_application_core(void)
{
    // Start the clocks
    {
        app_err(nrfx_clock_init(unused_clock_event_handler));
        nrfx_clock_enable();

        // High frequency crystal uses internally configurable capacitors
        uint32_t capacitance_pf = 8;
        int32_t slope = NRF_FICR->XOSC32MTRIM & 0x1F;
        int32_t trim = (NRF_FICR->XOSC32MTRIM >> 5) & 0x1F;

        nrf_oscillators_hfxo_cap_set(
            NRF_OSCILLATORS,
            true,
            (1 + slope / 16) * (capacitance_pf * 2 - 14) + trim);

        nrfx_clock_start(NRF_CLOCK_DOMAIN_HFCLK);
        nrfx_clock_start(NRF_CLOCK_DOMAIN_HFCLK192M);
        nrfx_clock_start(NRF_CLOCK_DOMAIN_LFCLK);
    }

    // Configure case detect pin for sleeping
    {
        app_err(nrfx_gpiote_init(NRFX_GPIOTE_DEFAULT_CONFIG_IRQ_PRIORITY));

        nrfx_gpiote_input_config_t input_config = {
            .pull = NRF_GPIO_PIN_PULLUP, // TODO decide on this
        };

        nrfx_gpiote_trigger_config_t trigger_config = {
            .trigger = NRFX_GPIOTE_TRIGGER_TOGGLE, // TODO decide on this
            .p_in_channel = NULL,
        };

        nrfx_gpiote_handler_config_t handler_config = {
            .handler = case_detect_pin_interrupt_handler,
            .p_context = NULL,
        };

        app_err(nrfx_gpiote_input_configure(CASE_DETECT_PIN,
                                            &input_config,
                                            &trigger_config,
                                            &handler_config));

        nrfx_gpiote_trigger_enable(CASE_DETECT_PIN, true);
    }

    // Set up ADC for battery level monitoring
    {}

    // Pass pins to network core control
    {
        nrf_gpio_pin_control_select(CAMERA_SLEEP_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(DISPLAY_SPI_CLOCK_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(DISPLAY_SPI_DATA_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(DISPLAY_SPI_SELECT_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(FPGA_PROGRAM_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(FPGA_SPI_CLOCK_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(FPGA_SPI_IO0_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(FPGA_SPI_IO1_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(FPGA_SPI_SELECT_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(I2C_SCL_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(I2C_SDA_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);
    }

    // Initialize the inter-processor communication
    {
        setup_interprocessor_messaging(interprocessor_message_handler);
    }

    // Turn on the network core
    {
        NRF_RESET->NETWORK.FORCEOFF = 0;
    }

    // Log that everything is ready on the application core
    {
        interprocessor_message_t message = INTERPROCESSOR_MESSAGE(
            LOG_FROM_APPLICATION_CORE,
            (uint8_t *)"Application processor started");

        push_interprocessor_message(message);
    }
}

int main(void)
{
    NRFX_LOG(RTT_CTRL_CLEAR);
    NRFX_LOG("MicroPython on Frame - " BUILD_VERSION " (" GIT_COMMIT ")");
    NRFX_LOG("Logging from application core");

    frame_setup_application_core();

    while (1)
    {
    }
}