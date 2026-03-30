今のブランチでやっていることを理解してください。PRも作っているので、必要であれば取得してください。

差分を取得する前に、必ず `BASE=$(bash ~/.claude/docs/get-base-branch.sh)` を実行してベースブランチを特定し、`git diff ${BASE}...HEAD` で差分を取得すること。developやmainを勝手に仮定しないこと。
