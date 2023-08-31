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
#include "nrf_clock.h"
#include "nrf_gpio.h"
#include "nrf_oscillators.h"
#include "nrf.h"
#include "nrfx_gpiote.h"
#include "nrfx_log.h"
#include "nrfx_qspi.h"
#include "nrfx_systick.h"
#include "pinout.h"

static volatile bool network_core_ready = false;
static volatile bool ready_to_sleep = false;
static volatile bool sleep_prevented = false;
static volatile bool not_real_hardware = false;

static void case_detect_pin_interrupt_handler(nrfx_gpiote_pin_t pin,
                                              nrfx_gpiote_trigger_t trigger,
                                              void *p_context)
{
    // Disable interrupts to prevent too many triggers from pin bounces
    nrfx_gpiote_trigger_disable(CASE_DETECT_PIN);
    NRFX_LOG("Going to sleep");

    // Inform the network core that we're about to sleep
    message_t message = MESSAGE_WITHOUT_PAYLOAD(PREPARE_FOR_SLEEP);
    push_message(message);

    // Wait for the network core to complete the shutdown process
    while (ready_to_sleep == false)
    {
        if (sleep_prevented)
        {
            NRFX_LOG("Sleep prevented");

            // Short delay to prevent too many messages clogging things up
            nrfx_systick_delay_ms(100);

            // Re-enable interrupts before exiting
            nrfx_gpiote_trigger_enable(CASE_DETECT_PIN, true);
            return;
        }
    }

    // Disable SPI to the FPGA

    // Deinitialize pins

    // Power off until the next pin interrupt
    NRF_REGULATORS->SYSTEMOFF = 1;
    __DSB();

    // Only required for debug mode where core doesn't actually sleep
    while (1)
    {
    }
}

static void interprocessor_message_handler(void)
{
    while (pending_message_length() > 0)
    {
        message_t *message = new_message(pending_message_length());

        pop_message(message);

        switch (message->instruction)
        {
        case RESET_CHIP:
            NVIC_SystemReset();
            break;

        case NETWORK_CORE_READY:
            network_core_ready = true;
            break;

        case READY_TO_SLEEP:
            ready_to_sleep = true;
            break;

        case SLEEP_PREVENTED:
            sleep_prevented = true;
            break;

        case NOT_REAL_HARDWARE:
            not_real_hardware = true;
            break;

        default:
            app_err(UNHANDLED_MESSAGE_INSTRUCTION);
            break;
        }

        free_message(message);
    }
}

static void frame_setup_application_core(void)
{
    // Configure the clock sources
    {
        // // High frequency crystal uses internally configurable capacitors
        uint32_t capacitance_pf = 8;
        int32_t slope = NRF_FICR->XOSC32MTRIM & 0x1F;
        int32_t trim = (NRF_FICR->XOSC32MTRIM >> 5) & 0x1F;

        nrf_oscillators_hfxo_cap_set(
            NRF_OSCILLATORS,
            true,
            (1 + slope / 16) * (capacitance_pf * 2 - 14) + trim);

        nrf_clock_lf_src_set(NRF_CLOCK, NRFX_CLOCK_CONFIG_LF_SRC);
        nrf_clock_hf_src_set(NRF_CLOCK, NRF_CLOCK_HFCLK_HIGH_ACCURACY);
        nrf_clock_hfclk192m_src_set(NRF_CLOCK, NRF_CLOCK_HFCLK_HIGH_ACCURACY);

        nrf_clock_task_trigger(NRF_CLOCK, NRF_CLOCK_TASK_LFCLKSTART);
        nrf_clock_task_trigger(NRF_CLOCK, NRF_CLOCK_TASK_HFCLKSTART);
        nrf_clock_task_trigger(NRF_CLOCK, NRF_CLOCK_TASK_HFCLK192MSTART);
    }

    // Configure systick so we can use it for simple delays
    {
        nrfx_systick_init();
    }

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

        nrf_gpio_pin_control_select(I2C_SCL_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);

        nrf_gpio_pin_control_select(I2C_SDA_PIN,
                                    NRF_GPIO_PIN_SEL_NETWORK);
    }

    // Initialize the inter-processor communication
    {
        setup_messaging(interprocessor_message_handler);
    }

    // Turn on the network core
    {
        NRF_RESET->NETWORK.FORCEOFF = 0;
    }

    // Wait for the network core to start up
    while (network_core_ready == false)
    {
        // Do nothing
    }

    // Read the case detect pin. If docked, we sleep right away
    {
        // TODO
    }

    // Configure case detect pin for sleeping
    {
        app_err(nrfx_gpiote_init(NRFX_GPIOTE_DEFAULT_CONFIG_IRQ_PRIORITY));

        nrfx_gpiote_input_config_t input_config = {
            .pull = NRF_GPIO_PIN_PULLUP, // TODO pull this up with a large resistor
        };

        nrfx_gpiote_trigger_config_t trigger_config = {
            .trigger = NRFX_GPIOTE_TRIGGER_HITOLO,
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

    // Initialize SPI and control pins to the FPGA
    {
        // nrf_gpio_cfg_output(FPGA_PROGRAM_PIN);
        // nrf_gpio_cfg_output(FPGA_SPI_SELECT_PIN);
        nrf_gpio_pin_set(FPGA_PROGRAM_PIN);
        nrf_gpio_pin_set(FPGA_SPI_SELECT_PIN);

        nrfx_qspi_config_t qspi_config = NRFX_QSPI_DEFAULT_CONFIG(
            FPGA_SPI_CLOCK_PIN,
            FPGA_SPI_SELECT_PIN,
            FPGA_SPI_IO0_PIN,
            FPGA_SPI_IO1_PIN,
            NRF_QSPI_PIN_NOT_CONNECTED,
            NRF_QSPI_PIN_NOT_CONNECTED);

        app_err(nrfx_qspi_init(&qspi_config, NULL, NULL));
    }

    // Run the FPGA application loading sequence
    {
        // Program the FPGA

        // Wait until FPGA has started

        // Check the chip ID

        if (not_real_hardware == false)
        {
            // if (id_value[0] != 0x0A)
            {
                app_err(HARDWARE_ERROR);
            }
        }
    }

    // Set up ADC for battery level monitoring
    {
        // TODO
    }

    NRFX_LOG("Application core configured");
}

int main(void)
{
    frame_setup_application_core();

    while (1)
    {
    }
}