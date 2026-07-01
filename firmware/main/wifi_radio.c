#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "proto.h"
#include "transport.h"

esp_err_t wifi_radio_init(void) {
    esp_err_t ret = esp_netif_init();
    if (ret != ESP_OK) return ret;
    ret = esp_event_loop_create_default();
    if (ret != ESP_OK && ret != ESP_ERR_INVALID_STATE) return ret;
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ret = esp_wifi_init(&cfg);
    if (ret != ESP_OK) return ret;
    ret = esp_wifi_set_storage(WIFI_STORAGE_RAM);
    if (ret != ESP_OK) return ret;
    return esp_wifi_set_mode(WIFI_MODE_NULL);
}

esp_err_t wifi_radio_start(void) {
    esp_err_t ret = esp_wifi_start();
    if (ret != ESP_OK) return ret;
    return esp_wifi_set_promiscuous(true);
}

esp_err_t wifi_radio_set_channel(uint8_t channel) {
    return esp_wifi_set_channel(channel, WIFI_SECOND_CHAN_NONE);
}

esp_err_t wifi_radio_inject(const uint8_t *buf, size_t len) {
    if (!buf || len == 0 || len > MAX_FRAME_SIZE) return ESP_ERR_INVALID_ARG;
    return esp_wifi_80211_tx(WIFI_IF_STA, buf, (int)len, false);
}
