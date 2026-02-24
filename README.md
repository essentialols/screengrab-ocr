# screengrab-ocr

Native macOS screen region OCR tool. Select a screen region and extract text instantly using Apple's Vision framework. Built in Swift, no dependencies.

## Features

- Interactive screen region selection
- OCR via Apple Vision framework (on-device, no API calls)
- Copies recognized text to clipboard
- Installable as a macOS keyboard shortcut

## Requirements

- macOS 12+
- Xcode command line tools

## Setup

```sh
./build.sh              # compile the Swift binary
./install-shortcut.sh   # set up as macOS shortcut
```

## Usage

Trigger via the configured keyboard shortcut (or run `./screengrab-ocr` directly). Select a screen region; recognized text is copied to your clipboard.

## Files

| File | Purpose |
|------|---------|
| `screengrab-ocr.swift` | Main source: screen capture + Vision OCR |
| `build.sh` | Compiles the Swift binary |
| `install-shortcut.sh` | Registers as macOS keyboard shortcut |
