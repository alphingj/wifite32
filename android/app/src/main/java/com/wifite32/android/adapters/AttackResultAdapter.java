package com.wifite32.android.adapters;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import com.wifite32.android.models.AttackResult;
import java.util.List;
public class AttackResultAdapter {
    private final List<AttackResult> items;
    public AttackResultAdapter(List<AttackResult> items) { this.items = items; }
    public int getCount() { return items.size(); }
    public AttackResult getItem(int i) { return items.get(i); }
    public long getItemId(int i) { return i; }
    public View getView(int i, View v, ViewGroup p) {
        TextView tv = new TextView(p.getContext());
        AttackResult r = getItem(i);
        tv.setText(r.type + " -> " + r.targetBssid + " | " + (r.success ? "OK" : "FAIL"));
        tv.setPadding(12,12,12,12);
        return tv;
    }
}
