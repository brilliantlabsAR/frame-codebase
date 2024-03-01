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
#include <stdint.h>

typedef struct camera_config_t
{
    uint16_t address;
    uint8_t value;
} camera_config_t;

static const camera_config_t camera_config[] = {
    {0x0103, 0x01}, // Software reset = on
    {0x0100, 0x00}, // Mode select = sleep mode
    {0x3001, 0x00}, // VSYNC output enable
    {0x3002, 0x00}, // GPIO output enable
    {0x3007, 0x00},
    {0x3010, 0x00},
    {0x3011, 0x08},
    {0x3014, 0x22},
    {0x301e, 0x15}, // Pixel clock divider
    {0x3030, 0x19}, // DAC clock divider
    {0x3080, 0x02}, // PLL clock pre divider
    {0x3081, 0x3c}, // PLL multiplier
    {0x3082, 0x04}, // PLL system clock divider
    {0x3083, 0x00}, // PLL pixel clock divider
    {0x3084, 0x02}, // PLL DAC clock divider
    {0x3085, 0x01},
    {0x3086, 0x01},
    {0x3089, 0x01}, // PLL MIPI clock divider
    {0x308a, 0x00}, // PLL MIPI PHY clock divider
    {0x3103, 0x01}, // System clock divider
    {0x3500, 0x00}, // Long exposure [19:16]
    {0x3501, 0x32}, // Long exposure [15:8]
    {0x3502, 0x00}, // Long exposure [7:0], bits [3:0] are fractional
    {0x3503, 0x03}, // AEC manual control
    {0x3504, 0x00}, // Manual sensor gain [9:8]
    {0x3505, 0xE0}, // Manual sensor gain [7:0], TODO: Anything above 0xFF is overflowing
    {0x3509, 0x18}, // AEC control 9
    {0x350a, 0x00}, // Long gain [9:8]
    {0x350b, 0x30}, // Long gain [7:0]
    {0x3600, 0x55},
    {0x3601, 0x02},
    {0x3605, 0x22},
    {0x3611, 0xe7},
    {0x3654, 0x10}, // Output format (RAW10)
    {0x3655, 0x77},
    {0x3656, 0x77},
    {0x3657, 0x07},
    {0x3658, 0x22}, // ?? sleep=0xff on=0x00
    {0x3659, 0x22}, // ?? sleep=0xff on=0x00
    {0x365a, 0x02}, // ?? sleep=0xff on=0x00
    {0x3784, 0x05},
    {0x3785, 0x55},
    {0x37c0, 0x07}, // Binning sum / average select
    {0x3800, 0x00}, // Horizontal start address [15:8]
    {0x3801, 0x04}, // Horizontal start address [7:0]
    {0x3802, 0x00}, // Vertical start address [15:8]
    {0x3803, 0x04}, // Vertical start address [7:0]
    {0x3804, 0x05}, // Horizontal end address [15:8]
    {0x3805, 0x0b}, // Horizontal end address [7:0]
    {0x3806, 0x02}, // Vertical end address [15:8]
    {0x3807, 0xdb}, // Vertical end address [7:0]
    {0x3808, 0x05}, // Horizontal output size [15:8]
    {0x3809, 0x02}, // Horizontal output size [7:0]
    {0x380a, 0x02}, // Vertical output size [15:8]
    {0x380b, 0xd2}, // Vertical output size [7:0]
    {0x380c, 0x05}, // Pixels per line [15:8]
    {0x380d, 0xc6}, // Pixels per line [7:0]
    {0x380e, 0x03}, // Lines per frame [15:8]
    {0x380f, 0x2a}, // Lines per frame [7:0]
    {0x3810, 0x00}, // ISP horizontal window offset [15:8]
    {0x3811, 0x00}, // ISP horizontal window offset [7:0]
    {0x3812, 0x00}, // ISP vertical window offset [15:8]
    {0x3813, 0x00}, // ISP vertical window offset [7:0]
    {0x3816, 0x00}, // VSYNC start row [15:8]
    {0x3817, 0x00}, // VSYNC start row [7:0]
    {0x3818, 0x00}, // VSYNC end row [15:8]
    {0x3819, 0x04}, // VSYNC end row [7:0]
    {0x3820, 0x18}, // Image FORMAT0
    {0x3821, 0x00}, // Image FORMAT1
    {0x382c, 0x06},
    {0x3d00, 0x00},
    {0x3d01, 0x00},
    {0x3d02, 0x00},
    {0x3d03, 0x00},
    {0x3d04, 0x00},
    {0x3d05, 0x00},
    {0x3d06, 0x00},
    {0x3d07, 0x00},
    {0x3d08, 0x00},
    {0x3d09, 0x00},
    {0x3d0a, 0x00},
    {0x3d0b, 0x00},
    {0x3d0c, 0x00},
    {0x3d0d, 0x00},
    {0x3d0e, 0x00},
    {0x3d0f, 0x00},
    {0x3d80, 0x00},
    {0x3d81, 0x00},
    {0x3d82, 0x38},
    {0x3d83, 0xa4},
    {0x3d84, 0x00},
    {0x3d85, 0x00},
    {0x3d86, 0x1f},
    {0x3d87, 0x03},
    {0x3d8b, 0x00},
    {0x3d8f, 0x00},
    {0x4001, 0xe0}, // Black level control 1
    {0x4009, 0x0b}, // Black level control 9
    {0x4300, 0x03},
    {0x4301, 0xff},
    {0x4304, 0x00},
    {0x4305, 0x00},
    {0x4309, 0x00},
    {0x4600, 0x00},
    {0x4601, 0x80},
    {0x4800, 0x00}, // MIPI control 0
    {0x4805, 0x00}, // MIPI control 5
    {0x4821, 0x50}, // MIPI clock post min [7:0]
    {0x4823, 0x50}, // MIPI clock trail min [7:0]
    {0x4837, 0x2d}, // MIPI pclk period
    {0x4a00, 0x00}, // Frame count
    {0x4f00, 0x80}, //
    {0x4f01, 0x10},
    {0x4f02, 0x00},
    {0x4f03, 0x00},
    {0x4f04, 0x00},
    {0x4f05, 0x00},
    {0x4f06, 0x00},
    {0x4f07, 0x00},
    {0x4f08, 0x00},
    {0x4f09, 0x00},
    {0x5000, 0x3f}, // ISP control 0
    {0x500c, 0x00}, // Pre ISP horizontal start [11:8]
    {0x500d, 0x00}, // Pre ISP horizontal start [7:0]
    {0x500e, 0x00}, // Pre ISP horizontal end [11:8]
    {0x500f, 0x00}, // Pre ISP horizontal end [7:0]
    {0x5010, 0x00}, // Pre ISP horizontal start [11:8]
    {0x5011, 0x00}, // Pre ISP horizontal start [7:0]
    {0x5012, 0x00}, // Pre ISP horizontal end [11:8]
    {0x5013, 0x00}, // Pre ISP horizontal end [7:0]
    {0x5014, 0x00}, // Pre ISP horizontal output size [11:8]
    {0x5015, 0x00}, // Pre ISP horizontal output size [7:0]
    {0x5016, 0x00}, // Pre ISP vertical output size [11:8]
    {0x5017, 0x00}, // Pre ISP vertical output size [7:0]
    {0x5080, 0x00}, // Pre ISP control 0
    {0x5180, 0x01}, // White balance red gain [11:8] (indoor=0x01, outdoor=0x01)
    {0x5181, 0x6F}, // White balance red gain [7:0] (indoor=0x6f, outdoor=0xaf)
    {0x5182, 0x01}, // White balance green gain [11:8] (indoor=0x01, outdoor=0x01)
    {0x5183, 0x00}, // White balance green gain [7:0] (indoor=0x00, outdoor=0x00)
    {0x5184, 0x01}, // White balance blue gain [11:8] (indoor=0x01, outdoor=0x01)
    {0x5185, 0xEF}, // White balance blue gain [7:0] (indoor=0xef, outdoor=0x6f)
    {0x5708, 0x06}, // Window control 8
    {0x5780, 0x3e}, // DPC control 0
    {0x5781, 0x0f}, // DPC control 1
    {0x5782, 0x44}, // DPC control 2
    {0x5783, 0x02}, // WTHRE list 1
    {0x5784, 0x01}, // WTHRE list 2
    {0x5785, 0x01}, // WTHRE list 3
    {0x5786, 0x00}, // Adaptive pattern threshold [3:0]
    {0x5787, 0x04}, // Adaptive pattern step [3:0]
    {0x5788, 0x02}, // Connection case thershold [3:0]
    {0x5789, 0x0f}, // DPC level list 0
    {0x578a, 0xfd}, // DPC level list 1
    {0x578b, 0xf5}, // DPC level list 2
    {0x578c, 0xf5}, // DPC level list 3
    {0x578d, 0x03}, // Gain list 0
    {0x578e, 0x08}, // Gain list 1
    {0x578f, 0x0c}, // Gain list 2
    {0x5790, 0x08}, // Matching threshold [3:0]
    {0x5791, 0x04}, // Status thershold [3:0]
    {0x5792, 0x00}, // Threshold ratio [3:0]
    {0x5793, 0x52}, // DPC control 13
    {0x5794, 0xa3}, // DPC control 14
    {0x0100, 0x01}, // Software reset = off
};
