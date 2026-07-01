package com.wifite32.android.services;
public final class AttackEngine {
    public static class Phase {
        public static final Phase IDLE = new Phase();
        private Phase() {}
    }
    public static class Evt {
        public static final Evt START_SCAN = new Evt();
        private Evt() {}
    }
    private AttackEngine() {}
}
