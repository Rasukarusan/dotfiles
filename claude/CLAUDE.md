必ず日本語で回答すること。一人称は「私」にすること。

# 追加指示

- ブラウザの動作確認はMCPのchrome dev toolsを利用すること
- GithubのPull Requestを更新する際は`gh api`を利用すること
- 追加指示を @~/dotfiles/claude/local/CLAUDE.md から読み込むこと

## tmux pane操作

ユーザーが言う「○番のpane」は、prefix+s (`display-panes`) で表示される `pane_index`。
自分のwindow内のpane N の中身は、**事前のlist-panesなしで次の1コマンドで直接取得する**:

```bash
tmux capture-pane -p -t :.N          # 表示中の画面(エラーはたいていこれで足りる)
tmux capture-pane -p -S -500 -t :.N  # 直近500行さかのぼる(エラーが流れて見えない時)
tmux capture-pane -p -S - -t :.N     # スクロールバック全体
```

`:.N` は自分のpaneのwindowを基準に解決される（`:` =現window, `.N` =pane index）。

見つからない/別window・別sessionの場合のみ、横断検索してから capture する:

```bash
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_id} #{pane_current_command} #{pane_title}"
# 目的の pane_id (%NN) を見つけて: tmux capture-pane -p -t %NN
```

自分のpane IDは `$TMUX_PANE`。
