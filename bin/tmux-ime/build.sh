#!/usr/bin/env bash
set -euo pipefail

# 入力ソース切替CLI(imselect)をビルドする。
# tmux の after-select-pane フック(tmux-ime-switch)から呼ばれる。権限不要。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.local/bin"
swiftc -O -o "$HOME/.local/bin/imselect" -framework Cocoa "$SCRIPT_DIR/imselect.swift"
chmod +x "$SCRIPT_DIR/tmux-ime-switch"

echo "  built: $HOME/.local/bin/imselect"
