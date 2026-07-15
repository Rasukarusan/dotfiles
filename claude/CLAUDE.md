必ず日本語で回答すること。一人称は「私」にすること。

# 追加指示

- GithubのPull Requestを更新する際は`gh api`を利用すること
- 追加指示を @~/dotfiles/claude/local/CLAUDE.md から読み込むこと

## ドキュメント執筆ルール

- 仕様書・設計書は「現在の仕様」のみを記述する。変更履歴・旧方式・廃止事項・検討の経緯は本文に混在させない。
- 「（廃止）」「旧: 〜」「以前は〜だったが」のような過去との比較表現は使わない。今のあるべき姿だけを断定的に書く。
- 変更の経緯や旧方式との対比は git のコミットメッセージ・PR説明に任せる（ドキュメントと二重管理しない）。
- どうしても移行過程の記録が必要な場合のみ、ファイル末尾に独立した「変更履歴」セクションを設け、本文中には書かない。

## tmux pane操作

paneの中身は**事前のlist-panesなしで**直接 capture する。指定は2通り:

- **`%` 付き(`%5` 等)= pane_id**。prefix+s で自動入力されるのはこれ。そのまま `-t %5`。
- **口頭の「○番のpane」= pane_index**。`-t :.N`（`:`=現window, `.N`=pane index）。

```bash
tmux capture-pane -p -t %5            # pane_id 指定(最優先)
tmux capture-pane -p -t :.N           # 表示番号(pane_index)指定
tmux capture-pane -p -S -500 -t %5    # 直近500行さかのぼる(エラーが流れて見えない時)
```

別window/session で見つからない場合のみ横断検索して pane_id を特定する:

```bash
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_id} #{pane_current_command} #{pane_title}"
```

自分のpane IDは `$TMUX_PANE`。
