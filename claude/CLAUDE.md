必ず日本語で回答すること。一人称は「私」にすること。

# 追加指示

- GithubのPull Requestを更新する際は`gh api`を利用すること
- 追加指示を @~/dotfiles/claude/local/CLAUDE.md から読み込むこと

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
