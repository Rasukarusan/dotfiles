#!/bin/bash

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

LAST_TEXT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # transcript への最終 assistant 行の flush 待ち。
  # 現在の mtime より新しくなる、または最大 ~1.8 秒経過するまで待機。
  START_MTIME=$(stat -f %m "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  for _ in 1 2 3 4 5 6; do
    CUR_MTIME=$(stat -f %m "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    [ "$CUR_MTIME" -gt "$START_MTIME" ] && break
    sleep 0.3
  done

  LAST_TEXT=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" \
    | tail -1 \
    | jq -r '.message.content | if type == "array" then map(select(.type == "text") | .text) | join("\n") else . end' 2>/dev/null)
  LAST_TEXT=$(printf '%s' "$LAST_TEXT" | grep -v '^[[:space:]]*$' | head -n 5 | cut -c 1-200)
fi

if [ -n "$CWD" ]; then
  TITLE="$(basename "$CWD")"
else
  TITLE="Claude Code"
fi

NOTIFIER="$HOME/.claude/bin/claude-notify.app"
if [ -x "$NOTIFIER/Contents/MacOS/claude-notify" ]; then
  open "$NOTIFIER" --args -title "$TITLE" -message "$LAST_TEXT"
else
  BODY_ESCAPED=$(printf '%s' "$LAST_TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS=""} {if (NR>1) printf "\\n"; print}')
  TITLE_ESCAPED=$(printf '%s' "$TITLE" | sed 's/\\/\\\\/g; s/"/\\"/g')
  osascript -e "display notification \"${BODY_ESCAPED}\" with title \"${TITLE_ESCAPED}\""
fi

exit 0
