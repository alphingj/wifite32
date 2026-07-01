package com.wifite32.android.ui;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("Wifite32 Android\n\nConnect ESP32 via USB OTG\n\nBuild: python3 build-apk.py");
        tv.setTextSize(18f);
        tv.setPadding(40, 40, 40, 40);
        addContentView(tv, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    }
}
