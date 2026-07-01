"""ESP32 backend for wifite2. Drop-in replacement for airmon.airodump."""
from __future__ import annotations
import os, time, subprocess, yaml
from typing import Optional, List, Tuple
from transport import ESP32Transport, TCPESP32Transport

def _default_serial() -> Optional[str]:
    for d in ["/dev/ttyUSB0", "/dev/ttyUSB1", "/dev/ttyACM0", "/dev/ttyACM1"]:
        if os.path.exists(d):
            return d
    return None

class Interface:
    def __init__(self, name: str):
        self.name = name
        self.channel = 0
        self.monitor = True
        self.up = True

class ESP32Backend:
    def __init__(self, device: Optional[str] = None, tcp: Optional[str] = None):
        self.serial = device or _default_serial()
        self.tcp = tcp
        self._transport = None
        self.interface = Interface("wlan1")
        self._ap_cache: List[dict] = []
        self._last_scan = 0.0

    def __enter__(self):
        self.open()
        return self
    def __exit__(self, exc_type, exc, tb):
        self.close()

    def open(self) -> None:
        if self.tcp:
            host, port = self.tcp.split(":")
            self._transport = TCPESP32Transport(host, int(port))
        else:
            self._transport = ESP32Transport(self.serial)
        time.sleep(0.1)

    def close(self) -> None:
        if self._transport:
            self._transport.close()
            self._transport = None
        self.interface.up = False

    def monitor_mode_on(self) -> Interface:
        self.interface.monitor = True
        return self.interface

    def monitor_mode_off(self) -> Interface:
        self.interface.monitor = False
        return self.interface

    def scan(self, timeout: float = 5.0) -> List[dict]:
        end = time.time() + timeout
        seen = {}
        for ts, rssi, pkt in self._transport.stream() if self._transport else []:
            if len(pkt) < 24:
                continue
            if pkt[0] & 0x08 and pkt[1] & 0x00:
                bssid = ":".join(f"{b:02x}" for b in pkt[10:16])
                seen.setdefault(bssid, {"bssid": bssid, "rssi": rssi, "count": 0, "last": ts})
                seen[bssid]["count"] += 1
                seen[bssid]["rssi"] = rssi
            if time.time() > end:
                break
        self._ap_cache = list(seen.values())
        self._last_scan = time.time()
        return self._ap_cache

    def capture(self, bssid: str, channel: int, timeout: float = 30.0) -> Tuple[bytes, ...]:
        ch = max(1, min(13 if channel != 0 else 1, channel))
        self.set_channel(ch)
        end = time.time() + timeout
        frames = []
        for ts, rssi, pkt in self._transport.stream() if self._transport else []:
            if len(pkt) < 34:
                continue
            frames.append(pkt)
            if pkt[0] == 0x88 and pkt[1] == 0x01:
                return tuple(frames)
            if time.time() > end:
                break
        return tuple(frames)

    def deauth(self, bssid: str, count: int = 8) -> None:
        cmd = f"deauth:{bssid}:{count}"
        if self._transport and hasattr(self._transport, "_ser"):
            self._transport._ser.write(cmd.encode() + b"\n")
            self._transport._ser.flush()
        time.sleep(0.05)

    def set_channel(self, ch: int) -> None:
        self.interface.channel = ch
        if self._transport and hasattr(self._transport, "_ser"):
            self._transport._ser.write(f"channel:{ch}\n".encode())

    def inject(self, frame: bytes) -> None:
        if self._transport and hasattr(self._transport, "_ser"):
            self._transport._ser.write(b"inject:" + frame.hex().encode() + b"\n")
            self._transport._ser.flush()

    def pmkid(self, bssid: str, timeout: float = 60.0) -> Optional[bytes]:
        end = time.time() + timeout
        for _, _, pkt in self._transport.stream() if self._transport else []:
            if len(pkt) >= 34 and pkt[0] == 0x88 and pkt[1] == 0x01:
                return pkt
            if time.time() > end:
                break
        return None
