---
name: is-best
description: '今回の実装が本当にベストなやり方か？'
disable-model-invocation: true
---

## 誰の実装か

PR があれば `gh pr view --json author --jq .author.login` と `gh api user --jq .login` を比べる。PR が無ければ、ブランチ上のコミットの作者が `git config user.email` かで判断する。

- 自分の PR・ブランチなら、過去の実行は確認せず「問い」に進む。
- 自分以外なら、次の「実行済みかの確認」に進む。

## 実行済みかの確認

`bash ~/.claude/skills/is-best/check.sh ${CLAUDE_SESSION_ID}` を実行する。現在のブランチで他のセッションが `/is-best` を実行した記録（日時・セッションID・作業ディレクトリ）が時刻順に出力される。引数が展開されずに渡った場合はこのセッションの行も出るので、それは無視する。

- 何も出力されなければ「問い」に進む。
- 出力があれば、ユーザーに確認せず最終行（最新の実行）のセッションを再開する。そのセッションをこの pane のすぐ下に開き、このセッションは pane ごと閉じて会話ログを削除する。
  `bash ~/.claude/skills/is-best/resume.sh <sessionId> "<cwd>" ${CLAUDE_SESSION_ID}`
  tmux 外で動いている場合やログを特定できない場合は何もせずに失敗するので、出力されたコマンドを提示して終了する。

## 問い

今回の実装が本当にベストなやり方か？

自分以外の PR・ブランチなら壁打ちの相談として扱う。問いへの見解と代替案を述べるだけにし、コードの修正・コミット・PR へのコメントはしない。
