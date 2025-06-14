# tmuxを使った部下（サブペイン）管理方法

## 概要

リーダー（ペイン1）として、tmuxの2つ目のペイン（ペイン2）で動作する部下のClaude Codeを管理する方法。

## 部下のClaude Code起動方法

```bash
# ペイン2を作成
tmux splitw -h
# ペイン2でClaude Codeを起動
tmux send-keys -t 2 "claude --dangerously-skip-permissions" ENTER
```

## 部下への指示方法

**重要**: tmuxでは指示とEnterキーを2回に分けて送信する必要があります。

```bash
# 1. まず指示内容を送信
tmux send-keys -t 2 "指示内容をここに記載"

# 2. 次にEnterキーを送信して実行
tmux send-keys -t 2 Enter
```

### 例

```bash
tmux send-keys -t 2 "lsの結果を確認してください"
tmux send-keys -t 2 Enter
```

## 部下からの報告受信方法

部下には以下の方法で報告させる：

```bash
# 部下が実行するコマンド（2段階で送信）
tmux send-keys -t 1 '# 部下からの報告: メッセージ内容'
tmux send-keys -t 1 Enter
```

部下にはこの2段階送信の重要性を明確に指示する必要があります。

## 部下の状態確認方法

```bash
# ペイン2の出力を確認
tmux capture-pane -t 2 -p | tail -20
```

## 注意事項

- Enterキーの送信は必ず別のコマンドとして実行する
- 部下にも同様に2段階送信の必要性を理解させる
