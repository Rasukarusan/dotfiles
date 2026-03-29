#!/bin/bash
# 経費画像ファイルにprefixを追加してリネームする
# 使い方: rename-files.sh <prefix> <ファイルパス>
# 例: rename-files.sh komeda_ /path/to/image.jpg

set -euo pipefail

PREFIX="$1"
FILE="$2"

if [ ! -f "$FILE" ]; then
  echo "エラー: ファイルが見つかりません: $FILE" >&2
  exit 1
fi

DIR=$(dirname "$FILE")
BASENAME=$(basename "$FILE")

# 既にprefixが付いている場合はスキップ
if [[ "$BASENAME" == "${PREFIX}"* ]]; then
  echo "スキップ(prefix済み): $BASENAME"
  exit 0
fi

NEW_PATH="${DIR}/${PREFIX}${BASENAME}"
mv "$FILE" "$NEW_PATH"
echo "リネーム: $BASENAME → ${PREFIX}${BASENAME}"
