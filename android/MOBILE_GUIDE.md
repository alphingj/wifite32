# Wifite32 Mobile (Android)
Use your phone as a standalone WiFi attack platform paired with the ESP32 controller.

## Requirements
- Android 8+ API 26
- ESP32 with `wifite32` firmware flashed
- USB OTG cable or WiFi transport (TCP fallback)

## Architecture
- `app/src/main/java/com/wifite32/android/...`
  - `services/AttackService.kt` - attack state machine + coroutines
  - `services/UsbSerialService.kt` - USB CDC serial transport
  - `services/Esp32Service.kt` - foreground service
  - `fragments/ScanFragment.kt` - AP scanner + frame stream
  - `fragments/AttackFragment.kt` - WPA/WPS/WEP/PMKID/Evil Twin
  - `utils/EscapeCipher.kt` - banner + channel formatting
  - `utils/ProtocolParser.kt` - frame/command protocol

## Build
```bash
cd /home/gj/wifite32/android
./gradlew assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
```

## Runtime
1. Plug ESP32 via USB OTG
2. Grant USB permission prompt
3. Select scan/attack tab
4. The app communicates over serial with the ESP32 and runs attacks locally.

## Supported Attacks (MVP)
- WPA/WPA2 handshake capture + offline crack
- PMKID extraction
- WPS pixie-dust
- WEP replay
- Evil Twin (limited on ESP32-S3 dual-iface)
