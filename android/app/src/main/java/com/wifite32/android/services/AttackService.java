package com.wifite32.android.services;
import android.app.Service;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.os.IBinder;
import com.wifite32.android.ui.MainActivity;
public class AttackService extends Service {
    @Override public void onCreate() {
        super.onCreate();
        NotificationChannel ch = new NotificationChannel("wifite32", "Wifite32", NotificationManager.IMPORTANCE_LOW);
        NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        nm.createNotificationChannel(ch);
        startForeground(101, new Notification.Builder(this, "wifite32")
            .setContentTitle("Wifite32").setContentText("idle")
            .setSmallIcon(android.R.drawable.stat_sys_warning).build());
    }
    @Override public IBinder onBind(Intent intent) { return null; }
}
