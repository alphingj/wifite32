#ifndef WIFITE_PROTOCOL_H_
#define WIFITE_PROTOCOL_H_

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define WIFITE_PROTO_VERSION "1.0.0"
#define MAX_FRAME_SIZE 2304
#define MAX_CMD_ARGS 16
#define CHANNEL_MAP_SIZE 64

typedef enum {
    WIFITE_CMD_SCAN = 0x01,
    WIFITE_CMD_CAPTURE = 0x02,
    WIFITE_CMD_INJECT = 0x03,
    WIFITE_CMD_CHANNEL = 0x04,
    WIFITE_CMD_WPS_REG = 0x05,
    WIFITE_CMD_DEAUTH = 0x06,
    WIFITE_CMD_PMKID = 0x07,
    WIFITE_CMD_CAPABILITIES = 0x08,
    WIFITE_CMD_PING = 0x09,
    WIFITE_CMD_SET_FILTER = 0x0A
} wifite_cmd_id_t;

typedef enum {
    WIFITE_STATUS_OK = 0x00,
    WIFITE_STATUS_ERROR = 0x01,
    WIFITE_STATUS_TIMEOUT = 0x02,
    WIFITE_STATUS_INVALID_CMD = 0x03,
    WIFITE_STATUS_INVALID_ARG = 0x04,
    WIFITE_STATUS_BUSY = 0x05,
    WIFITE_STATUS_NOT_SUPPORTED = 0x06
} wifite_status_t;

typedef struct {
    uint32_t timestamp_us;
    int8_t rssi;
    uint16_t len;
    uint8_t data[MAX_FRAME_SIZE];
} __attribute__((packed)) frame_record_t;

typedef struct {
    uint8_t cmd_id;
    uint8_t seq;
    char args[MAX_CMD_ARGS][32];
    uint8_t arg_count;
} command_t;

typedef struct {
    uint8_t chip_rev;
    char chip_name[16];
    bool has_5g;
    uint16_t max_channels_2g;
    uint16_t max_channels_5g;
    uint8_t supported_attacks;
    uint32_t serial_baud;
} capabilities_t;

#define CAP_ATTACK_WPA     (1 << 0)
#define CAP_ATTACK_PMKID  (1 << 1)
#define CAP_ATTACK_WPS    (1 << 2)
#define CAP_ATTACK_WEP    (1 << 3)
#define CAP_ATTACK_DEAUTH (1 << 4)

wifite_status_t proto_command_init(void);
wifite_status_t proto_send_response(uint8_t cmd_id, uint8_t seq,
                                    const char *json_payload, size_t payload_len);
wifite_status_t proto_send_frame(const frame_record_t *frame);
wifite_status_t proto_process_command(const command_t *cmd);
wifite_status_t proto_request_capabilities(capabilities_t *caps);
wifite_status_t proto_set_filter(uint32_t filter_mask);

#ifdef __cplusplus
}
#endif

#endif
