#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$HOME/.claude/bin/claude-notify.app"
BINARY="$APP_DIR/Contents/MacOS/claude-notify"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$SCRIPT_DIR/claude-notify-Info.plist" "$APP_DIR/Contents/Info.plist"

if [ -f "$SCRIPT_DIR/icon.icns" ]; then
  cp "$SCRIPT_DIR/icon.icns" "$APP_DIR/Contents/Resources/icon.icns"
fi

swiftc -o "$BINARY" -framework Cocoa -framework UserNotifications "$SCRIPT_DIR/claude-notify.swift" 2>/dev/null

codesign --force --sign - "$APP_DIR" 2>/dev/null

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister "$APP_DIR" 2>/dev/null

echo "  built: $APP_DIR"
