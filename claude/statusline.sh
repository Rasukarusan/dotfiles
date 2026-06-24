#!/usr/bin/env bash

input=$(cat)

# 各種情報を取得
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // "0"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# レイテンシを秒に変換（小数点1桁）
latency=$(echo "scale=1; $duration_ms / 1000" | bc)

# カレントディレクトリをホーム短縮表示（~）
dir="${cwd/#$HOME/~}"

# ステータスライン表示
echo "${model} | ${dir} | Context: ${used}% used | ${latency}s"
