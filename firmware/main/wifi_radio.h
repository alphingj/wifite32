#ifndef WIFI_RADIO_H_
#define WIFI_RADIO_H_
#include <stdint.h>
#include "proto.h"
esp_err_t wifi_radio_init(void);
esp_err_t wifi_radio_start(void);
esp_err_t wifi_radio_set_channel(uint8_t channel);
esp_err_t wifi_radio_inject(const uint8_t *buf, size_t len);
#endif
