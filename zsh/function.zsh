# ==============================#
#            Function           #
# ==============================#

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

# fzf版cdd
_fzf-cdr() {
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

# ag & view
_jump(){
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
_look() {
    if [ "$1" = "-a" ]; then
        local find_result=$(find . -type f -o -type l)
    else
        local find_result=$(find . -maxdepth 1 -type f -o -type l)
    fi
    local target_files=($(echo "$find_result" \
        | sed 's/\.\///g' \
        | grep -v -e '.jpg' -e '.gif' -e '.png' -e '.jpeg' \
        | sort -r \
        | fzf --prompt 'vim ' --preview 'bat --color always {}'
    ))
    [ "$target_files" = "" ] && return
    vim -p ${target_files[@]}
}

# remoteに設定されているURLを開く
_git_remote_open() {
    local remote=$(git remote show | fzf)
    local url=$(git remote get-url $remote)
    if [ "$url" = '' ]; then; return; fi
    if ! echo $url | grep 'http' >/dev/null; then
        url=$(echo $url | sed 's/git@bitbucket.org:/https:\/\/bitbucket\.org\//g')
    fi
    open $url
}

# 現在のブランチをoriginにpushする
_git_push_fzf() {
    local remote=`git remote | fzf`
    git push ${remote} $(git branch | grep "*" | sed -e "s/^\*\s*//g")
}

# git logをpreviewで差分を表示する
# -S "pattern"でpatternを含む差分のみを表示することができる
_git_log_preview_open() {
    local hashCommit=$(git log --oneline "$@" \
        | fzf \
            --prompt 'SELECT COMMIT>' \
            --delimiter=' ' --with-nth 1.. \
            --preview 'git show --color=always {1}' \
            --bind 'ctrl-y:execute-silent(echo -n {1} | pbcopy)' \
            --preview-window=right:50% \
            --height=100% \
        | awk '{print $1}'
    )
    [ -z "$hashCommit" ] && return
    git show $hashCommit
}

# fzfを使ってプロセスKILL
_process_kill(){
    local process=(`ps aux | awk '{print $2,$9,$11,$12}' | fzf | awk '{print $1}'`)
    echo $process | pbcopy
    for item in ${process[@]}
    do
        kill $process
    done
}

# git add をfzfでdiffを見ながら選択
_git_add(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    local option='--modified --exclude-standard'
    local previewCmd='git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy'
    # Untracked fileのものだけ表示
    if [ "$1" = '-u' ]; then
        option='--others --exclude-standard'
        previewCmd='bat --color always {}'
    fi
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
    local files=($(eval git -C $path_working_tree_root ls-files $option \
        | fzf --prompt "ADD FILES>" --preview "$previewCmd"))
    [ -z "$files" ] && return
    for file in "${files[@]}";do
        git add ${path_working_tree_root}${file}
    done
}

# git add -pをfzfでdiffを見ながら選択
_git_add-p(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
    local files=($(git -C $path_working_tree_root ls-files --modified \
        | fzf --prompt "ADD FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy"))
    [ -z "$files" ] && return
    for file in "${files[@]}";do
        git add -p ${path_working_tree_root}${file}
    done
}

# git diff をfzfで選択
_git_diff(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
    local files=($(git -C $path_working_tree_root ls-files --modified \
        | fzf --prompt "SELECT FILES>" --preview 'git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy'))
    [ -z "$files" ] && return
    for file in "${files[@]}";do
        git diff -b ${path_working_tree_root}${file}
    done
}

# git checkout fileをfzfで選択
_git_checkout(){
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
    local files=($(git -C $path_working_tree_root ls-files --modified \
        | fzf --prompt "CHECKOUT FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy"))
    [ -z "$files" ] && return
    for file in "${files[@]}";do
        git checkout ${path_working_tree_root}${file}
    done
}

# git resetをfzfでdiffを見ながら選択
_git_reset() {
    local path_working_tree_root=$(git rev-parse --show-cdup)
    [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
    local files=($(git -C $path_working_tree_root diff --name-only --cached \
        | fzf --prompt "RESET FILES>" --preview "git diff --cached --color=always $(git rev-parse --show-cdup){} | diff-so-fancy"))
    [ -z "$files" ] && return
    for file in "${files[@]}";do
        git reset ${path_working_tree_root}${file}
    done
}

# fgをfzfで
_fgg() {
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
_noti() {
    local msg=$1
    if [ -z "$msg" ]; then
        msg='コマンド完了'
    fi
    terminal-notifier -message "$msg"
}
# あらかじめ指定したGitディレクトリを全て最新にする
_update_dotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printf "\e[33m`basename ${targetDir}`\e[m\n"
        git -C ${targetDir} pull origin master
        echo ""
    done
}
# あらかじめ指定したGitディレクトリを全てpushする
_push_dotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printf "\e[33m`basename ${targetDir}`\e[m\n"
        git -C ${targetDir} add -A
        git -C ${targetDir} commit -v
        git -C ${targetDir} push origin master
        echo ""
    done
}
# あらかじめ指定したGitディレクトリのgit statusを表示
_show_git_status_dotfile() {
    for targetDir in ${MY_TARGET_GIT_DIR[@]}; do 
        printf "\e[33m`basename ${targetDir}`\e[m\n"
        git -C ${targetDir} status
        echo ""
    done
}
# 選択したディレクトリのgit diffを表示
_preview_my_git_diff() {
    local target_dir=$(echo ${MY_TARGET_GIT_DIR[@]} | tr ' ' '\n' | fzf --preview 'git -C {} diff --color=always')
    if [ -z "$target_dir" ]; then 
        return
    fi
    git -C $target_dir add -p && git -C $target_dir commit
}
# 全テーブル検索
_findValue() {
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
_bcc() {
    echo "scale=2;$1" | bc | sed 's/^\./0\./g'
}
# agの結果をfzfで絞り込み選択するとvimで開く
_ag_and_vim() {
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
viml() {
    local file_path=`pbpaste | awk -F ':' '{print $1}'`
    local line_num=`pbpaste | awk -F ':' '{print $2}'`
    vim $file_path +$line_num
}

# terminal上からGoogle検索
_search_by_google() {
    # 第一引数がない場合はpbpasteの中身を検索単語とする
    [ -z "$1" ] && searchWord=`pbpaste` || searchWord=$1
    open https://www.google.co.jp/search\?q\=$searchWord
}

_show_mail_log() {
    log stream --predicate '(process == "smtpd") || (process == "smtp")' --info
}

# 記事メモコマンド
_write_article() {
    local ARTICLE_DIR=/Users/`whoami`/Desktop/develop_tools/articles
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
_move_posted_articles() {
    # 投稿完了を意味する目印
    local POSTED_MARK='完'
    # 下書き記事の保存場所
    local ARTICLE_DIR=/Users/`whoami`/Desktop/develop_tools/articles

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
_redmine_to_markdown() {
    sed "s/^# /1. /g" | \
    sed "s/h2./##/g"  | \
    sed "s/h3./###/g" | \
    sed "s/<pre>/\`\`\`zsh/g" | \
    sed "s/<\/pre>/\`\`\`/g" 
}

# markdown記法からRedmine形式へ変換
_markdown_to_redmine() {
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
_show_function() {
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
_generate_random_string() {
    local length=${1:-10}
    cat /dev/urandom | base64 | fold -w $length | head -n 1
}

# ランダムな数値文字列を生成。第一引数に桁数を指定。デフォルトは4。
# 乱数ではなく数値文字列であることに注意。 ex.) "0134"
_generate_random_number_str() {
    local length=${1:-4}
    od -vAn -to1 </dev/urandom  | tr -d " " | fold -w $length | head -n 1
}

# 指定範囲内のランダムな整数を生成。第一引数に範囲を指定。デフォルトは100。
_generate_random_number() {
    local range=${1:-100}
    awk 'BEGIN{srand();print int(rand() * '"${range}"')}'
}

# 第一引数の文字列をバッジにする。tmux未対応。
_set_badge() {
    printf "\e]1337;SetBadgeFormat=%s\a"\
    $(echo -n "$1" | base64)
}


# Dockerコマンドをfzfで選択
_docker_commands() {
    local select_command=`cat <<- EOF | fzf
		docker exec
		docker logs
		docker ps
		docker ps -a
		docker stop
		docker system df
		docker images -a
		docker-compose ps
		docker-compose up
		docker-compose up --build
		docker-compose up -d
		docker-compose up --build -d
		docker-compose up --force-recreate
		docker-compose stop
		docker rm
		docker rmi
		docker cp
	EOF`
    local arg=`echo $select_command | sed "s/docker //g"`
    case "${arg}" in
        'exec' )
            container=$(docker ps --format "{{.Names}}" | sort | fzf)
            test -z "$container" && return
            execCommand="docker exec -it $container bash"
            echo $execCommand && eval $execCommand
            ;;
        'logs' )
            container=$(docker ps --format "{{.Names}}" | sort | fzf)
            test -z "$container" && return
            execCommand="docker logs -ft $container"
            echo $execCommand && eval $execCommand
            ;;
        'stop' )
            containers=($(docker ps --format "{{.Names}}" | sort | fzf ))
            [ "${#containers[@]}" -eq 0 ] && return
            for container in ${containers[@]}; do
                docker stop $container
            done
            ;;
        'rm' )
            containers=($(docker ps -a --format "{{.Names}}\t{{.ID}}\t{{.RunningFor}}\t{{.Status}}" \
                | column -t -s "`printf '\t'`" \
                | fzf --header "$(echo 'NAME\tCONTAINER_ID\tCREATED\tSTATUS' | column -t)" \
                | awk '{print $2}' \
            ))
            for container in ${containers[@]}; do
                docker rm $container
            done
            ;;
        'rmi' )
            images=($(docker images \
                | fzf \
                | awk '{print $3}' \
            ))
            for image in ${images[@]}; do
                docker rmi -f $image
            done
            ;;
        'cp' )
            local targetFiles=($(find . -maxdepth 1 \
                | sed '/^\.$/d' \
                | fzf \
                    --prompt='送信したいファイルを選択してください' \
                    --preview='file {} | awk -F ":" "{print \$2}" | grep directory >/dev/null && tree --charset=C -NC {} || bat --color always {}'
            ))
            [ "${#targetFiles[@]}" -eq 0 ] && return
            docker ps --format "{{.Names}}" | fzf | while read container;do
                containerId=$(docker ps -aq --filter "name=$container")
                test -z "$containerId" && echo "Not found $container's Container ID." && continue

                for targetFile in "${targetFiles[@]}";do
                    echo "$targetFile =====> ${container}(${containerId})"
                    docker cp ${targetFile} ${containerId}:/root/
                done
            done
            ;;
        *) echo $select_command && eval $select_command ;;
    esac
}

# 自作スクリプト編集時、fzfで選択できるようにする
_edit_my_script() {
    local targetFiles=$(find ~/scripts -follow -maxdepth 1 -name "*.sh";ls -1 ~/.zshrc.local ~/.xvimrc)
    local selected=$(echo "$targetFiles" | fzf --preview '{bat --color always {}}')
    [ -z "$selected" ] && return
    vim $selected
}

# 自作スクリプトをfzfで選んで実行
_source_my_script() {
    local targetFiles=$(find ~/scripts -follow -maxdepth 1 -name "*.sh")
    local selected=$(echo "$targetFiles" | fzf --preview '{bat --color always {}}')
    [ -z "$selected" ] && return
    sh $selected
}

# tmuxコマンド集
_tmux_commands() {
    local command=$(cat <<-EOF | fzf --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
		rename-window
		man
		list-keys
		list-commands
		kill-window
		kill-session
		kill-server
		tmux
		EOF
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
            local sessionIds=($(tmux ls | fzf | awk -F ':' '{print $1}'))
            test -z "$sessionIds" && return
            for sessionId in ${sessionIds[@]}; do
                tmux kill-session -t $sessionId
            done
            ;;
        *)
            tmux $command
    esac
}

# 起動中のアプリを表示、選択して起動する
_open_launched_app() {
    local app=$(ps aux | awk -F '/' '{print "/"$2"/"$3}' | grep Applications | sort -u | sed 's/\/Applications\///g' | fzf ) 
    test -z "$app" && return
    open "/Applications/$app"
}

# git危険コマンド集
_danger_git_commands() {
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
_delete_all_histories_by_file() {
    local targetFile=$(find . -type f -not -path "./.git/*" -not -path "./Carthage/*" -not -path "./*vendor/*" | fzf)
    test -z "$targetFile" && return
    git filter-branch -f --tree-filter "rm -f $targetFile" HEAD
    git gc --aggressive --prune=now
}

# masterのコミットを全て削除する(自分のPublicリポジトリにpushする際使用)
_delete_all_git_log() {
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
_change_author() {
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
_change_config_local() {
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
_edit_vim_files() {
    local nvimFiles=$(find ~/dotfiles $XDG_CONFIG_HOME/nvim/myautoload -follow -name "*.vim")
    local deinToml=~/dotfiles/vim/dein.toml
    local xvimrc=~/dotfiles/vim/.xvimrc
    # 文字数でソートする
    local editFile=$(echo "$nvimFiles\n$deinToml\n$xvimrc" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | fzf)
    test -z "$editFile" && return
    vim $editFile
}

# zshrc関連ファイルをfzfで選択しvimで開く
_edit_zsh_files() {
    local zshFiles=$(find ~/dotfiles/zsh -type f)
    # 文字数でソートする
    local editFiles=($(echo "$zshFiles" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | fzf --preview "bat --color always {}"))
    test -z "$editFiles" && return
    vim -p "${editFiles[@]}"
}

# git stashでよく使うコマンド集
_git_stash_commands() {
    local actions=(
        'stash:_git_stash'
        'pop:_git_stash_pop'
        'stash一覧表示(list):_git_stash_list'
        'stash適用(apply):_fzf_git_stash_apply'
        'stashを名前を付けて保存(save):_git_stash_with_name'
        'stashを削除(drop):_fzf_git_stash_drop'
    )
    local action=$(echo "${actions[@]}" | tr ' ' '\n' | awk -F ':' '{print $1}' | fzf)
    test -z "$action" && return
    eval $(echo "${actions[@]}" | tr ' ' '\n' | grep $action | awk -F ':' '{print $2}')
}

_git_stash_list() {
    local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':' )
    [ -z "$stashNo" ] && return 130
    git stash show --color=always -p $stashNo
}

_git_stash() {
    git stash
}

_git_stash_pop() {
    git stash pop
}

_git_stash_with_name() {
    echo "保存名を入力してくだい"
    read name
    test -z "${name}" && return
    git stash save "${name}"
}

_fzf_git_stash_apply() {
    local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':' )
    test -z "${stashNo}" && return
    git stash apply "${stashNo}"
}

_fzf_git_stash_drop() {
    local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':' )
    test -z "${stashNo}" && return
    git stash drop "${stashNo}"
}

_clipboard_diff() {
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
_toggle_desktop_icon_display() {
    local isDisplay=$(defaults read com.apple.finder CreateDesktop)
    if [ $isDisplay -eq 1 ]; then
        defaults write com.apple.finder CreateDesktop -boolean false && killall Finder
    else
        defaults write com.apple.finder CreateDesktop -boolean true && killall Finder
    fi
}

# 囲まれた文字のみを抽出
_grep_surround_word() {
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
_fzf_selenium() {
    local action=`cat <<- EOF | fzf
		status
		log
		up
		stop
	EOF`
    [ -z "$action" ] && return
    case $action in
        'status' )
            ps aux | grep -v grep | grep -c selenium
            ;;
        'log' )
            local LOG_DIR=~/.selenium-log
            local latest_selenium_log=$(echo $(ls -t $LOG_DIR | head -n 1))
            tail -f $LOG_DIR/$latest_selenium_log
            ;;
        'up' )
            local LOG_DIR=~/.selenium-log
            if [ ! -e $LOG_DIR ]; then 
                mkdir $LOG_DIR
            fi
            local is_run=`ps aux | grep -v grep | grep -c selenium`
            local today=`date +%Y-%m-%d`
            if [ $is_run -eq 0 ]; then
                java -jar /Library/java/Extensions/selenium-server-standalone-3.4.0.jar > $LOG_DIR/$today.log 2>&1 &
            fi
            ;;
        'stop' )
            ps aux | grep selenium | grep -v grep | awk '{print \$2}' | xargs kill -9
            ;;
    esac
    eval $select_command
}

# masterブランチを最新にする
_update_master() {
    git checkout master
    git fetch --all
    git pull --rebase origin master
}

# お天気情報を出力する
_tenki() {
    case "$1" in
        "-c") curl -4 http://wttr.in/$2 ;;
          "") finger Kanagawa@graph.no ;;
           *) finger $1@graph.no ;;
    esac
}

# vagrantのコマンドをfzfで選択
_fzf_vagrant() {
    local select_command=`cat <<- EOF | fzf
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
            vagrant ssh 
            ;;
        'up' ) 
            vagrant up
            ;;
        'provision' )
            vagrant provisio
            ;;
        'reload' )
            vagrant reload
            ;;
        'halt' )
            vagrant halt
            ;;
        'global-status' )
            vagrant global-status
            ;;
        'reload&provision' )
            vagrant reload
            vagrant provision
            ;;
        *) echo "${arg} Didn't match anything"
    esac
}

# コマンド実行配下にパスワードなど漏れると危険な単語が入力されていないかをチェック
_check_danger_input() {
    for danger_word in `cat ~/danger_words.txt`; do
    echo $danger_word
        ag --ignore-dir=vendor $danger_word ./*
    done
}

# 文字画像を生成。第一引数に生成したい文字を指定。
_create_bg_img() {
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
_gmail() {
    local USER_ID=`cat ~/account.json | jq -r '.gmail.user_id'` 
    local PASS=`cat ~/account.json | jq -r '.gmail.pass'` 
    curl -u ${USER_ID}:${PASS} --silent "https://mail.google.com/mail/feed/atom" \
        | tr -d '\n' \
        | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' \
        | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\2 - \1/p"
}

# 定義済み関数をfzfで中身を見ながら出力する
_show_functions() {
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

# cddの履歴クリーン。存在しないPATHを履歴から削除
_clear_cdr_cache() {
    # while文はforkされて別プロセスで実行されるため、while文中の変数が使えない
    # そのため別関数として切り出す
    local getDeleteNumbers() {
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

_open_path_by_vim() {
  vim "$(which -p "$1")"
}

# fzfの出力をしてからvimで開く
_fzf_vim() {
    local excludeDirs=(
        node_modules
        .git
    )
    local excludeCmd
    for excludeDir in ${excludeDirs[@]}; do
        excludeCmd="$excludeCmd -type d -name "$excludeDir" -prune -o "
    done
    local files=($(eval find . $excludeCmd -type f -o -type l | fzf --preview "bat --color always {}"))
    [ -z "$files" ] && return
    vim -p "${files[@]}"
}

# 現在開いているfinderのディレクトリに移動
_cd_opend_finder() {
    cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

# builtin-commandsのmanを参照
_man_builtin_command_zsh() {
    man zshbuiltins | less -p "^       $1 "
}

_man_builtin_command_bash() {
    man bash | less -p "^       $1 "
}

# ログインShellを切り替える
_switch_login_shell() {
    local target=$(cat /etc/shells | grep '^/' | fzf)
    [ -z "$target" ] && return
    chsh -s $target
}

# インストール一覧コマンド集
_show_installed_list() {
    local targets=`cat <<-EOS | fzf
	brew
	cask
	mas
	npm
	yarn
	gem
	pip
	pip3
	EOS`
    [ -z "$targets" ] && return
    echo "$targets" | while read target; do
        local cmd=''
        case $target in
            'cask')
                cmd='brew cask list'
                ;;
            'npm')
                cmd='npm ls -g'
                ;;
            *) cmd="$target list"
        esac
        printf "\n\e[33m\$ $cmd\e[m\n"
        eval $cmd
    done
}

# phpbrewによるphpバージョン切り替え
_fzf_phpbrew() {
    local currentVersion=$(php -v)
    local selected=$(phpbrew list \
        | grep php \
        | tr -d ' ' \
        | tr -d '*' \
        | currentVersion=$(php -v) fzf --preview="echo '$(php -v)'" --preview-window=down:50%
    )
    [ -z "$selected" ] && return
    phpbrew use $selected
    echo '$ php -v' && php -v
}

# npmコマンドをfzfで実行
_fzf_npm() {
    if [ -f package.json ]; then 
        local action=$(cat package.json | jq -r '.scripts | keys | .[]' \
            | fzf --preview "cat package.json | jq -r '.scripts[\"{}\"]'" --preview-window=up:1)
        [ -z "$action" ] && return
        npm run $action
    else
        echo 'Not Found package.json'
    fi
}
