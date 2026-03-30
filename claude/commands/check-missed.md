今のブランチのPRの概要を取得し、今回の変更に対して**動作確認が漏れている箇所**を出してくれ。差分を取得する前に、必ず `BASE=$(bash ~/.claude/docs/get-base-branch.sh)` を実行してベースブランチを特定し、`git diff ${BASE}...HEAD` で差分を取得すること。developやmainを勝手に仮定しないこと。
