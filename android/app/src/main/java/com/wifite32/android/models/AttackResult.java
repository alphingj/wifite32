package com.wifite32.android.models;
public final class AttackResult {
    public final String type;
    public final String targetBssid;
    public final boolean success;
    public final String credential;
    public final String message;
    public AttackResult(String type, String targetBssid, boolean success, String credential, String message) {
        this.type = type; this.targetBssid = targetBssid; this.success = success;
        this.credential = credential; this.message = message;
    }
}
