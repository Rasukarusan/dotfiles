# Claude Code 部下管理・作業分担ガイド

## 🚨 部下起動の即座実行ガイド（リーダー向け）

**重要：リーダーは計画立案時に"ultrathink"を使用すること**

**「部下を起動してタスクをやらせてください」と指示されたら、以下を即座に実行すること：**

### 【クイックスタート】最小構成での部下起動

```bash
# 0. 既存ペインのクリーンアップ（必須）
# リーダーペイン（ペイン1）以外を削除
for i in {2..9}; do
    if tmux list-panes -F '#{pane_index}' | grep -q "^$i$"; then
        tmux kill-pane -t $i 2>/dev/null || true
    fi
done

# 1. tmuxペイン作成（必須）
tmux split-window -h

# 2. 部下Claude起動（必須）
tmux send-keys -t 2 'claude --dangerously-skip-permissions' Enter

# 3. 起動確認（1秒待機）
sleep 1

# 4. タスク指示送信（必ず2段階で送信）
tmux send-keys -t 2 'タスクの内容をここに記載

報告は以下の2段階でリーダーペイン（ペイン1）に送信してください：
1段階目：tmux send-keys -t 1 "【部下2報告】報告内容"
2段階目：tmux send-keys -t 1 Enter'  # 1段階目：内容のみ
tmux send-keys -t 2 Enter                            # 2段階目：Enterを別途送信

# 5. リーダーペインに戻る（重要）
tmux select-pane -t 1

# 6. 部下からの報告受信
# 部下からの報告は直接リーダーペインに表示される
# 例：【部下2報告】作業を開始しました
```

### 【フルスタート】複数部下での並行作業時

```bash
# 0. 既存ペインのクリーンアップ（必須）
# リーダーペイン（ペイン1）以外を削除
for i in {2..9}; do
    if tmux list-panes -F '#{pane_index}' | grep -q "^$i$"; then
        tmux kill-pane -t $i 2>/dev/null || true
    fi
done

# 1. git-worktree準備（複数部下の場合必須）
git worktree add ../$(basename $(pwd))-worker1 -b feature/worker1-task master
git worktree add ../$(basename $(pwd))-worker2 -b feature/worker2-task master

# 2. tmuxペイン作成（3ペイン構成）
tmux split-window -h        # 部下1用
tmux split-window -v        # 部下2用

# 3. 各worktreeへ移動
tmux send-keys -t 2 'cd ../$(basename $(pwd))-worker1' Enter
tmux send-keys -t 3 'cd ../$(basename $(pwd))-worker2' Enter

# 4. 部下Claude起動
tmux send-keys -t 2 'claude --dangerously-skip-permissions' Enter
tmux send-keys -t 3 'claude --dangerously-skip-permissions' Enter

# 5. 起動確認
sleep 1

# 6. タスク指示（必ず2段階で送信）
tmux send-keys -t 2 'タスク1の内容をここに記載'  # 1段階目
tmux send-keys -t 2 Enter                        # 2段階目
tmux send-keys -t 3 'タスク2の内容をここに記載'  # 1段階目
tmux send-keys -t 3 Enter                        # 2段階目

# 7. リーダーペインに戻る（重要）
tmux select-pane -t 1
```

### 【部下起動チェックリスト】

- [ ] tmuxペインを作成したか？
- [ ] claudeコマンドを実行したか？
- [ ] --dangerously-skip-permissionsオプションを付けたか？
- [ ] Enterキーを送信したか？
- [ ] 起動を待機したか？（1秒以上）
- [ ] タスク内容を送信したか？（2段階送信で）
- [ ] **タスク送信時、内容とEnterを別々に送信したか？**

---

## 【重要】複数部下作業時の必須ルール

**⚠️ 複数の部下に作業をやらせる時は、必ずgit-worktreeを使用すること**

理由：

- 同一ディレクトリでの並行作業はファイルコンフリクトを引き起こす
- 部下が同じファイルを同時編集すると作業が破綻する
- worktreeによる環境分離が並行作業の前提条件

## 作業フロー全体像

```
1. 事前準備（TodoWrite + 作業計画）
    ↓
2. git-worktree環境構築（必須）
    ↓
3. tmuxペイン作成・部下起動
    ↓
4. 部下への作業指示・進捗監視
    ↓
5. PR作成指示
    ↓
6. クリーンアップ（worktree削除・ペイン削除）
```

## ステップ別詳細手順

### 1. 事前準備・計画フェーズ

```bash
# リーダーは計画立案時にultrathinkを使用
# 例：「ultrathink 複数の機能を効率的に実装するための分担計画を立ててください」

# TodoWriteで作業計画を立てる
- [ ] 作業内容の詳細確認と分担計画
- [ ] git-worktree環境構築（必須）
- [ ] 部下用tmuxペイン作成
- [ ] 各部下への作業指示
- [ ] 作業進捗監視とサポート（リーダーによる確認）
- [ ] PR作成指示
- [ ] 環境クリーンアップ
```

**ultrathink使用例：**

- 複雑なタスクの分担計画を立てる時
- 技術的な判断や設計決定を行う時
- 問題解決やトラブルシューティングを行う時
- 作業の優先順位を決める時

### 2. git-worktree環境構築（必須手順）

```bash
# 【必須】複数部下作業前にworktree環境を構築

# 1. 現在の作業状態を確認
git status

# 2. 現在の作業をコミット（基準点作成）
git add .
git commit -m "WIP: 部下作業開始前の状態"

# 3. 部下用worktree作成（プロジェクト名を適切に変更）
git worktree add ../kidoku-worker1 -b feature/issue-XX-task1 master
git worktree add ../kidoku-worker2 -b feature/issue-YY-task2 master

# 4. worktree確認
git worktree list
```

### 3. tmux環境構築

```bash
# 【必須】既存の余分なペインを整理してから3ペイン構成を作成

# 1. 現在のペイン状態を確認
tmux list-panes

# 2. リーダーペイン以外をすべて削除（エラーが出ても無視）
# リーダーペイン（ペイン1）以外を削除
for i in {2..9}; do
    if tmux list-panes -F '#{pane_index}' | grep -q "^$i$"; then
        tmux kill-pane -t $i 2>/dev/null || true
    fi
done

# 3. 基本構成：リーダー1つ + 部下2つのペイン
tmux split-window -h        # 右に縦分割（部下1用）
tmux split-window -v        # 現在ペインを横分割（部下2用）

# 4. ペイン構成確認（必ずリーダー、部下1、部下2の3つになる）
tmux list-panes

# 5. リーダーペインを選択状態にする（重要：リーダーで作業しないため）
tmux select-pane -t 1
```

**ペイン構成図：**

```
┌─────────────┬─────────────┐
│             │   部下1     │
│   リーダー   │  (ペイン2)   │
│  (ペイン1)   ├─────────────┤
│             │   部下2     │
│             │  (ペイン3)   │
└─────────────┴─────────────┘
```

### 4. 部下のClaude起動

```bash
# 【重要】各部下を専用worktreeに移動（パスは実際のプロジェクトに合わせて変更）
tmux send-keys -t 2 'cd ~/Documents/github/kidoku-worker1' Enter
tmux send-keys -t 3 'cd ~/Documents/github/kidoku-worker2' Enter

# 各worktreeでの位置確認
tmux send-keys -t 2 'pwd' Enter
tmux send-keys -t 3 'pwd' Enter

# 部下Claude起動（必須オプション付き）
tmux send-keys -t 2 'claude --dangerously-skip-permissions' Enter
tmux send-keys -t 3 'claude --dangerously-skip-permissions' Enter

# 【重要】起動待機（必須）
sleep 1  # Claudeの起動を待つ

# 起動確認メッセージ
echo "部下Claudeを起動しました。タスクを指示してください。"
```

### 5. 部下への指示方法

```bash
# 【超重要】必ず2段階送信すること！1行で書かない！
# ❌ 間違い例：tmux send-keys -t 2 'タスク内容' Enter
# ✅ 正しい例：
#   tmux send-keys -t 2 'タスク内容'
#   tmux send-keys -t 2 Enter

# 例1: 部下1に具体的なタスクを指示（報告方法も明示）
tmux send-keys -t 2 'src/components/配下のコンポーネントをTypeScript化してください。型定義を適切に追加し、any型は使用しないでください。

報告方法：
進捗報告は以下の2段階でリーダーペイン（ペイン1）に送信してください：
1段階目：tmux send-keys -t 1 "【部下1報告】報告内容"
2段階目：tmux send-keys -t 1 Enter

報告タイミング：
- 作業開始時
- 問題発生時（即座に）
- 作業完了時'
tmux send-keys -t 2 Enter

# 例2: 部下2に別のタスクを指示（報告方法も明示）
tmux send-keys -t 3 'src/api/配下のAPIクライアントのエラーハンドリングを改善してください。try-catchを適切に実装し、エラーログを追加してください。

報告方法：
進捗報告は以下の2段階でリーダーペイン（ペイン1）に送信してください：
1段階目：tmux send-keys -t 1 "【部下1報告】報告内容"
2段階目：tmux send-keys -t 1 Enter

報告タイミング：
- 作業開始時
- 問題発生時（即座に）
- 作業完了時'
tmux send-keys -t 3 Enter
```

### 6. 作業進捗監視

**📢 重要：部下からリーダーペインへの報告送信方法**

部下は以下のコマンドでリーダーペイン（ペイン1）に直接報告を送信します：

```bash
# 部下からリーダーへの報告送信フォーマット（必ず2段階で送信）
# 例1：作業開始報告
tmux send-keys -t 1 '【部下2報告】作業開始：TypeScript化を開始します'
tmux send-keys -t 1 Enter

# 例2：問題報告
tmux send-keys -t 1 '【部下2報告】問題：型定義ファイルが見つかりません'
tmux send-keys -t 1 Enter

# 例3：完了報告
tmux send-keys -t 1 '【部下2報告】完了：全ファイルのTypeScript化が完了しました'
tmux send-keys -t 1 Enter
```

**リーダーによる進捗確認（必要に応じて実施）**

```bash
# リーダーが必要と判断した時に進捗確認を要求
tmux send-keys -t 2 '現在の進捗状況を報告してください。報告は以下のコマンドでリーダーペイン（ペイン1）に送信してください：
1段階目：tmux send-keys -t 1 "【部下2報告】進捗内容をここに記載"
2段階目：tmux send-keys -t 1 Enter'
tmux send-keys -t 2 Enter

# リーダーの確認タイミング例
# - タスク開始5-10分後：初期進捗確認
# - 予定時間を超過した場合
# - 部下からの報告が途絶えた場合
# - 作業内容に不安がある場合
```

#### 効果的な報告の要求方法

```bash
# 具体的な質問で報告を要求
tmux send-keys -t 2 '以下の項目について報告してください：
1. 現在作業中のタスク
2. 完了率（%）
3. 直面している課題（あれば）
4. 完了予定時刻

報告は以下のコマンドで送信してください：
1段階目：tmux send-keys -t 1 "【部下2報告】項目1: xxx, 項目2: xxx%"
2段階目：tmux send-keys -t 1 Enter' Enter

# 問題解決のサポート要求
tmux send-keys -t 2 'エラーや問題に直面している場合は、詳細を教えてください。必要であればサポートします。
報告は以下のコマンドで送信してください：
1段階目：tmux send-keys -t 1 "【部下2報告】問題: 詳細内容"
2段階目：tmux send-keys -t 1 Enter' Enter

# 報告例
# リーダーペインには以下のように表示される：
# 【部下2報告】作業開始：TypeScript化を開始します
# 【部下2報告】進捗50%：10ファイル中5ファイル完了
# 【部下2報告】問題：型定義ファイルが見つかりません
# 【部下2報告】完了：全ファイルのTypeScript化が完了しました
```

### 7. PR作成指示

```bash
# 作業完了確認後、各部下にPR作成を指示

# 部下1へのPR作成指示
tmux send-keys -t 2 'タスクが完了したので、PRを作成してください。変更内容を適切にまとめ、テストプランも含めてPRの説明を書いてください。'
tmux send-keys -t 2 Enter

# 部下2へのPR作成指示
tmux send-keys -t 3 'タスクが完了したので、PRを作成してください。変更内容を適切にまとめ、テストプランも含めてPRの説明を書いてください。'
tmux send-keys -t 3 Enter

# PR作成状況の確認
tmux send-keys -t 2 'PR作成は完了しましたか？PRのURLを教えてください。'
tmux send-keys -t 2 Enter
```

### 8. 環境クリーンアップ

```bash
# 【必須】作業完了後のクリーンアップ

# 1. 部下の作業終了、tmuxペイン削除
tmux send-keys -t 2 'exit' Enter && tmux send-keys -t 2 Enter
tmux send-keys -t 3 'exit' Enter && tmux send-keys -t 3 Enter

# 2. リーダーペイン（ペイン1）以外を削除
for i in {2..9}; do
    if tmux list-panes -F '#{pane_index}' | grep -q "^$i$"; then
        tmux kill-pane -t $i 2>/dev/null || true
    fi
done

# 3. worktree削除
git worktree remove ../kidoku-worker1
git worktree remove ../kidoku-worker2

# 4. worktree確認（削除されていることを確認）
git worktree list
```

## 作業分担の指針

### 効果的な分担方法

1. **ファイルベース分担**

   - 異なるディレクトリ・ファイルを担当
   - 例: 部下1=フロントエンド、部下2=バックエンド

2. **機能ベース分担**

   - 独立した機能単位で分割
   - 例: 部下1=認証機能、部下2=検索機能

3. **タスクタイプ別分担**
   - 作業の性質で分割
   - 例: 部下1=新機能実装、部下2=リファクタリング+テスト

### 分担時の注意点

- 依存関係が少ないタスクを選ぶ
- 同じファイルを編集させない
- 明確な境界線を設定する

## トラブルシューティング

### よくある問題と対処法

```bash
# 【問題】部下が起動しない・応答しない
# 原因1: tmuxペインが作成されていない
tmux list-panes  # ペイン確認
tmux split-window -h  # ペイン作成し直し

# 原因2: claudeコマンドが実行されていない
tmux send-keys -t 2 'claude --dangerously-skip-permissions' Enter
sleep 1  # 必ず待機

# 原因3: Enterキーが送信されていない
tmux send-keys -t 2 Enter  # 再度Enter送信

# 原因5: タスク指示を1行で送信してしまった
# ❌ 間違い：tmux send-keys -t 2 'タスク' Enter
# ✅ 修正方法：
tmux send-keys -t 2 'タスク内容'  # まず内容のみ
tmux send-keys -t 2 Enter          # 次にEnter

# 原因4: 部下がフリーズしている
tmux send-keys -t 2 C-c  # Ctrl+C送信
tmux send-keys -t 2 'claude --dangerously-skip-permissions' Enter  # 再起動
sleep 1

# ペイン番号がわからない場合
tmux list-panes -a  # 全ペイン情報表示

# worktreeが削除できない場合
git worktree prune  # 壊れたworktree参照をクリーン
git worktree remove --force ../kidoku-worker1  # 強制削除

# 部下の出力が見切れる場合
tmux capture-pane -t 2 -p -S -3000  # 過去3000行まで取得
```

## 最終チェックリスト

作業完了時の確認事項：

- [ ] 各部下が担当作業を完了
- [ ] 作業進捗を適切に把握していたか
- [ ] 作業内容の品質確認（コードレビュー）
- [ ] **【必須】各部下にPR作成を指示し、PR URLを確認**
- [ ] PRの内容が適切か確認
- [ ] **【必須】すべてのworktreeを削除**
- [ ] tmuxペインをクリーンアップ
- [ ] TodoWriteで全タスクを完了マーク

## 重要な注意事項

**⚠️ 部下起動時の必須事項：**

1. **「部下を起動して」と言われたら即座にtmuxペイン作成とclaude起動を実行**
2. **claudeコマンドには必ず`--dangerously-skip-permissions`オプションを付ける**
3. **コマンド送信後は必ずEnterキーも送信する**
4. **起動後は1秒待機してからタスクを指示する**
5. **リーダーは計画立案・高度判断時に"ultrathink"を使用する**
6. **【超重要】タスク指示は必ず2段階送信（内容送信→Enter送信を別々に）**
7. **【超重要】部下への指示には必ず2段階送信の報告方法を含める**

**🚨 リーダーの絶対禁止事項：**

1. **リーダーペインで直接コーディング作業を行うことは絶対禁止**
2. **すべての実装作業は必ず部下にやらせる**
3. **リーダーは指示・監視・調整のみを行う**
4. **リーダーは必ずペイン1を使用し、作業用ペインに切り替えない**
5. **リーダーは計画立案時に"ultrathink"を使用すること**

**✅ リーダーの責務：**

1. **部下の進捗を必要に応じて確認する**
   - 部下からの報告は【部下X報告】形式でリーダーペインに直接表示される
   - リーダーが必要と判断したタイミングで進捗確認を要求する
2. **部下からの報告に基づいて適切な指示を出す**
3. **問題発生時は迅速にサポートする**
4. **全体の作業調整と品質管理を行う**

**⚠️ 複数部下作業では以下を厳守すること：**

1. **必ずworktree環境を事前に構築する**
2. **各部下を独立したworktreeで作業させる**
3. **作業完了後は各部下にPR作成を指示する**
4. **必ずworktreeとペインをクリーンアップする**

この手順を守らないと、ファイルコンフリクトやブランチの混乱により作業が破綻します。

## デバッグ用コマンド

```bash
# 部下の状態確認
tmux capture-pane -t 2 -p | tail -20  # 最新20行を確認

# ペイン一覧確認
tmux list-panes -a

# 部下プロセス確認
ps aux | grep claude
```
