---
name: kaisetsu-list
description: kaisetsuの過去レビューを一覧表示し、ユーザーが選んだレビューの画面(ローカルサーバ)を再表示する。選択後はサーバ起動のみ行い、コメント対応は画面で「レビュー完了」が押されてから行う。
---

# kaisetsu-list

`/kaisetsu` で行ったレビューの履歴を一覧し、選ばれたレビューを再開するスキル。
レビューは `~/.kaisetsu/<リポジトリ名>/<YYYYMMDD-HHMMSS>/review-data.json` に保存されている。

## ① 一覧の収集

```bash
find ~/.kaisetsu -mindepth 3 -maxdepth 3 -name 'review-data.json' | sort -r
```

各レビューについて以下を読み取る。**`review-data.json` はdiff全文を含むためReadしないこと。**
表示用の値は同じディレクトリの小さな `meta.json` から取る(1回のBashでjqをループさせて全行を作るとよい):

- 日時: ディレクトリ名(`YYYYMMDD-HHMMSS`)
- リポジトリ: 親ディレクトリ名
- `title` / `tagline` / `repoRoot`: `meta.json` から(無い旧レビューのみ `jq -r '.title, .repoRoot'` で
  review-data.json からフィールド抽出する。この場合もReadは使わない)
- 状態: 同じディレクトリに `review-data.result.json` があれば **完了済み**。あればコメント件数
  (`.comments + .groupComments` の長さ)もjqで取る

## ② 一覧の提示と選択

新しい順の表で提示する:

| # | 日時 | リポジトリ | タイトル | 状態 |
|---|---|---|---|---|
| 1 | 2026-07-28 12:00 | myapp | app/system URL整理 | ✔ 完了(コメント3件) |
| 2 | … | … | … | ─ 未完了 |

- 候補が4件以下なら AskUserQuestion で選択肢として提示してよい。多い場合は表を出して番号で選んでもらう。
- 0件なら「レビュー履歴がありません」と伝えて終了。

## ③ 選択されたレビューの再開

完了済みかどうかに関わらず、**まずレビュー画面を再表示するだけ**にする。
過去のコメントへの対応やまとめの提示は、この時点では行わない。

1. 古い `review-data.result.json` があれば削除する(完了検知が即発火するのを防ぐ。
   画面上のコメントはブラウザのlocalStorageから復元されるので消えない)。
2. `~/.claude/skills/kaisetsu/SKILL.md` の手順③④以降に従い、その `review-data.json` で
   サーバを起動する(`repoRoot` をCWDにする)。完了検知のバックグラウンド待機も同様に仕掛ける。
3. 「レビュー画面を開きました」とだけ伝えて待つ。ユーザーが画面で「レビュー完了」を押したら、
   kaisetsu本体の手順⑤⑥どおり結果を読んで対応する。

以後のファイル操作・差分参照は `repoRoot` を基準に行う。
