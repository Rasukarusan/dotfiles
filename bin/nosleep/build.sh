#!/usr/bin/env bash
set -euo pipefail

# メニューバーからスリープ無効化(pmset -a disablesleep)を切り替える NoSleep.app をビルドし、
# ログイン時に自動起動する LaunchAgent と、pmset をパスワードなしで実行できる sudoers を置く。
# ~/Applications に .app として置くので Spotlight からも起動できる。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.rasukarusan.nosleep"
APP="$HOME/Applications/NoSleep.app"
BIN="$APP/Contents/MacOS/nosleep"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SUDOERS="/etc/sudoers.d/nosleep"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$HOME/Library/LaunchAgents"
swiftc -O -o "$BIN" -framework Cocoa "$SCRIPT_DIR/nosleep.swift"

iconset="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$iconset"
swift "$SCRIPT_DIR/icon.swift" "$iconset"
iconutil -c icns -o "$APP/Contents/Resources/AppIcon.icns" "$iconset"
rm -rf "$(dirname "$iconset")"

# LSUIElement で Dock に出さず、メニューバーだけに常駐させる
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>$LABEL</string>
  <key>CFBundleName</key>
  <string>NoSleep</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleExecutable</key>
  <string>nosleep</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF
codesign --force --sign - "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

# 許可するのは disablesleep の 0/1 切り替えだけ
SUDOERS_LINE="$(whoami) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
if ! sudo -n -l /usr/bin/pmset -a disablesleep 0 >/dev/null 2>&1 ||
   ! sudo -n -l /usr/bin/pmset -a disablesleep 1 >/dev/null 2>&1; then
  tmp="$(mktemp)"
  echo "$SUDOERS_LINE" > "$tmp"
  sudo visudo -cf "$tmp" >/dev/null
  sudo install -m 0440 -o root -g wheel "$tmp" "$SUDOERS"
  rm -f "$tmp"
fi

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

# 起動しっぱなしだと古いバイナリが動き続けるので入れ直す
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "  built: $APP"
