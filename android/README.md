# Wifite32 Android

## Build
```bash
./gradlew assembleDebug
```

## Run
Install `app-debug.apk` on your phone and pair it over USB with the ESP32 running `wifite32` firmware.

## Notes
- Uses `lifecycle-viewmodel-ktx` for state handling.
- USB host API with CDC-ACM is required.
