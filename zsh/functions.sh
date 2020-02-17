# ============================== #
#            Function            #
# ============================== #

# 囲まれた文字のみを抽出
tgrep() {
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
sell() {
    local select_command=`cat <<- EOF | fzf
		selenium-status
		selenium-log
		selenium-up
		selenium-stop
	EOF`
    eval $select_command
}

# herokuへデプロイするのを楽に。第一引数にcommitメッセージを付与できる。指定しない場合は"更新"と入る
ghero() {
    if [ "$1" = "" ]; then
        1="更新"
    fi
    git add -A
    git commit -m $1
    git push heroku master
}

# masterブランチを最新にする
update_master() {
    git checkout master
    git fetch --all
    git pull --rebase origin master
}

# お天気情報を出力する
tenki() {
    case "$1" in
        "-c") curl -4 http://wttr.in/$2 ;;
          "") finger Kanagawa@graph.no ;;
           *) finger $1@graph.no ;;
    esac
}

# vagrantのコマンドをfzfで選択
vgg() {
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
check_danger_input() {
    for danger_word in `cat ~/danger_words.txt`; do
    echo $danger_word
        ag --ignore-dir=vendor $danger_word ./*
    done
}

# 文字画像を生成。第一引数に生成したい文字を指定。
create_bg_img() {
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
gmail() {
    local USER_ID=`cat ~/account.json | jq -r '.gmail.user_id'` 
    local PASS=`cat ~/account.json | jq -r '.gmail.pass'` 
    curl -u ${USER_ID}:${PASS} --silent "https://mail.google.com/mail/feed/atom" \
        | tr -d '\n' \
        | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' \
        | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\2 - \1/p"
}

# 定義済み関数をfzfで中身を見ながら出力する
func() {
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
wk() {
    local column=${1:-1} 
    awk -v column="${column}" '{print $column}'
}

# cddの履歴クリーン。存在しないPATHを履歴から削除
clean_cdr_cache_history() {
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

viw() {
  vim "$(which "$1")"
}

# 現在開いているfinderのディレクトリに移動
cdf() {
    cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

# builtin-commandsのmanを参照
manzsh() {
    man zshbuiltins | less -p "^       $1 "
}

manbash() {
    man bash | less -p "^       $1 "
}

# ログインShellを切り替える
shell() {
    local target=$(cat /etc/shells | grep '^/' | fzf)
    [ -z "$target" ] && return
    chsh -s $target
}

# インストール一覧コマンド集
list() {
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
phpp() {
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

