PR #$ARGUMENTS のレビューをお願いします。PR番号が空の場合、今のブランチのPRをレビューしてください。
PRにコメントはしないこと。差分を取得する前に、必ず `BASE=$(bash ~/.claude/docs/get-base-branch.sh)` を実行してベースブランチを特定し、`git diff ${BASE}...HEAD` で差分を取得すること。developやmainを勝手に仮定しないこと。レビュー観点は、@~/.claude/docs/local/pr-guideline.md のガイドラインにしたがってください。
