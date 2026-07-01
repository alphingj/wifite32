#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "nvs_flash.h"
#include "esp_log.h"
#include "esp_task_wdt.h"
#include "hal/wdt_types.h"
#include "hal/wdt_hal.h"
#include "proto.h"
#include "transport.h"
#include "wifi_radio.h"
#include "commands.h"

static const char *TAG = "wifite_main";

static void disable_wdt(void) {
    wdt_hal_context_t wdt_ctx = RWDT_HAL_CONTEXT_DEFAULT();
    wdt_hal_write_protect_disable(&wdt_ctx);
    wdt_hal_disable(&wdt_ctx);
    wdt_hal_write_protect_enable(&wdt_ctx);
}

static void transport_task(void *pvParameters) {
    transport_init();
    command_parser_init();

    while (1) {
        if (transport_process() == WIFITE_STATUS_OK) {
            command_parser_loop();
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

void app_main(void) {
    ESP_LOGI(TAG, "Starting...");

    // Disable WDT before any potentially long operations
    disable_wdt();

    esp_err_t ret = nvs_flash_init();
    if (ret != ESP_OK) {
        ESP_LOGW(TAG, "NVS init failed: %s", esp_err_to_name(ret));
    }

    wifi_radio_init();
    wifi_radio_start();

    xTaskCreate(transport_task, "transport", 8192, NULL, 5, NULL);
    ESP_LOGI(TAG, "Wifite32 firmware started");
}