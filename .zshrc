alias vim='nvim'
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

# crontab -eでもvimを開くようにする
export EDITOR=vim
# GNU系のコマンドをg付けずに実行するため
# export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
# ggrepをgrepにするため
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/python@2/bin:$PATH"
# fzfのリストを上から並べ、全画面ではなくvimのquickfixライクにする
export FZF_DEFAULT_OPTS='--color=fg+:11 --height 70% --reverse --select-1 --exit-0 --multi --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'
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

# ================================================== #
#
# ============================== #
#            Function            #
# ============================== #
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

# herokuへデプロイするのを楽に。第一引数にcommitメッセージを付与できる。指定しない場合は"更新"と入る
function ghero() {
    if [ "$1" = "" ]; then
        1="更新"
    fi
    git add -A
    git commit -m $1
    git push heroku master
}

# masterブランチを最新にする
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

# コマンド実行配下にパスワードなど漏れると危険な単語が入力されていないかをチェック
function check_danger_input() {
    for danger_word in `cat ~/danger_words.txt`; do
    echo $danger_word
        ag --ignore-dir=vendor $danger_word ./*
    done
}

# 文字画像を生成。第一引数に生成したい文字を指定。
function create_bg_img() {
    local sizeList=(75x75 100x100 320x240 360x480 500x500 600x390 640x480 720x480 1000x1000 1024x768 1280x960)
    local sizes=($(echo ${sizeList} | tr ' ' '\n' | fzf))
    local backgroundColor="#000000"
    local fillColor="#ff8ad8" # 文字色
    # フォントによっては日本語対応しておらず「?」になってしまうので注意
    local fontPath=/System/Library/Fonts/ヒラギノ明朝\ ProN.ttc 
    local default_caption='(･∀･)'
    local caption=${1:-$default_caption}
    for size in ${sizes[@]}; do
        local imgPath=~/Desktop/${size}.png
        echo $imgPath
        convert \
          -size $size  \
          -background $backgroundColor\
          -fill $fillColor \
          -font $fontPath \
          caption:$caption \
          $imgPath
    done
}

# gmailを既読を付けずにタイトルだけ表示
function gmail() {
    local USER_ID=`cat ~/account.json | jq -r '.gmail.user_id'` 
    local PASS=`cat ~/account.json | jq -r '.gmail.pass'` 
    curl -u ${USER_ID}:${PASS} --silent "https://mail.google.com/mail/feed/atom" \
        | tr -d '\n' \
        | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' \
        | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\2 - \1/p"
}

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

# awkの省略形。command | wk 2 のような形で指定した列を出力する
function wk() {
    local column=${1:-1} 
    awk -v column="${column}" '{print $column}'
}

# cddの履歴クリーン。存在しないPATHを履歴から削除
function clean_cdr_cache_history() {
    # while文はforkされて別プロセスで実行されるため、while文中の変数が使えない
    # そのため別関数として切り出す
    local function getDeleteNumbers() {
        local delete_line_number=1
        local delete_line_numbers=()
        while read line; do
            ls $line >/dev/null 2>&1 
            if [ $? -eq 1 ]; then
                # 削除する際、上から順に削除すると行番号がずれるので逆順で配列に入れる
                delete_line_numbers=($delete_line_number "${delete_line_numbers[@]}" )
            fi
            delete_line_number=$(expr $delete_line_number + 1)
        done
        echo "${delete_line_numbers[@]}"
    }

    local history_cache=~/.cache/cdr/history
    local delete_line_numbers=($(cat $history_cache | tr -d "$" | tr -d "'" | getDeleteNumbers))
    for delete_line_number in "${delete_line_numbers[@]}"
    do
        printf "\e[31;1m$(sed -n ${delete_line_number}p $history_cache)\n"
        sed -i '' -e "${delete_line_number}d" $history_cache
    done
}

# ================================================== #
#
# ============================== #
#         Function-alias         #
# ============================== #
# fzf版cdd
function _fzf-cdr() {
    local target_dir=$(cdr -l  \
        | sed 's/^[^ ][^ ]*  *//' \
        | fzf --bind 'ctrl-t:execute-silent(echo {} | sed "s/~/\/Users\/$(whoami)/g" | xargs -I{} tmux split-window -h -c {})+abort' \
              --preview "echo {} | sed 's/~/\/Users\/$(whoami)/g' | xargs -I{} ls -l {} | head -n100" \
        )
    # ~だと移動できないため、/Users/hogeの形にする
    target_dir=$(echo ${target_dir/\~/$HOME})
    if [ -n "$target_dir" ]; then
        cd $target_dir
    fi
}
# 英語のmanを表示する
#alias man='env LANG=C man'
function _run_selenium_server() {
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
function _tail_latest_selenium_log() {
    local LOG_DIR=~/.selenium-log
    local latest_selenium_log=`echo $(ls -t $LOG_DIR | head -n 1)`
    tail -f $LOG_DIR/$latest_selenium_log
}

# ag & view
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
function _look() {
    if [ "$1" = "-a" ]; then
        local find_result=$(find . -type f -o -type l)
    else
        local find_result=$(find . -maxdepth 1 -type f -o -type l)
    fi
    local target_file=$(echo "$find_result" \
        | sed 's/\.\///g' \
        | grep -v -e '.jpg' -e '.gif' -e '.png' -e '.jpeg' \
        | sort -r \
        | fzf --prompt 'vim ' --preview 'bat --color always {}'
    )
    [ "$target_file" = "" ] && return
    vim $target_file
}
# remoteに設定されているURLを開く
function _git_remote_open() {
    local remote=$(git remote show | fzf)
    local url=$(git remote get-url $remote)
    if [ "$url" = '' ]; then; return; fi
    if ! echo $url | grep 'http' >/dev/null; then
        url=$(echo $url | sed 's/git@bitbucket.org:/https:\/\/bitbucket\.org\//g')
    fi
    open $url
}
# 現在のブランチをoriginにpushする
function _git_push_fzf() {
    local remote=`git remote | fzf`
    git push ${remote} $(git branch | grep "*" | sed -e "s/^\*\s*//g")
}
# git logをpreviewで差分を表示する
function _git_log_preview_open() {
    local option=''
    if [ "$1" = "-S" ];then
        option="-S"
    fi
    local hashCommit=`git log --oneline $option $2| fzf --height=100% --prompt "SELECT COMMIT>" --preview "echo {} | cut -d' ' -f1 | xargs git show --color=always"`
    if [ -n "$hashCommit" ]; then
        git show `echo ${hashCommit} | awk '{print $1}'`
    fi
}
# 差分のあるファイルをfzfでプレビューしながら一覧に表示し、ENTERでlessモード&ファイルパスをクリップボードに
function _git_diff_preview_copy() {
    local target_diff=`git diff $(git diff --name-only | fzf --prompt "CHECKOUT BRANCH>" --preview "git diff --color=always {}")`
    echo $target_diff | grep "\-\-\- a" | sed "s/--- a\///g" | tr -d "\n" | pbcopy
}
# fzfを使ってプロセスKILL
function _process_kill(){
    local process=(`ps aux | awk '{print $2,$9,$11,$12}' | fzf | awk '{print $1}'`)
    echo $process | pbcopy
    for item in ${process[@]}
    do
        kill $process
    done
}

# git add をfzfでdiffを見ながら選択
function _git_add(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=.
    local files=$(git -C $path_working_tree_root ls-files --modified --exclude-standard --others \
        | fzf --prompt "ADD FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy")
    if [ -n "$files" ]; then
        git add $(git rev-parse --show-cdup)${=files}
    fi
}

# git add -pをfzfでdiffを見ながら選択
function _git_add-p(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=.
    local files=$(git -C $path_working_tree_root ls-files --modified \
        | fzf --prompt "ADD FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy")
    if [ -n "$files" ]; then
        git add -p $(git rev-parse --show-cdup)${=files}
    fi
}

# git diff をfzfで選択
function _git_diff(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=.
    local files=$(git -C $path_working_tree_root ls-files --modified \
        | fzf --prompt "SELECT FILES>" --preview 'git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy')
    if [ -n "$files" ]; then
        echo "$files" | tr -d "\n" | pbcopy
        git diff -b $(git rev-parse --show-cdup)$files
    fi
}

# git checkout fileをfzfで選択
function _git_checkout(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=.
    local files=$(git -C $path_working_tree_root ls-files --modified \
        | fzf --prompt "CHECKOUT FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy")
    if [ -n "$files" ]; then
        git checkout $(git rev-parse --show-cdup)${=files}
    fi
}

# git resetをfzfでdiffを見ながら選択
function _git_reset() {
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=.
    local files=$(git -C $path_working_tree_root ls-files --modified \
        | fzf --prompt "RESET FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy")
    if [ -n "$files" ]; then
        git reset $(git rev-parse --show-cdup)${=files}
    fi
}

# fgをfzfで
function _fgg() {
    local wc=$(jobs | grep -c ^)
    if [ $wc -ne 0 ]; then
        local job=$(jobs | awk -F "suspended" "{print $1 $2}"|sed -e "s/\-//g" -e "s/\+//g" -e "s/\[//g" -e "s/\]//g" | grep -v pwd | fzf | awk "{print $1}")
        local wc_grep=$(echo $job | grep -v grep | grep 'suspended')
        if [ "$wc_grep" != "" ]; then
            fg %$job
        fi
    fi
}

# コマンド完了時に通知を受け取る
function _noti() {
    local msg=$1
    if [ -z "$msg" ]; then
        msg='コマンド完了'
    fi
    terminal-notifier -message "$msg"
}
# あらかじめ指定したGitディレクトリを全て最新にする
function _update_dotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printf "\e[33m`basename ${targetDir}`\e[m\n"
        git -C ${targetDir} pull origin master
        echo ""
    done
}
# あらかじめ指定したGitディレクトリを全てpushする
function _push_dotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printf "\e[33m`basename ${targetDir}`\e[m\n"
        git -C ${targetDir} add -A
        git -C ${targetDir} commit -v
        git -C ${targetDir} push origin master
        echo ""
    done
}
# あらかじめ指定したGitディレクトリのgit statusを表示
function _show_git_status_dotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printf "\e[33m`basename ${targetDir}`\e[m\n"
        git -C ${targetDir} status
        echo ""
    done
}
# 選択したディレクトリのgit diffを表示
function _preview_my_git_diff() {
    local target_dir=$(echo ${MY_TARGET_GIT_DIR[@]} | tr ' ' '\n' | fzf --preview 'git -C {} diff --color=always')
    if [ -z "$target_dir" ]; then 
        return
    fi
    git -C $target_dir add -p && git -C $target_dir commit
}
# 全テーブル検索
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
# bcコマンドを簡単にかつ小数点時に.3333となるのを0.3333に直す(0を付け足す)
function _bcc() {
    echo "scale=2;$1" | bc | sed 's/^\./0\./g'
}
# agの結果をfzfで絞り込み選択するとvimで開く
function _ag_and_vim() {
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


# ファイルパス:行番号のようなものをvimで開く
function viml() {
    local file_path=`pbpaste | awk -F ':' '{print $1}'`
    local line_num=`pbpaste | awk -F ':' '{print $2}'`
    vim $file_path +$line_num
}

# terminal上からGoogle検索
function _search_by_google() {
    # 第一引数がない場合はpbpasteの中身を検索単語とする
    [ -z "$1" ] && searchWord=`pbpaste` || searchWord=$1
    open https://www.google.co.jp/search\?q\=$searchWord
}

function _show_mail_log() {
    log stream --predicate '(process == "smtpd") || (process == "smtp")' --info
}

# 記事メモコマンド
function _write_article() {
    local ARTICLE_DIR=/Users/`whoami`/Desktop/ru-she-1nian-mu/articles
    local article=`ls ${ARTICLE_DIR}/*.md | xargs basename | fzf`

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
function _move_posted_articles() {
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
            git mv ${ARTICLE_DIR}/${file} $POSTED_DIR/
            printf "\e[33m${file} is moved!\e[m\n"
        fi
    done
}

# Redmine記法からmarkdown形式へ変換
function _redmine_to_markdown() {
    sed "s/^# /1. /g" | \
    sed "s/h2./##/g"  | \
    sed "s/h3./###/g" | \
    sed "s/<pre>/\`\`\`zsh/g" | \
    sed "s/<\/pre>/\`\`\`/g" 
}

# markdown記法からRedmine形式へ変換
function _markdown_to_redmine() {
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

# 定義済みの関数を表示
function _show_function() {
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
function _generate_random_string() {
    local length=${1:-10}
    cat /dev/urandom | base64 | fold -w $length | head -n 1
}

# ランダムな数値文字列を生成。第一引数に桁数を指定。デフォルトは4。
# 乱数ではなく数値文字列であることに注意。 ex.) "0134"
function _generate_random_number_str() {
    local length=${1:-4}
    od -vAn -to1 </dev/urandom  | tr -d " " | fold -w $length | head -n 1
}

# 指定範囲内のランダムな整数を生成。第一引数に範囲を指定。デフォルトは100。
function _generate_random_number() {
    local range=${1:-100}
    awk 'BEGIN{srand();print int(rand() * '"${range}"')}'
}

# 第一引数の文字列をバッジにする。tmux未対応。
function _set_badge() {
    printf "\e]1337;SetBadgeFormat=%s\a"\
    $(echo -n "$1" | base64)
}


# Dockerコマンドをfzfで選択
function _docker_commands() {
    local select_command=`cat << EOF | fzf
docker exec
docker logs
docker ps
docker ps -a
docker stop
docker system df
docker images -a
docker-compose ps
docker-compose up
docker-compose up -d
docker-compose up --force-recreate
docker-compose stop
docker rm
docker rmi
setDotfiles
EOF`
    local arg=`echo $select_command | sed "s/docker //g"`
    echo $select_command
    case "${arg}" in
        'exec' )
            container=$(docker ps --format "{{.Names}}" | fzf)
            test -z "$container" && return
            echo "docker exec -it $container bash"
            docker exec -it $container bash
            ;;
        'logs' )
            container=$(docker ps --format "{{.Names}}" | fzf)
            test -z "$container" && return
            echo "docker logs -ft $container"
            docker logs -ft $container
            ;;
        'stop' )
            docker ps --format "{{.Names}}" | fzf | xargs docker stop
            ;;
        'rm' )
            docker ps -a --format "{{.Names}}\t{{.ID}}\t{{.RunningFor}}\t{{.Status}}" \
                | column -t -s "`printf '\t'`" \
                | fzf --header "$(echo 'NAME\tCONTAINER_ID\tCREATED\tSTATUS' | column -t)" \
                | awk '{print $2}' \
                | xargs docker rm
            ;;
        'rmi' )
            docker images \
                | fzf \
                | awk '{print $3}' \
                | xargs docker rmi
            ;;
        'setDotfiles' )
            local dotfilesPath=~/docker-dotfiles
            docker ps --format "{{.Names}}" | while read container
            do
                containerId=$(docker ps | grep $container | awk '{print $1}')
                echo "send to ${container}(${containerId})"
                docker cp ${dotfilesPath}/$(ls ${dotfilesPath} | grep $container) ${containerId}:/root/.bashrc
                docker cp ${dotfilesPath}/vimrc ${containerId}:/root/.vimrc
            done
            ;;
        *) eval $select_command ;;
    esac
}

# 自作スクリプト編集時、fzfで選択できるようにする
function _edit_my_script() {
    local targetFiles=$(find ~/scripts -follow -maxdepth 1 -name "*.sh";ls -1 ~/.zshrc.local ~/.xvimrc)
    local selected=$(echo "$targetFiles" | fzf --preview '{bat --color always {}}')
    [ -z "$selected" ] && return
    vim $selected
}

# 自作スクリプトをfzfで選んで実行
function _source_my_script() {
    local targetFiles=$(find ~/scripts -follow -maxdepth 1 -name "*.sh")
    local selected=$(echo "$targetFiles" | fzf --preview '{bat --color always {}}')
    [ -z "$selected" ] && return
    sh $selected
}

# tmuxコマンド集
function _tmux_commands() {
    local commands=(
        'rename-window'
        'man'
        'list-keys'
        'list-commands'
        'kill-window'
        'kill-session'
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
        'kill-session')
            local session_no=$(tmux ls | fzf | awk -F ':' '{print $1}')
            test -z "$session_no" && return
            tmux kill-session -t $session_no
            ;;
        *)
            tmux $command
    esac
}

# 起動中のアプリを表示、選択して起動する
function _open_launched_app() {
    local app=$(ps aux | awk -F '/' '{print "/"$2"/"$3}' | grep Applications | sort -u | sed 's/\/Applications\///g' | fzf ) 
    test -z "$app" && return
    open "/Applications/$app"
}

# git危険コマンド集
function _danger_git_commands() {
    local actions=(
        '特定ファイルと関連する履歴を全て削除:_delete_all_histories_by_file'
        'masterのコミットを全て削除:_delete_all_git_log'
        'コミットのAuthorを全て書き換える:_change_author'
        'ローカル(特定リポジトリ)のConfigを変更:_change_config_local'
    )
    local action=$(echo "${actions[@]}" | tr ' ' '\n' | awk -F ':' '{print $1}' | fzf)
    test -z "$action" && return
    eval $(echo "${actions[@]}" | tr ' ' '\n' | grep $action | awk -F ':' '{print $2}')

}

# 特定ファイルの履歴を全て削除(ファイルも削除されるので注意)
function _delete_all_histories_by_file() {
    local targetFile=$(find . -type f -not -path "./.git/*" -not -path "./Carthage/*" -not -path "./*vendor/*" | fzf)
    test -z "$targetFile" && return
    git filter-branch -f --tree-filter "rm -f $targetFile" HEAD
    git gc --aggressive --prune=now
}

# masterのコミットを全て削除する(自分のPublicリポジトリにpushする際使用)
function _delete_all_git_log() {
    local PC_ENV=`cat ~/account.json | jq -r '.pc_env["'$USER'"]'` 
    echo $PC_ENV
    # プライベートPCでのみ実行する
    if [ "$PC_ENV" != 'private' ]; then
        echo 'This computer is not private'
        return 0
    fi
    /bin/echo -n '本当に実行して良いですか？(y/N) > '
    read isOK
    case "${isOK}" in
        y|Y|yes)
            git checkout --orphan tmp
            git commit -m "first commit"
            git checkout -B master
            git branch -d tmp
            ;;
        *)
            ;;
    esac
}

# コミットのAuthor、Committerを全て変更
function _change_author() {
    local USER_NAME=`cat ~/account.json | jq -r '.github["user_name"]'` 
    local MAIL_ADDR=`cat ~/account.json | jq -r '.github["mail_addr"]'` 
    test "$USER_NAME" = "null" || test "$MAIL_ADDR" = "null" && return
    echo -n "AUTHOR: $USER_NAME\nEMAIL: $MAIL_ADDR\nに書き換えますがよろしいですか？(y/N) > "
    read isOK
    case "${isOK}" in
        y|Y|yes)
            git filter-branch -f --env-filter \
            "GIT_AUTHOR_NAME='${USER_NAME}'; \
            GIT_AUTHOR_EMAIL='${MAIL_ADDR}'; \
            GIT_COMMITTER_NAME='${USER_NAME}'; \
            GIT_COMMITTER_EMAIL='${MAIL_ADDR}';" \
            HEAD
            ;;
        *)
            ;;
    esac
}

# ローカル(特定リポジトリ)のユーザー名,メールアドレスを変更
function _change_config_local() {
    local USER_NAME=`cat ~/account.json | jq -r '.github["user_name"]'` 
    local MAIL_ADDR=`cat ~/account.json | jq -r '.github["mail_addr"]'` 
    test "$USER_NAME" = "null" || test "$MAIL_ADDR" = "null" && return
    echo -n "AUTHOR: $USER_NAME\nEMAIL: $MAIL_ADDR\nに書き換えますがよろしいですか？(y/N) > "
    read isOK
    case "${isOK}" in
        y|Y|yes)
            git config --local user.name "${USER_NAME}"
            git config --local user.email "${MAIL_ADDR}"
            ;;
        *)
            ;;
    esac
}

# vim関連ファイルをfzfで選択しvimで開く
function _edit_vim_files() {
    local nvimFiles=$(find ~/dotfiles ~/dotfiles/dein_tomls $XDG_CONFIG_HOME/nvim/myautoload -follow -maxdepth 1  -name "*.vim")
    local deinToml=~/dotfiles/dein.toml
    local xvimrc=~/dotfiles/.xvimrc
    # 文字数でソートする
    local editFile=$(echo "$nvimFiles\n$deinToml\n$xvimrc" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | fzf)
    test -z "$editFile" && return
    vim $editFile
}

# git stashでよく使うコマンド集
function _git_stash_commands() {
    local actions=(
        'stash一覧表示(list):_git_stash_list'
        'stash適用(apply):_fzf_git_stash_apply'
        'stashを名前を付けて保存(save):_git_stash_with_name'
        'stashを削除(drop):_fzf_git_stash_drop'
    )
    local action=$(echo "${actions[@]}" | tr ' ' '\n' | awk -F ':' '{print $1}' | fzf)
    test -z "$action" && return
    eval $(echo "${actions[@]}" | tr ' ' '\n' | grep $action | awk -F ':' '{print $2}')
}

function _git_stash_list() {
    local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':' )
    [ -z "$stashNo" ] && return 130
    git stash show --color=always -p $stashNo
}

function _git_stash_with_name() {
    echo "保存名を入力してくだい"
    read name
    test -z "${name}" && return
    git stash save "${name}"
}

function _fzf_git_stash_apply() {
    local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':' )
    test -z "${stashNo}" && return
    git stash apply "${stashNo}"
}

function _fzf_git_stash_drop() {
    local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':' )
    test -z "${stashNo}" && return
    git stash drop "${stashNo}"
}

function _clipboard_diff() {
    local PATH_CLIP_LOG_DIR=~/.cliplog
    local clipLogs=($(ls -t $PATH_CLIP_LOG_DIR | fzf --prompt "CHOOSE" --preview "cat $PATH_CLIP_LOG_DIR/{}" --preview-window=right:80%))
    [ ${#clipLogs[@]} -ne 2 ] && return
    local selectFiles=''
    for clipLog in ${clipLogs[@]}; do
        selectFiles="${selectFiles} ${PATH_CLIP_LOG_DIR}/${clipLog}"
    done
    echo "$selectFiles"
    [ -z "$selectFiles" ] && return
    vimdiff $(echo "$selectFiles")
}

# デスクトップ上アイコンの表示/非表示を切り替える
function _toggle_desktop_icon_display() {
    local isDisplay=$(defaults read com.apple.finder CreateDesktop)
    if [ $isDisplay -eq 1 ]; then
        defaults write com.apple.finder CreateDesktop -boolean false && killall Finder
    else
        defaults write com.apple.finder CreateDesktop -boolean true && killall Finder
    fi
}

# ================================================== #
#
# ============================== #
#       alias-ShellScript        #
# ============================== #
# phpでprint_rしたものを変数定義できるようにコピー
alias phparr='pbpaste | xargs sh ~/scripts/phparr.sh | pbcopy'
alias rr='sh ~/scripts/redmine.sh'
alias findColumn='sh ~/scripts/findColumn.sh'
alias allExecute='sh ~/scripts/allDbExecute.sh'
alias execBatch='sh ~/scripts/execBatch.sh'
alias cl='sh ~/scripts/clipboard.sh'
alias ch='sh ~/scripts/chromeHistory.sh'
alias pullReqCaption='sh ~/scripts/pullReqCaption.sh'
alias showColors='~/getColorPrintf.sh'
alias itt='sh ~/scripts/iterm.sh'
alias bb='sh ~/scripts/bitbucket.sh'
alias cdf='cd $(osascript ~/scripts/finder.sh)'
# ディスプレイ明るさを0に
alias 00='osascript ~/scripts/up_or_down_brightness.sh 1'
alias 11='osascript ~/scripts/up_or_down_brightness.sh 0'
alias gg='sh ~/scripts/githubAPI.sh'
alias cw='sh ~/scripts/chatwork.sh'
alias ctt='sh ~/scripts/chromeSelectTab.sh'
alias sqq='sh ~/scripts/fzf_sequel_pro.sh'

# ================================================== #
#
# ============================== #
#         alias-Command          #
# ============================== #
alias l='ls -ltrG'
alias la='ls -laG'
alias laa='ls -ld .*'
alias ll='ls -lG'
alias ls='ls -G'
alias grep='grep --color=auto'
alias ...='cd ../../'
alias his='history -E -i 1 | fzf'
alias history='history 1'
alias time='/usr/bin/time -p'
alias ssh='TERM=xterm ssh'
# treeコマンドで日本語表示
alias tree="tree --charset=C -NC"
alias zshrc='vim ~/.zshrc'
alias szsh='source ~/.zshrc'
alias stmux='tmux source-file ~/.tmux.conf'
alias tconf='vim ~/.tmux.conf'
alias plantuml='java -jar ~/.plantuml/plantuml.jar'
alias selenium-stop="ps aux | grep selenium | grep -v grep | awk '{print \$2}' | xargs kill -9"
alias selenium-status='ps aux | grep -v grep | grep -c selenium'
alias grepr='grep -r'
alias phpS='php -S localhost:9000'
alias phps='hyper-run -s localhost:9000 -t .'
alias cot='open $1 -a /Applications/CotEditor.app'
alias js='osascript -l JavaScript'
# terminalの描画がおかしいときにそれも直してclearする
alias clear='stty sane;clear'
alias gd='git diff -b'
alias gdc='git diff -b --cached'
# 現在のブランチをpullする
alias -g gpl='git pull --rebase origin $(git branch | grep "*" | sed -e "s/^\*\s*//g")'
alias chromium='/Applications/Chromium.app/Contents/MacOS/Chromium --headless --disable-gpu'
alias repoo='vim `ls ~/Desktop/ru-she-1nian-mu/DayReport/*.md | fzf`'
alias memo='vim ~/Desktop/ru-she-1nian-mu/memo.md -c ":$"'
# git checkout branchをfzfで選択
alias co='git checkout $(git branch -a | tr -d " " |fzf --height=100% --prompt "CHECKOUT BRANCH>" --preview "git log --color=always {}" | head -n 1 | sed -e "s/^\*\s*//g" | perl -pe "s/remotes\/origin\///g")'
alias co-='git checkout -'
alias gst='git status'
alias gv='git remote -v'
# 全てのファイルをgit checkout
alias gca='git checkout $(git diff --name-only)'
# ctagsをbrew installしたものを使う
alias ctags="`brew --prefix`/bin/ctags"
# コマンドでgoogle翻訳
alias trans='trans -b en:ja'
alias transj='trans -b ja:en'
# 対象のDBでカラム名を検索
alias getTable='cat ~/result.txt | tgrep "SELECT * FROM " " WHERE"'
# Docコメントの"*"を削除してダブルクォートで囲む
alias deled='(echo -n \" ; pbpaste | sed "s/*//g" ; echo -n \")'
# ブラウザからコピーした時など、プレーンテキストに戻したい時に使用
alias pcopy='pbpaste | pbcopy'
# スプレッドシートから表をコピーしてRedmineのテーブル形式に整形したい時に使用(先頭と末尾に|を挿入,タブを|に置換)
alias rtable='pbpaste | tr "\t" "|" | sed -e "s/^/|/g" -e "s/$/|/g" -e "/|\"/s/|$//g" -e "/\"|/s/^|//g" | tr -d \" | pbcopy'
# modifiedのファイルを全てタブで開く
alias vims='vim -p `git diff --name-only`'
# fzfの出力をしてからvimで開く
alias vimf='vim -p `fzf`'
# Unite tabでコピーしたものをタブで開く
alias vimt="vim -p `pbpaste | sed 's/(\/)//g' | awk -F ':' '{print $2}' | grep -v '\[' | tr '\n' ' '`"
# 合計値を出す。列が一つのときのみ有効
alias tsum='awk "{sum += \$1}END{print sum}"'
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
alias gol='gol -f'
alias oo='open .'
alias hosts='sudo vim /etc/hosts'
alias dekita='afplay ~/Music/iTunes/iTunes\ Media/Music/Unknown\ Artist/Unknown\ Album/dekita.mp3'
alias chen='afplay ~/Music/iTunes/iTunes\ Media/Music/Unknown\ Artist/Unknown\ Album/jacky_chen.mp3'
alias mailque='postqueue -p'
alias maildel='sudo postsuper -d ALL deferred'
# YYYY/mm/dd(曜日)形式で本日を出力
alias today="date '+%Y/%m/%d(%a)'" 
# クリップボードの行数を出力
alias wcc='pbpaste | grep -c ^'
# vimをvimrcなし, プラグインなしで起動する
# NONEにvimrcのPATHを入れれば読み込むことができる
alias vimn='vim -u NONE -N'
alias pbp='pbpaste'
alias pbc='pbcopy'
# グローバルIPを確認
alias myip='curl ifconfig.io'
alias xcode-restore='update_xcode_plugins --restore'
alias xcode-unsign='update_xcode_plugins --unsign'
alias copyMinVimrc='cat ~/dotfiles/min_vimrc | grep -v "\"" | pbcopy'
alias copyMinBashrc='cat ~/dotfiles/min_bashrc | grep -v "#" | pbcopy'
alias selenium-stop="ps aux | grep selenium | grep -v grep | awk '{print \$2}' | xargs kill -9"
alias selenium-status='ps aux | grep -v grep | grep -c selenium'
# wifiをON/OFFする
alias wifiConnect='networksetup -setairportpower en0 off && networksetup -setairportpower en0 on'
# printfの色出力を一覧表示
alias printColors='for fore in `seq 30 37`; do printf "\e[${fore}m \\\e[${fore}m \e[m\n"; for mode in 1 4 5; do printf "\e[${fore};${mode}m \\\e[${fore};${mode}m \e[m"; for back in `seq 40 47`; do printf "\e[${fore};${back};${mode}m \\\e[${fore};${back};${mode}m \e[m"; done; echo; done; echo; done; printf " \\\e[m\n"'
alias sshadd='ssh-add ~/.ssh/id_rsa'
# FortClientはMacの上部バーから終了する際、一々パスワードを求めてくるのでkillが楽
alias fortKill="ps aux | grep 'Fort' | awk '{print \$2}' | xargs kill"
# metabase起動。起動後しばらくしたらhttp://localhost:3300でアクセスできる
alias metabase-run='docker run -d -p 3300:3000 -v /tmp:/tmp -e "MB_DB_FILE=/tmp/metabase.db" --name metabase metabase/metabase'
# Redemineのテンプレート文言をvimで開く
alias redmine_template='vim $(mktemp XXXXXXXXXX) -c ":read! cat ~/redmine_template.txt"'

# ================================================== #
#
# ============================== #
#         alias-Function         #
# ============================== #
alias cdd='_fzf-cdr'
alias selenium-log='_tail_latest_selenium_log'
alias selenium-up='_run_selenium_server'
alias jump='_jump'
alias lk='_look'
alias gro='_git_remote_open'
alias tigg='_git_log_preview_open'
alias tigd='_git_diff_preview_copy'
alias pspk='_process_kill'
alias gcpp='_git_checkout'
alias gadd='_git_add'
alias gapp='_git_add-p'
alias gdd='_git_diff'
alias grpp='_git_reset'
alias po='_git_push_fzf'
alias fgg='_fgg'
alias noti='_noti'
alias upd='_update_dotfile'
alias psd='_push_dotfile'
alias std='_show_git_status_dotfile'
alias stdd='_preview_my_git_diff'
alias findValue='_findValue'
alias bcc='_bcc'
alias goo='_search_by_google'
alias maillog='_show_mail_log'
alias art='_write_article'
alias mpa='_move_posted_articles'
alias rtm='_redmine_to_markdown'
alias mtr='_markdown_to_redmine'
alias fun='_show_function'
alias randomStr='_generate_random_string'
alias randomStrNum='_generate_random_number_str'
alias randomNum='_generate_random_number'
alias ba='_set_badge'
alias dcc='_docker_commands'
alias scc='_edit_my_script'
alias ss='_source_my_script'
alias tt='_tmux_commands'
alias agg="_ag_and_vim"
alias oaa='_open_launched_app'
alias dgg='_danger_git_commands'
alias vimrc='_edit_vim_files'
alias gss='_git_stash_commands'
alias cld='_clipboard_diff'
alias dt='_toggle_desktop_icon_display'

# zshrc.localを読み込む(行末に書くことで設定を上書きする)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
