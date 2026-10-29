#!/usr/bin/env bash
set -euo pipefail

# メニューバーからスリープ無効化(pmset -a disablesleep)を切り替える nosleep をビルドし、
# ログイン時に自動起動する LaunchAgent と、pmset をパスワードなしで実行できる sudoers を置く。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin/nosleep"
LABEL="com.rasukarusan.nosleep"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SUDOERS="/etc/sudoers.d/nosleep"

mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
swiftc -O -o "$BIN" -framework Cocoa "$SCRIPT_DIR/nosleep.swift"

# 許可するのは disablesleep の 0/1 切り替えだけ
SUDOERS_LINE="$(whoami) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
if [ "$(sudo cat "$SUDOERS" 2>/dev/null)" != "$SUDOERS_LINE" ]; then
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

echo "  built: $BIN"
