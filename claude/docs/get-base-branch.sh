#!/bin/bash
# ベースブランチを特定して標準出力に返す
# 使い方: bash ~/.claude/docs/get-base-branch.sh

set -euo pipefail

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 1. PRのベースブランチを取得
BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || echo "")

if [ -n "$BASE" ]; then
  echo "$BASE"
  exit 0
fi

# 2. reflogから分岐元を特定
REFLOG_LINE=$(git reflog show --no-abbrev --decorate "$CURRENT_BRANCH" 2>/dev/null | tail -1 || echo "")

if [ -n "$REFLOG_LINE" ] && echo "$REFLOG_LINE" | grep -q "Created from"; then
  FROM=$(echo "$REFLOG_LINE" | sed 's/.*Created from //' | sed 's/ *$//')
  FROM=${FROM#refs/heads/}

  if [ "$FROM" = "HEAD" ]; then
    # HEADの場合、そのコミットから分岐元ブランチを逆引き
    COMMIT=$(echo "$REFLOG_LINE" | awk '{print $1}')
    RESOLVED=$(git branch --contains "$COMMIT" 2>/dev/null | grep -v "^\*" | grep -v "$CURRENT_BRANCH" | head -1 | xargs || echo "")
    if [ -n "$RESOLVED" ]; then
      echo "$RESOLVED"
      exit 0
    fi
  elif git rev-parse --verify "$FROM" >/dev/null 2>&1; then
    echo "$FROM"
    exit 0
  fi
fi

# 3. 特定できなかった
echo "UNKNOWN"
exit 1
