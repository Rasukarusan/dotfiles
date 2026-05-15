#!/bin/bash

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')

# アイドルタイムアウト（60秒無入力）の通知はスキップ。
# 承認・選択肢系は tool_name が入る想定。
if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

if [ -n "$COMMAND" ]; then
  DETAIL="$COMMAND"
elif [ -n "$FILE_PATH" ]; then
  DETAIL="$FILE_PATH"
elif [ -n "$MESSAGE" ]; then
  DETAIL="$MESSAGE"
else
  DETAIL=""
fi

SUBTITLE="${TOOL_NAME} の承認を待っています"

osascript -e "display notification \"${DETAIL}\" with title \"Claude Code\" subtitle \"${SUBTITLE}\""

exit 0
