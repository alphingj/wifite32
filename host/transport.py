from __future__ import annotations
import serial
import socket
import struct
import json
import time
from typing import Iterator, Tuple
from queue import Queue
from threading import Thread

class ESP32Transport:
    def __init__(self, device: str = "/dev/ttyUSB0", baud: int = 921600):
        self._ser = serial.Serial(device, baudrate=baud, timeout=0.05, write_timeout=0.05)
        self._rx = Queue()
        self._stop = False
        Thread(target=self._reader, daemon=True).start()

    def __enter__(self): return self
    def __exit__(self, *a): self.close()

    def _reader(self) -> None:
        buf = b""
        while not self._stop:
            try:
                b = self._ser.read(1024)
                if not b:
                    time.sleep(0.005)
                    continue
                buf += b
                off = 0
                while off + 11 <= len(buf):
                    ts = struct.unpack_from("<Q", buf, off)[0]
                    rssi = struct.unpack_from("<b", buf, off + 8)[0]
                    fl = struct.unpack_from("<H", buf, off + 9)[0]
                    if off + 11 + fl > len(buf):
                        break
                    pkt = buf[off + 11: off + 11 + fl]
                    self._rx.put((ts, rssi, pkt))
                    off += 11 + fl
                buf = buf[off:]
            except Exception:
                time.sleep(0.005)

    def stream(self) -> Iterator[Tuple[int, bytes]]:
        while not self._stop:
            try:
                yield self._rx.get(timeout=0.2)
            except Exception:
                pass

    def close(self) -> None:
        self._stop = True
        try:
            self._ser.close()
        except Exception:
            pass

class TCPESP32Transport:
    def __init__(self, host: str = "192.168.4.1", port: int = 3333):
        self._sock = socket.create_connection((host, port), timeout=5.0)
        self._sock.settimeout(0.05)
        self._rx = Queue()
        self._stop = False
        Thread(target=self._reader, daemon=True).start()

    def _reader(self):
        buf = b""
        while not self._stop:
            try:
                b = self._sock.recv(4096)
                if not b:
                    time.sleep(0.01)
                    continue
                buf += b
                off = 0
                while off + 11 <= len(buf):
                    ts = struct.unpack_from("<Q", buf, off)[0]
                    rssi = struct.unpack_from("<b", buf, off + 8)[0]
                    fl = struct.unpack_from("<H", buf, off + 9)[0]
                    if off + 11 + fl > len(buf):
                        break
                    pkt = buf[off + 11: off + 11 + fl]
                    self._rx.put((ts, rssi, pkt))
                    off += 11 + fl
                buf = buf[off:]
            except Exception:
                time.sleep(0.005)

    def stream(self):
        while not self._stop:
            try:
                yield self._rx.get(timeout=0.2)
            except Exception:
                pass

    def close(self):
        self._stop = True
        try:
            self._sock.close()
        except Exception:
            pass
