#!/usr/bin/env bash
set -euo pipefail

# 字幕オーバーレイアプリ(claude-caption)をビルドする。
# E2E動作確認動画の撮影時に caption コマンド(bin/caption)から字幕を切り替える。権限不要。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.local/bin"
swiftc -O -o "$HOME/.local/bin/claude-caption" -framework Cocoa "$SCRIPT_DIR/claude-caption.swift"
chmod +x "$SCRIPT_DIR/../caption"

echo "  built: $HOME/.local/bin/claude-caption"
