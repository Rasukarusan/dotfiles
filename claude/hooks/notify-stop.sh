#!/bin/bash

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

LAST_TEXT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  LAST_TEXT=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" \
    | tail -1 \
    | jq -r '.message.content | if type == "array" then map(select(.type == "text") | .text) | join("\n") else . end' 2>/dev/null)
  LAST_TEXT=$(printf '%s' "$LAST_TEXT" | grep -v '^[[:space:]]*$' | tail -n 1 | cut -c 1-200)
fi

if [ -n "$LAST_TEXT" ]; then
  DETAIL="$LAST_TEXT"
elif [ -n "$CWD" ]; then
  DETAIL="$(basename "$CWD")"
else
  DETAIL=""
fi

DETAIL_ESCAPED=$(printf '%s' "$DETAIL" | sed 's/\\/\\\\/g; s/"/\\"/g')

osascript -e "display notification \"\" with title \"${DETAIL_ESCAPED}\""

exit 0
