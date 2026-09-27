#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$ROOT_DIR/dist/Buttershell.app"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/buttershell" "$APP_DIR/Contents/MacOS/buttershell"
ditto "$BIN_DIR/Buttershell_Buttershell.bundle" \
    "$APP_DIR/Contents/Resources/Buttershell_Buttershell.bundle"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$ROOT_DIR/AppInfo.plist" "$APP_DIR/Contents/Info.plist"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

printf 'created %s\n' "$APP_DIR"
