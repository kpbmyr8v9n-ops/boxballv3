#!/usr/bin/env bash
# Usage: bash scripts/build-android.sh apk|aab   (needs Node 22+, JDK 21, Android SDK; or just open ./android in Android Studio)
set -e
cd "$(dirname "$0")/.."
[ -d node_modules ] || npm install
[ -d android ] || npm run android:add
npx cap sync android
cd android
if [ "$1" = "aab" ]; then ./gradlew bundleRelease; echo "AAB: android/app/build/outputs/bundle/release/app-release.aab"
else ./gradlew assembleDebug; echo "APK: android/app/build/outputs/apk/debug/app-debug.apk"; fi
