#include "proto.h"
#include <string.h>

wifite_status_t proto_command_init(void) {
    return WIFITE_STATUS_OK;
}

wifite_status_t proto_send_response(uint8_t cmd_id, uint8_t seq,
                                    const char *json_payload, size_t payload_len) {
    (void)cmd_id; (void)seq; (void)json_payload; (void)payload_len;
    return WIFITE_STATUS_BUSY;
}

wifite_status_t proto_send_frame(const frame_record_t *frame) {
    if (!frame) return WIFITE_STATUS_INVALID_ARG;
    return WIFITE_STATUS_BUSY;
}

wifite_status_t proto_process_command(const command_t *cmd) {
    if (!cmd) return WIFITE_STATUS_INVALID_CMD;
    return WIFITE_STATUS_NOT_SUPPORTED;
}

wifite_status_t proto_request_capabilities(capabilities_t *caps) {
    if (!caps) return WIFITE_STATUS_INVALID_ARG;
    memset(caps, 0, sizeof(*caps));
    return WIFITE_STATUS_BUSY;
}

wifite_status_t proto_set_filter(uint32_t filter_mask) {
    (void)filter_mask;
    return WIFITE_STATUS_OK;
}
