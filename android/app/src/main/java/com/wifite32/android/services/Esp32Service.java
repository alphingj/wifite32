package com.wifite32.android.services;
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
public class Esp32Service extends Service {
    public class LocalBinder extends android.os.Binder {
        public Esp32Service getService() { return Esp32Service.this; }
    }
    private final LocalBinder binder = new LocalBinder();
    @Override
    public IBinder onBind(Intent intent) { return binder; }
}
