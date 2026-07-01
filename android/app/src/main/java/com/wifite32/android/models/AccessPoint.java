package com.wifite32.android.models;
public final class AccessPoint {
    public final String bssid;
    public final String ssid;
    public final int channel;
    public final int rssi;
    public final String encryption;
    public final boolean wpsEnabled;
    public AccessPoint(String bssid, String ssid, int channel, int rssi, String encryption, boolean wpsEnabled) {
        this.bssid = bssid; this.ssid = ssid; this.channel = channel; this.rssi = rssi;
        this.encryption = encryption; this.wpsEnabled = wpsEnabled;
    }
}
