---
name: move-worktree-sessions
description: worktree で起動した Claude Code のセッションを、メインリポジトリのセッションとして付け替える。worktree を消した後もメインから /resume できるようにする。「このセッションをメインに移して」「worktree のセッションを移動して」「消した worktree のセッションを拾って」で使う。
allowed-tools: Bash(~/.claude/skills/move-worktree-sessions/move.sh:*)
---

セッションは起動ディレクトリごとに `~/.claude/projects/` の下に保存される。worktree のセッションをメインリポジトリの保存先へ移し、メインで `/resume` したときに一覧に出るようにする。メインリポジトリは worktree の中からでも git から判定できるので、ユーザーに聞かない。

## 実行

既定は今のセッションだけを移す。

```bash
~/.claude/skills/move-worktree-sessions/move.sh --session ${CLAUDE_SESSION_ID}
```

依頼が次のときだけ、別の形で実行する。

```bash
# 今いる worktree のセッションすべて
~/.claude/skills/move-worktree-sessions/move.sh

# 指定した worktree のセッションすべて (削除済みのパスでもよい)
~/.claude/skills/move-worktree-sessions/move.sh <worktree のパス>

# 削除済みの worktree に残ったセッションすべて
~/.claude/skills/move-worktree-sessions/move.sh --orphans
```

## 報告

移した件数と移し先を伝える。今のセッションを移したときは、移した後のやり取りはメインに残らないので、このセッションを終えてから次のコマンドで再開するよう伝える。

```bash
cd <メインリポジトリ> && claude --resume ${CLAUDE_SESSION_ID}
```
