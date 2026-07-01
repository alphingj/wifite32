package com.wifite32.android.utils;
public final class FramePacket {
    public final long ts;
    public final int rssi;
    public final int len;
    public final byte[] frame;
    public FramePacket(long ts, int rssi, int len, byte[] frame) {
        this.ts = ts; this.rssi = rssi; this.len = len; this.frame = frame;
    }
}
