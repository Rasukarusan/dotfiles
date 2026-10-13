#!/usr/bin/env bash
# 現在のブランチで /is-best を実行済みのセッションを、会話ログから列挙する。
# 使い方: check.sh [除外するセッションID]
set -euo pipefail

exclude="${1:-}"
branch="$(git branch --show-current)"
[ -n "$branch" ] || { echo "ブランチを取得できない（detached HEAD）"; exit 0; }

shopt -s nullglob
logs=(~/.claude/projects/*/*.jsonl)
[ ${#logs[@]} -gt 0 ] || exit 0

/usr/bin/grep -h -e '<command-name>/is-best</command-name>' -- "${logs[@]}" \
  | jq -r --arg branch "$branch" --arg exclude "$exclude" '
      select(.type == "user" and .isSidechain != true)
      | select(.gitBranch == $branch and .sessionId != $exclude)
      | select((.message.content | type) == "string"
               and (.message.content | startswith("<command-message>is-best</command-message>")))
      | [.timestamp, .sessionId, .cwd] | @tsv' \
  | sort
