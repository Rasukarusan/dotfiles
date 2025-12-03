# ============================== #
#         alias-Command          #
# ============================== #
alias dot='cd ~/dotfiles'
alias vim='nvim'
alias ls='ls -G'
alias l='ls -1'
alias la='ls -laG'
alias laa='ls -ld .*'
alias ll='ls -lG'
alias lh='ls -lh'
alias lm='ls -l "$@" | awk '"'"'{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k);print}'"'"''
alias grep='grep --color=auto -i'
alias ...='cd ../../'
alias ....='cd ../../../'
alias history='history 1'
alias time='/usr/bin/time -p'
alias ssh='TERM=xterm ssh'
alias tree='tree -N -a -I ".DS_Store|.git|node_modules|vendor|.next|dist"'
alias szsh='source ~/.zshrc'
alias stmux='tmux source-file ~/.tmux.conf'
alias tconf='vim ~/.tmux.conf'
alias hp='vim ~/.hyper.js'
alias plantuml='java -jar ~/.plantuml/plantuml.jar'
alias grepr='grep -r'
alias phpS='php -S localhost:9000'
alias phps='hyper-run -s localhost:9000 -t .'
alias js='osascript -l JavaScript'
alias clear='stty sane;clear'
alias gd='git diff -b'
alias gdc='git diff -b --cached'
alias repoo='vim `ls ~/Documents/github/develop_tools/DayReport/*.md | fzf`'
alias co='git checkout $(git branch -a | tr -d " " |fzf-tmux -p80% --prompt "CHECKOUT BRANCH>" --preview "git log --color=always {}" | head -n 1 | sed -e "s/^\*\s*//g" | perl -pe "s/remotes\/origin\///g")'
alias co-='git checkout -'
alias gst='git status'
alias gv='git remote -v'
alias gcl='git clone'
alias gfa='git fetch --all --prune'
# ctagsをbrew installしたものを使う
alias ctags='$(brew --prefix)/bin/ctags'
alias trans='trans -b en:ja'
alias transj='trans -b ja:en'
# ブラウザからコピーした時など、プレーンテキストに戻したい時に使用
alias pcopy='pbpaste | pbcopy'
# スプレッドシートから表をコピーしてRedmineのテーブル形式に整形したい時に使用(先頭と末尾に|を挿入,タブを|に置換)
alias rtable='pbpaste | tr "\t" "|" | sed -e "s/^/|/g" -e "s/$/|/g" -e "/|\"/s/|$//g" -e "/\"|/s/^|//g" | tr -d \" | pbcopy'
# modifiedのファイルを全てタブで開く
alias vims='vim -p `git diff --name-only`'
# Unite tabでコピーしたものをタブで開く
alias vimt="vim -p `pbpaste | sed 's/(\/)//g' | awk -F ':' '{print $2}' | grep -v '\[' | tr '\n' ' '`"
# 最終更新日が一番新しいもののファイル名を取得
alias fin='echo `ls -t | head -n 1`'
# less `fin`と打つのが面倒だったため関数化。finはコマンドとして残しておきたいので残す
alias late='less $(echo `ls -t | head -n 1`)'
# 現在のブランチの番号のみを取得してコピーする
alias gget="git rev-parse --abbrev-ref HEAD | grep -oP '[0-9]*' | tr -d '\n' | pbcopy;pbpaste"
# 空行を削除
alias demp='sed "/^$/d"'
# 一時ファイル作成エイリアス
alias p1='pbpaste > ~/p1'
alias p2='pbpaste > ~/p2'
alias p1e='vim ~/p1'
alias p2e='vim ~/p2'
alias pd='vimdiff ~/p1 ~/p2'
alias pst='pstree | less -S'
alias oo='open .'
alias of='ls -1F | grep -v "/" | fzf --preview "bat --color=always {}" | xargs open'
alias hosts='sudo vim /etc/hosts'
alias mailque='postqueue -p'
alias maildel='sudo postsuper -d ALL deferred'
alias today="date '+%Y/%m/%d(%a)'"
# クリップボードの行数を出力
alias wcc='pbpaste | grep -c ^'
# vimをvimrcなし, プラグインなしで起動する
# NONEにvimrcのPATHを入れれば読み込むことができる
alias vimn='vim -u NONE -N'
alias pp='pbpaste'
alias pc='pbcopy'
# グローバルIPを確認
alias myip='curl ifconfig.io -4'
alias xcode-restore='update_xcode_plugins --restore'
alias xcode-unsign='update_xcode_plugins --unsign'
# wifiをON/OFFする
alias wifiConnect='networksetup -setairportpower en0 off && networksetup -setairportpower en0 on'
# printfの色出力を一覧表示
alias printColors='for fore in `seq 30 37`; do printf "\e[${fore}m \\\e[${fore}m \e[m\n"; for mode in 1 4 5; do printf "\e[${fore};${mode}m \\\e[${fore};${mode}m \e[m"; for back in `seq 40 47`; do printf "\e[${fore};${back};${mode}m \\\e[${fore};${back};${mode}m \e[m"; done; echo; done; echo; done; printf " \\\e[m\n"'
alias sshadd='ssh-add ~/.ssh/id_rsa'
alias ts='ts-node'
alias bll='bluetooth-fzf'
alias fa='find ./ -name'
# 半角文字のみの行を抽出する。-vをつければ全角文字の行のみ抽出する
alias hankaku="LANG=C grep '^[[:cntrl:][:print:]]*$'"
# gitで変更があったファイルのみ対象にagをかける
alias mag='git ls-files -m -o --exclude-standard  | xargs ag'
alias man='env LANG=C man'
# terminal上からGoogle検索
alias goo='search_by_google'
alias pj='pbpaste | jq'
alias ch='chrome_history'
alias gg='github'
alias cw='chatwork'
alias sqq='sequel_ace'
alias itt='sh ~/Documents/github/iterm-scripts/iterm.sh'
alias android='~/Library/Android/sdk/emulator/emulator -avd Pixel_4_API_29 -netdelay none -netspeed full'
alias ip='open "https://www.cman.jp/network/support/go_access.cgi"'
alias pjq='pbpaste | jq'
alias code="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"
alias d='cd ~/Desktop'
# SQLフォーマット
alias fq='pbpaste | sleek --uppercase | pbcopy && pbpaste'
alias pq='pbpaste | jq'
alias conda='/opt/homebrew/anaconda3/_conda'
alias cdc='cd $(find . -type d | grep -v .git | fzf --preview "tree {}")'
alias k='kubectl'
alias ag='ag --hidden -S' # --hidden: 隠しファイル対象、-S: 大文字小文字区別なし, -uu: ignore設定を全部無視して全検索。
alias cl='claude'
alias clc='claude --continue'
alias cld='claude --dangerously-skip-permissions'
alias cldr='claude --dangerously-skip-permissions --resume'
alias rg="rg --hidden" # --no-ignoreで全検索
alias tc="table-to-clipboard"

