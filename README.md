# wifite32

A hybrid WiFi auditing toolkit that combines ESP32 firmware with a Python host controller for wireless security assessments.

## Overview

wifite32 migrates wifite2 to support ESP32 devices in a hybrid architecture where ESP32 firmware handles radio operations (packet capture/injection/channel hopping) while the host runs the existing wifite2 attack logic.

## Architecture

```
wifite32/
├── firmware/           # ESP32 C firmware (ESP-IDF)
│   ├── main/
│   │   ├── main.c      # Application entry point
│   │   ├── wifi_radio.c # Radio operations (promiscuous, injection)
│   │   ├── transport.c # Serial transport layer
│   │   ├── commands.c  # Command parser for host control
│   │   └── attack_handlers.c # Attack-specific frame operations
│   └── components/
│       └── wifite_protocol/ # Shared protocol definitions
├── host/               # Python host controller
│   ├── pywifite32.py # Main entry script
│   ├── esp32_backend.py # Backend replacing airmon/airodump
│   └── transport.py  # Host-side transport implementation
├── android/            # Android APK source
│   ├── app/            # Java/Kotlin app
│   └── wifite32_flutter/ # Flutter alternative implementation
└── tools/              # Helper utilities
```

## Requirements

### ESP32 Firmware
- ESP-IDF v5.3+
- ESP32 Development Board (ESP32-S3 recommended for 5GHz support)
- USB-UART adapter (if not using onboard USB)

### Host Controller
- Python 3.8+
- pyserial (`pip install pyserial`)

## Quick Start

### 1. Flash ESP32 Firmware

```bash
cd firmware
idf.py set-target esp32
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

### 2. Run Host Controller

```bash
cd host
python3 pywifite32.py
```

## ESP32 Firmware Build

The firmware is configured with WDT (Watchdog Timer) disabled:
- `CONFIG_BOOTLOADER_WDT_ENABLE=n` - Disables bootloader RTC watchdog
- Runtime WDT disable in `app_main()` via `RWDT_HAL_CONTEXT_DEFAULT`

### Configuration Options (sdkconfig.defaults)
```ini
CONFIG_IDF_TARGET="esp32"
CONFIG_FREERTOS_UNICORE=y
CONFIG_ESP_CONSOLE_NONE=y
CONFIG_BOOTLOADER_WDT_ENABLE=n
```

## Host Controller Usage

```python
from esp32_backend import ESP32Backend

with ESP32Backend("/dev/ttyUSB0") as backend:
    # Scan for APs
    aps = backend.scan(5.0)
    print(f"Found {len(aps)} access points")
    
    # Set channel
    backend.set_channel(6)
    
    # Deauth attack
    backend.deauth(bssid, count=8)
```

## Attack Support

| Attack | ESP32 Support | Description |
|--------|---------------|-------------|
| WPA/WPA2 Handshake | Full | Promiscuous capture + deauth injection |
| PMKID Extraction | Full | EAPOL frame capture for PMKID |
| WPS Pixie-Dust | Partial | Requires EAPOL handling |
| WEP Attacks | Full | ARP replay, fragmentation, chopchop |
| Evil Twin | Limited | ESP32 captures probes; host orchestrates |

## Protocol

### Serial Protocol
- Baud rate: 921600 (configurable)
- Frame format: `[timestamp(8 bytes)][rssi(1 byte)][length(2 bytes)][frame(N bytes)]`

### Commands
| Command ID | Description |
|------------|-------------|
| 0x01 | SCAN - Start/stop AP scan |
| 0x02 | CAPTURE - Enable/disable capture |
| 0x03 | INJECT - Send raw 802.11 frame |
| 0x04 | CHANNEL - Set WiFi channel |
| 0x05 | WPS_REG - WPS registration attempt |
| 0x06 | DEAUTH - Send deauthentication frames |
| 0x07 | PMKID - Initiate PMKID extraction |
| 0x08 | CAPABILITIES - Query device capabilities |
| 0x09 | PING - Health check |

## Android App

The Flutter-based APK is in `wifite32_flutter/`. Build with:
```bash
cd wifite32_flutter
flutter build apk
```

## Development

### Project Status
See [MIGRATION_PLAN.md](MIGRATION_PLAN.md) for implementation phases and technical challenges.

### Testing
Run the host test to verify ESP32 connectivity:
```bash
cd host
python3 -c "
from esp32_backend import ESP32Backend
with ESP32Backend('/dev/ttyUSB0') as b:
    print('ESP32 connected')
    aps = b.scan(5.0)
    print(f'Found {len(aps)} APs')
"
```

## License

See LICENSE file for details.

## Credits

Based on wifite2 WiFi auditing framework.