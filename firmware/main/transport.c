#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "driver/uart.h"
#include "proto.h"
#include "commands.h"

wifite_status_t transport_init(void) {
    QueueHandle_t q = NULL;
    uart_driver_install(0, 4096, 4096, 64, &q, 0);
    uart_config_t cfg = { .baud_rate = 921600, .data_bits = UART_DATA_8_BITS, .parity = UART_PARITY_DISABLE, .stop_bits = UART_STOP_BITS_1, .flow_ctrl = UART_HW_FLOWCTRL_DISABLE, .source_clk = UART_SCLK_APB };
    uart_param_config(0, &cfg);
    uart_set_pin(0, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    return WIFITE_STATUS_OK;
}

wifite_status_t transport_send(const uint8_t *data, size_t len) {
    int w = uart_write_bytes(0, (const char *)data, len);
    return (w >= 0 && (size_t)w == len) ? WIFITE_STATUS_OK : WIFITE_STATUS_TIMEOUT;
}

wifite_status_t transport_process(void) {
    return command_parser_loop();
}
