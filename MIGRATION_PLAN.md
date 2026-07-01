# Wifite2 ESP32 Hybrid Migration Plan

## Overview
Migrate wifite2 to support ESP32 devices in a hybrid architecture where ESP32 firmware handles radio operations (packet capture/injection/channel hopping) while the host runs the existing wifite2 attack logic.

## Architecture

### Hybrid Model
- **ESP32 Firmware**: C/ESP-IDF application handling low-level WiFi operations
- **Host Controller**: Python extension to wifite2 running on Linux/macOS
- **Transport**: Serial CDC (primary) with TCP fallback for network-connected ESP32

### Component Structure

```
wifite32/
├── firmware/           # ESP32 C firmware (ESP-IDF)
│   ├── main/
│   │   ├── wifi_radio.c      # Radio operations (promiscuous, injection)
│   │   ├── commands.c        # Command parser for host control
│   │   ├── transport.c       # Serial/TCP transport layer
│   │   └── attack_handlers.c # Attack-specific frame operations
│   └── components/
│       └── wifite_protocol/  # Shared protocol definitions
├── host/               # Python host controller
│   ├── esp32_backend.py  # Backend replacing airmon/airodump
│   ├── transport.py      # Host-side transport implementation
│   └── patches/        # Patches to integrate with wifite2
└── tools/
    ├── flash_tool.py   # ESP32 flashing utility
    └── monitor.py      # Device discovery and status
```

## ESP32 Firmware Design

### Capabilities Detection
- Query chip at startup: `esp_chip_info_t`
- ESP32-S3: 5GHz support (channels 36-165)
- ESP32/ESP32-C3/C6: 2.4GHz only (channels 1-14)

### WiFi Radio Operations

#### Promiscuous Mode
```c
esp_wifi_set_promiscuous(true);
esp_wifi_set_promiscuous_filter(&filter);
esp_wifi_register_recv_cb(recv_cb);
```

#### Packet Injection
```c
esp_wifi_80211_tx(wifi_interface_t ifx, const uint8_t *buffer, int len, bool en_sys_desc);
```

#### Channel Hopping
```c
esp_wifi_set_channel(channel, WIFI_SECOND_CHAN_NONE);
```

### Command Protocol (JSON over serial)

| Command | Description |
|---------|-------------|
| SCAN | Start/stop access point scan |
| CAPTURE | Enable/disable packet capture |
| INJECT | Send raw 802.11 frame(s) |
| CHANNEL | Set channel for all interfaces |
| WPS_REG | Register WPS PIN attempt |
| DEAUTH | Send deauthentication frames |
| PMKID | Initiate PMKID extraction handshake |
| CAPABILITIES | Query supported features |

## Host Controller Implementation

### Backend Replacement Strategy

Replace wifite2 tool interfaces:

| wifite2 Component | ESP32 Replacement |
|-------------------|-------------------|
| airmon.py | ESP32Backend.monitor_mode_on()/off() |
| airodump.py | ESP32Backend.scan() / capture() |
| aireplay-ng | ESP32Backend.inject() / deauth() |

### Transport Layer

```python
class ESP32Transport:
    def __init__(self, device='/dev/ttyUSB0', baudrate=921600):
        self.serial = Serial(device, baudrate)
    
    def send_command(self, cmd: dict) -> dict:
        # Send JSON command, wait for response
        pass
    
    def stream_packets(self) -> Iterator[bytes]:
        # Continuously receive captured frames
        pass
```

### Packet Streaming Protocol
- Framing: Length-prefixed binary over serial
- Format: `[4-byte length][N-byte packet data]`
- Packet format: `[timestamp(8)][rssi(1)][length(2)][frame_data(N)]`

## Attack Vector Mapping

### WPA/WPA2 Handshake Capture
**ESP32 Capabilities:** Full support
- **Capture**: Promiscuous mode captures EAPOL frames
- **Injection**: Deauth frames disconnect clients for handshake capture
- **Implementation**: `attack_handlers.c::handle_deauth()` + `recv_cb` filter

### PMKID Extraction
**ESP32 Capabilities:** Full support
- **AP Association**: ESP32 initiates RSN association to trigger PMKID
- **Capture**: EAPOL frames containing PMKID
- **Implementation**: `attack_handlers.c::handle_pmkid_assoc()`

### WPS Pixie-Dust/PIN
**ESP32 Capabilities:** Partial (requires EAPOL handling)
- **Enrollee Detection**: Capture beacon/probe for WPS-enabled APs
- **EAPOL Exchange**: ESP32 generates/modifies EAPOL-Fast frames
- **Implementation**: `attack_handlers.c::handle_wps_eapol()`

### WEP Attacks
**ESP32 Capabilities:** Full support
- **ARP Replay**: Inject captured ARP requests
- **Fragmentation**: Fragmented packet injection
- **Chopchop**: Packet replay/modification
- **Implementation**: `attack_handlers.c::handle_wep_injection()`

### Evil Twin
**ESP32 Capabilities:** Limited (no AP mode in monitor mode)
- **Workaround**: ESP32 captures client probes, host orchestrates with separate AP device
- **Alternative**: Use ESP32-S2/S3 AP mode + separate capture device

## Integration Points

### Modified wifite2 Files

| File | Changes |
|------|---------|
| args.py | Add `--esp32-device`, `--esp32-transport` options |
| config.py | Add ESP32 device configuration section |
| tools/airmon.py | Add ESP32Monitor class extending MonitorInterface |
| tools/airodump.py | Add ESP32Scan class for passive/active scanning |
| attack/all.py | Modify attacks to use ESP32Backend injection API |

### Backend Selection Logic
```python
# In airmon.py or main entry
if args.esp32_mode:
    backend = ESP32Backend(args.esp32_device)
else:
    backend = AirmonBackend()
```

## Build System

### ESP-IDF Firmware Build
```bash
# Configuration
idf.py set-target esp32s3
idf.py menuconfig  # WiFi settings, transport options

# Build & Flash
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

### Host Python Package
```bash
pip install -e .
# Dependencies: pyserial, pywifi (existing), scapy
```

## Testing Strategy

### Unit Tests
- **Firmware**: ESP-IDF pytest for command handlers
- **Host**: pytest for transport layer, backend mock tests

### Integration Tests
1. **Device Detection**: Verify ESP32 enumeration and capabilities
2. **Channel Hopping**: Validate rapid channel switching across bands
3. **Packet Capture**: Confirm 802.11 frame reception with RSSI
4. **Injection Tests**: Send deauth/WEP frames, verify on air

### Hardware Test Matrix
| Variant | 2.4GHz Test | 5GHz Test (if applicable) | Notes |
|---------|-------------|--------------------------|-------|
| ESP32 (classic) | ✓ | - | Channels 1-14 |
| ESP32-S3 | ✓ | ✓ | Channels 1-165 |
| ESP32-C3/C6 | ✓ | - | RISC-V, channels 1-14 |

## Deployment Workflow

### Initial Setup
1. User installs ESP-IDF toolchain
2. Build firmware with `idf.py build`
3. Flash via `idf.py -p PORT flash` or `tools/flash_tool.py`
4. Run wifite2 with `--esp32-device /dev/ttyUSB0`

### Runtime
1. Host discovers/connects to ESP32 via serial/TCP
2. Query capabilities, configure attack parameters
3. Launch attacks through ESP32Backend
4. Stream captured packets to wifite2 processing loop

## Critical Technical Challenges

### 1. Throughput Limitations
- **Issue**: Serial bandwidth limits (max ~1500 packets/sec at 921600 baud)
- **Mitigation**: Filter frames on ESP32, prioritize EAPOL/beacon/ probe

### 2. Timing Precision
- **Issue**: Microsecond timing for injection attacks
- **Mitigation**: Use ESP32 timer APIs, pre-schedule injection bursts

### 3. Memory Constraints
- **Issue**: Limited RAM for frame buffers (ESP32: ~520KB)
- **Mitigation**: Immediate streaming to host, minimal buffering

### 4. Concurrent Operations
- **Issue**: Cannot monitor and inject simultaneously on same interface
- **Mitigation**: Use secondary interface for injection (ESP32-S3 supports 2 interfaces)

## Implementation Phases

### Phase 1: Foundation (Estimated: 2 weeks)
- [ ] ESP32 firmware skeleton with serial transport
- [ ] Basic packet capture streaming
- [ ] Host transport layer
- [ ] Device discovery/integration with wifite2 args

### Phase 2: Core Attacks (Estimated: 3 weeks)
- [ ] Channel hopping implementation
- [ ] Deauth injection for WPA handshake
- [ ] WEP injection support
- [ ] AP scanning/capturing

### Phase 3: Advanced Attacks (Estimated: 2 weeks)
- [ ] PMKID extraction
- [ ] WPS EAPOL handling
- [ ] Multi-band support (ESP32-S3)

### Phase 4: Polish (Estimated: 1 week)
- [ ] Error handling/recovery
- [ ] Performance optimization
- [ ] Documentation and examples

## Success Metrics
- [ ] All ESP32 variants enumerate correctly
- [ ] WPA handshake capture works on 2.4GHz
- [ ] 5GHz support verified on ESP32-S3
- [ ] WEP attacks functional (ARP replay tested)
- [ ] Zero regressions in existing wifite2 functionality