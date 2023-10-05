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

#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "nrf.h"
#include "nrfx_log.h"

static void application_core_message_handler(void)
{
    message_t message;

    while (message_pending(&message))
    {
        switch (message.command)
        {
        case LOG_FROM_APPLICATION_CORE:
            LOG("%s", message.payload);
            break;

        case BLUETOOTH_DATA_TO_SEND:
            // TODO replace this with bluetooth send
            printf("\x1B[95m%.*s", message.payload_length, message.payload);
            break;

        default:
            error_with_message("Unhandled interprocessor message");
            break;
        }
    }
}

int main(void)
{
    LOG(RTT_CTRL_RESET RTT_CTRL_CLEAR);

    // Initialize the inter-processor communication
    {
        setup_messaging(application_core_message_handler);
    }

    LOG("Network core configured");

    while (1)
    {
        // TODO replace this with Bluetooth receive
        uint8_t buffer[253];

        uint32_t buffer_length = SEGGER_RTT_Read(0, buffer, sizeof(buffer));

        if (buffer_length > 0)
        {
            send_message(BLUETOOTH_DATA_RECEIVED, buffer, buffer_length);
        }
    }
}