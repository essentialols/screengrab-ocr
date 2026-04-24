# screengrab-ocr

Native macOS screen region OCR. Select a screen region with a global hotkey, extract text instantly via Apple Vision, and copy it to your clipboard.

## Features

- Global hotkey (Cmd+Shift+2) works in any app, any context
- OCR via Apple Vision framework (on-device, no API calls)
- Copies recognized text to clipboard with notification
- Menu bar icon with manual trigger
- Starts automatically on login
- Stable bundle ID for persistent Screen Recording permission

## Requirements

- macOS 12+
- Xcode command line tools

## Setup

```sh
./install.sh
```

This builds the app, installs it to `~/Applications`, adds it as a Login Item, and launches it. On first launch:

1. Allow notifications when prompted
2. Grant Screen Recording in System Settings > Privacy & Security > Screen Recording
3. Press Cmd+Shift+2 to OCR any screen region

## Usage

**Hotkey**: Cmd+Shift+2 anywhere on the system. Select a region; recognized text is copied to your clipboard.

**Menu bar**: Click the viewfinder icon for manual trigger or to quit.

## Files

| File | Purpose |
|------|---------|
| `screengrab-ocr.swift` | App source: global hotkey, screen capture, Vision OCR, menu bar |
| `Info.plist` | App bundle metadata and Screen Recording usage description |
| `build.sh` | Compiles Swift source into a signed .app bundle |
| `install.sh` | Builds, installs to ~/Applications, sets up Login Item |
| `uninstall.sh` | Removes app, Login Item, and old Quick Action |

## Uninstall

```sh
./uninstall.sh
```

## Known Limitations

- macOS only (relies on Apple Vision and the `screencapture` binary).
- The Cmd+Shift+2 hotkey is fixed in source. If another app has claimed it, you will see a notification at launch and the menu bar item is the only trigger.
- Screen Recording permission must be granted manually on first run, per macOS policy.

## License

MIT. See [LICENSE](LICENSE).
