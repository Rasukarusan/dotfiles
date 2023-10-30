# ==============================#
#            export             #
# ==============================#

# crontab -eでもvimを開くようにする
export EDITOR=nvim
# メモリに保存される履歴の件数
export HISTSIZE=1000
# 履歴ファイルに保存される履歴の件数
export SAVEHIST=100000
# history にコマンド実行時刻を記録する
export HIST_STAMPS="mm/dd/yyyy"
# 履歴ファイルの保存先
export HISTFILE=${HOME}/.zsh_history
# vimでESCを押した際のタイムラグをなくす
export KEYTIMEOUT=0
export LDFLAGS="-L/usr/local/opt/mysql@5.6/lib"
export CPPFLAGS="-I/usr/local/opt/mysql@5.6/include"
# neovim
export XDG_CONFIG_HOME="$HOME/.config"
# batのpager設定(brew install bat)
export BAT_PAGER="less -R"
# go getのインストール先
export GOPATH=$HOME/go
# gtagsでpygmentsを指定(多言語対応 e.g.) ruby, javascript)
export GTAGSLABEL=pygments
# 文字コードの指定
export LANG=ja_JP.UTF-8
# fzfのリストを上から並べ、全画面ではなくvimのquickfixライクにする
export FZF_DEFAULT_OPTS='
  --color fg:188,hl:103,fg+:222,bg+:234,hl+:104
  --color info:183,prompt:110,spinner:107,pointer:167,marker:215
  --height 70%
  --reverse
  --exit-0
  --multi
  --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all
  '
export MY_TARGET_GIT_DIR=(
  ~/dotfiles
  ~/scripts
  ~/Documents/github/*
)
# ggrepをgrepにするため
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/python@2/bin:$PATH"
# gemでインストールしたものにPATHを通す
export PATH="/usr/local/lib/ruby/gems/2.5.0/bin:$PATH"
# pyenvにPATHを通す(これをしないとpyenv globalでバージョンが切り替えられない)
export PATH="$HOME/.pyenv/shims:$PATH"
# mysql8.0が入っていて、古いmysqlを使いたい場合必要
export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
# composerの設定
export PATH="$HOME/.config/composer/vendor/bin:$PATH"
# remoteAtomの設定
export PATH=$HOME/local/bin:$PATH
# phpenvの設定
export PATH="$HOME/.phpenv/bin:$PATH"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:$GOPATH/bin
export PATH="/usr/local/Cellar/node/12.9.0/bin/:$PATH"
export PATH=$HOME/.nodebrew/current/bin:$PATH
export PATH="$HOME/.cargo/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# 自作スクリプト
export PATH="$HOME/dotfiles/bin:$PATH"
