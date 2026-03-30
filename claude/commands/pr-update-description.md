現在のブランチのPRは既に作成済みです。PRから差分を確認し、PRの内容を考えてくれ。フォーマットは.github配下のPRテンプレートに従ってください。差分を取得する前に、必ず `BASE=$(bash ~/.claude/docs/get-base-branch.sh)` を実行してベースブランチを特定し、`git diff ${BASE}...HEAD` で差分を取得すること。developやmainを勝手に仮定しないこと。
最終的にコードブロック4つで囲んでmarkdownで出力してください。
