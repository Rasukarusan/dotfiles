#!/usr/bin/env bash
# worktree で起動した Claude Code のセッションを、メインリポジトリのセッションとして付け替える。
# セッションは起動ディレクトリごとに保存されるため、付け替えないとメインから /resume できない。
#
# 使い方:
#   move.sh [--session <session-id>] [<worktree のパス>]  指定した worktree (省略時は今いる worktree)
#   move.sh --orphans                                    削除済みの worktree すべて
#
# --session を付けると、そのセッションだけを移す。
set -euo pipefail

projects="$HOME/.claude/projects"
session=""
orphans=0
target=""

while [ $# -gt 0 ]; do
  case "$1" in
    --session) session="$2"; shift 2 ;;
    --orphans) orphans=1; shift ;;
    *) target="$1"; shift ;;
  esac
done

encode() { printf '%s' "$1" | sed 's/[^a-zA-Z0-9]/-/g'; }

# 削除済みの worktree を指定されたら、今いるリポジトリから辿る
git_c=()
[ -n "$target" ] && [ -d "$target" ] && git_c=(-C "$target")

# worktree の中からでも、共有の .git の親がメインリポジトリになる
common_dir=$(git ${git_c[@]+"${git_c[@]}"} rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
  echo "gitリポジトリ内で実行してください" >&2
  exit 1
}
main=$(dirname "$common_dir")
dst="$projects/$(encode "$main")"

moved=0

move_dir() {
  local src="$1"
  [ -d "$src" ] && [ "$src" != "$dst" ] || return 0
  mkdir -p "$dst"
  local f id
  for f in "$src"/*.jsonl; do
    [ -e "$f" ] || continue
    id=$(basename "$f" .jsonl)
    [ -z "$session" ] || [ "$id" = "$session" ] || continue
    mv -n "$f" "$dst/"
    [ -e "$src/$id" ] && mv -n "$src/$id" "$dst/"
    moved=$((moved + 1))
  done
  rmdir "$src" 2>/dev/null || true
}

if [ "$orphans" -eq 1 ]; then
  # 削除済み worktree のパスは git から引けないので、セッションに残った cwd で見分ける
  parents=("$main/.claude/worktrees")
  while IFS= read -r wt; do
    [ "$wt" = "$main" ] || parents+=("$(dirname "$wt")")
  done < <(git -C "$main" worktree list --porcelain | sed -n 's/^worktree //p')

  for src in "$projects"/*/; do
    src="${src%/}"
    f=$(ls "$src"/*.jsonl 2>/dev/null | head -n 1) || true
    [ -n "$f" ] || continue
    cwd=$(grep -m 1 -o '"cwd":"[^"]*"' "$f" | sed 's/^"cwd":"//; s/"$//') || true
    [ -n "$cwd" ] && [ ! -d "$cwd" ] || continue
    for p in "${parents[@]}"; do
      if [[ "$cwd" == "$p"/* ]]; then
        move_dir "$src"
        break
      fi
    done
  done
else
  if [ -n "$target" ] && [ ! -d "$target" ]; then
    wt="$target"
  else
    wt=$(git ${git_c[@]+"${git_c[@]}"} rev-parse --show-toplevel)
  fi
  if [ "$wt" = "$main" ]; then
    echo "メインリポジトリです。worktree で実行するか、パスを指定してください" >&2
    exit 1
  fi
  move_dir "$projects/$(encode "$wt")"
fi

echo "移動: ${moved} 件 → ${main}"
