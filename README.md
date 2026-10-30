# screengrab-ocr

Native macOS screen-region optical character recognition (OCR). Press a global hotkey, select part of the screen, recognize text locally with Apple Vision, and copy the result to the clipboard.

A small, single-purpose native menu-bar app. It is built as a `.app` bundle (an earlier Automator Quick Action version is replaced; `install.sh` removes the old Quick Action if present). The build targets Apple Silicon (`arm64`) on macOS 12 or newer.

## What it does

- Registers **Command+Shift+2** as a system-wide hotkey.
- Opens macOS interactive region capture with `/usr/sbin/screencapture`.
- Runs accurate, on-device text recognition with Apple Vision.
- Uses Vision language correction when recognizing text.
- Copies recognized text to the system clipboard.
- Shows native notifications for success and most failures.
- Provides a menu-bar item as a manual fallback if the global hotkey cannot be registered.
- Installs as a macOS Login Item so it starts automatically after login.

No remote OCR service or application programming interface (API) is used by the recognition path.

## Requirements

- Apple Silicon Mac (`arm64`)
- macOS 12 or newer
- Xcode Command Line Tools, including `swiftc` and `codesign`
- Screen Recording permission for `ScreengrabOCR`
- Notification permission if you want status/error banners

## Install

From the repository root:

```sh
./install.sh
```

The installer:

1. runs `build.sh`;
2. builds `build/ScreengrabOCR.app`;
3. copies the app to `~/Applications/ScreengrabOCR.app`;
4. removes the retired `~/Library/Services/OCR Screenshot.workflow` if it still exists;
5. replaces any existing `ScreengrabOCR` Login Item with the newly installed app; and
6. launches the app.

On first launch, allow notifications if desired and grant Screen Recording access in **System Settings -> Privacy & Security -> Screen Recording**.

## Use

### Global hotkey

Press **Command+Shift+2**, then drag over the region you want to recognize. When OCR succeeds, the recognized text is copied to the clipboard and a notification reports the word and line counts.

Pressing **Escape** during region selection is treated as a normal cancellation and does not produce an error notification.

### Menu bar

Use the `text.viewfinder` menu-bar item to trigger OCR manually or quit the app. This remains available if another application has already claimed the global hotkey.

## Runtime data and cleanup

Temporary screenshots are created under the system temporary directory with unique filenames and are removed after processing.

Diagnostic logging is written to:

```text
~/Library/Logs/screengrab-ocr.log
```

When the log exceeds roughly 1 MiB, the app rotates it to `screengrab-ocr.log.1`. The uninstaller removes both files.

The logs can contain operational details such as capture filenames, image dimensions, OCR timing, character counts, and permission state. They do **not** intentionally log the recognized text itself.

## Uninstall

```sh
./uninstall.sh
```

This removes the Login Item, the installed app, the retired Quick Action if present, and the two local log files.

The macOS Screen Recording permission entry is **not** removed automatically. Remove it manually in System Settings if you no longer want it retained.

## Repository layout

| Path | Purpose |
| --- | --- |
| `screengrab-ocr.swift` | App source: menu bar, global hotkey, capture, Apple Vision OCR, clipboard, notifications, logging |
| `Info.plist` | Bundle identity, minimum macOS version, menu-bar-app behavior, Screen Recording usage description |
| `build.sh` | Builds and ad-hoc signs `build/ScreengrabOCR.app` for `arm64-apple-macos12.0` |
| `install.sh` | Builds, installs to `~/Applications`, creates the Login Item, launches the app |
| `uninstall.sh` | Removes installed and runtime artifacts |
| `LICENSE` | MIT license |

## Building and checking

```sh
./build.sh
codesign --verify --deep --strict build/ScreengrabOCR.app
```

Shell and plist sanity checks: `bash -n build.sh install.sh uninstall.sh` and `plutil -lint Info.plist`. There is no automated test suite; trying the hotkey and the menu-bar capture by hand (with Screen Recording permission granted) is the real check.

## Known limitations

- macOS only; the implementation depends on Apple Vision, AppKit, Carbon hotkeys, and `/usr/sbin/screencapture`.
- The current build is Apple-Silicon-only because `build.sh` explicitly targets `arm64-apple-macos12.0`.
- **Command+Shift+2** is fixed in source rather than user-configurable.
- If another app owns that hotkey, registration fails and the menu-bar trigger must be used instead.
- Screen Recording permission must be granted through macOS; installation cannot bypass that privacy control.
- OCR quality depends on the captured image and Apple Vision's recognition behavior.

## License

MIT. See [LICENSE](LICENSE).
