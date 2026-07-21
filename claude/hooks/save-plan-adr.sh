#!/bin/bash
# ExitPlanMode の PostToolUse hook。
# 承認されたプランを ~/any/docs/<ANY-XXX>/adr.md に追記する。
# <ANY-XXX> は cwd のブランチ名から取得し、取得できない場合は ANY-XXX に保存する。
set -euo pipefail

INPUT=$(cat)

PLAN=$(echo "$INPUT" | jq -r '.tool_input.plan // empty')
[ -z "$PLAN" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD=$(pwd)

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || true)
TICKET=$(echo "$BRANCH" | grep -oE 'ANY-[0-9]+' | head -n1 || true)
[ -z "$TICKET" ] && TICKET="ANY-XXX"

DIR="$HOME/any/docs/$TICKET"
mkdir -p "$DIR"
ADR="$DIR/adr.md"

[ -f "$ADR" ] || echo "# ADR ($TICKET)" > "$ADR"

{
  echo ""
  echo "---"
  echo ""
  echo "## $(date '+%Y-%m-%d %H:%M') (branch: ${BRANCH:-unknown})"
  echo ""
  echo "$PLAN"
} >> "$ADR"

exit 0
