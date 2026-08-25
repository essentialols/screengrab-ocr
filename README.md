# screengrab-ocr

Native macOS screen-region optical character recognition (OCR). Press a global hotkey, select part of the screen, recognize text locally with Apple Vision, and copy the result to the clipboard.

## Current status

This is a small, single-purpose native menu-bar app. The current implementation is the `.app`-bundle version introduced after the older Automator Quick Action approach; `install.sh` removes that legacy Quick Action if it is still present.

The last substantive code hardening in this repository was completed on **2026-07-26**. Treat that date as repository history, not as a claim that the app has been revalidated against every newer macOS release.

The current build script targets **Apple Silicon (`arm64`) on macOS 12 or newer**.

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

On first launch, allow notifications if desired and grant Screen Recording access in **System Settings → Privacy & Security → Screen Recording**.

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
| `screengrab-ocr.swift` | App source: menu bar, global hotkey, capture, Apple Vision OCR, clipboard, notifications, and logging |
| `Info.plist` | Bundle identity, minimum macOS version, agent-app behavior, and Screen Recording usage description |
| `build.sh` | Builds and ad-hoc signs `build/ScreengrabOCR.app` for `arm64-apple-macos12.0` |
| `install.sh` | Builds, installs to `~/Applications`, creates the Login Item, and launches the app |
| `uninstall.sh` | Removes installed/runtime artifacts owned by this project |
| `.gitignore` | Excludes build products and local generated files |
| `LICENSE` | MIT license |

The flat layout is intentional. `build.sh` directly expects `screengrab-ocr.swift` and `Info.plist` beside it, while `install.sh` invokes `./build.sh` relative to the repository root. Moving those files into conventional `src/` or `scripts/` folders would require coordinated path changes and provides little navigational benefit at this repository size.

## Development and lightweight validation

For documentation or shell-only changes, useful low-cost checks are:

```sh
bash -n build.sh install.sh uninstall.sh
plutil -lint Info.plist
```

To validate the native build on a compatible Mac:

```sh
./build.sh
codesign --verify --deep --strict build/ScreengrabOCR.app
```

A full behavioral check additionally requires granting Screen Recording permission and exercising both the hotkey and menu-bar capture path. There is currently no automated test suite tracked in this repository, so do not describe a build-only check as end-to-end validation.

## Known limitations

- macOS only; the implementation depends on Apple Vision, AppKit, Carbon hotkeys, and `/usr/sbin/screencapture`.
- The current build is Apple-Silicon-only because `build.sh` explicitly targets `arm64-apple-macos12.0`.
- **Command+Shift+2** is fixed in source rather than user-configurable.
- If another app owns that hotkey, registration fails and the menu-bar trigger must be used instead.
- Screen Recording permission must be granted through macOS; installation cannot bypass that privacy control.
- OCR quality depends on the captured image and Apple Vision's recognition behavior.

## License

MIT. See [LICENSE](LICENSE).
