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

#include "nrf_gpio.h"

#define BATTERY_LEVEL_PIN NRF_SAADC_INPUT_AIN3

#define CAMERA_SLEEP_PIN NRF_GPIO_PIN_MAP(0, 16) // Inverted pin

#define CASE_DETECT_PIN NRF_GPIO_PIN_MAP(0, 17)

#define DISPLAY_SPI_CLOCK_PIN NRF_GPIO_PIN_MAP(0, 11)
#define DISPLAY_SPI_DATA_PIN NRF_GPIO_PIN_MAP(0, 13)
#define DISPLAY_SPI_SELECT_PIN NRF_GPIO_PIN_MAP(1, 9) // Inverted pin

#define FPGA_PROGRAM_PIN NRF_GPIO_PIN_MAP(0, 20) // Inverted pin
#define FPGA_SPI_CIPO_PIN NRF_GPIO_PIN_MAP(0, 15)
#define FPGA_SPI_CLOCK_PIN NRF_GPIO_PIN_MAP(0, 19)
#define FPGA_SPI_COPI_PIN NRF_GPIO_PIN_MAP(0, 25)
#define FPGA_SPI_SELECT_PIN NRF_GPIO_PIN_MAP(0, 22) // Inverted pin

#define I2C_SCL_PIN NRF_GPIO_PIN_MAP(1, 13)
#define I2C_SDA_PIN NRF_GPIO_PIN_MAP(1, 11)

#define IMU_INTERRUPT_PIN NRF_GPIO_PIN_MAP(1, 5)

#define MICROPHONE_CLOCK_PIN NRF_GPIO_PIN_MAP(0, 4)
#define MICROPHONE_DATA_PIN NRF_GPIO_PIN_MAP(0, 1)