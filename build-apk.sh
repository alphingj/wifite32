#!/bin/bash
set -euo pipefail
APPDIR=android/app/src/main
OUT=/home/gj/wifite32/build/android
JAVA_HOME="$(readlink -f /usr/bin/java | sed 's|/bin/java||')"
SDK_HOME=${ANDROID_HOME:-/home/gj/Android/Sdk}
PLAT=$SDK_HOME/platforms/android-35/android.jar
KOTLINC=/home/gj/Downloads/android-studio/plugins/Kotlin/kotlinc/bin/kotlinc
D8="$SDK_HOME/build-tools/34.0.0/d8"
AAPT2="$SDK_HOME/build-tools/34.0.0/aapt2"
ZIPALIGN="$SDK_HOME/build-tools/34.0.0/zipalign"
APKSIGNER="$SDK_HOME/build-tools/34.0.0/apksigner"

CP="$PLAT"
for j in \
  "$HOME/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-stdlib/2.1.10"/*kotlin-stdlib-2.1.10.jar \
  "$HOME/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlinx/kotlinx-coroutines-android/1.10.2"/*kotlinx-coroutines-android-1.10.2.jar \
  "$HOME/.gradle/caches/8.13/transforms/36cba8bd0806c20a3e5305ab819ed973/transformed/material-1.12.0-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/3cced542944b295a21ad7f81029a0348/transformed/appcompat-1.7.0-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/97542c3efb01142ebc62e2ba6d7b418d/transformed/appcompat-resources-1.7.0-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/3abeba4ab0154839cd58bb28b5d92288/transformed/constraintlayout-2.0.1-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/46d9b062ba5d133cc5a2baa3ad75b354/transformed/lifecycle-livedata-core-2.6.2-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/62d3b6b4dd59f472249307902c35341a/transformed/lifecycle-viewmodel-2.6.2-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/f413101a03962a592afc60ea5481c169/transformed/lifecycle-runtime-2.6.2-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/c8c0da9a5e3463f7bc864bc3b71a7a1f/transformed/fragment-1.6.1-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/a22ec3c0f412e6ccd5936e36c8c82573/transformed/fragment-ktx-1.6.1-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/20b8e5bb6588470b819d7f7e83eb2a29/transformed/core-ktx-1.13.1-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/c8bf50ad72e1d32b462bfd38d9afb4f7/transformed/core-1.13.1-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/6249987dce84c9d9a46a4ff97ca184ca/transformed/activity-1.8.0-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/d4cb4042efb1d4e9c8fa3588a81f50db/transformed/recyclerview-1.3.2-runtime.jar" \
  "$HOME/.gradle/caches/8.13/transforms/fdb5ebadb6adf50c302d6dcf756caed7/transformed/activity-ktx-1.8.0-runtime.jar"
 do CP="$CP:$j"; done

mkdir -p "$OUT"/{res,dex,tmp}
cp -rf "$APPDIR"/res/* "$OUT/res/"
"$AAPT2" compile --dir "$OUT/res" -o "$OUT/res/compiled.zip"

SRCDIR="$APPDIR/java"
rm -rf "$OUT/res/tmp" "$OUT/tmp/classes"
mkdir -p "$OUT/res/tmp" "$OUT/tmp/classes"

# compile kotlin
KOTLIN_FILES=$(find "$SRCDIR" -name '*.kt' | tr '\n' ' ')
echo "[+] kotlinc $KOTLIN_FILES"
"$KOTLINC" \
  -cp "$CP" \
  -d "$OUT/tmp/classes/app.jar" \
  -no-stdlib \
  -Xuse-ir \
  -Xopt-in=kotlin.RequiresOptIn \
  $KOTLIN_FILES 2>&1 | tail -50 || true

echo "[+] compile to dex"
mkdir -p "$OUT/tmp/dex"
if [ -f "$OUT/tmp/classes/app.jar" ]; then
  cp "$OUT/tmp/classes/app.jar" "$OUT/tmp/dex/app.jar"
else
  echo "WARN: no app classes, creating stub"
  echo "public class stub { }" > /tmp/stub.java
  jalap -d "$OUT/tmp/dex/stub.jar" -cp "$PLAT" /tmp/stub.jar || javac -d "$OUT/tmp/dex/stub" -cp "$PLAT" /tmp/stub.java 2>/dev/null || true
fi

"$D8" --min-api 26 --lib "$PLAT" --output "$OUT/tmp/dex" "$OUT/tmp/dex/"*.jar "$CP" 2>&1 | tail -20 || true

ls "$OUT/tmp/dex/" | head -30

echo "[+] package apk"
APK_UNSIGNED="$OUT/app-unsigned.apk"
"$AAPT2" link --proto-format -I "$PLAT" -o "$APK_UNSIGNED" --manifest "$APPDIR/AndroidManifest.xml" -R "$OUT/res/compiled.zip" --java "$OUT/res/tmp" "$OUT/tmp/dex/classes*.dex" 2>&1 | tail -40 || true

echo "[+] align $APK_UNSIGNED"
"$ZIPALIGN" -p 4 "$APK_UNSIGNED" "$OUT/app-aligned-unsigned.apk" 2>&1 || true

echo "[+] sign"
mkdir -p /tmp/wifite32-keystore
if [ ! -f /tmp/wifite32-keystore/debug.keystore ]; then
  keytool -genkeypair -keystore /tmp/wifite32-keystore/debug.keystore -alias androiddebugkey -storepass android -keypass android -keyalg RSA -validity 10000 -dname "CN=Wifite32,O=Wifite,OU=Mobility,L=Planet,ST=GHz,C=US" 2>&1 | tail -5 || true
fi
"$APKSIGNER" sign --ks /tmp/wifite32-keystore/debug.keystore --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out "$OUT/wifite32-debug.apk" "$OUT/app-aligned-unsigned.apk" 2>&1 | tail -10 || true

ls -lh "$OUT"/wifite32-debug.apk "$OUT"/app-aligned-unsigned.apk "$APK_UNSIGNED" 2>/dev/null || true
file "$OUT/wifite32-debug.apk" 2>/dev/null || true
