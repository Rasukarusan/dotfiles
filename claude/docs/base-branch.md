# ベースブランチの特定（差分取得時の共通ルール）

差分を取得する際は、**必ず最初に**以下のスクリプトを実行してベースブランチを特定すること。

```bash
BASE_BRANCH=$(bash ~/.claude/docs/get-base-branch.sh)
git diff ${BASE_BRANCH}...HEAD
```

- developやmainを勝手に仮定して `git diff` しないこと
- 結果が`UNKNOWN`またはエラーの場合はユーザーに確認すること
