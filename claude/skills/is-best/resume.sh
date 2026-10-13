#!/usr/bin/env bash
# 既存セッションを今の pane の下に開き、今のセッションを pane ごと閉じて会話ログを削除する。
# 今のセッションは /is-best を呼んだだけで何もしていないため、次回の check.sh に拾われないよう消す。
# 使い方: resume.sh <再開するセッションID> <その作業ディレクトリ> <今のセッションID>
set -euo pipefail

target="$1"
target_cwd="$2"
current="$3"

[ -n "${TMUX_PANE:-}" ] || { echo "tmux 外のため実行しない: cd \"$target_cwd\" && claude --resume $target"; exit 1; }

shopt -s nullglob
logs=(~/.claude/projects/*/"$current".jsonl)
[ ${#logs[@]} -eq 1 ] || { echo "今のセッションのログを特定できない: $current"; exit 1; }

tmux split-window -v -t "$TMUX_PANE" -c "$target_cwd" "claude --resume $target"
# 今の pane を閉じると Claude が終了時にログへ書き足すことがあるため、閉じた後に消す
tmux run-shell -b "tmux kill-pane -t '$TMUX_PANE'; sleep 2; rm -f '${logs[0]}'"
