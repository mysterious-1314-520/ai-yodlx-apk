#!/bin/bash
# Build AiyodlxApk - liquid-glass WebView wrapper for ai.yodlx.com
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

JAVA_CAND="/opt/jdk-17.0.20.1+1"
if [ -x "$JAVA_CAND/bin/java" ]; then export JAVA_HOME="$JAVA_CAND"
else export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"
fi
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="/opt/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

SDK="$ANDROID_HOME"
PLATFORM="$SDK/platforms/android-34"
BT="$SDK/build-tools/34.0.0"
AAPT="$BT/aapt"
D8="$BT/d8"
ZIPALIGN="$BT/zipalign"
JAVAC="$JAVA_HOME/bin/javac"
JARSIGNER="$JAVA_HOME/bin/jarsigner"
APKSIGNER="$BT/apksigner"

APP_ID="com.yodlx.apk"
SRC="$ROOT/src/main"
TMP="$ROOT/build"
KEYSTORE="$ROOT/keystore.jks"

rm -rf "$TMP"; mkdir -p "$TMP"

# ---- keystore (debug-style, kept in repo for reproducible builds) ----
if [ ! -f "$KEYSTORE" ]; then
  keytool -genkey -v -keystore "$KEYSTORE" -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US" -storepass android -keypass android -noprompt
fi

echo "=== [1/6] aapt: compile resources -> resources.ap_ ==="
"$AAPT" package -f -I "$PLATFORM/android.jar" \
  -M "$SRC/AndroidManifest.xml" \
  -S "$SRC/res" \
  -A "$SRC/assets" \
  -J "$TMP" \
  -o "$TMP/resources.ap_"

echo "=== [2/6] javac -> classes ==="
mkdir -p "$TMP/classes"
"$JAVAC" -encoding UTF-8 -d "$TMP/classes" \
  -cp "$PLATFORM/android.jar" \
  "$TMP/R.java" "$SRC/java/com/yodlx/apk/MainActivity.java"

echo "=== [3/6] d8 -> classes.dex ==="
mkdir -p "$TMP/dexin"
find "$TMP/classes" -name "*.class" -exec cp {} "$TMP/dexin/" \;
"$D8" --output "$TMP" --lib "$PLATFORM/android.jar" "$TMP/dexin"/*.class
# D8 writes classes.dex + possibly classes2.dex directly into --output
ls "$TMP"/*.dex

echo "=== [4/6] aapt: package APK (no dex) -> unsigned.apk ==="
"$AAPT" package -f -I "$PLATFORM/android.jar" \
  -M "$SRC/AndroidManifest.xml" \
  -S "$SRC/res" \
  -A "$SRC/assets" \
  -F "$TMP/unsigned.apk"

echo "=== [5/6] inject classes.dex + sign ==="
cd "$TMP"
jar uf unsigned.apk classes.dex
cd "$ROOT"
"$JARSIGNER" -verbose -keystore "$KEYSTORE" -storepass android -keypass android \
  -signedjar "$TMP/signed.apk" "$TMP/unsigned.apk" androiddebugkey

echo "=== [6/6] zipalign + apksigner ==="
"$ZIPALIGN" -f 4 "$TMP/signed.apk" "$TMP/aligned.apk"
"$APKSIGNER" sign --ks "$KEYSTORE" --ks-pass pass:android \
  --ks-key-alias androiddebugkey --key-pass pass:android \
  --out "$TMP/AiyodlxApk.apk" "$TMP/aligned.apk"

ls -la "$TMP/AiyodlxApk.apk"
echo "BUILD OK -> $TMP/AiyodlxApk.apk"