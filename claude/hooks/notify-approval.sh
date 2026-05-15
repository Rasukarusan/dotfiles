#!/bin/bash

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')

if [ -n "$COMMAND" ]; then
  DETAIL="$COMMAND"
elif [ -n "$FILE_PATH" ]; then
  DETAIL="$FILE_PATH"
elif [ -n "$MESSAGE" ]; then
  DETAIL="$MESSAGE"
else
  DETAIL=""
fi

if [ -n "$TOOL_NAME" ]; then
  SUBTITLE="${TOOL_NAME} の承認を待っています"
else
  SUBTITLE="入力待ち"
fi

osascript -e "display notification \"${DETAIL}\" with title \"Claude Code\" subtitle \"${SUBTITLE}\""

exit 0
