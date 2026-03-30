#!/bin/bash
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message')

# 無限ループ防止
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

FLAG_FILE="/tmp/.claude-research/$SESSION_ID"

if [ -f "$FLAG_FILE" ]; then
  TICKET=$(jq -r '.ticket' "$FLAG_FILE")
  TARGET_DIR="$HOME/any/docs/$TICKET"

  echo "" >> "$TARGET_DIR/research.md"
  echo "$LAST_MSG" >> "$TARGET_DIR/research.md"

  # フラグファイル削除
  rm -f "$FLAG_FILE"
fi

exit 0
