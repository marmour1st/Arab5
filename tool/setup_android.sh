#!/usr/bin/env bash
# Prepares the Android project files, then builds nothing.
# Run once from the project folder (Git Bash on Windows works):
#   bash tool/setup_android.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  echo "Creating Android project files..."
  flutter create --org com.arabacademy --project-name arab_academy --platforms android .
fi

echo "Applying app settings (internet permission, name, splash color)..."
cp android_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
for d in drawable drawable-v21; do
  if [ -d "android/app/src/main/res/$d" ]; then
    cp android_overrides/launch_background.xml "android/app/src/main/res/$d/launch_background.xml"
  fi
done

flutter pub get
echo "Generating app icons..."
dart run flutter_launcher_icons

echo
echo "Done. Build the APK with:"
echo "  flutter build apk --release"
