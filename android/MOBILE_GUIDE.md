# Wifite32 Mobile (Android)

Use your phone as a standalone WiFi attack platform paired with the ESP32 controller.

## Requirements
- Android 8+ (API 26)
- ESP32 with `wifite32` firmware flashed
- USB OTG cable
- Root (optional, for direct `/dev/ttyUSB0` access)

## Architecture (Java)
- `app/src/main/java/com/wifite32/android/...`
  - `services/UsbSerialService.java` - USB CDC serial transport (usbserial library)
  - `services/Esp32Service.java` - foreground service wrapper
  - `services/AttackService.java` - attack orchestration
  - `services/AttackEngine.java` - attack phase state machine
  - `ui/MainActivity.java` - main interface
  - `utils/FrameProtocol.java` - frame parser (7-byte header)
  - `utils/Esp32Protocol.java` - command constants
  - `models/AccessPoint.java`, `models/AttackResult.java` - data models

## Method 1: Android APK (Recommended for beginners)

### Build
```bash
cd android
./gradlew assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
```

### Install & Run
1. Transfer APK to phone
2. Enable "Install unknown apps" for your file manager
3. Install the APK
4. Connect ESP32 via USB OTG
5. Grant USB permission when prompted
6. The app auto-connects to ESP32 at 921600 baud

## Method 2: Termux (Rooted phone, full control)

### Setup
```bash
# Install Termux from F-Droid
pkg update && pkg upgrade

# Install required packages
pkg install python git pyserial

# (Optional) For cracking
pkg install aircrack-ng
```

### USB Access (Root Required)
```bash
su
chmod 666 /dev/ttyUSB0
setenforce 0  # If SELinux blocks access
```

### Run
```bash
git clone https://github.com/alphingj/wifite32.git
cd wifite32/host
python3 pywifite32.py
```

## Method 3: Termux + SSH (Remote control)

If ESP32 is connected to a Linux host via USB:

```bash
# On phone
pkg install ssh
ssh user@your-linux-host  # Run host controller remotely
```

## Protocol Details

| Setting | Value |
|---------|-------|
| Baud rate | 921600 |
| Frame header | 7 bytes (timestamp:4, rssi:1, length:2) |
| Command format | Text-based: `channel:6\n` or `deauth:AA:BB:...\n` |

## Supported Attacks

- WPA/WPA2 handshake capture + deauth injection
- PMKID extraction  
- WPS pixie-dust (partial)
- WEP replay attacks
- Evil Twin (ESP32-S3 dual interface required)