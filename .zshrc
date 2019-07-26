bindkey -e # ctrl-aやctrl-eでカーソル移動
# zshのTab補完
autoload -U compinit && compinit
# テーマ読み込み
source ~/dotfiles/zsh-my-theme.sh
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

alias l='ls -ltrG'
alias la='ls -laG'
alias laa='ls -ld .*'
alias ll='ls -lG'
alias ls='ls -G'
alias grep='grep --color=auto'
alias ...='cd ../../'
alias his='history -E -i 1 | fzf'

#centosにsshするとviで下記のエラーが出ることがあるので対策
# E437: terminal capability "cm" required
alias ssh='TERM=xterm ssh'
# crontab -eでもvimを開くようにする
export EDITOR=vim
# GNU系のコマンドをg付けずに実行するため
# export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
# ggrepをgrepにするため
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/python@2/bin:$PATH"
# fzfのリストを上から並べ、全画面ではなくvimのquickfixライクにする
export FZF_DEFAULT_OPTS='--color=fg+:11 --height 70% --reverse --select-1 --exit-0 --multi'
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
# batのpager設定(brew install bat)
export BAT_PAGER="less -R"
# go getのインストール先
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
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
# dotfileなど家と会社のPCで差分があると困るものを指定する
export MY_TARGET_GIT_DIR=(
# ~/.vim 
    ~/dotfiles
    ~/Desktop/ru-she-1nian-mu
)
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

# PATHがsource ~/.zshrcする度に重複して登録されないようにする
typeset -U path PATH
# vimでESCを押した際のタイムラグをなくす
KEYTIMEOUT=0
# fzf版cdd
alias cdd='fzf-cdr'
function fzf-cdr() {
    local target_dir=$(cdr -l | sed 's/^[^ ][^ ]*  *//' | fzf)
    # ~だと移動できないため、/Users/hogeの形にする
    target_dir=$(echo ${target_dir/\~/$HOME})
    if [ -n "$target_dir" ]; then
        cd $target_dir
    fi
}
# 英語のmanを表示する
#alias man='env LANG=C man'
# treeコマンドで日本語表示
alias tree="tree --charset=C -NC"
# vim ~/.zshrcと打つのが面倒なのでzshrcにする
alias zshrc='vim ~/.zshrc'
# source ~/.zshrcを簡略化
alias szsh='source ~/.zshrc'
# vim ~/.vimrcと打つのが面倒なのでvimrcにする
alias vimrc='vim ~/.vimrc'
alias stmux='tmux source-file ~/.tmux.conf'
alias tconf='vim ~/.tmux.conf'
# plantUMLのエイリアス
alias plantuml='java -jar ~/.plantuml/plantuml.jar'
alias selenium-stop="ps aux | grep selenium | grep -v grep | awk '{print \$2}' | xargs kill -9"
alias selenium-log='_tailLatestSeleniumLog'
alias selenium-status='ps aux | grep -v grep | grep -c selenium'
alias selenium-up='_runSeleniumServer'
function _runSeleniumServer() {
    local LOG_DIR=~/.selenium-log
    if [ ! -e $LOG_DIR ]; then 
        mkdir $LOG_DIR
    fi
    local is_run=`ps aux | grep -v grep | grep -c selenium`
    local today=`date +%Y-%m-%d`
    if [ $is_run -eq 0 ]; then
        java -jar /Library/java/Extensions/selenium-server-standalone-3.4.0.jar > $LOG_DIR/$today.log 2>&1 &
    fi
}
function _tailLatestSeleniumLog() {
    local LOG_DIR=~/.selenium-log
    local latest_selenium_log=`echo $(ls -t $LOG_DIR | head -n 1)`
    tail -f $LOG_DIR/$latest_selenium_log
}

# seleniumの操作リスト
function sell() {
local select_command=`cat << EOF | fzf
selenium-status
selenium-log
selenium-up
selenium-stop
EOF`
    eval $select_command
}

alias grepr='grep -r'
alias phpS='php -S localhost:9000'
alias phps='hyper-run -s localhost:9000 -t .'
source /Users/$(whoami)/.phpbrew/bashrc
alias cot='open $1 -a /Applications/CotEditor.app'
alias js='osascript -l JavaScript'
# terminalの描画がおかしいときにそれも直してclearする
alias clear='stty sane;clear'

# ag & view
alias jump='_jump'
function _jump(){
    if [ -n "$1" ]; then
        #pathと書くと$PATHと被ってエラーが出るので注意
        local file=$(ag $1 | fzf | awk -F ':' '{printf  $1 " +" $2}'| sed -e 's/\+$//')
        if [ -n "$file" ]; then
            # vim $fileのようにそのまま渡すと開けないので文字列で渡して実行
            eval "vim $file"
        fi
    fi
}

# カレントディレクトリ以下をプレビューし選択して開く
alias lk='_look'
function _look() {
    if [ "$1" = "-a" ]; then
        local find_result=`find . -type f`
    else
        local find_result=`find . -maxdepth 1 -type f`
    fi
    local target_file=`echo "$find_result" | sed 's/\.\///g' | grep -v -e ".jpg" -e ".gif" -e ".png" -e ".jpeg" | fzf --prompt "vim " --preview 'bat --color always {}'`

    if [ "$target_file" = "" ]; then
        return
    fi
    vim $target_file
}
alias gd='git diff -b'
alias gdc='git diff -b --cached'
# remoteに設定されているURLを開く
alias gro='_gitRemoteOpen'
function _gitRemoteOpen() {
    local remote=$(git remote show | fzf)
    local url=$(git remote get-url $remote)
    if [ "$url" = '' ]; then; return; fi
    if ! echo $url | grep 'http' >/dev/null; then
        url=$(echo $url | sed 's/git@bitbucket.org:/https:\/\/bitbucket\.org\//g')
    fi
    open $url
}
# 現在のブランチをoriginにpushする
alias -g po='gitPushFzf'
function gitPushFzf() {
    local remote=`git remote | fzf`
    git push ${remote} $(git branch | grep "*" | sed -e "s/^\*\s*//g")
}
# 現在のブランチをpullする
alias -g gpl='git pull --rebase origin $(git branch | grep "*" | sed -e "s/^\*\s*//g")'
# git logをpreviewで差分を表示する
alias -g tigg='_gitLogPreviewOpen'
function _gitLogPreviewOpen() {
    local hashCommit=`git log --oneline | fzf --height=100% --prompt "SELECT COMMIT>" --preview "echo {} | cut -d' ' -f1 | xargs git show --color=always"`
    if [ -n "$hashCommit" ]; then
        git show `echo ${hashCommit} | awk '{print $1}'`
    fi
}
# 差分のあるファイルをfzfでプレビューしながら一覧に表示し、ENTERでlessモード&ファイルパスをクリップボードに
alias -g tigd='_gitDiffPreviewCopy'
function _gitDiffPreviewCopy() {
    local target_diff=`git diff $(git diff --name-only | fzf --prompt "CHECKOUT BRANCH>" --preview "git diff --color=always {}")`
    echo $target_diff | grep "\-\-\- a" | sed "s/--- a\///g" | tr -d "\n" | pbcopy
}
alias chromium='/Applications/Chromium.app/Contents/MacOS/Chromium --headless --disable-gpu'
alias repoo='vim `ls ~/Desktop/ru-she-1nian-mu/DayReport/*.md | fzf`'
# メモを開く
alias memo='vim ~/Desktop/ru-she-1nian-mu/memo.md -c ":$"'
# fzfを使ってプロセスKILL
alias pspk='_pspk'
function _pspk(){
    process=(`ps aux | awk '{print $2,$9,$11,$12}' | fzf | awk '{print $1}'`)
    echo $process | pbcopy
    for item in ${process[@]}
    do
        kill $process
    done
}

# git checkout branchをfzfで選択
alias co='git checkout $(git branch -a | tr -d " " |fzf --height=100% --prompt "CHECKOUT BRANCH>" --preview "git log --color=always {}" | head -n 1 | sed -e "s/^\*\s*//g" | perl -pe "s/remotes\/origin\///g")'
alias co-='git checkout -'
alias cop='_checkoutAndPull'
function _checkoutAndPull() {
    local branches=(`git branch -a | tr -d " " | fzf --prompt "CHECKOUT BRANCH>" --preview "git log {}" | sed -e "s/^\*\s*//g" | perl -pe "s/remotes\/origin\///g"`)
    for branch in ${branches[@]}
    do
        git checkout $branch
        git pull origin $branch
    done
}
alias gst='git status'
# 全てのファイルをgit checkout
alias gca='git checkout $(git diff --name-only)'
# git checkout fileをfzfで選択
alias gcpp='_gitcheckout'
function _gitcheckout(){
    local files=$(git ls-files --modified | fzf --prompt "CHECKOUT FILES>" --preview "git diff --color=always {}")
    if [ -n "$files" ]; then
        git checkout ${=files}
    fi
}

# git add をfzfでdiffを見ながら選択
alias gadd='_gitadd'
function _gitadd(){
    local files=$(git ls-files --modified | fzf --prompt "ADD FILES>" --preview "git diff --color=always {}")
    if [ -n "$files" ]; then
        git add ${=files}
    fi
}

# Untrackedファイルをfzfで見ながらgit add
alias gaut='_gitAddUntrackedFiles'
function _gitAddUntrackedFiles() {
    local files=$(git ls-files --others --exclude-standard | fzf --prompt "ADD FILES>" --preview "bat --color always {}")
    if [ -n "$files" ]; then
        git add ${=files}
    fi
}

# git add -pをfzfでdiffを見ながら選択
alias gapp='_gitadd-p'
function _gitadd-p(){
    local files=$(git ls-files --modified | fzf --prompt "ADD FILES>" --preview "git diff --color=always {} | diff-so-fancy")
    if [ -n "$files" ]; then
        git add -p ${=files}
    fi
}

# git diff をfzfで選択
alias gdd='_gitdiff'
function _gitdiff(){
    local files=$(git ls-files --modified | fzf --prompt "SELECT FILES>" --preview 'git diff --color=always {} | diff-so-fancy')
    if [ -n "$files" ]; then
        echo "$files" | tr -d "\n" | pbcopy
        git diff -b $files
    fi
}
# git resetをfzfでdiffを見ながら選択
alias grpp='_gitreset'
function _gitreset() {
    local files=$(git ls-files --modified | fzf --prompt "RESET FILES>" --preview "git diff --color=always {}")
    if [ -n "$files" ]; then
        git reset ${=files}
    fi
}
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

# herokuへデプロイするのを楽に。第一引数にcommitメッセージを付与できる。指定しない場合は"更新"と入る
function ghero() {
    if [ "$1" = "" ]; then
        1="更新"
    fi
    git add -A
    git commit -m $1
    git push heroku master
}

# fgをfzfで
alias fgg='_fgg'
function _fgg() {
    local wc=$(jobs | wc -l | tr -d ' ')
    if [ $wc -ne 0 ]; then
        local job=$(jobs | awk -F "suspended" "{print $1 $2}"|sed -e "s/\-//g" -e "s/\+//g" -e "s/\[//g" -e "s/\]//g" | grep -v pwd | fzf | awk "{print $1}")
        local wc_grep=$(echo $job | grep -v grep | grep 'suspended')
        if [ "$wc_grep" != "" ]; then
            fg %$job
        fi
    fi
}

function update_master() {
    git checkout master
    git fetch --all
    git pull --rebase origin master
}

# お天気情報を出力する
function tenki() {
    case "$1" in
        "-c") curl -4 http://wttr.in/$2 ;;
          "") finger Kanagawa@graph.no ;;
           *) finger $1@graph.no ;;
    esac
}

# 1~100の中でXの倍数のみを出力
function getMultiple() {
    if [ "$1" = "" ]; then 
        echo "Usage: getMultiple [integer]"
        return 
    fi
    for i in `seq 1 100`
    do
        local num=`echo "$i%$1" | bc`
        if [ $num -eq 0 ]; then
            echo $i
        fi
    done
}

# ctagsをbrew installしたものを使う
alias ctags="`brew --prefix`/bin/ctags"
# phpでprint_rしたものを変数定義できるようにコピー
alias phparr='pbpaste | xargs sh ~/phparr.sh | pbcopy'
# コマンド完了時に通知を受け取る
alias noti='_noti'
function _noti() {
    local msg=$1
    if [ -z "$msg" ]; then
        msg='コマンド完了'
    fi
    terminal-notifier -message "$msg"
}
# コマンドでgoogle翻訳
alias trans='trans -b en:ja'
alias transj='trans -b ja:en'
# sh redmineを実行
alias rr='sh ~/redmine.sh'
# dotfile系
alias upd='_updateDotfile'
alias psd='_pushDotfile'
alias std='_showGitStatusDotfile'
# 色付きで出力する
function printColor() {
    printf "\e[33m$1\e[m\n"
}
# あらかじめ指定したGitディレクトリを全て最新にする
function _updateDotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printColor `basename ${targetDir}`
        git -C ${targetDir} pull origin master
        echo ""
    done
}
# あらかじめ指定したGitディレクトリを全てpushする
function _pushDotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printColor `basename ${targetDir}`
        git -C ${targetDir} add -A
        git -C ${targetDir} commit -v
        git -C ${targetDir} push origin master
        echo ""
    done
}
# あらかじめ指定したGitディレクトリのgit statusを表示
function _showGitStatusDotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printColor `basename ${targetDir}`
        git -C ${targetDir} status
        echo ""
    done
}
# 選択したディレクトリのgit diffを表示
alias stdd='_previewMyGitDiff'
function _previewMyGitDiff() {
    local target_dir=$(echo ${MY_TARGET_GIT_DIR[@]} | tr ' ' '\n' | fzf --preview 'git -C {} diff --color=always')
    if [ -z "$target_dir" ]; then 
        return
    fi
    git -C $target_dir add -p && git -C $target_dir commit
}
# 対象のDBでカラム名を検索
alias findColumn='sh ~/findColumn.sh'
alias getTable='cat ~/result.txt | tgrep "SELECT * FROM " " WHERE"'
# 全テーブル検索
alias findValue='_findValue'
function _findValue() {
    # 現在使用している端末のtty
    local currentTerminal=`tty`
    # 使用していないが開いている端末のtty
    local anotherTerminal=`w -h | grep -v "console" | awk '{t="/dev/tty"$2} END {if(t != "'"$currentTerminal"'")print t}'`
    # 画面分割していない場合終了
    if [ -z "$anotherTerminal" ]; then
        anotherTerminal=$currentTerminal
    fi
    echo $currentTerminal
    echo $anotherTerminal
    # grepで抽出した結果をファイルとして保存する
    local RESULT_FILE_PATH=~/result.txt
    sh ~/findValue.sh $1 | tee > $anotherTerminal >(grep --color=never -B 2 -A 2 '|' > $currentTerminal) >(grep --color=never -B 2 -A 2 '|' > $RESULT_FILE_PATH)
    getTable
}
# 全台実行
alias allExecute='sh ~/allDbExecute.sh'
# Docコメントの"*"を削除してダブルクォートで囲む
alias deled='(echo -n \" ; pbpaste | sed "s/*//g" ; echo -n \")'
# bcコマンドを簡単にかつ小数点時に.3333となるのを0.3333に直す(0を付け足す)
alias bcc='_bcc'
function _bcc() {
    echo "scale=2;$1" | bc | sed 's/^\./0\./g'
}
# ブラウザからコピーした時など、プレーンテキストに戻したい時に使用
alias pcopy='pbpaste | pbcopy'
# スプレッドシートから表をコピーしてRedmineのテーブル形式に整形したい時に使用(先頭と末尾に|を挿入,タブを|に置換)
alias rtable='pbpaste | tr "\t" "|" | sed -e "s/^/|/g" -e "s/$/|/g" -e "/|\"/s/|$//g" -e "/\"|/s/^|//g" | tr -d \" | pbcopy'

# agの結果をfzfで絞り込み選択するとvimで開く
alias agg="_agAndVim"
function _agAndVim() {
    if [ -z "$1" ]; then
        echo 'Usage: agg PATTERN'
        return 0
    fi
    local result=`ag $1 | fzf`
    local line=`echo "$result" | awk -F ':' '{print $2}'`
    local file=`echo "$result" | awk -F ':' '{print $1}'`
    if [ -n "$file" ]; then
        vim $file +$line
    fi
}

# 囲まれた文字のみを抽出
function tgrep() {
    # 正規表現の特殊文字をエスケープ
    local escape='
        s/*/\\\*/g;
        s/+/\\\+/g;
        s/\./\\\./g;
        s/?/\\\?/g;
        s/{/\\\{/g;
        s/}/\\\}/g;
        s/(/\\\(/g;
        s/)/\\\)/g;
        s/\[/\\\[/g;
        s/\]/\\\]/g;
        s/\^/\\\^/g;
        s/|/\\\|/g;
        '
    local firstWord=`echo "$1" | sed "$escape"`
    local lastWord=`echo "$2" | sed "$escape"`
    grep -oP "(?<=$firstWord).*(?=$lastWord)"
}

# ファイルパス:行番号のようなものをvimで開く
function viml() {
    local file_path=`pbpaste | awk -F ':' '{print $1}'`
    local line_num=`pbpaste | awk -F ':' '{print $2}'`
    vim $file_path +$line_num
}

# modifiedのファイルを全てタブで開く
alias vims='vim -p `git diff --name-only`'
# fzfの出力をしてからvimで開く
alias vimf='vim -p `fzf`'
# Unite tabでコピーしたものをタブで開く
alias vimt="vim -p `pbpaste | sed 's/(\/)//g' | awk -F ':' '{print $2}' | grep -v '\[' | tr '\n' ' '`"

# 合計値を出す。列が一つのときのみ有効
alias tsum='awk "{sum += \$1}END{print sum}"'

# vagrantのコマンドをfzfで選択
function vgg() {
local select_command=`cat << EOF | fzf
vagrant ssh
vagrant up
vagrant provision
vagrant reload
vagrant halt
vagrant reload&provision
vagrant global-status
EOF`
    test -z "$select_command" && return
    local arg=`echo $select_command | sed "s/vagrant //g"`
    case "${arg}" in
        'ssh' )
            fqdn=`echo "default\norigin\nclone" | fzf`
            test -z "$fqdn" && return
            vagrant ssh $fqdn;;
        'up' ) vagrant up ;;
        'provision' ) vagrant provision ;;
        'reload' ) vagrant reload ;;
        'halt' ) 
            fqdns=(`echo "default\norigin\nclone" | fzf`)
            if [ ${#fqdns[@]} -eq 0 ]; then 
                return 0 
            fi
            for fqdn in ${fqdns[@]}; do 
                vagrant halt $fqdn
            done
            ;;
        'global-status' ) vagrant global-status ;;
        'reload&provision' )
            vagrant reload
            vagrant provision
            ;;
        *) echo "${arg} Didn't match anything"
    esac
}

# 最終更新日が一番新しいもののファイル名を取得
alias fin='echo `ls -t | head -n 1`'
# less `fin`と打つのが面倒だったため関数化。finはコマンドとして残しておきたいので残す
alias late='less $(echo `ls -t | head -n 1`)'
alias execBatch='sh ~/execBatch.sh'
alias cl='sh ~/clipboard.sh'
alias ch='sh ~/chromeHistory.sh'
# 現在のブランチの番号のみを取得してコピーする
alias gget="git rev-parse --abbrev-ref HEAD | grep -oP '[0-9]*' | tr -d '\n' | pbcopy;pbpaste"

# _terminalCtrlPをterminalCtrlPとしてwidget登録
# zshのbindkeyはwidgetを登録するものなので必要な作業
zle -N terminalCtrlP _terminalCtrlP
function _terminalCtrlP() {
    local target_file=`fzf`
    if [ -n "$target_file" ]; then
        # @see https://qiita.com/suhirotaka/items/27cb38f88b0dc5f7c4f3
        echo $target_file | xargs -o vim
    fi
}
# キーバインドに設定
bindkey '^@' terminalCtrlP

# terminal上からGoogle検索
alias goo='searchByGoogle'
function searchByGoogle() {
    # 第一引数がない場合はpbpasteの中身を検索単語とする
    [ -z "$1" ] && searchWord=`pbpaste` || searchWord=$1
    open https://www.google.co.jp/search\?q\=$searchWord
}

# 空行を削除
alias demp='sed "/^$/d"'
# 一時ファイル作成エイリアス
alias p1='pbpaste > ~/p1'
alias p2='pbpaste > ~/p2'
alias p1e='vim ~/p1'
alias p2e='vim ~/p2'
alias pd='vimdiff ~/p1 ~/p2'
alias pst='pstree | less -S'
alias pullReqCaption='sh ~/pullReqCaption.sh'
alias xcode-restore='update_xcode_plugins --restore'
alias xcode-unsign='update_xcode_plugins --unsign'
alias copyMinVimrc='cat ~/dotfiles/min_vimrc | grep -v "\"" | pbcopy'
alias copyMinBashrc='cat ~/dotfiles/min_bashrc | grep -v "#" | pbcopy'
alias gol='gol -f'
alias oo='open .'
alias showColors='~/getColorPrintf.sh'
alias hosts='sudo vim /etc/hosts'
alias dekita='afplay ~/Music/iTunes/iTunes\ Media/Music/Unknown\ Artist/Unknown\ Album/dekita.mp3'
alias chen='afplay ~/Music/iTunes/iTunes\ Media/Music/Unknown\ Artist/Unknown\ Album/jacky_chen.mp3'
alias mailque='postqueue -p'
alias maildel='sudo postsuper -d ALL deferred'
alias maillog='_showMailLog'
function _showMailLog() {
    log stream --predicate '(process == "smtpd") || (process == "smtp")' --info
}
alias kali='_loginVMKaliAsRoot'
function _loginVMKaliAsRoot() {
    local kaliDir=~/Desktop/vm-kali-linux
    if [ -e $kaliDir ];then
        sh ~/Desktop/vm-kali-linux/shell/login.sh
    else 
        echo "Not exsit vm-kali-linux directory"
    fi
}

# wifiをON/OFFする
function wifiConnect() {
    networksetup -setairportpower en0 off
    networksetup -setairportpower en0 on
}

# 記事メモコマンド
alias art='_writeArticle'
function _writeArticle() {
    local ARTICLE_DIR=/Users/`whoami`/Desktop/ru-she-1nian-mu/articles
    local article=`ls $ARTICLE_DIR/*.md | xargs basename | fzf`

    # 何も選択しなかった場合は終了
    if [ -z "$article" ]; then
        return 0
    fi

    if [ "$article" = "00000000.md" ]; then
        echo "タイトルを入力してくだい"
        read title
        today=`date '+%Y_%m_%d_'`
        vim ${ARTICLE_DIR}/${today}${title}.md
    else
        vim ${ARTICLE_DIR}/${article}
    fi
}
# 投稿した記事を別ディレクトリに移動
alias mpa='_movePostedArticles'
function _movePostedArticles() {
    # 投稿完了を意味する目印
    local POSTED_MARK='完'
    # 下書き記事の保存場所
    local ARTICLE_DIR=/Users/`whoami`/Desktop/ru-she-1nian-mu/articles

    # 投稿が完了した記事を保存するディレクトリ
    local POSTED_DIR=$ARTICLE_DIR/posted

    for file in `ls $ARTICLE_DIR`; do
        tail -n 1 ${ARTICLE_DIR}/${file} | grep $POSTED_MARK > /dev/null
        # 投稿が完了したファイルを別ディレクトリに移す
        if [ $? -eq 0 ]; then 
            if [ "$1" = '-l' ]; then 
                echo ${file}
            else 
                mv ${ARTICLE_DIR}/${file} $POSTED_DIR/
                printf "\e[33m${file} is moved!\e[m\n"
            fi
        fi
    done
}

# masterのコミットを全て削除する(自分のPublicリポジトリにpushする際使用)
function deleteAllGitLog() {
    local PC_ENV=`cat ~/account.json | jq -r '.pc_env["'$USER'"]'` 
    # プライベートPCでのみ実行する
    if [ "$PC_ENV" != 'private' ]; then
        echo 'This computer is not private'
        return 0
    fi
    git checkout --orphan tmp
    git commit -m "first commit"
    git checkout -B master
    git branch -d tmp
}

# コマンド実行配下にパスワードなど漏れると危険な単語が入力されていないかをチェック
function checkDangerInput() {
    for danger_word in `cat ~/danger_words.txt`; do
    echo $danger_word
        ag --ignore-dir=vendor $danger_word ./*
    done
}

# Redmine記法からmarkdown形式へ変換
alias rtm='redmineToMarkdown'
function redmineToMarkdown() {
    sed "s/^# /1. /g" | \
    sed "s/h2./##/g"  | \
    sed "s/h3./###/g" | \
    sed "s/<pre>/\`\`\`zsh/g" | \
    sed "s/<\/pre>/\`\`\`/g" 
}

# markdown記法からRedmine形式へ変換
alias mtr='markdownToRedmine'
function markdownToRedmine() {
    local converted=$(pbpaste | \
    sed "s/^[0-9]\. /# /g" | \
    sed "s/###/h3./g" | \
    sed "s/##/h2./g"  | \
    sed "s/\`\`\`.*/<pre>/g"
    )
    # 偶数番目の<pre>を</pre>に変換
    local pre_line_numbers=(`echo "$converted" | grep -nP "^<pre>$" | sed 's/:.*//g'`)
    local cnt=0
    for pre_line_number in ${pre_line_numbers[@]};do 
        if [ `expr $cnt % 2` -ne 0 ]; then 
            converted=`echo "$converted" | sed "$pre_line_number s/<pre>/<\/pre>/g"`
        fi
        cnt=`expr $cnt + 1`
    done
    echo "$converted"
}

alias fun='_showFunction'
function _showFunction() {
    cmd=`alias | fzf` 
    if [ -z "$cmd" ]; then 
        return
    fi
    if $(echo $cmd | grep "'" > /dev/null) ; then
        echo $cmd
    else 
        functions `echo $cmd | awk -F '=' '{print $2}'`
    fi
}

# ランダムな文字列を生成。第一引数に桁数を指定。デフォルトは10。
alias randomStr='_generateRandomString'
function _generateRandomString() {
    local length=${1:-10}
    cat /dev/urandom | base64 | fold -w $length | head -n 1
}

# ランダムな数値文字列を生成。第一引数に桁数を指定。デフォルトは4。
# 乱数ではなく数値文字列であることに注意。 ex.) "0134"
alias randomStrNum='_generateRandomNumberStr'
function _generateRandomNumberStr() {
    local length=${1:-4}
    od -vAn -to1 </dev/urandom  | tr -d " " | fold -w $length | head -n 1
}

# 指定範囲内のランダムな整数を生成。第一引数に範囲を指定。デフォルトは100。
alias randomNum='_generateRandomNumber'
function _generateRandomNumber() {
    local range=${1:-100}
    awk 'BEGIN{srand();print int(rand() * '"${range}"')}'
}

alias itt='sh ~/iterm.sh'
alias bb='sh ~/bitbucket.sh'

# 文字画像を生成。第一引数に生成したい文字を指定。
function create_bg_img() {
    local sizes=(75x75 100x100 320x240 360x480 500x500 600x390 640x480 720x480 1000x1000 1024x768 1280x960)
    local size=$(echo ${sizes} | tr ' ' '\n' | fzf)
    local backgroundColor="#000000"
    local fillColor="#ff8ad8" # 文字色
    # フォントによっては日本語対応しておらず「?」になってしまうので注意
    local fontPath=/System/Library/Fonts/ヒラギノ明朝\ ProN.ttc 
    local default_caption='(･∀･)'
    local caption=${1:-$default_caption}
    local imgPath=~/output.png
    convert \
      -size $size  \
      -background $backgroundColor\
      -fill $fillColor \
      -font $fontPath \
      caption:$caption \
      $imgPath
}

# zshrc.localを読み込む(行末に書くことで設定を上書きする)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# iTerm2バッジ設定関数
# GUIでバッジを設定する(常時表示させたい)時に使用。\(user.badge)。
iterm2_print_user_vars() {
  iterm2_set_user_var badge $(my_badge)
}
# バッジで表示する文字列を返す関数
function my_badge() {
    :
}

# 第一引数の文字列をバッジにする
alias ba='_showBadge'
function _showBadge() {
    printf "\e]1337;SetBadgeFormat=%s\a"\
    $(echo -n "$1" | base64)
}

function set_iterm_property() {
    printf "\e]1337;SetMark\x7"
}

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# gmailを既読を付けずにタイトルだけ表示
function gmail() {
    local USER_ID=`cat ~/account.json | jq -r '.gmail.user_id'` 
    local PASS=`cat ~/account.json | jq -r '.gmail.pass'` 
    curl -u ${USER_ID}:${PASS} --silent "https://mail.google.com/mail/feed/atom" | tr -d '\n' | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\2 - \1/p"
}

alias cdf='cd $(osascript ~/finder.sh)'
# 定義済み関数をfzfで中身を見ながら出力する
function func() {
    local func=$(
       typeset -f \
       | grep ".*() {$" \
       | grep "^[a-z_]" \
       | tr -d "() {"   \
       | fzf --preview "source ~/.zshrc; typeset -f {}"
   )
    if [ -z "$func" ]; then
        return
    fi
    typeset -f $func
}

# YYYY/mm/dd(曜日)形式で本日を出力
alias today="date '+%Y/%m/%d(%a)'" 

# awkの省略形
# command | wk 2 のような形で指定した列を出力する
function wk() {
    local column=${1:-1} 
    awk -v column="${column}" '{print $column}'
}

# Dockerコマンドをfzfで選択
alias dcc='_dockerCommands'
function _dockerCommands() {
    local containers=(
        main-local51
        api-local
        base-local
        nedevtools
        vm-ne-dev-clone
        vm-ne-dev-origin
        vm-ne-dev-origin-db
        vm-ne-dev-clone-db
    )
local select_command=`cat << EOF | fzf
docker exec
docker logs
docker ps
docker-compose ps
docker-compose up
docker stop
docker-compose stop
setDotfiles
EOF`
    local arg=`echo $select_command | sed "s/docker //g"`
    echo $select_command
    case "${arg}" in
        'exec' )
            container=$(echo "${containers[@]}" | tr ' ' '\n' | fzf)
            test -z "$container" && return
            echo "docker exec -it $container bash"
            docker exec -it $container bash
            ;;
        'logs' )
            container=$(echo "${containers[@]}" | tr ' ' '\n' | fzf)
            test -z "$container" && return
            echo "docker logs -ft $container"
            docker logs -ft $container
            ;;
        'ps' )
            eval $select_command
            ;;
        'docker-compose ps' )
            eval $select_command
            ;;
        'docker-compose up' )
            eval $select_command
            ;;
        'stop' )
            eval $select_command
            ;;
        'docker-compose stop' )
            eval $select_command
            ;;
        'setDotfiles' )
            local dotfilesPath=~/docker-dotfiles
            for container in ${containers[@]}; do
                containerId=$(docker ps | grep $container | awk '{print $1}')
                echo "send to ${container}(${containerId})"
                docker cp ${dotfilesPath}/$(ls ${dotfilesPath} | grep $container) ${containerId}:/root/.bashrc
                docker cp ${dotfilesPath}/vimrc ${containerId}:/root/.vimrc
            done
            ;;
        *) ;;
    esac
}

# 自作スクリプト編集時、fzfで選択できるようにする
alias scc='_editMyScript'
function _editMyScript() {
    local targetFile=$(ls ~/*.sh | xargs basename | fzf --height=100% --preview 'cd ~; bat --color always {}')
    if [ -n "$targetFile" ];then 
        vim ~/$targetFile
    fi
}
# クリップボードの行数を出力
alias wcc='pbpaste | wc -l | tr -d " "'

# vimをvimrcなし, プラグインなしで起動する
# NONEにvimrcのPATHを入れれば読み込むことができる
alias vimn='vim -u NONE -N'
alias pbp='pbpaste'
alias pbc='pbcopy'
# ディスプレイ明るさを0に。brew install brightnessが必要
alias 00='brightness 0'

if (which zprof > /dev/null 2>&1) ;then
  zprof
fi

# tmuxコマンド集
alias tt='_tmux_commands'
function _tmux_commands() {
    local commands=(
        'rename-window'
        'man'
        'list-keys'
        'list-commands'
        'kill-server'
        'tmux'
    )
    local command=$(
        echo "${commands[@]}" | tr ' ' '\n' \
            | fzf --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
    )
    test -z "$command" && return

    case "${command}" in
        'rename-window')
            /bin/echo  -n 'INPUT NAME>'
            read  name
            tmux rename-window $name
            ;;
        'man')
            man tmux
            ;;
        'tmux')
            tmux
            ;;
        'list-keys' | 'list-commands')
            tmux $command | less -S
            ;;
        *)
            tmux $command
    esac
}
# グローバルIPを確認
alias myip='curl ifconfig.io'
