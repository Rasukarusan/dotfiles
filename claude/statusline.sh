#!/usr/bin/env bash

input=$(cat)

# 各種情報を取得
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# カレントディレクトリをホーム短縮表示（~）
dir="${cwd/#$HOME/~}"

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

# ステータスライン表示
echo "${model} | ${dir} | Context: ${used}% used${usage}"
