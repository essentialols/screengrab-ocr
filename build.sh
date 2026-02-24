#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swiftc -O -framework Vision -framework AppKit -o screengrab-ocr screengrab-ocr.swift
codesign --force --sign - screengrab-ocr
echo "Built: ./screengrab-ocr"
