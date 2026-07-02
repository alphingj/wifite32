# Wifite32 Android

## Build

### Option A: Android Studio
1. Open Android Studio
2. Open project from `android/` directory
3. Build > Generate Signed Bundle/APK
4. Select APK, create debug keystore if needed
5. Build > Build Bundle(s) / APK(s) > Build APK(s)

### Option B: Command Line
```bash
cd android
./gradlew assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
```

### Option C: Termux (Direct Python)
Skip the APK entirely and run Python from Termux:
```bash
pkg install python git pyserial
git clone https://github.com/alphingj/wifite32.git
cd wifite32/host
python3 pywifite32.py
# The app UI is basic - use Termux for full functionality
```

## Run (APK)

1. Install `app/build/outputs/apk/debug/app-debug.apk` on your phone
2. Connect ESP32 via USB OTG cable
3. Grant USB permission when prompted
4. The app will auto-detect ESP32 on serial `/dev/ttyUSB0`

## Run (Termux)

```bash
# Give Termux permission to access USB
su
chmod 666 /dev/ttyUSB0

# Run host controller
cd wifite32/host
python3 pywifite32.py
```

## USB Serial Setup (Rooted Required)

The APK and Termux both need USB serial access. For rooted phones:

```bash
# Terminal or Termux
su
chmod 666 /dev/ttyUSB0
setenforce 0  # Disable SELinux if needed
```

## Protocol

The app communicates with ESP32 firmware at 921600 baud:
- Frame header: 7 bytes (timestamp:4, rssi:1, length:2)
- Binary format for performance

## Notes
- Uses `usbserial` library for USB-CDC communication
- Minimum Android 8+ (API 26) required
- USB host mode must be supported by device