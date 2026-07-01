#ifndef ATTACK_HANDLERS_H_
#define ATTACK_HANDLERS_H_
#include <stdint.h>
#include "proto.h"
esp_err_t attack_deauth(const char *bssid);
esp_err_t attack_pmkid(const char *bssid);
esp_err_t attack_wps_reg(const char *bssid, const char *pin);
esp_err_t attack_inject(const char *hex);
esp_err_t attack_capture(const char *filter_cfg);
#endif
