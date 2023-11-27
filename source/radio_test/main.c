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
#include "i2c.h"
#include "nrf.h"
#include "nrfx_gpiote.h"
#include "nrfx_systick.h"
#include "nrfx_log.h"
#include "pinout.h"
#include "radio_test.h"

bool not_real_hardware = false;

void case_detect_pin_interrupt_handler(nrfx_gpiote_pin_t unused_gptiote_pin,
                                       nrfx_gpiote_trigger_t unused_gptiote_trigger,
                                       void *unused_gptiote_context_pointer)
{
    // This helps to debounce and stops the interrupt being called too often
    nrfx_gpiote_trigger_disable(CASE_DETECT_PIN);
    nrfx_systick_delay_ms(100);

    // Disconnect AMUX
    check_error(i2c_write(PMIC, 0x28, 0x0F, 0x00).fail);

    // Put PMIC main bias into low power mode
    check_error(i2c_write(PMIC, 0x10, 0x20, 0x20).fail);

    for (uint8_t pin = 0; pin < 16; pin++)
    {
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(0, pin));
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(0, pin + 16));
        nrf_gpio_cfg_default(NRF_GPIO_PIN_MAP(1, pin));
    }

    nrf_gpio_cfg_sense_input(CASE_DETECT_PIN,
                             NRF_GPIO_PIN_NOPULL,
                             NRF_GPIO_PIN_SENSE_LOW);

    // Clear the reset reasons
    NRF_POWER->RESETREAS = 0xF000F;

    LOG("Going to sleep");

    NRF_POWER->SYSTEMOFF = 1;
    __DSB();

    // Only required for debug mode where core doesn't actually sleep
    while (1)
    {
    }
}

int main(void)
{
    LOG(RTT_CTRL_CLEAR);
    LOG("Starting radio test firmware");

    // Always reboot into bootloader
    NRF_POWER->GPREGRET = 0xB1;

    // Init systick so it can be used later
    nrfx_systick_init();

    // Configure the shutdown pin
    check_error(nrfx_gpiote_init(NRFX_GPIOTE_DEFAULT_CONFIG_IRQ_PRIORITY));

    nrfx_gpiote_input_config_t input_config = {
        .pull = NRF_GPIO_PIN_NOPULL,
    };

    nrfx_gpiote_trigger_config_t trigger_config = {
        .trigger = NRFX_GPIOTE_TRIGGER_LOTOHI,
        .p_in_channel = NULL,
    };

    nrfx_gpiote_handler_config_t handler_config = {
        .handler = case_detect_pin_interrupt_handler,
        .p_context = NULL,
    };

    check_error(nrfx_gpiote_input_configure(CASE_DETECT_PIN,
                                            &input_config,
                                            &trigger_config,
                                            &handler_config));

    bool case_detect_pin = nrf_gpio_pin_read(CASE_DETECT_PIN);

    if (case_detect_pin == true)
    {
        case_detect_pin_interrupt_handler(0, 0, NULL);
    }

    nrfx_gpiote_trigger_enable(CASE_DETECT_PIN, true);

    // Setup I2C and PMIC
    i2c_configure();

    i2c_response_t pmic_id = i2c_read(PMIC, 0x14, 0x0F);

    if (pmic_id.fail)
    {
        LOG("Running on fake hardware");
        not_real_hardware = true;
    }

    // Set the SBB drive strength
    check_error(i2c_write(PMIC, 0x2F, 0x03, 0x01).fail);

    // Set SBB0 to 1.0V
    check_error(i2c_write(PMIC, 0x29, 0x7F, 0x04).fail);

    // Set SBB2 to 2.7V
    check_error(i2c_write(PMIC, 0x2D, 0x7F, 0x26).fail);

    // Set LDO0 to 1.2V
    check_error(i2c_write(PMIC, 0x38, 0x7F, 0x10).fail);

    // Turn off SBB2 (2.7V rail) with active discharge resistor on
    check_error(i2c_write(PMIC, 0x2E, 0x0F, 0x0C).fail);

    // Turn off LDO0 (1.2V rail)
    check_error(i2c_write(PMIC, 0x39, 0x0F, 0x0C).fail);

    // Turn off SBB0 (1.0V rail) with active discharge resistor on
    check_error(i2c_write(PMIC, 0x2A, 0x0F, 0x0C).fail);

    // Vhot & Vwarm = 45 degrees. Vcool = 15 degrees. Vcold = 0 degrees
    check_error(i2c_write(PMIC, 0x20, 0xFF, 0x2E).fail);

    // Set CHGIN limit to 475mA
    check_error(i2c_write(PMIC, 0x21, 0x1C, 0x10).fail);

    // Charge termination current to 5%, and top-off timer to 30mins
    check_error(i2c_write(PMIC, 0x22, 0x1F, 0x06).fail);

    // Set junction regulation temperature to 70 degrees
    check_error(i2c_write(PMIC, 0x23, 0xE0, 0x20).fail);

    // Set the fast charge current value to 225mA
    check_error(i2c_write(PMIC, 0x24, 0xFC, 0x74).fail);

    // Set the Vcool & Vwarm current to 112.5mA, and enable the thermistor
    check_error(i2c_write(PMIC, 0x25, 0xFE, 0x3A).fail);

    // Set constant voltage to 4.3V for both fast charge and JEITA
    check_error(i2c_write(PMIC, 0x26, 0xFC, 0x70).fail);
    check_error(i2c_write(PMIC, 0x27, 0xFC, 0x70).fail);

    // Connect AMUX to battery voltage
    check_error(i2c_write(PMIC, 0x28, 0x0F, 0x03).fail);

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
    radio_test_config.params.modulated_tx.pattern = TRANSMIT_PATTERN_RANDOM;
    radio_test_config.params.modulated_tx.channel = TEST_FREQUENCY - 2400;
    radio_test_config.params.modulated_tx.packets_num = 0;
    radio_test_config.params.modulated_tx.cb = NULL;

#if TEST_POWER == 8
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_POS8DBM;
#elif TEST_POWER == 7
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_POS7DBM;
#elif TEST_POWER == 6
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_POS6DBM;
#elif TEST_POWER == 5
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_POS5DBM;
#elif TEST_POWER == 4
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_POS4DBM;
#elif TEST_POWER == 3
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_POS3DBM;
#elif TEST_POWER == 2
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_POS2DBM;
#elif TEST_POWER == 0
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_0DBM;
#elif TEST_POWER == -4
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_NEG4DBM;
#elif TEST_POWER == -8
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_NEG8DBM;
#elif TEST_POWER == -12
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_NEG12DBM;
#elif TEST_POWER == -16
    radio_test_config.params.modulated_tx.txpower = NRF_RADIO_TXPOWER_NEG16DBM;
#else
#error Invalid TX_POWER value
#endif

    // Start test
    radio_test_init(&radio_test_config);
    radio_test_start(&radio_test_config);

    LOG("Running modulated TX on %uMHz at %ddBm",
        TEST_FREQUENCY,
        TEST_POWER);

    while (1)
    {
        __WFE();
    }
}