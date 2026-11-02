#!/bin/bash

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Stop hook の入力に最後の assistant の本文が入っているので、transcript は読まない。
LAST_TEXT=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')
LAST_TEXT=$(printf '%s' "$LAST_TEXT" | grep -v '^[[:space:]]*$' | head -n 5 | cut -c 1-200)

if [ -n "$CWD" ]; then
  TITLE="$(basename "$CWD")"
else
  TITLE="Claude Code"
fi

NOTIFIER="$HOME/.claude/bin/claude-notify.app"
if [ -x "$NOTIFIER/Contents/MacOS/claude-notify" ]; then
  open -n "$NOTIFIER" --args -title "$TITLE" -message "$LAST_TEXT" -pane "${TMUX_PANE:-}"
else
  BODY_ESCAPED=$(printf '%s' "$LAST_TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS=""} {if (NR>1) printf "\\n"; print}')
  TITLE_ESCAPED=$(printf '%s' "$TITLE" | sed 's/\\/\\\\/g; s/"/\\"/g')
  osascript -e "display notification \"${BODY_ESCAPED}\" with title \"${TITLE_ESCAPED}\""
fi

exit 0
