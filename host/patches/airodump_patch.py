# airodump.py patch: delegate to ESP32Backend.
# Append this at bottom of wifite2 tools/airodump.py:
def _esp32_capture(args, bssid, channel, timeout=30.0):
    from host.esp32_backend import ESP32Backend
    backend = ESP32Backend(getattr(args, "esp32_device", None) or getattr(args, "esp32", None))
    backend.open()
    backend.set_channel(channel)
    return backend.capture(bssid, channel, timeout)
