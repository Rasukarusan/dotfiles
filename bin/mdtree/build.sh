#!/usr/bin/env bash
set -euo pipefail

# mdtree をビルドして ~/.local/bin に配置する。
# 再実行で再ビルドする。setup.sh から呼ばれるほか、単体でも実行できる。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.local/bin"

if ! command -v go &>/dev/null; then
  echo "  skip: go が見つかりません (brew install go)" >&2
  exit 0
fi

mkdir -p "$DEST"
echo "  building mdtree..."
( cd "$SCRIPT_DIR" && go build -o "$DEST/mdtree" . )
echo "  done: $DEST/mdtree"
