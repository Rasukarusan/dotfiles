#!/bin/bash
# 毎月の定期経費（出社交通費・ChatGPT Plus）をhyou.mdの行形式で出力する
# 出社交通費は対象月の月・火・水から日本の祝日を除いた日に作成する
# 使い方: fixed-expenses.sh <YYYY/MM>
# 例: fixed-expenses.sh 2026/08

set -euo pipefail

if [[ ! "${1:-}" =~ ^([0-9]{4})/([0-9]{1,2})$ ]]; then
  echo "使い方: fixed-expenses.sh <YYYY/MM>" >&2
  exit 1
fi

YEAR="${BASH_REMATCH[1]}"
MONTH=$(printf '%02d' "$((10#${BASH_REMATCH[2]}))")

# 祝日を YYYY/MM/DD<TAB>名称 形式で取得する（内閣府CSV → holidays-jp APIの順に試す）
fetch_holidays() {
  local csv json
  if csv=$(curl -fsS --max-time 10 https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv | iconv -f SHIFT_JIS -t UTF-8) \
    && grep -q "^${YEAR}/" <<< "$csv"; then
    tr -d '\r' <<< "$csv" | awk -F, 'NR > 1 { split($1, d, "/"); printf "%04d/%02d/%02d\t%s\n", d[1], d[2], d[3], $2 }'
    return
  fi
  if json=$(curl -fsS --max-time 10 https://holidays-jp.github.io/api/v1/date.json) \
    && grep -q "\"${YEAR}-" <<< "$json"; then
    sed -nE 's/^ *"([0-9]{4})-([0-9]{2})-([0-9]{2})": "(.*)",?$/\1\/\2\/\3\t\4/p' <<< "$json"
    return
  fi
  echo "エラー: ${YEAR}年の祝日を取得できませんでした" >&2
  exit 1
}

holidays=$(fetch_holidays | grep "^${YEAR}/${MONTH}/" || true)

commute_rows=()
excluded=()
day=1
while date -j -f '%Y/%m/%d' "${YEAR}/${MONTH}/$(printf '%02d' "$day")" '+%m' 2>/dev/null | grep -qx "$MONTH"; do
  ymd="${YEAR}/${MONTH}/$(printf '%02d' "$day")"
  weekday=$(date -j -f '%Y/%m/%d' "$ymd" '+%u')
  if (( weekday <= 3 )); then
    holiday=$(awk -F'\t' -v d="$ymd" '$1 == d { print $2 }' <<< "$holidays")
    if [ -n "$holiday" ]; then
      excluded+=("${ymd} ${holiday}")
    else
      commute_rows+=("|船橋競馬場↔︎東京|旅費交通費||東海旅客鉄道株式会社|1,172|${ymd}|課対仕入10%|支出|")
    fi
  fi
  day=$((day + 1))
done

printf '%s\n' "${commute_rows[@]}"
echo "|ChatGPT Plus|通信費||OpenAI|2,860|${YEAR}/${MONTH}/22|課対仕入10%|支出|"

if [ ${#excluded[@]} -gt 0 ]; then
  printf '除外した祝日: %s\n' "${excluded[@]}" >&2
fi
