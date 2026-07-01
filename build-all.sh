#!/bin/bash
set -euo pipefail
echo "[wifite32] build-all"
echo "  - ESP32 firmware (requires idf.py)"
echo "  - Android APK (requires Android SDK/JDK + Gradle)"
echo "  - Linux host (python3 + pyserial + pyyaml)"

build_linux() {
  echo "[linux] py_compile host/"
  python3 -m py_compile host/transport.py
  python3 -m py_compile host/esp32_backend.py
  python3 -m py_compile host/pywifite32.py
  python3 -m compileall -q host/
  echo "DONE: linux bytecode"
}

build_esp32() {
  if ! command -v idf.py >/dev/null 2>&1; then
    echo "SKIP: idf.py not installed (needs ESP-IDF v5.x)"
    echo "  1) export IDF_PATH=~/esp/esp-idf"
    echo "  2) . \$IDF_PATH/export.sh"
    echo "  3) idf.py -C firmware set-target esp32"
    echo "  4) idf.py -C firmware build"
    echo "  5) idf.py -C firmware -p /dev/ttyUSB0 flash"
  else
    ( cd firmware && idf.py build )
  fi
}

build_android() {
  if ! command -v javac >/dev/null 2>&1; then
    echo "SKIP: JDK not installed"
    echo "  -> requires JDK 17+, Android SDK + ndk;25+, gradle"
  elif ! command -v gradle >/dev/null 2>&1 && [ ! -x android/gradlew ]; then
    echo "SKIP: gradle missing"
    echo "  -> in android/: gradle wrapper"
  else
    ( cd android && ./gradlew assembleDebug assembleRelease )
  fi
}

linux_host_target() {
  echo "[linux host] build py_packages"
  mkdir -p build/linux
  rsync -a host/ build/linux/wifite32_host/
  python3 -m compileall -q build/linux
  echo "Linux host: build/linux"
}

case "${1:-help}" in
  firmware|esp32) build_esp32 ;;
  android|apk) build_android ;;
  linux) linux_host_target ;;
  all) build_linux; build_esp32; build_android; linux_host_target ;;
  *) echo "usage: build-all.sh [linux|esp32|android|all]" ;;
esac

