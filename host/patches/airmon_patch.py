# airmon.py patch: delegate to ESP32Backend when --esp32-device is set.
# Append this at bottom of wifite2 tools/airmon.py:
def _esp32_iface(args):
    from host.esp32_backend import ESP32Backend
    backend = ESP32Backend(getattr(args, "esp32_device", None) or getattr(args, "esp32", None))
    backend.open()
    return backend.monitor_mode_on()

if "esp32_device" in globals():
    iface = _esp32_iface(args)
