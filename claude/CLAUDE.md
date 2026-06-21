必ず日本語で回答すること。一人称は「私」にすること。

# 追加指示

- ブラウザの動作確認はMCPのchrome dev toolsを利用すること
- GithubのPull Requestを更新する際は`gh api`を利用すること
- 追加指示を @~/dotfiles/claude/local/CLAUDE.md から読み込むこと

## tmux pane操作

paneの指定には2通りある:

- **`pane%5を確認して`** のように `%` 付きで来たら、それは **pane_id**(`%5` 等)。
  paneを削除しても番号がズレない安定IDなので、**そのまま `-t %5` で capture する**。
  prefix+s でclaudeペインに自動入力されるのはこの形式。
- ユーザーが口頭で言う **「○番のpane」** は、prefix+s (`display-panes`) で表示される `pane_index`。
  この場合は下記の `:.N` 形式を使う。

paneの中身は、**事前のlist-panesなしで次の1コマンドで直接取得する**:

```bash
tmux capture-pane -p -t %5            # pane_id 指定(prefix+s で来るのはこれ。最優先)
tmux capture-pane -p -t :.N           # 表示番号(pane_index)指定
tmux capture-pane -p -S -500 -t %5    # 直近500行さかのぼる(エラーが流れて見えない時)
tmux capture-pane -p -S - -t %5       # スクロールバック全体
```

`:.N` は自分のpaneのwindowを基準に解決される（`:` =現window, `.N` =pane index）。
`%5` のような pane_id はwindow/session に依らずグローバルに解決される。

見つからない/別window・別sessionの場合のみ、横断検索してから capture する:

```bash
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_id} #{pane_current_command} #{pane_title}"
# 目的の pane_id (%NN) を見つけて: tmux capture-pane -p -t %NN
```

自分のpane IDは `$TMUX_PANE`。
