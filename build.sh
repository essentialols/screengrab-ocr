#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ScreengrabOCR"
APP_DIR="build/${APP_NAME}.app/Contents"

rm -rf "build/${APP_NAME}.app"
mkdir -p "$APP_DIR/MacOS"

swiftc -O \
    -target arm64-apple-macos12.0 \
    -framework Vision \
    -framework AppKit \
    -framework Carbon \
    -framework UserNotifications \
    -o "$APP_DIR/MacOS/$APP_NAME" \
    screengrab-ocr.swift

cp Info.plist "$APP_DIR/Info.plist"

codesign --force --sign - --identifier "com.ingmarsturm.screengrab-ocr" \
    "build/${APP_NAME}.app"

echo "Built: build/${APP_NAME}.app"
