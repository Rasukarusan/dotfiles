# Claude Code 部下管理・作業分担ガイド

## 【重要】複数部下作業時の必須ルール

**⚠️ 複数の部下に作業をやらせる時は、必ずgit-worktreeを使用すること**

理由：
- 同一ディレクトリでの並行作業はファイルコンフリクトを引き起こす
- 部下が同じファイルを同時編集すると作業が破綻する
- worktreeによる環境分離が並行作業の前提条件

## 部下管理の基本フロー

### 1. 事前準備・計画フェーズ

```bash
# TodoWriteで作業計画を立てる
- 作業内容の詳細確認と分担計画
- git-worktree環境構築（必須）
- 部下用tmuxペイン作成
- 作業進捗監視とサポート
```

### 2. git-worktree環境構築（必須手順）

```bash
# 【必須】複数部下作業前にworktree環境を構築
# 1. 現在の作業をコミット（基準点作成）
git add .
git commit -m "WIP: 部下作業開始前の状態"

# 2. 部下用worktree作成
git worktree add ../project-worker1 -b feature/issue-XX-task1 master
git worktree add ../project-worker2 -b feature/issue-YY-task2 master

# 3. worktree確認
git worktree list
```

### 3. tmux環境構築

```bash
# 基本構成：リーダー1つ + 部下2つのペイン
tmux split-window -h        # 右に縦分割
tmux split-window -v        # 現在ペインを横分割

# ペイン構成確認・調整
tmux list-panes            # 現在のペイン状態確認
tmux kill-pane -t <番号>   # 不要ペイン削除
```

### 4. 部下のClaude起動

```bash
# 【重要】各部下を専用worktreeに移動
tmux send-keys -t 2 'cd /path/to/project-worker1' Enter
tmux send-keys -t 3 'cd /path/to/project-worker2' Enter

# 部下Claude起動（必須オプション）
tmux send-keys -t 2 'claude --dangerously-skip-permissions' Enter
tmux send-keys -t 3 'claude --dangerously-skip-permissions' Enter
```

### 5. 部下への指示方法

```bash
# 【重要】2段階送信が必須
# 1. 指示内容送信
tmux send-keys -t 2 '具体的な作業指示をここに記載'

# 2. 実行（Enter送信）
tmux send-keys -t 2 Enter
```

### 6. 作業進捗監視

```bash
# 部下の現在状況確認
tmux capture-pane -t 2 -p | tail -10
tmux capture-pane -t 3 -p | tail -10

# 定期的に進捗確認指示
tmux send-keys -t 2 '進捗状況を報告してください'
tmux send-keys -t 2 Enter
```

## git-worktree による作業環境分離

### なぜgit-worktreeを使うか

**⚠️ 重要：複数部下作業時はworktree使用が必須**

- 複数の部下が同時に同じファイルを編集するとコンフリクトが発生
- 部下が同じディレクトリで作業すると相互に干渉し作業が破綻する
- 各部下に独立したworking directoryを提供することで完全に回避
- **今後は複数部下作業時には必ずworktreeを使用すること**

### worktree基本操作

```bash
# 現在の作業をコミット（基準点作成）
git add .
git commit -m "WIP: 部下作業開始前の状態"

# 部下用worktree作成（各々独立したブランチで）
git worktree add ../project-worker1 -b feature/issue-XX-task1 master
git worktree add ../project-worker2 -b feature/issue-YY-task2 master

# worktree確認
git worktree list

# 部下を各worktreeに移動
tmux send-keys -t 2 'cd /path/to/project-worker1' Enter
tmux send-keys -t 3 'cd /path/to/project-worker2' Enter

# 作業完了後のworktree削除（必須クリーンアップ）
git worktree remove ../project-worker1
git worktree remove ../project-worker2
```

## ペイン管理のベストプラクティス

### ペイン構成

```
┌─────────────┬─────────────┐
│             │   部下1     │
│   リーダー   │  (ペイン2)   │
│  (ペイン1)   ├─────────────┤
│             │   部下2     │
│             │  (ペイン3)   │
└─────────────┴─────────────┘
```

### ペイン操作

```bash
# ペイン間移動
tmux select-pane -t 1  # リーダーペインに移動
tmux select-pane -t 2  # 部下1ペインに移動

# ペインサイズ調整
tmux resize-pane -t 1 -x 50%  # リーダーペインを50%幅に
```

## 作業分担の指針

### 分担の考え方

1. **ファイルベース分担**: 異なるファイルを担当させる
2. **機能ベース分担**: 異なる機能領域を担当させる
3. **段階的分担**: 依存関係を考慮して順次実行

### 典型的な分担例

```
部下1: フロントエンド変更
- コンポーネントの修正
- UIロジックの変更

部下2: バックエンド変更 + クリーンアップ
- API修正
- 不要ファイル削除
- テスト実行
```

## エラー対処

### よくある問題と対処法

```bash
# 部下が応答しない場合
tmux send-keys -t 2 'C-c'  # 強制停止
tmux send-keys -t 2 'claude --dangerously-skip-permissions' Enter  # 再起動

# コンフリクト発生時
# → git-worktreeで環境分離

# ペイン構成がおかしい時
tmux list-panes           # 状況確認
tmux kill-pane -t <番号>  # 不要ペイン削除
# 必要に応じてペイン再作成
```

## 最終チェックリスト

作業完了時の確認事項：

- [ ] 各部下が担当作業を完了
- [ ] 適切なブランチでPR作成
- [ ] **【必須】不要なworktreeを削除**
- [ ] tmuxペインをクリーンアップ  
- [ ] TodoWriteで全タスク完了マーク

### 重要な注意事項

**⚠️ 今後の複数部下作業では以下を厳守すること：**

1. **事前にworktree環境を構築**
2. **各部下を独立したworktreeに配置**
3. **作業完了後は必ずworktreeをクリーンアップ**

この手順を守らないと、ファイルコンフリクトにより作業が破綻する可能性があります。
