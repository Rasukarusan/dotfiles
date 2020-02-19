alias vim='nvim'
bindkey -e # ctrl-aやctrl-eでカーソル移動
# zshのTab補完
autoload -U compinit && compinit
# テーマ読み込み
source ~/dotfiles/zsh/zsh-my-theme.zsh
# Tabで選択できるように
zstyle ':completion:*:default' menu select=2
# 補完で大文字にもマッチ
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# ファイル補完候補に色を付ける
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
setopt auto_param_slash       # ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt mark_dirs              # ファイル名の展開でディレクトリにマッチした場合 末尾に / を付加
setopt auto_menu              # 補完キー連打で順に補完候補を自動で補完
setopt interactive_comments   # コマンドラインでも # 以降をコメントと見なす
setopt magic_equal_subst      # コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt complete_in_word       # 語の途中でもカーソル位置で補完
setopt print_eight_bit        # 日本語ファイル名等8ビットを通す
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt share_history          # 他のターミナルとヒストリーを共有
setopt histignorealldups      # ヒストリーに重複を表示しない
setopt hist_save_no_dups      # 重複するコマンドが保存されるとき、古い方を削除する。
setopt extended_history       # $HISTFILEに時間も記録
setopt print_eight_bit        # 日本語ファイル名を表示可能にする
setopt hist_ignore_all_dups   # 同じコマンドをヒストリに残さない
setopt auto_cd                # ディレクトリ名だけでcdする
setopt no_beep                # ビープ音を消す
# コマンドを途中まで入力後、historyから絞り込み
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# crontab -eでもvimを開くようにする
export EDITOR=vim
# GNU系のコマンドをg付けずに実行するため
# export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
# ggrepをgrepにするため
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/python@2/bin:$PATH"
# gemでインストールしたものにPATHを通す
export PATH="/usr/local/lib/ruby/gems/2.5.0/bin:$PATH"
# pyenvにPATHを通す(これをしないとpyenv globalでバージョンが切り替えられない)
export PATH="$HOME/.pyenv/shims:$PATH"
# mysql8.0が入っていて、古いmysqlを使いたい場合必要
export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
# composerの設定
export PATH="$HOME/.composer/vendor/bin:$PATH"
# remoteAtomの設定
export PATH=$HOME/local/bin:$PATH
# phpenvの設定
export PATH="$HOME/.phpenv/bin:$PATH"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export LDFLAGS="-L/usr/local/opt/mysql@5.6/lib"
export CPPFLAGS="-I/usr/local/opt/mysql@5.6/include"
# neovim
export XDG_CONFIG_HOME="$HOME/.config"
# batのpager設定(brew install bat)
export BAT_PAGER="less -R"
# go getのインストール先
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
# gtagsでpygmentsを指定(多言語対応 e.g.) ruby, javascript)
export GTAGSLABEL=pygments
# 文字コードの指定
export LANG=ja_JP.UTF-8
# 履歴ファイルの保存先
export HISTFILE=${HOME}/.zsh_history
# メモリに保存される履歴の件数
export HISTSIZE=1000
# 履歴ファイルに保存される履歴の件数
export SAVEHIST=100000
# history にコマンド実行時刻を記録する
export HIST_STAMPS="mm/dd/yyyy"
# fzfのリストを上から並べ、全画面ではなくvimのquickfixライクにする
export FZF_DEFAULT_OPTS='--color=fg+:11 --height 70% --reverse --select-1 --exit-0 --multi --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'
export MY_TARGET_GIT_DIR=(
    ~/dotfiles
    ~/Desktop/ru-she-1nian-mu
)
# 特定のコマンドのみ履歴に残さない
zshaddhistory() {
    local line=${1%%$'\n'}
    local cmd=${line%% *}
    # 以下の条件をすべて満たすものだけをヒストリに追加する
    [[ ${#line} -ge 5
        && ${cmd} != (l|l[sal]) # l,ls,la,ll
        && ${cmd} != (c|cd)
        && ${cmd} != (fg|fgg)
    ]]
}

fpath=(~/.zsh/anyframe(N-/) $fpath)
autoload -Uz anyframe-init
anyframe-init
# cdrの設定
autoload -Uz is-at-least
if is-at-least 4.3.11
then
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ':chpwd:*'      recent-dirs-max 500
  zstyle ':chpwd:*'      recent-dirs-default yes
  zstyle ':chpwd:*'      recent-dirs-file "$HOME/.cache/cdr/history"
  zstyle ':completion:*' recent-dirs-insert both
fi

# fgを使わずctrl+zで行ったり来たりする
fancy-ctrl-z () {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fg"
    zle accept-line
  else
    zle push-input
    zle clear-screen
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# PATHがsource ~/.zshrcする度に重複して登録されないようにする
typeset -U path PATH
# vimでESCを押した際のタイムラグをなくす
KEYTIMEOUT=0
source /Users/$(whoami)/.phpbrew/bashrc

[ -f ~/dotfiles/zsh/function.zsh ] && source ~/dotfiles/zsh/function.zsh
[ -f ~/dotfiles/zsh/alias_script.zsh ] && source ~/dotfiles/zsh/alias_script.zsh
[ -f ~/dotfiles/zsh/alias_command.zsh ] && source ~/dotfiles/zsh/alias_command.zsh
[ -f ~/dotfiles/zsh/alias_function.zsh ] && source ~/dotfiles/zsh/alias_function.zsh
# zshrc.localを読み込む(行末に書くことで設定を上書きする)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
