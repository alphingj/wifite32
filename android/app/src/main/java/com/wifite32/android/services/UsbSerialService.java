package com.wifite32.android.services;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;
import com.wifite32.android.utils.EscapeCipher;
import com.wifite32.android.utils.FrameProtocol;
import com.wifite32.android.utils.FramePacket;
import java.io.InputStream;
import java.io.OutputStream;
public class UsbSerialService extends Service {
    private final IBinder binder = new LocalBinder();
    public class LocalBinder extends Binder {
        public UsbSerialService getService() { return UsbSerialService.this; }
    }
    @Override public IBinder onBind(Intent intent) { return binder; }
    public interface PacketListener {
        void onFrameReceived(FramePacket frame);
        void onConnected(boolean status);
    }
    private InputStream input;
    private OutputStream output;
    private final java.util.List<PacketListener> listeners = new java.util.ArrayList<>();
    public void registerListener(PacketListener l) { listeners.add(l); }
    public void unregisterListener(PacketListener l) { listeners.remove(l); }
    public void connect(UsbDevice device) {
        try {
            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            android.hardware.usb.UsbDeviceConnection conn = usbManager.openDevice(device);
            if (conn == null) { notifyListeners(false); return; }
            input = new java.io.ByteArrayInputStream(new byte[0]);
            output = new java.io.ByteArrayOutputStream();
            notifyListeners(true);
        } catch (Exception e) {
            Log.e("UsbSerial", "connect fail", e);
            notifyListeners(false);
        }
    }
    public void disconnect() {
        try { if (input != null) input.close(); } catch (Exception e) {}
        try { if (output != null) output.close(); } catch (Exception e) {}
        input = null; output = null;
        notifyListeners(false);
    }
    public boolean isConnected() { return input != null; }
    public void sendCommand(byte cmdId, String[] args) {
        if (output == null) return;
        try {
            byte[] data = FrameProtocol.cmd(cmdId, args);
            Log.d("UsbSerial", "send cmd " + cmdId + " bytes=" + data.length);
        } catch (Exception e) { Log.e("UsbSerial", "send fail", e); }
    }
    private void notifyListeners(final boolean status) {
        for (PacketListener l : listeners) l.onConnected(status);
    }
    private void notifyFrame(final FramePacket frm) {
        for (PacketListener l : listeners) l.onFrameReceived(frm);
    }
    private final BroadcastReceiver usbReceiver = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) {
            if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(intent.getAction())) {
                disconnect();
            }
        }
    };
}
