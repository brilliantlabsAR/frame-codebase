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
#include "ble.h"
#include "error_logging.h"
#include "luaport.h"
#include "nrf_nvic.h"
#include "nrf_sdm.h"
#include "nrfx_log.h"

nrf_nvic_state_t nrf_nvic_state = {{0}, 0};

extern uint32_t _ram_start;
static uint32_t ram_start = (uint32_t)&_ram_start;

static struct ble_handles_t
{
    uint16_t connection;
    uint8_t advertising;
    ble_gatts_char_handles_t repl_rx_write;
    ble_gatts_char_handles_t repl_tx_notification;
} ble_handles = {
    .connection = BLE_CONN_HANDLE_INVALID,
    .advertising = BLE_GAP_ADV_SET_HANDLE_NOT_SET,
};

static struct advertising_data_t
{
    uint8_t length;
    uint8_t payload[31];
} adv = {
    .length = 0,
    .payload = {0},
};

static const uint16_t ble_preferred_max_mtu = 256;
static uint16_t ble_negotiated_mtu;

static void softdevice_assert_handler(uint32_t id, uint32_t pc, uint32_t info)
{
    error_with_message("Softdevice crashed");
}

void SD_EVT_IRQHandler(void)
{
    uint32_t evt_id;
    uint8_t ble_evt_buffer[sizeof(ble_evt_t) + ble_preferred_max_mtu];

    // While any softdevice events are pending, service flash operations
    while (sd_evt_get(&evt_id) != NRF_ERROR_NOT_FOUND)
    {
        switch (evt_id)
        {
        case NRF_EVT_FLASH_OPERATION_SUCCESS:
            // TODO In case we add a filesystem in the future
            break;

        case NRF_EVT_FLASH_OPERATION_ERROR:
            // TODO In case we add a filesystem in the future
            break;

        default:
            break;
        }
    }

    // While any BLE events are pending
    while (1)
    {
        // Pull an event from the queue
        uint16_t buffer_len = sizeof(ble_evt_buffer);
        uint32_t status = sd_ble_evt_get(ble_evt_buffer, &buffer_len);

        // If we get the done status, we can exit the handler
        if (status == NRF_ERROR_NOT_FOUND)
        {
            break;
        }

        // Check for other errors
        check_error(status);

        // Make a pointer from the buffer which we can use to find the event
        ble_evt_t *ble_evt = (ble_evt_t *)ble_evt_buffer;

        switch (ble_evt->header.evt_id)
        {

        case BLE_GAP_EVT_CONNECTED:
        {
            ble_handles.connection = ble_evt->evt.gap_evt.conn_handle;

            ble_gap_conn_params_t conn_params;

            check_error(sd_ble_gap_ppcp_get(&conn_params));
            check_error(sd_ble_gap_conn_param_update(ble_handles.connection,
                                                     &conn_params));
            check_error(sd_ble_gatts_sys_attr_set(ble_handles.connection,
                                                  NULL,
                                                  0,
                                                  0));
            break;
        }

        case BLE_GAP_EVT_DISCONNECTED:
        {
            ble_handles.connection = BLE_CONN_HANDLE_INVALID;
            check_error(sd_ble_gap_adv_start(ble_handles.advertising, 1));
            break;
        }

        case BLE_GAP_EVT_PHY_UPDATE_REQUEST:
        {
            ble_gap_phys_t const phys = {
                .rx_phys = BLE_GAP_PHY_2MBPS,
                .tx_phys = BLE_GAP_PHY_2MBPS,
            };
            check_error(sd_ble_gap_phy_update(ble_evt->evt.gap_evt.conn_handle,
                                              &phys));
            break;
        }

        case BLE_GATTS_EVT_EXCHANGE_MTU_REQUEST:
        {
            // The client's desired MTU size
            uint16_t client_mtu =
                ble_evt->evt.gatts_evt.params.exchange_mtu_request.client_rx_mtu;

            // Respond with our max MTU size
            sd_ble_gatts_exchange_mtu_reply(ble_handles.connection,
                                            ble_preferred_max_mtu);

            // Choose the smaller MTU as the final length we'll use
            // -3 data to accommodate for Op-code and attribute service
            ble_negotiated_mtu = ble_preferred_max_mtu < client_mtu
                                     ? ble_preferred_max_mtu - 3
                                     : client_mtu - 3;
            break;
        }

        case BLE_GATTS_EVT_WRITE:
        {
            // If REPL service
            if (ble_evt->evt.gatts_evt.params.write.handle ==
                ble_handles.repl_rx_write.value_handle)
            {
                // Handle raw data
                if (ble_evt->evt.gatts_evt.params.write.data[0] == 0x01)
                {
                    // TODO
                }

                // Catch keyboard interrupts
                else if (ble_evt->evt.gatts_evt.params.write.data[0] == 0x03)
                {
                    // TODO
                }

                // Lua reset (0x04) is handled in the luaport.c file directly

                // Otherwise pass the string to the Lua interpreter
                else
                {
                    lua_write_to_repl(
                        ble_evt->evt.gatts_evt.params.write.data,
                        ble_evt->evt.gatts_evt.params.write.len);
                }
            }

            break;
        }

        case BLE_GATTS_EVT_TIMEOUT:
        {
            check_error(sd_ble_gap_disconnect(
                ble_handles.connection,
                BLE_HCI_REMOTE_USER_TERMINATED_CONNECTION));
            break;
        }

        case BLE_GATTS_EVT_SYS_ATTR_MISSING:
        {
            check_error(sd_ble_gatts_sys_attr_set(ble_handles.connection,
                                                  NULL,
                                                  0,
                                                  0));
            break;
        }

        case BLE_GAP_EVT_DATA_LENGTH_UPDATE_REQUEST:
        {
            check_error(sd_ble_gap_data_length_update(ble_handles.connection,
                                                      NULL,
                                                      NULL));
            break;
        }

        case BLE_GAP_EVT_SEC_PARAMS_REQUEST:
        {
            // TODO enabling pairing later
            check_error(sd_ble_gap_sec_params_reply(
                ble_handles.connection,
                BLE_GAP_SEC_STATUS_PAIRING_NOT_SUPP,
                NULL,
                NULL));
            break;
        }

        case BLE_GAP_EVT_CONN_PARAM_UPDATE:
        case BLE_GAP_EVT_PHY_UPDATE:
        case BLE_GAP_EVT_DATA_LENGTH_UPDATE:
        case BLE_GATTS_EVT_HVN_TX_COMPLETE:
        {
            // Unused events
            break;
        }

        default:
        {
            LOG("Unhandled BLE event: %u", ble_evt->header.evt_id);
            break;
        }
        }
    }
}

void bluetooth_setup(void)
{
    // Enable the softdevice using internal RC oscillator
    check_error(sd_softdevice_enable(NULL, softdevice_assert_handler));

    // Enable softdevice interrupt
    check_error(sd_nvic_EnableIRQ((IRQn_Type)SD_EVT_IRQn));

    // Add GAP configuration to the BLE stack
    ble_cfg_t cfg;
    cfg.conn_cfg.conn_cfg_tag = 1;
    cfg.conn_cfg.params.gap_conn_cfg.conn_count = 1;
    cfg.conn_cfg.params.gap_conn_cfg.event_length = 300;
    check_error(sd_ble_cfg_set(BLE_CONN_CFG_GAP, &cfg, ram_start));

    // Set BLE role to peripheral only
    memset(&cfg, 0, sizeof(cfg));
    cfg.gap_cfg.role_count_cfg.periph_role_count = 1;
    check_error(sd_ble_cfg_set(BLE_GAP_CFG_ROLE_COUNT, &cfg, ram_start));

    // Set max MTU size
    memset(&cfg, 0, sizeof(cfg));
    cfg.conn_cfg.conn_cfg_tag = 1;
    cfg.conn_cfg.params.gatt_conn_cfg.att_mtu = ble_preferred_max_mtu;
    check_error(sd_ble_cfg_set(BLE_CONN_CFG_GATT, &cfg, ram_start));

    // Configure two queued transfers
    memset(&cfg, 0, sizeof(cfg));
    cfg.conn_cfg.conn_cfg_tag = 1;
    cfg.conn_cfg.params.gatts_conn_cfg.hvn_tx_queue_size = 1;
    check_error(sd_ble_cfg_set(BLE_CONN_CFG_GATTS, &cfg, ram_start));

    // Configure number of custom UUIDs
    memset(&cfg, 0, sizeof(cfg));
    cfg.common_cfg.vs_uuid_cfg.vs_uuid_count = 1;
    check_error(sd_ble_cfg_set(BLE_COMMON_CFG_VS_UUID, &cfg, ram_start));

    // Configure GATTS attribute table
    memset(&cfg, 0, sizeof(cfg));
    cfg.gatts_cfg.attr_tab_size.attr_tab_size = 206 * 4; // multiples of 4
    check_error(sd_ble_cfg_set(BLE_GATTS_CFG_ATTR_TAB_SIZE, &cfg, ram_start));

    // No service changed attribute needed
    memset(&cfg, 0, sizeof(cfg));
    cfg.gatts_cfg.service_changed.service_changed = 0;
    check_error(sd_ble_cfg_set(BLE_GATTS_CFG_SERVICE_CHANGED, &cfg, ram_start));

    // Start the Softdevice
    check_error(sd_ble_enable(&ram_start));

    LOG("Softdevice using 0x%lx data of RAM", ram_start - 0x20000000);

    // Set security to open // TODO make this paired
    ble_gap_conn_sec_mode_t sec_mode;
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&sec_mode);

    // Set device name
    const char device_name[] = "frame";
    check_error(sd_ble_gap_device_name_set(&sec_mode,
                                           (const uint8_t *)device_name,
                                           strlen(device_name)));

    // Set connection parameters
    ble_gap_conn_params_t gap_conn_params = {0};
    gap_conn_params.min_conn_interval = (15 * 1000) / 1250;
    gap_conn_params.max_conn_interval = (15 * 1000) / 1250;
    gap_conn_params.slave_latency = 0;
    gap_conn_params.conn_sup_timeout = (2000 * 1000) / 10000;
    check_error(sd_ble_gap_ppcp_set(&gap_conn_params));

    // Create the service UUIDs
    ble_uuid128_t repl_service_uuid128 = {.uuid128 = {0xC4, 0x49, 0xAD, 0xF6,
                                                      0x31, 0x84, 0x4C, 0x65,
                                                      0xA4, 0xA6, 0x75, 0x54,
                                                      0xCD, 0x11, 0x23, 0x7A}};

    ble_uuid_t repl_service_uuid = {.uuid = 0x0001};

    check_error(sd_ble_uuid_vs_add(&repl_service_uuid128,
                                   &repl_service_uuid.type));

    uint16_t repl_service_handle;

    // Configure RX characteristic
    ble_uuid_t rx_uuid = {.uuid = 0x0002};
    rx_uuid.type = repl_service_uuid.type;

    ble_gatts_char_md_t rx_char_md = {0};
    rx_char_md.char_props.write = 1;
    rx_char_md.char_props.write_wo_resp = 1;

    ble_gatts_attr_md_t rx_attr_md = {0};
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&rx_attr_md.read_perm);
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&rx_attr_md.write_perm);
    rx_attr_md.vloc = BLE_GATTS_VLOC_STACK;
    rx_attr_md.vlen = 1;

    ble_gatts_attr_t rx_attr = {0};
    rx_attr.p_uuid = &rx_uuid;
    rx_attr.p_attr_md = &rx_attr_md;
    rx_attr.init_len = sizeof(uint8_t);
    rx_attr.max_len = ble_preferred_max_mtu - 3;

    // Configure both TX characteristic
    ble_uuid_t tx_uuid = {.uuid = 0x0003};
    tx_uuid.type = repl_service_uuid.type;

    ble_gatts_char_md_t tx_char_md = {0};
    tx_char_md.char_props.notify = 1;

    ble_gatts_attr_md_t tx_attr_md = {0};
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&tx_attr_md.read_perm);
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&tx_attr_md.write_perm);
    tx_attr_md.vloc = BLE_GATTS_VLOC_STACK;
    tx_attr_md.vlen = 1;

    ble_gatts_attr_t tx_attr = {0};
    tx_attr.p_uuid = &tx_uuid;
    tx_attr.p_attr_md = &tx_attr_md;
    tx_attr.init_len = sizeof(uint8_t);
    tx_attr.max_len = ble_preferred_max_mtu - 3;

    // Characteristics must be added sequentially after each service
    check_error(sd_ble_gatts_service_add(BLE_GATTS_SRVC_TYPE_PRIMARY,
                                         &repl_service_uuid,
                                         &repl_service_handle));

    check_error(sd_ble_gatts_characteristic_add(repl_service_handle,
                                                &rx_char_md,
                                                &rx_attr,
                                                &ble_handles.repl_rx_write));

    check_error(sd_ble_gatts_characteristic_add(repl_service_handle,
                                                &tx_char_md,
                                                &tx_attr,
                                                &ble_handles.repl_tx_notification));

    // Add name to advertising payload
    adv.payload[adv.length++] = strlen((const char *)device_name) + 1;
    adv.payload[adv.length++] = BLE_GAP_AD_TYPE_COMPLETE_LOCAL_NAME;
    memcpy(&adv.payload[adv.length],
           device_name,
           sizeof(device_name));
    adv.length += strlen((const char *)device_name);

    // Set discovery mode flag
    adv.payload[adv.length++] = 0x02;
    adv.payload[adv.length++] = BLE_GAP_AD_TYPE_FLAGS;
    adv.payload[adv.length++] = BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE;

    // Add only the REPL service to the advertising data
    uint8_t encoded_uuid_length;
    check_error(sd_ble_uuid_encode(&repl_service_uuid,
                                   &encoded_uuid_length,
                                   &adv.payload[adv.length + 2]));

    adv.payload[adv.length++] = 0x01 + encoded_uuid_length;
    adv.payload[adv.length++] = BLE_GAP_AD_TYPE_128BIT_SERVICE_UUID_COMPLETE;
    adv.length += encoded_uuid_length;

    ble_gap_adv_data_t adv_data = {
        .adv_data.p_data = adv.payload,
        .adv_data.len = adv.length,
        .scan_rsp_data.p_data = NULL,
        .scan_rsp_data.len = 0};

    // Set up advertising parameters
    ble_gap_adv_params_t adv_params;
    memset(&adv_params, 0, sizeof(adv_params));
    adv_params.properties.type = BLE_GAP_ADV_TYPE_CONNECTABLE_SCANNABLE_UNDIRECTED;
    adv_params.primary_phy = BLE_GAP_PHY_1MBPS;
    adv_params.secondary_phy = BLE_GAP_PHY_1MBPS;
    adv_params.interval = (20 * 1000) / 625;

    // Configure the advertising set
    check_error(sd_ble_gap_adv_set_configure(&ble_handles.advertising,
                                             &adv_data,
                                             &adv_params));

    // Start advertising
    check_error(sd_ble_gap_adv_start(ble_handles.advertising, 1));
}

bool bluetooth_send_data(const uint8_t *data, size_t length)
{
    if (ble_handles.connection == BLE_CONN_HANDLE_INVALID)
    {
        return true;
    }

    // TODO check if notifications are enabled
    // if (!ble_are_tx_notifications_enabled(DATA_TX))
    // {
    //     return true;
    // }

    // Initialise the handle value parameters
    ble_gatts_hvx_params_t hvx_params = {0};
    hvx_params.handle = ble_handles.repl_tx_notification.value_handle;
    hvx_params.p_data = data;
    hvx_params.p_len = (uint16_t *)&length;
    hvx_params.type = BLE_GATT_HVX_NOTIFICATION;

    uint32_t status = sd_ble_gatts_hvx(ble_handles.connection, &hvx_params);

    if (status == NRF_SUCCESS)
    {
        return false;
    }

    return true;
}
