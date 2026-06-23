---
name: crit-stop-all
description: 起動中のcritデーモンを全て停止する。crit stop --all で止まらない取りこぼし(crit _serve)もpkillで確実に落とす。
allowed-tools: Bash(crit:*), Bash(pkill:*), Bash(pgrep:*)
---

起動中の crit デーモンを全て停止するスキル。

## 実行手順

以下を順に実行する。

1. **通常停止**: `crit stop --all`
2. **取りこぼし確認**: `pgrep -fl 'crit _serve'`(別ディレクトリ/別キーで起動したデーモンは
   `crit stop --all` のレジストリから漏れて残ることがある)
3. **残っていれば強制停止**: `pkill -f 'crit _serve'`
4. **最終確認**: `pgrep -fl 'crit _serve'` が何も返さないことを確認する

まとめて実行する例:

```bash
crit stop --all
sleep 0.5
if pgrep -fl 'crit _serve' | grep -v pgrep; then
  pkill -f 'crit _serve'
  sleep 0.5
fi
pgrep -fl 'crit _serve' | grep -v pgrep || echo "全てのcritデーモンを停止しました"
```

## 注意

- このスキルは**デーモン(プロセス)の停止のみ**を行う。レビューのコメント
  (`~/.crit/reviews/<key>/review.json`)は削除しない。
- コメントごと消したい場合は別途 `crit comment --clear` か `rm -rf ~/.crit/reviews/*` を使う。
- 結果は「停止したプロセス数」と「残存の有無」を簡潔に報告する。
