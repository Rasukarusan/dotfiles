---
name: is-best
description: '今回の実装が本当にベストなやり方か？'
disable-model-invocation: true
---

## 実行済みかの確認

最初に `bash ~/.claude/skills/is-best/check.sh ${CLAUDE_SESSION_ID}` を実行する。現在のブランチで他のセッションが `/is-best` を実行した記録（日時・セッションID・作業ディレクトリ）が出力される。

- このセッション自身の実行は除外済み。引数が展開されずに渡った場合はこのセッションの行も出るので、それは無視する。
- 何も出力されなければ、そのまま次の「問い」に進む。
- 出力があれば、各実行の日時・セッションIDと、`git log -1 --format=%cI` で得た最新コミット日時を示し、AskUserQuestion で次のどちらにするか聞く。最終実行より後にコミットがあれば、その旨を添える。
  - **既存セッションを再開**: 次を実行する。最新の実行のセッションをこの pane のすぐ下に開き、このセッションは pane ごと閉じて会話ログを削除する。
    `bash ~/.claude/skills/is-best/resume.sh <sessionId> "<cwd>" ${CLAUDE_SESSION_ID}`
    tmux 外で動いている場合やログを特定できない場合は何もせずに失敗するので、出力されたコマンドを提示して終了する。
  - **このセッションで改めて実行**: 次の「問い」に進む。

## 誰の実装か

PR があれば `gh pr view --json author --jq .author.login` と `gh api user --jq .login` を比べる。PR が無ければ、ブランチ上のコミットの作者が `git config user.email` かで判断する。

自分以外の PR・ブランチなら壁打ちの相談として扱う。問いへの見解と代替案を述べるだけにし、コードの修正・コミット・PR へのコメントはしない。

## 問い

今回の実装が本当にベストなやり方か？
