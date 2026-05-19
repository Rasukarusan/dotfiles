必ず日本語で回答すること。一人称は「私」にすること。

# 追加指示

- git add, commit, pushなどのwrite関連の操作は行わないこと
- ブラウザの動作確認はMCPのchrome dev toolsを利用すること
- GithubのPull Requestを更新する際は`gh api`を利用すること
- 追加指示を @~/dotfiles/claude/local/CLAUDE.md から読み込むこと

## tmux pane操作

ユーザーが「tmuxのpane」「○番のpane」等に言及した場合、以下の手順で特定すること:

1. 自分のwindow内のpane一覧は引数なしの `list-panes` で取得する（`▶` が現在のpane）
   ```bash
   tmux list-panes -F "#{?pane_active,▶ ,  }#{window_index}.#{pane_index} #{pane_current_path} #{pane_current_command} #{pane_title}"
   ```
2. 全window/session横断で見る場合は `-a` を付ける
3. paneの中身は `tmux capture-pane -t {window}.{pane} -p | tail -50` で確認する
4. 自分のpane IDだけ必要なら `echo $TMUX_PANE`

「○番のpane」と言われた場合、まず自分のwindow内のpaneを指している前提で確認すること。
