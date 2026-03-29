#!/bin/bash
# 画像ファイルを品質30%で圧縮する
# 使い方: compress-images.sh [対象ディレクトリ(デフォルト: カレントディレクトリ)]

set -euo pipefail

TARGET_DIR="${1:-.}"
QUALITY=30

if ! command -v magick &> /dev/null; then
  echo "エラー: imagemagickがインストールされていません" >&2
  echo "  brew install imagemagick" >&2
  exit 1
fi

shopt -s nullglob nocaseglob

files=("$TARGET_DIR"/*.{jpg,jpeg,png,heic,webp})

if [ ${#files[@]} -eq 0 ]; then
  echo "圧縮対象の画像ファイルが見つかりません: $TARGET_DIR"
  exit 0
fi

for file in "${files[@]}"; do
  original_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
  magick "$file" -quality "$QUALITY" "$file"
  new_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
  reduction=$(( (original_size - new_size) * 100 / original_size ))
  echo "圧縮: $(basename "$file")  ${original_size}B → ${new_size}B  (-${reduction}%)"
done

echo "完了: ${#files[@]}件の画像を圧縮しました"
