#!/bin/bash
# Build AiyodlxApk - liquid-glass WebView wrapper for ai.yodlx.com
#
# 依赖: JDK 17 + Android SDK 34 (platforms/android-34 + build-tools/34.0.0)
# 用法: ./build.sh
# 环境变量覆盖: JAVA_HOME / ANDROID_HOME / SDK_VERSION / BUILD_TOOLS_VERSION
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# ── 工具链探测 ──────────────────────────────────────────────
export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export SDK_VERSION="${SDK_VERSION:-34}"
export BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-34.0.0}"

# JDK: 优先环境变量 → 常见路径 → which
if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then :; fi
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
  for cand in /opt/jdk-17* /usr/lib/jvm/java-17* /usr/lib/jvm/openjdk-17*; do
    if [ -x "$cand/bin/java" ]; then export JAVA_HOME="$cand"; break; fi
  done
fi
if [ -z "${JAVA_HOME:-}" ] && command -v java >/dev/null 2>&1; then
  export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
fi
if [ ! -x "$JAVA_HOME/bin/java" ]; then
  echo "ERROR: JDK 17 not found. Set JAVA_HOME or install openjdk-17." >&2
  exit 1
fi
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

SDK="$ANDROID_HOME"
PLATFORM="$SDK/platforms/android-$SDK_VERSION"
BT="$SDK/build-tools/$BUILD_TOOLS_VERSION"
AAPT="$BT/aapt"
D8="$BT/d8"
ZIPALIGN="$BT/zipalign"
JAVAC="$JAVA_HOME/bin/javac"
JARSIGNER="$JAVA_HOME/bin/jarsigner"
APKSIGNER="$BT/apksigner"

# 工具链完整性检查
for tool in "$AAPT" "$D8" "$ZIPALIGN" "$APKSIGNER" "$PLATFORM/android.jar"; do
  if [ ! -x "$tool" ] && [ ! -f "$tool" ]; then
    echo "ERROR: missing toolchain component: $tool" >&2
    echo "  Run: sdkmanager --sdk_root=$SDK 'platforms;android-$SDK_VERSION' 'build-tools;$BUILD_TOOLS_VERSION'" >&2
    exit 1
  fi
done

APP_ID="com.yodlx.apk"
MIN_SDK=21
TARGET_SDK="$SDK_VERSION"
VERCODE=1
VERNAME="1.0.0"
SRC="$ROOT/src/main"
TMP="$ROOT/build"
KEYSTORE="$ROOT/keystore.jks"

rm -rf "$TMP"; mkdir -p "$TMP"

# ── 签名密钥（debug 风格，缺失自动生成） ──────────────────
if [ ! -f "$KEYSTORE" ]; then
  echo "-- generating keystore ..."
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

ls -lh "$TMP/AiyodlxApk.apk"
echo "BUILD OK -> $TMP/AiyodlxApk.apk"