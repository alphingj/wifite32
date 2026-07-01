idf_component_register(SRCS "main.c"
                       "wifi_radio.c"
                       "commands.c"
                       "transport.c"
                       "attack_handlers.c"
                    REQUIRES esp_wifi esp_event driver freertos nvs_flash wifite_protocol
                    INCLUDE_DIRS "." "..")
