---
name: stars-sync
description: GitHubのstar一覧を最新化し、新しくstarしたリポジトリをカテゴリ分類して github-stars サイト(stars.json)を更新・pushする。「starを同期」「スター分類更新」などで起動。
---

# stars-sync

GitHubでstarしたリポジトリのカテゴリ別閲覧サイト `~/Documents/github/github-stars`（公開: https://rasukarusan.github.io/github-stars/）を最新化するスキル。

## 前提

- リポジトリは `~/Documents/github/github-stars`
- `categories.json` … 分類マッピング本体（`owner/repo` → カテゴリkey）
- `category-meta.json` … カテゴリ定義（label/emoji/order）
- `build.sh` … star取得→分類適用→`stars.json`生成。**既定は増分**(直近100件のみ取得し手元にマージ)。全件取り直しは `./build.sh --full`

## 手順

1. `cd ~/Documents/github/github-stars && ./build.sh` を実行する。
2. 出力に「⚠ 未分類のリポジトリがあります」が出たら、その `owner/repo` を一覧化する。
   - 出ない場合は分類変更なし。手順5へ。
3. 未分類の各リポジトリについて、`gh api repos/{owner}/{repo} -q '.description, (.language//""), (.topics|join(","))'` 等で説明・言語・topicsを確認し、`category-meta.json` にある既存カテゴリkeyのいずれかに分類する。
   - 判断に迷う場合のみユーザーに確認する。基本は説明文から自動で振り分ける。
   - どうしても合うカテゴリが無く、かつ複数件が同種なら新カテゴリを `category-meta.json` に追加してよい（label/emoji/order を付与）。
4. `categories.json` に `"owner/repo": "カテゴリkey"` を追記する（JSONとして妥当に保つ）。
5. `./build.sh` を再実行し、未分類警告が消えたこと・`total`件数を確認する。
6. `git add -A && git commit -m "stars: 同期（新規N件を分類）" && git push` する。
   - 件数や追加カテゴリがあればコミットメッセージに反映する。
7. 完了をユーザーに報告（取得総数・新規分類した件数・新カテゴリの有無）。

## メモ

- `raw.json` は中間生成物で `.gitignore` 済み。コミット対象は `stars.json` と各設定JSON。
- カテゴリの並び順は `category-meta.json` の `order` で制御。
- 既存の分類を見直したい場合は `categories.json` の値を書き換えて `./build.sh` するだけ。
