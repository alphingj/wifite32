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

import com.hoho.android.usbserial.driver.UsbSerialDriver;
import com.hoho.android.usbserial.driver.UsbSerialPort;
import com.hoho.android.usbserial.driver.UsbSerialProber;
import com.wifite32.android.utils.FrameProtocol;
import com.wifite32.android.utils.FramePacket;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

public class UsbSerialService extends Service {
    private static final String TAG = "UsbSerialService";
    private final IBinder binder = new LocalBinder();
    private UsbSerialPort port;
    private static final int BAUD_RATE = 921600;

    public class LocalBinder extends Binder {
        public UsbSerialService getService() { return UsbSerialService.this; }
    }
    @Override public IBinder onBind(Intent intent) { return binder; }

    public interface PacketListener {
        void onFrameReceived(FramePacket frame);
        void onConnected(boolean status);
    }
    private final List<PacketListener> listeners = new java.util.ArrayList<>();
    public void registerListener(PacketListener l) { listeners.add(l); }
    public void unregisterListener(PacketListener l) { listeners.remove(l); }

    public boolean connect(UsbDevice device) {
        try {
            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            List<UsbSerialDriver> drivers = UsbSerialProber.getDefaultProber().probeDevice(device);
            if (drivers.isEmpty()) {
                Log.e(TAG, "No USB serial driver found");
                notifyListeners(false);
                return false;
            }
            UsbSerialDriver driver = drivers.get(0);
            android.hardware.usb.UsbDeviceConnection conn = usbManager.openDevice(driver.getDevice());
            if (conn == null) {
                Log.e(TAG, "Failed to open USB device");
                notifyListeners(false);
                return false;
            }
            port = driver.getPorts().get(0);
            port.open(conn);
            port.setParameters(BAUD_RATE, 8, 1, 0);
            Log.i(TAG, "Connected at " + BAUD_RATE + " baud");
            startReaderThread();
            notifyListeners(true);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "connect fail", e);
            notifyListeners(false);
            return false;
        }
    }

    private void startReaderThread() {
        new Thread(() -> {
            byte[] buffer = new byte[4096];
            while (port != null) {
                try {
                    int len = port.read(buffer, 100);
                    if (len > 0) {
                        for (int off = 0; off <= len - 7; ) {
                            int frameLen = ((buffer[off + 6] & 0xFF) << 8) | (buffer[off + 5] & 0xFF);
                            if (off + 7 + frameLen > len) break;
                            try {
                                FramePacket pkt = FrameProtocol.parse(Arrays.copyOfRange(buffer, off, off + 7 + frameLen));
                                if (pkt != null) {
                                    for (PacketListener l : listeners) l.onFrameReceived(pkt);
                                }
                            } catch (Exception e) {
                                Log.w(TAG, "Parse error", e);
                            }
                            off += 7 + frameLen;
                        }
                    }
                } catch (IOException e) {
                    Log.w(TAG, "Read error", e);
                }
            }
        }).start();
    }

    public void disconnect() {
        try {
            if (port != null) port.close();
        } catch (IOException e) {
            Log.w(TAG, "Close error", e);
        }
        port = null;
        notifyListeners(false);
    }

    public boolean isConnected() { return port != null; }

    public void sendCommand(byte cmdId, String... args) {
        if (port == null) return;
        try {
            String cmd = String.format("cmd:%02x:", cmdId);
            for (String a : args) cmd += a + ":";
            cmd += "\n";
            port.write(cmd.getBytes(), 100);
            Log.d(TAG, "Sent cmd: " + cmd.trim());
        } catch (IOException e) {
            Log.e(TAG, "send fail", e);
        }
    }

    private void notifyListeners(final boolean status) {
        for (PacketListener l : listeners) l.onConnected(status);
    }

    private final BroadcastReceiver usbReceiver = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) {
            if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(intent.getAction())) {
                disconnect();
            }
        }
    };
}