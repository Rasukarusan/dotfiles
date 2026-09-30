#!/usr/bin/env python3
"""勤怠システムから貼り付けたテキストを、anyフレンズの時間管理表と同じレイアウトのCSVに変換する。

使い方: kintai.py <貼り付けテキストのファイル> [YYYY/MM]
  YYYY/MM を省略すると、貼り付けた日付と曜日が一致する月を今月・先月の順に探す。
"""

import calendar
import csv
import datetime
import re
import sys

WEEKDAYS = "月火水木金土日"
DAY_RE = re.compile(r"^(\d{1,2}) ([月火水木金土日])$")
TIME_RE = re.compile(r"^(\d{1,2}):(\d{2})$")
STATUSES = {"申請", "申請中", "未申請", "承認済み", "承認待ち", "差戻し", "差し戻し", "却下"}
KINDS = {"出勤", "公休", "休日", "有休", "有給", "欠勤", "振休", "代休", "特休"}


def to_min(s):
    h, m = TIME_RE.match(s).groups()
    return int(h) * 60 + int(m)


def fmt(minutes, seconds=False):
    h, m = divmod(minutes, 60)
    return f"{h}:{m:02d}:00" if seconds else f"{h}:{m:02d}"


def parse_blocks(text):
    blocks = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        m = DAY_RE.match(line)
        if m:
            blocks.append({"day": int(m.group(1)), "wd": m.group(2), "lines": []})
        elif blocks:
            blocks[-1]["lines"].append(line)
    return blocks


def parse_day(block):
    """1日分の行から勤務区分・開始・終了・休憩・メモを取り出す。

    時刻は開始・終了それぞれ「採用値, 打刻値」の2つが並ぶため、1つ目を採用する。
    最後の時刻が休憩時間。
    """
    lines = block["lines"]
    kinds = [l for l in lines if l in KINDS]
    times = [l for l in lines if TIME_RE.match(l)]
    last_time = max((i for i, l in enumerate(lines) if TIME_RE.match(l)), default=-1)
    memo = [l for l in lines[last_time + 1:] if l not in STATUSES]

    day = {"day": block["day"], "wd": block["wd"], "kind": kinds[0] if kinds else "", "memo": " ".join(memo)}
    if "出勤" not in kinds:
        return day

    brk, clocks = times[-1], times[:-1]
    if len(clocks) == 4:
        start, end = clocks[0], clocks[2]
    elif len(clocks) == 3:
        # どちらかの値が1つ欠けている。同じ値が並んでいる側を開始/終了の組とみなす
        if clocks[0] == clocks[1]:
            start, end = clocks[0], clocks[2]
        elif clocks[1] == clocks[2]:
            start, end = clocks[0], clocks[1]
        else:
            raise ValueError(f"{block['day']}日: 時刻の並びを判定できません {clocks}")
    elif len(clocks) == 2:
        start, end = clocks
    else:
        raise ValueError(f"{block['day']}日: 時刻の数が想定外です {clocks}")

    s, e, b = to_min(start), to_min(end), to_min(brk)
    if e < s:
        e += 24 * 60
    day.update(start=start, end=end, brk=brk, work=e - s - b)
    return day


def detect_month(days, arg):
    if arg:
        m = re.fullmatch(r"(\d{4})/(\d{1,2})", arg)
        if not m:
            sys.exit("エラー: 対象月は YYYY/MM で指定してください")
        return int(m.group(1)), int(m.group(2))

    today = datetime.date.today()
    prev = today.replace(day=1) - datetime.timedelta(days=1)
    for y, mo in [(today.year, today.month), (prev.year, prev.month)]:
        last = calendar.monthrange(y, mo)[1]
        if all(d["day"] <= last and WEEKDAYS[datetime.date(y, mo, d["day"]).weekday()] == d["wd"] for d in days):
            return y, mo
    sys.exit("エラー: 日付と曜日が一致する月が今月・先月にありません。YYYY/MM を指定してください")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    with open(sys.argv[1], encoding="utf-8") as f:
        days = [parse_day(b) for b in parse_blocks(f.read())]
    if not days:
        sys.exit("エラー: 日付行（例: 01 火）が見つかりません")

    year, month = detect_month(days, sys.argv[2] if len(sys.argv) > 2 else None)
    by_day = {d["day"]: d for d in days}
    last = calendar.monthrange(year, month)[1]

    rows = [
        ["日付", "曜日", "開始時刻", "終了時刻", "休憩時間", "中抜け", "実働時間", "作業メモ"],
    ]
    total = 0
    for n in range(1, last + 1):
        date = datetime.date(year, month, n)
        d = by_day.get(n, {})
        if "work" in d:
            total += d["work"]
            cells = [d["start"], d["end"], d["brk"], "", fmt(d["work"])]
        else:
            cells = [""] * 5
        rows.append([f"{date:%Y/%m/%d}", WEEKDAYS[date.weekday()], *cells, d.get("memo", "")])
    rows.append([""] * 8)
    rows.append(["総勤務時間", "", "", "", "", "", fmt(total, seconds=True), ""])

    missing = [n for n in range(1, last + 1) if n not in by_day]
    if missing:
        print(f"注意: 貼り付けに無い日があります: {missing}", file=sys.stderr)

    csv.writer(sys.stdout, lineterminator="\n").writerows(rows)


if __name__ == "__main__":
    main()
