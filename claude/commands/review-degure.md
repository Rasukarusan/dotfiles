PR #$ARGUMENTS のレビューをお願いします。PR番号が空の場合、今のブランチのPRをレビューしてくれ。差分を取得する前に、必ず `BASE=$(bash ~/.claude/docs/get-base-branch.sh)` を実行してベースブランチを特定し、`git diff ${BASE}...HEAD` で差分を取得すること。developやmainを勝手に仮定しないこと。

レビュー観点は、既存機能が壊れていないか、デグレ確認をすることです。
