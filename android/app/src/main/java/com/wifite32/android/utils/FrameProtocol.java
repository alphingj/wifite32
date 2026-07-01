package com.wifite32.android.utils;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
public final class FrameProtocol {
    private FrameProtocol() {}
    public static FramePacket parse(byte[] data) {
        if (data == null || data.length < 11) return null;
        long ts = ByteBuffer.wrap(data, 0, 8).order(ByteOrder.LITTLE_ENDIAN).getLong();
        int rssi = data[8] & 0xFF;
        int len = ((data[10] & 0xFF) << 8) | (data[9] & 0xFF);
        if (data.length < 11 + len) return null;
        byte[] frame = new byte[len];
        System.arraycopy(data, 11, frame, 0, len);
        return new FramePacket(ts, rssi, len, frame);
    }
    public static byte[] cmd(byte id, String... args) {
        byte[] h = new byte[2];
        h[0] = id;
        h[1] = (byte)(args.length & 0xFF);
        byte[] ab = new byte[args.length * 32];
        for (int i = 0; i < args.length; i++) {
            byte[] b = args[i].getBytes();
            int m = Math.min(b.length, 31);
            System.arraycopy(b, 0, ab, i * 32, m);
        }
        byte[] r = new byte[h.length + ab.length];
        System.arraycopy(h, 0, r, 0, h.length);
        System.arraycopy(ab, 0, r, h.length, ab.length);
        return r;
    }
}
