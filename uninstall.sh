#!/bin/bash
set -euo pipefail

APP_NAME="ScreengrabOCR"

# Quit
osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
sleep 0.5

# Remove Login Item
osascript -e "
tell application \"System Events\"
    try
        delete login item \"${APP_NAME}\"
    end try
end tell
" 2>/dev/null

# Remove app
rm -rf "$HOME/Applications/${APP_NAME}.app"

# Remove old Quick Action too (if it exists)
rm -rf "$HOME/Library/Services/OCR Screenshot.workflow"

# Remove log files
rm -f "$HOME/Library/Logs/screengrab-ocr.log" "$HOME/Library/Logs/screengrab-ocr.log.1"

echo "Uninstalled ScreengrabOCR"
echo "Note: Screen Recording permission entry remains in System Settings (remove manually if desired)"
