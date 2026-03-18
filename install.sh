#!/bin/bash
#
# Builds ScreengrabOCR.app, installs to ~/Applications,
# adds as a Login Item, and removes the old Quick Action.
#
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ScreengrabOCR"
INSTALL_DIR="$HOME/Applications"

# Build
./build.sh

mkdir -p "$INSTALL_DIR"

# Quit existing instance
osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
sleep 0.5

# Remove old version and install new
rm -rf "$INSTALL_DIR/${APP_NAME}.app"
cp -R "build/${APP_NAME}.app" "$INSTALL_DIR/"

# Remove old Quick Action (Automator workflow)
if [[ -d "$HOME/Library/Services/OCR Screenshot.workflow" ]]; then
    rm -rf "$HOME/Library/Services/OCR Screenshot.workflow"
    /System/Library/CoreServices/pbs -flush 2>/dev/null || true
    echo "Removed old Quick Action: OCR Screenshot.workflow"
fi

# Add as Login Item (idempotent)
osascript -e "
tell application \"System Events\"
    try
        delete login item \"${APP_NAME}\"
    end try
    make login item at end with properties {path:\"${INSTALL_DIR}/${APP_NAME}.app\", hidden:true}
end tell
" 2>/dev/null

echo ""
echo "Installed: $INSTALL_DIR/${APP_NAME}.app"
echo "Added as Login Item (starts automatically on login)"
echo ""
echo "Launching..."
open "$INSTALL_DIR/${APP_NAME}.app"
echo ""
echo "First launch:"
echo "  1. Allow notifications when prompted"
echo "  2. Grant Screen Recording in System Settings > Privacy & Security > Screen Recording"
echo "  3. Press Cmd+Shift+2 to OCR any screen region"
