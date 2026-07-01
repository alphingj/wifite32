package com.wifite32.android.utils;
public final class Esp32Protocol {
    public static final int BAUD_RATE = 921600;
    public static final int FRAME_HEADER_LENGTH = 11;
    public static final int MAX_FRAME_SIZE = 2304;
    public static final byte CMD_SCAN = 0x01;
    public static final byte CMD_CAPTURE = 0x02;
    public static final byte CMD_INJECT = 0x03;
    public static final byte CMD_CHANNEL = 0x04;
    public static final byte CMD_WPS_REG = 0x05;
    public static final byte CMD_DEAUTH = 0x06;
    public static final byte CMD_PMKID = 0x07;
    public static final byte CMD_CAPABILITIES = 0x08;
    public static final byte CMD_PING = 0x09;
    public static final byte CMD_SET_FILTER = 0x0A;
    private Esp32Protocol() {}
}
