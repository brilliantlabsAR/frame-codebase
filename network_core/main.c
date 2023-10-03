/*
 * This file is a part https://github.com/brilliantlabsAR/frame-codebase
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

static void interprocessor_message_handler(void)
{
    while (pending_message_length() > 0)
    {
        message_t *message = new_message(pending_message_length());

        pop_message(message);

        switch (message->instruction)
        {
        case LOG_FROM_APPLICATION_CORE:
            LOG("%s", message->payload);
            break;

        default:
            app_err(UNHANDLED_MESSAGE_INSTRUCTION);
            break;
        }

        free_message(message);
    }
}

int main(void)
{
    LOG(RTT_CTRL_RESET RTT_CTRL_CLEAR);

    // Initialize the inter-processor communication
    {
        setup_messaging(interprocessor_message_handler);
    }

    // Inform the application processor that the hardware is configured
    {
        message_t message = MESSAGE_WITHOUT_PAYLOAD(NETWORK_CORE_READY);
        push_message(message);
    }

    LOG("Network core configured");

    while (1)
    {
    }
}