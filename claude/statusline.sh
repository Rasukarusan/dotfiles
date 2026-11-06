#!/usr/bin/env bash

input=$(cat)

# 文字数の判定・切り詰めを日本語でも文字単位で行う
export LC_ALL=en_US.UTF-8

# 各種情報を取得
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# カレントディレクトリをホーム短縮表示（~）
dir="${cwd/#$HOME/~}"

# git ブランチ名（detached HEAD なら短縮ハッシュ）
branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# ブランチの PR を「URL<TAB>#123 タイトル」形式で返す
# gh は遅いのでブランチごとにキャッシュし、古ければ裏で取り直して今回は前回の値を出す
pr_cache_ttl=300
get_pr() {
  [ -z "$branch" ] && return
  command -v gh >/dev/null 2>&1 || return

  local toplevel cache_dir cache now mtime
  toplevel=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || return
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/pr-v2"
  mkdir -p "$cache_dir"
  cache="${cache_dir}/$(printf '%s:%s' "$toplevel" "$branch" | shasum | cut -c1-16)"

  now=$(date +%s)
  mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
  if [ $((now - mtime)) -ge "$pr_cache_ttl" ]; then
    # 取得中に何度も起動しないよう、先に mtime を更新しておく
    touch "$cache"
    (
      cd "$toplevel" &&
        gh pr view "$branch" --json number,title,state,url \
          -q 'select(.state == "OPEN") | "\(.url)\t#\(.number) \(.title)"' >"${cache}.tmp" 2>/dev/null
      mv "${cache}.tmp" "$cache"
    ) >/dev/null 2>&1 &
  fi

  [ -s "$cache" ] && head -n1 "$cache"
}

# セッションのタイトル（/rename の名前を優先し、無ければ自動で付くタイトル）
get_session_title() {
  local transcript title
  transcript=$(echo "$input" | jq -r '.transcript_path // empty')
  [ -f "$transcript" ] || return
  title=$(grep -o '"customTitle":"[^"]*"' "$transcript" | tail -n1)
  [ -z "$title" ] && title=$(grep -o '"aiTitle":"[^"]*"' "$transcript" | tail -n1)
  title="${title#*\":\"}"
  echo "${title%\"}"
}

# PR があれば「#123 PRタイトル」、無ければセッションのタイトルを出す
pr=$(get_pr)
pr_url=""
if [ -n "$pr" ]; then
  pr_url="${pr%%$'\t'*}"
  pr="${pr#*$'\t'}"
  title="$pr"
else
  title=$(get_session_title)
fi

# 使用量（サブスク契約時のみ渡ってくる）を「53%(2h30m)」形式で整形する
format_limit() {
  local key=$1
  local pct reset now diff label

  pct=$(echo "$input" | jq -r ".rate_limits.${key}.used_percentage // empty")
  [ -z "$pct" ] && return

  reset=$(echo "$input" | jq -r ".rate_limits.${key}.resets_at // empty")
  label=$(printf '%.0f%%' "$pct")

  if [ -n "$reset" ]; then
    now=$(date +%s)
    diff=$((reset - now))
    if [ "$diff" -gt 0 ]; then
      if [ "$diff" -ge 86400 ]; then
        label="${label}($((diff / 86400))d$((diff % 86400 / 3600))h)"
      elif [ "$diff" -ge 3600 ]; then
        label="${label}($((diff / 3600))h$((diff % 3600 / 60))m)"
      else
        label="${label}($((diff / 60))m)"
      fi
    fi
  fi

  echo "$label"
}

five_hour=$(format_limit five_hour)
seven_day=$(format_limit seven_day)

usage=""
[ -n "$five_hour" ] && usage="${usage} | 5h: ${five_hour}"
[ -n "$seven_day" ] && usage="${usage} | 7d: ${seven_day}"

# 表示幅を取得する（statusline は tty を持たないため tmux から pane 幅を引く）
get_width() {
  if [ -n "$TMUX_PANE" ]; then
    tmux display -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null && return
  fi
  echo "${COLUMNS:-0}"
}

yellow=$'\e[33m'
red=$'\e[31m'
cyan=$'\e[36m'
green=$'\e[32m'
reset=$'\e[0m'

# Context 使用率に応じた色（40%超で黄、60%以上で赤）
used_int=$(printf '%.0f' "$used")
used_color=""
if [ "$used_int" -ge 60 ]; then
  used_color=$red
elif [ "$used_int" -gt 40 ]; then
  used_color=$yellow
fi

head="${model} | Context: ${used_color}${used}%${reset} used${usage}"
dir_colored="${cyan}${dir}${reset}"
dir_plain="${dir}"
if [ -n "$branch" ]; then
  dir_colored="${dir_colored} ${green}${branch}${reset}"
  dir_plain="${dir_plain} ${branch}"
fi

# ステータスライン表示（1行に収まらなければ dir を2行目に回す）
# 幅判定はエスケープシーケンスを含まない文字列で行う
plain="${model} | Context: ${used}% used${usage} | ${dir_plain}"
width=$(get_width)
# Claude Code 側の左右余白ぶんを差し引く
margin=4

if [ "$width" -gt 0 ] && [ "${#plain}" -gt $((width - margin)) ]; then
  echo "$head"
  echo "$dir_colored"
else
  echo "${head} | ${dir_colored}"
fi

# タイトルは長くなりがちなので常に独立した行に出す
# PR は OSC 8 のリンクにして Cmd+クリックで開けるようにする
if [ -n "$pr_url" ]; then
  printf '\e]8;;%s\e\\%s%s%s\e]8;;\e\\\n' "$pr_url" "$yellow" "$title" "$reset"
elif [ -n "$title" ]; then
  echo "${yellow}${title}${reset}"
fi
