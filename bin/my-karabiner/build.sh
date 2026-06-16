#!/usr/bin/env bash
set -euo pipefail

# my-karabiner を .app バンドルとしてビルドし、LaunchAgent として登録する。
# 再実行すると再ビルド & 再ロードする。
#
# .app バンドルにしている理由: 入力監視(Input Monitoring)などの TCC 権限は、
# 素のコマンドラインバイナリだと正しく紐付かないことがある。bundle id を持つ
# .app にすることで System 設定のトグルが確実に効くようになる(Karabiner や
# Hammerspoon と同じ方式)。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.rasukarusan.my-karabiner"
APP_DIR="$HOME/.local/bin/my-karabiner.app"
BINARY="$APP_DIR/Contents/MacOS/my-karabiner"
LOG="$HOME/Library/Logs/my-karabiner.log"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

mkdir -p "$APP_DIR/Contents/MacOS" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# 旧・素のバイナリが残っていれば掃除
rm -f "$HOME/.local/bin/my-karabiner"

# Info.plist 配置
cp "$SCRIPT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

# ビルド
swiftc -O -o "$BINARY" -framework Cocoa "$SCRIPT_DIR/my-karabiner.swift"

# .app バンドルごとアドホック署名(安定IDを付与)
codesign --force --deep --sign - --identifier "$LABEL" "$APP_DIR" 2>/dev/null || true

# Launch Services に登録(設定アプリのリストに出やすくする)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister "$APP_DIR" 2>/dev/null || true

# plist 生成(バイナリのパスを埋め込む)
sed -e "s|__BINARY__|$BINARY|g" -e "s|__LOG__|$LOG|g" \
  "$SCRIPT_DIR/$LABEL.plist" > "$PLIST"

# 再ロード
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load -w "$PLIST"

echo "  built:  $APP_DIR"
echo "  loaded: $PLIST"
echo "  log:    $LOG"
