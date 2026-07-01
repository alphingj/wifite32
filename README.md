# wifite32

A hybrid WiFi auditing toolkit that combines ESP32 firmware with a Python host controller and Android app for wireless security assessments.

## Architecture

ESP32 firmware handles radio operations while the host runs attack logic:

```
wifite32/
├── firmware/           # ESP32 C firmware (ESP-IDF)
│   ├── main/
│   │   ├── main.c      # Entry point with WDT disable
│   │   ├── wifi_radio.c  # WiFi init, promiscuous mode, channel control
│   │   ├── transport.c   # UART serial transport (115200 baud)
│   │   ├── commands.c    # Command parser for host control
│   │   └── attack_handlers.c # Deauth/PMKID/WPS/WEP attack handlers
│   └── components/
│       └── wifite_protocol/ # Shared protocol definitions
├── host/               # Python 3.8+ host controller
│   ├── pywifite32.py    # Main entry script
│   ├── esp32_backend.py   # Backend API (scan, capture, deauth, inject)
│   └── transport.py       # Serial/TCP transport with binary framing
├── android/            # Android APK source
│   └── app/src/main/java/com/wifite32/android/
│       ├── services/      # AttackService, UsbSerialService, Esp32Service
│       ├── ui/           # MainActivity
│       └── utils/        # ProtocolParser, EscapeCipher
└── tools/              # Build utilities
```

## Requirements

### ESP32 Firmware
- ESP-IDF v5.3+
- ESP32 development board (ESP32-S3 recommended for 5GHz support)

### Host Controller
- Python 3.8+
- pyserial (`pip install pyserial`)

### Android App
- Android 8+ (API 26)
- USB OTG cable

## Quick Start

### Flash Firmware
```bash
cd firmware
idf.py set-target esp32
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor
```

### Host Controller
```bash
cd host
python3 pywifite32.py
```

### Build Android APK
```bash
cd android
./gradlew assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
```

## Protocol

### Serial Protocol
- Baud rate: 115200 (firmware) / 921600 (host)
- Frame format: `[timestamp(4)][rssi(1)][length(2)][frame(N bytes)]`

### Commands
| ID | Command | Description |
|----|---------|-------------|
| 0x01 | SCAN | Start/stop AP scan |
| 0x02 | CAPTURE | Enable/disable packet capture |
| 0x03 | INJECT | Send raw 802.11 frame |
| 0x04 | CHANNEL | Set WiFi channel (1-13) |
| 0x05 | WPS_REG | WPS registration attempt |
| 0x06 | DEAUTH | Send deauthentication frames |
| 0x07 | PMKID | Initiate PMKID extraction |
| 0x08 | CAPABILITIES | Query device capabilities |
| 0x09 | PING | Health check |

## Attack Support

| Attack | ESP32 Support | Notes |
|--------|---------------|-------|
| WPA/WPA2 Handshake | Full | Deauth injection + capture |
| PMKID Extraction | Full | EAPOL frame capture |
| WPS Pixie-Dust | Partial | Needs EAPOL handling |
| WEP Attacks | Full | ARP replay, fragmentation |
| Evil Twin | Limited | Host orchestrates with separate AP |

## Key Files

- `firmware/main/main.c` - Application entry point with `disable_wdt()` call
- `firmware/components/wifite_protocol/proto.h` - Protocol definitions
- `host/esp32_backend.py` - Python backend class API
- `host/transport.py` - Binary frame streaming over serial

## WDT Disable

The ESP32 watchdog timer is disabled via:
- `CONFIG_BOOTLOADER_WDT_ENABLE=n` in sdkconfig.defaults
- Runtime disable in `main.c` using `wdt_hal_disable()`

## License

See LICENSE file.