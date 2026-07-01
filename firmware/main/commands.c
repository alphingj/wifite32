#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "proto.h"
#include "wifi_radio.h"
#include "attack_handlers.h"
#include "esp_wifi.h"
#include "driver/uart.h"
#include <string.h>
#include <stdlib.h>

static command_t g_cmd;
static uint8_t g_seq;

static wifite_status_t cap_cmd(void) { capabilities_t caps; proto_request_capabilities(&caps); return WIFITE_STATUS_OK; }
static wifite_status_t channel_cmd(void) { char *end; long ch = strtol(g_cmd.args[0], &end, 10); if (end == g_cmd.args[0] || ch < 1) return WIFITE_STATUS_INVALID_ARG; return wifi_radio_set_channel((uint8_t)ch); }
static wifite_status_t deauth_cmd(void) { return attack_deauth(g_cmd.args[0]); }
static wifite_status_t pmkid_cmd(void) { return attack_pmkid(g_cmd.args[0]); }
static wifite_status_t wps_reg_cmd(void) { return attack_wps_reg(g_cmd.args[0], g_cmd.args[1]); }
static wifite_status_t inject_cmd(void) { return attack_inject(g_cmd.args[0]); }
static wifite_status_t scan_cmd(void) { esp_wifi_set_channel(1, WIFI_SECOND_CHAN_NONE); return WIFITE_STATUS_OK; }
static wifite_status_t capture_cmd(void) { return attack_capture(g_cmd.args[0]); }
static wifite_status_t ping_cmd(void) { return WIFITE_STATUS_OK; }

wifite_status_t command_parser_init(void) { memset(&g_cmd, 0, sizeof(g_cmd)); g_seq = 0; return WIFITE_STATUS_OK; }

static wifite_status_t dispatch_cmd(const command_t *cmd) {
    switch (cmd->cmd_id) {
        case WIFITE_CMD_SCAN: return scan_cmd();
        case WIFITE_CMD_CAPTURE: return cmd->arg_count ? capture_cmd() : WIFITE_STATUS_INVALID_ARG;
        case WIFITE_CMD_INJECT: return inject_cmd();
        case WIFITE_CMD_CHANNEL: return cmd->arg_count ? channel_cmd() : WIFITE_STATUS_INVALID_ARG;
        case WIFITE_CMD_WPS_REG: return cmd->arg_count >= 2 ? wps_reg_cmd() : WIFITE_STATUS_INVALID_ARG;
        case WIFITE_CMD_DEAUTH: return cmd->arg_count ? deauth_cmd() : WIFITE_STATUS_INVALID_ARG;
        case WIFITE_CMD_PMKID: return cmd->arg_count ? pmkid_cmd() : WIFITE_STATUS_INVALID_ARG;
        case WIFITE_CMD_CAPABILITIES: return cap_cmd();
        case WIFITE_CMD_PING: return ping_cmd();
        default: return WIFITE_STATUS_INVALID_CMD;
    }
}

static wifite_status_t parser_feed(uint8_t b) {
    static uint8_t idx = 0;
    static uint8_t arg_idx = 0;
    if (idx < 2) {
        if (idx == 0) g_cmd.cmd_id = b;
        else { g_cmd.arg_count = b; arg_idx = 0; }
        idx++;
        return WIFITE_STATUS_OK;
    }
    if (arg_idx >= MAX_CMD_ARGS) return WIFITE_STATUS_OK;
    size_t cur = strlen(g_cmd.args[arg_idx]);
    if (cur < 31) g_cmd.args[arg_idx][cur] = (char)b;
    if ((char)b == '\0' || cur == 31) arg_idx++;
    if (arg_idx >= g_cmd.arg_count) {
        wifite_status_t st = dispatch_cmd(&g_cmd);
        proto_send_response(g_cmd.cmd_id, g_seq, "", 0);
        memset(&g_cmd, 0, sizeof(g_cmd));
        idx = 0; arg_idx = 0;
        return st;
    }
    return WIFITE_STATUS_OK;
}

wifite_status_t command_parser_loop(void) {
    uint8_t buf[64]; int n = uart_read_bytes(0, buf, sizeof(buf), 0);
    for (int i = 0; i < n; i++) parser_feed(buf[i]);
    return WIFITE_STATUS_OK;
}
