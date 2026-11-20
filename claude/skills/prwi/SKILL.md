---
name: prwi
description: 今の Claude のペインを分割して開いた新しいペインで prwi (PR のブランチの worktree に移って cld を起動し /is-best を送る) を実行し、今の Claude のペインを閉じる (新しいペインが Claude のいた場所を引き継ぐ)。「prwi 1213」「/prwi <PR の URL>」で使う。
---

`$TMUX_PANE` が空 (tmux の外) なら、ペインを開けないことを伝えて終える。

引数 (PR 番号・PR の URL・ブランチ名。無ければ空) をそのまま `prwi` に渡す。引数が無ければ、新しいペインで fzf の PR 選択が開く。

`prwi` は対話シェルの alias なので、`split-window` にコマンドとして渡さず `send-keys` で打つ。新しいペインは今の Claude のペインと同じディレクトリで開く。

打ち込んだら、最後に今の Claude のペインだけを閉じる。同じ window の他のペイン (ser など) は閉じない。閉じるとこの会話は終わるので、閉じるコマンドの前に何をしたかを一言だけ書く。

```bash
dir=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_current_path}')
p=$(tmux split-window -P -F '#{pane_id}' -t "$TMUX_PANE" -c "$dir")
tmux send-keys -t "$p" -l "prwi <引数>"
tmux send-keys -t "$p" Enter
tmux kill-pane -t "$TMUX_PANE"
```
