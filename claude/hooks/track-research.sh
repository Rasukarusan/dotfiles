#!/bin/bash
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt')
CWD=$(echo "$INPUT" | jq -r '.cwd')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

if echo "$PROMPT" | grep -q "調査"; then
  # ブランチ名の2番目のセグメントからチケット番号を取得
  BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
  TICKET=$(echo "$BRANCH" | cut -d'/' -f2)
  if [ -z "$TICKET" ] || [ "$TICKET" = "$BRANCH" ]; then
    TICKET="unknown"
  fi

  # フラグファイルを作成（Stop hookで参照する）
  FLAG_DIR="/tmp/.claude-research"
  mkdir -p "$FLAG_DIR"
  jq -n --arg ticket "$TICKET" --arg prompt "$PROMPT" --arg cwd "$CWD" \
    '{ticket: $ticket, prompt: $prompt, cwd: $cwd}' > "$FLAG_DIR/$SESSION_ID"

  TARGET_DIR="$HOME/any/docs/$TICKET"
  mkdir -p "$TARGET_DIR"

  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "" >> "$TARGET_DIR/research.md"
  echo "## [$TIMESTAMP] $PROMPT" >> "$TARGET_DIR/research.md"
fi

exit 0
