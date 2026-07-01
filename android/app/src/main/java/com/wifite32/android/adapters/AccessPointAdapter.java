package com.wifite32.android.adapters;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import com.wifite32.android.models.AccessPoint;
import java.util.List;
public class AccessPointAdapter {
    private final List<AccessPoint> items;
    public AccessPointAdapter(List<AccessPoint> items) { this.items = items; }
    public int getCount() { return items.size(); }
    public AccessPoint getItem(int i) { return items.get(i); }
    public long getItemId(int i) { return i; }
    public View getView(int i, View v, ViewGroup p) {
        TextView tv = new TextView(p.getContext());
        AccessPoint ap = getItem(i);
        tv.setText(ap.ssid.isEmpty() ? "(Hidden)" : ap.ssid + "\n" + ap.bssid + " | Ch" + ap.channel + " | " + ap.rssi + "dBm | " + ap.encryption);
        tv.setPadding(12,12,12,12);
        return tv;
    }
}
