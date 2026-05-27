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

if [ "$TOOL_NAME" = "AskUserQuestion" ]; then
  QUESTION=$(echo "$INPUT" | jq -r '.tool_input.questions[0].question // empty')
  DETAIL="$QUESTION"
  SUBTITLE="質問への回答待ち"
else
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
fi

NOTIFIER="$HOME/.claude/bin/claude-notify.app"
if [ -x "$NOTIFIER/Contents/MacOS/claude-notify" ]; then
  open "$NOTIFIER" --args -title "Claude Code" -subtitle "$SUBTITLE" -message "$DETAIL"
else
  DETAIL_ESCAPED=$(printf '%s' "$DETAIL" | sed 's/\\/\\\\/g; s/"/\\"/g')
  SUBTITLE_ESCAPED=$(printf '%s' "$SUBTITLE" | sed 's/\\/\\\\/g; s/"/\\"/g')
  osascript -e "display notification \"${DETAIL_ESCAPED}\" with title \"Claude Code\" subtitle \"${SUBTITLE_ESCAPED}\""
fi

exit 0
