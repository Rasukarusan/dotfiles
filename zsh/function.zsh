# ==============================#
#           Functions           #
# ==============================#
#
# fgを使わずctrl+zで行ったり来たりする
fancy-ctrl-z () {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fgg"
    zle accept-line
  else
    zle push-input
    zle clear-screen
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# fzf版cdd
alias cdd='_fzf-cdr'
_fzf-cdr() {
  local target_dir=$(cdr -l  \
    | sed 's/^[^ ][^ ]*  *//' \
    | fzf-tmux -p80% --bind 'ctrl-t:execute-silent(echo {} | sed "s/~/\/Users\/$(whoami)/g" | xargs -I{} tmux split-window -h -c {})+abort' \
        --preview "echo {} | sed 's/~/\/Users\/$(whoami)/g' | xargs -I{} ls -l {} | head -n100" \
    )
  # ~だと移動できないため、/Users/hogeの形にする
  target_dir=$(echo ${target_dir/\~/$HOME} | tr -d '\')
  if [ -n "$target_dir" ]; then
    cd $target_dir
  fi
}

# カレントディレクトリ以下をプレビューし選択して開く
alias lk='_look'
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
    | fzf-tmux -p80% --select-1 --prompt 'vim ' --preview 'bat --color always {}' --preview-window=right:70%
  ))
  [ "$target_files" = "" ] && return
  vim -p ${target_files[@]}
}

# remoteに設定されているURLを開く
# PRがある場合はPRを開く
alias gro='_git_remote_open'
_git_remote_open() {
  local url=$(gh pr view --json url | jq -r ".url")
  if [ -z "$url" ]; then
    gh repo view --web
  else
    echo "open $url"
    open $url
  fi
}

# 現在のブランチをoriginにpushする
alias po='_git_push_fzf'
_git_push_fzf() {
  local remote=`git remote | fzf --select-1`
  git push $1 ${remote} $(git branch | grep "*" | sed -e "s/^\*\s*//g")
}
alias pof='_git_push_fzf -f'

# git logをpreviewで差分を表示する
# -S "pattern"でpatternを含む差分のみを表示することができる
alias tigg='_git_log_preview_open'
_git_log_preview_open() {
  local hashCommit=$(git log --oneline "$@" \
    | fzf-tmux -p80% \
      --prompt 'SELECT COMMIT>' \
      --delimiter=' ' --with-nth 1.. \
      --preview 'git show --color=always {1}' \
      --bind 'ctrl-y:execute-silent(echo {} | awk "{print \$1}" | tr -d "\n" | pbcopy)' \
      --preview-window=right:50% \
      --height=100% \
    | awk '{print $1}'
  )
  # echo $hashCommit
  [ -z "$hashCommit" ] && return
  git show ${hashCommit}
}

# fzfを使ってプロセスKILL
alias pspk='_process_kill'
_process_kill(){
  local process=(`ps aux | awk '{print $2,$9,$11,$12}' | fzf-tmux -p80% | awk '{print $1}'`)
  echo $process | pbcopy
  for item in ${process[@]}
  do
    kill $process
  done
}

# git add をfzfでdiffを見ながら選択
alias gadd='_git_add'
_git_add(){
  local path_working_tree_root=$(git rev-parse --show-cdup)
  [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
  local files=($(eval git -C $path_working_tree_root ls-files --modified --others --exclude-standard\
    | fzf-tmux -p80% --prompt 'modified' \
      --bind "U:reload(git ls-files --others --exclude-standard)+change-prompt(untracked)" \
      --bind "M:reload(git ls-files --modified)+change-prompt(modified)" \
      --bind "A:reload(git ls-files --modified --others --exclude-standard)+change-prompt(all)" \
      --preview "git diff --exit-code {} >/dev/null && bat --color always {} || git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy" \
      --preview-window=right:50% \
    ))
  [ -z "$files" ] && return
  for file in "${files[@]}";do
    git add ${path_working_tree_root}${file}
  done
}

# git add -pをfzfでdiffを見ながら選択
alias gapp='_git_add-p'
_git_add-p(){
  local path_working_tree_root=$(git rev-parse --show-cdup)
  [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
  local files=($(git -C $path_working_tree_root ls-files --modified \
    | fzf-tmux -p80% --prompt "ADD FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy" --preview-window=right:50% ))
  [ -z "$files" ] && return
  for file in "${files[@]}";do
    git add -p ${path_working_tree_root}${file}
  done
}

# git diff をfzfで選択
alias gdd='_git_diff'
_git_diff(){
  local path_working_tree_root=$(git rev-parse --show-cdup)
  [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
  local files=($(git -C $path_working_tree_root ls-files --modified \
    | fzf-tmux -p80% --select-1 --prompt "SELECT FILES>" --preview 'git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy' --preview-window=right:50% ))
  [ -z "$files" ] && return
  for file in "${files[@]}";do
    git diff -b ${path_working_tree_root}${file}
  done
}

# git checkout fileをfzfで選択
alias gcpp='_git_checkout'
_git_checkout(){
  local path_working_tree_root=$(git rev-parse --show-cdup)
  [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
  local files=($(git -C $path_working_tree_root ls-files --modified \
    | fzf-tmux -p80% --prompt "CHECKOUT FILES>" --preview "git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy" --preview-window=right:50%))
  [ -z "$files" ] && return
  for file in "${files[@]}";do
    git checkout ${path_working_tree_root}${file}
  done
}

# git resetをfzfでdiffを見ながら選択
alias grpp='_git_reset'
_git_reset() {
  local path_working_tree_root=$(git rev-parse --show-cdup)
  [ "$path_working_tree_root" = '' ] && path_working_tree_root=./
  local files=($(git -C $path_working_tree_root diff --name-only --cached \
    | fzf-tmux -p80% --prompt "RESET FILES>" --preview "git diff --cached --color=always $(git rev-parse --show-cdup){} | diff-so-fancy" --preview-window=right:50% ))
  [ -z "$files" ] && return
  for file in "${files[@]}";do
    git reset ${path_working_tree_root}${file}
  done
}

# fgをfzfで
alias fgg='_fgg'
_fgg() {
  local job=$(jobs \
    | grep  '^\[' \
    | fzf --select-1\
    |grep -oP '(?<=\[)[1-9]*(?=\])'
  )
  [ -n "$job" ] && fg %${job}
}

# 記事に関するコマンド集
alias art='_article_commands'
_article_commands() {
  local actions=(
    '記事を書く:_write_article'
    'articlesに移動:_cd_articles'
    'pushする:_push_article'
    'pullする:_pull_article'
  )
  local action=$(echo "${actions[@]}" | tr ' ' '\n' | fzf -d ':' --with-nth=1 | cut -d ':' -f 2,2)
  [ -n "$action" ] && eval "$action"
}

# 記事を書く
_write_article() {
  local ARTICLE_DIR=/Users/`whoami`/Documents/github/articles
  if [ "$1" = '-a' ];then
    local targetFile=$(find $ARTICLE_DIR -name "*.md" | fzf-tmux -p80% --delimiter 'articles' --with-nth  -1 --preview "bat --color=always {}")
    [ -z "$targetFile" ] && return
    vim $targetFile
    return
  fi
  local article=`ls ${ARTICLE_DIR}/*.md | xargs -I {} basename {} | fzf-tmux -p80% --preview "bat --color=always ${ARTICLE_DIR}/{}"`

  # 何も選択しなかった場合は終了
  if [ -z "$article" ]; then
    return 0
  fi

  if [ "$article" = "00000000.md" ]; then
    local tmpfile=$(mktemp)
    vim $tmpfile
    local title="$(cat $tmpfile | tr -d '\n')"
    rm $tmpfile

    local today=`date '+%Y_%m_%d_'`
    vim ${ARTICLE_DIR}/${today}${title}.md -c "call setline(1, '# ${title}')"
  else
    vim ${ARTICLE_DIR}/${article}
  fi
}

# 記事ディレクトリに移動
_cd_articles() {
  cd $HOME/Documents/github/articles
}

# 投稿した記事を別ディレクトリに移動
_move_posted_articles() {
  # 投稿完了を意味する目印
  local POSTED_MARK='完'
  # 下書き記事の保存場所
  local ARTICLE_DIR=/Users/`whoami`/Documents/github/articles
  # 投稿が完了した記事を保存するディレクトリ
  local POSTED_DIR=$ARTICLE_DIR/posted

  # 投稿が完了したファイルを別ディレクトリに移す
  ls $ARTICLE_DIR | while read file; do
    if tail -n 1 "${ARTICLE_DIR}/${file}" | grep $POSTED_MARK > /dev/null; then
      # git管理されていない場合失敗するので通常のmvを実行する
      git mv "${ARTICLE_DIR}/${file}" "$POSTED_DIR/" || mv "${ARTICLE_DIR}/${file}" "$POSTED_DIR/"
      printf "\e[33m${file} is moved!\e[m\n"
    fi
  done
}

# 記事投稿に関するコミットをまとめてする
_push_article() {
  _move_posted_articles
  local targets=(
    $HOME/Documents/github/keynote-template
    $HOME/Documents/github/articles
  )
  for target in ${targets[@]}; do
    printf "\e[33m${target}\e[m\n"
    git -C $target add -A
    git -C $target commit --no-verify -m "posted"
    git -C $target pull --rebase origin master
    git -C $target push origin master
  done
}

# 記事投稿に関するリポジトリを更新する
_pull_article() {
  local targets=(
    $HOME/Documents/github/keynote-template
    $HOME/Documents/github/articles
  )
  for target in ${targets[@]}; do
    printf "\e[33m${target}\e[m\n"
    git -C $target pull --rebase origin master
  done
}

# マインドマップを書く
alias map='_write_mindmap'
_write_mindmap() {
  local dir=/Users/`whoami`/Documents/github/mindmap-view/data
  local mindmap=`(echo 00000000.md && ls ${dir}/*.md | xargs -I {} basename {}) | fzf-tmux -p80% --preview "bat --color=always ${dir}/{}"`
  test -z "$mindmap" && return

  if [ "$mindmap" = "00000000.md" ]; then
    local tmpfile=$(mktemp)
    vim $tmpfile
    local title="$(cat $tmpfile | tr -d '\n')"
    rm $tmpfile
    test -z "$title" && return

    local today=`date '+%Y_%m_%d_'`
    local target=${dir}/${today}${title}.md
    echo "# ${title}" > $target
    vim ${dir}/${today}${title}.md -c "MarkMap"
  else
    vim ${dir}/${mindmap} -c "MarkMap"
  fi
}

# 定義済みのaliasを表示
alias com='_show_alias'
_show_alias() {
  local cmd=$(alias | sort | fzf-tmux -p80% )
  [ -z "$cmd" ] && return

  if $(echo $cmd | grep "'" > /dev/null) ; then # コマンドaliasの場合
    local cmdName=$(echo $cmd | grep -oP '.*=')
    local filePath lineNumber
    read filePath lineNumber <<< $(ag "alias $cmdName" ~/dotfiles/zsh | awk -F ':' '{print $1,$2}')
    vim $filePath +$lineNumber
  else # 関数aliasの場合
    local functionName=$(echo $cmd | awk -F '=' '{print $2}')
    [ -z "$functionName" ] && return

    local definePath=~/dotfiles/zsh/function.zsh
    local define=$(ag "${functionName}\(\)" $definePath | awk -F ':' '{print $1}')
    [ -z "$define" ] && return
    vim $definePath +${define}
  fi
}

# ランダムな文字列を生成。第一引数に桁数を指定。デフォルトは10。
alias randomStr='_generate_random_string'
_generate_random_string() {
  local length=${1:-10}
  cat /dev/urandom | base64 | fold -w $length | head -n 1
}

# ランダムな数値文字列を生成。第一引数に桁数を指定。デフォルトは4。
# 乱数ではなく数値文字列であることに注意。 ex.) "0134"
alias randomStrNum='_generate_random_number_str'
_generate_random_number_str() {
  local length=${1:-4}
  od -vAn -to1 </dev/urandom  | tr -d " " | fold -w $length | head -n 1
}

# 指定範囲内のランダムな整数を生成。第一引数に範囲を指定。デフォルトは100。
alias randomNum='_generate_random_number'
_generate_random_number() {
  local range=${1:-100}
  awk 'BEGIN{srand();print int(rand() * '"${range}"')}'
}

# 第一引数の文字列をバッジにする。tmux未対応。
alias ba='_set_badge'
_set_badge() {
  printf "\e]1337;SetBadgeFormat=%s\a"\
  $(echo -n "$1" | base64)
}

# Dockerコマンドをfzfで選択
alias dcc='_docker_commands'
_docker_commands() {
  local selectCommand=`cat <<- EOF | fzf-tmux -p80%
		docker exec -it
		docker exec -it --user root
		docker logs
		docker ps
		docker ps -a
		docker stop
		docker system df
		docker stats
		docker images -a
		docker-compose ps
		docker-compose build --progress=plain
		docker-compose build --progress=plain --no-cache
		docker-compose up
		docker-compose up <service>
		docker-compose up --build
		docker-compose up -d
		docker-compose up --build -d
		docker-compose up --build -d <service>
		docker-compose --compatibility up -d
		docker-compose up --force-recreate
		docker-compose stop
		docker-compose logs -f
		docker rm
		docker rmi
		docker cp
		docker system prune -a
		copy minrc
	EOF`
  local arg=`echo $selectCommand | sed "s/docker //g"`
  local execCommand
  case "${arg}" in
    'exec -it' | 'exec -it --user root' )
      container=$(docker ps --format "{{.Names}}" | sort | fzf-tmux -p80%)
      test -z "$container" && return
      availableShells=$(docker exec -it $container cat /etc/shells)
      # bashが使えるならbashでログインする
      if  echo "$availableShells" | grep bash >/dev/null ; then
        execCommand="$selectCommand $container bash"
      else
        execCommand="$selectCommand $container $(echo "$availableShells" | tail -n 1 | tr -d '\r')"
      fi
      ;;
    'logs' )
      container=$(docker ps --format "{{.Names}}" | sort | fzf-tmux -p80%)
      test -z "$container" && return
      execCommand="docker logs -f --tail=100 $container"
      ;;
    'stop' )
      containers=($(docker ps --format "{{.Names}}" | sort | fzf-tmux -p80% ))
      [ "${#containers[@]}" -eq 0 ] && return
      for container in ${containers[@]}; do
        execCommand="docker stop $container"
        printf "\e[33m${execCommand}\e[m\n" && eval $execCommand
      done
      return
      ;;
    'rm' )
      containers=($(docker ps -a --format "{{.Names}}\t{{.ID}}\t{{.RunningFor}}\t{{.Status}}\t{{.Networks}}" \
        | column -t -s "`printf '\t'`" \
        | fzf-tmux -p80% --header "$(echo 'NAME\tCONTAINER_ID\tCREATED\tSTATUS\tNETWORK' | column -t)" \
        | awk '{print $2}' \
      ))
      for container in ${containers[@]}; do
        execCommand="docker rm $container"
        printf "\e[33m${execCommand}\e[m\n" && eval $execCommand
      done
      return
      ;;
    'rmi' )
      images=($(docker images | tail -n +2 \
        | fzf-tmux -p80% --header "$(echo 'REPOSITORY\tTAG\tIMAGE_ID\tCREATED\tSIZE' | column -t)"\
        | awk '{print $3}' \
      ))
      for image in ${images[@]}; do
        execCommand="docker rmi -f $image"
        printf "\e[33m${execCommand}\e[m\n" && eval $execCommand
      done
      return
      ;;
    'cp' )
      local targetFiles=($(find . -maxdepth 1 \
        | sed '/^\.$/d' \
        | fzf-tmux -p80% \
          --prompt='送信したいファイルを選択してください' \
          --preview='file {} | awk -F ":" "{print \$2}" | grep directory >/dev/null && tree --charset=C -NC {} || bat --color always {}'
      ))
      [ "${#targetFiles[@]}" -eq 0 ] && return
      docker ps --format "{{.Names}}" | fzf-tmux -p80% | while read container;do
        containerId=$(docker ps -aq --filter "name=$container")
        test -z "$containerId" && echo "Not found $container's Container ID." && continue

        for targetFile in "${targetFiles[@]}";do
          echo "$targetFile =====> ${container}(${containerId})"
          execCommand="docker cp ${targetFile} ${containerId}:/root/"
          print -s "$execCommand"
          printf "\e[33m${execCommand}\e[m\n" && eval $execCommand
        done
      done
      return
      ;;
    'copy minrc' ) # dockerコンテナにminrc配置
      targetFile="${HOME}/dotfiles/zsh/minrc"
      containers=($(docker ps --format "{{.Names}}"))
      for container in ${containers[@]};do
        printf "\e[35m${container}\e[m\n"
        shell="ash"

        # bashが使えるか判定
        if docker exec -it $container cat /etc/shells | grep bash >/dev/null ; then
          shell="bash"
        fi

        # コンテナにコピー
        id=$(docker ps -aq --filter "name=$container")
        test -z "$id" && echo "Not found $container's Container ID." && continue

        # コンテナのHOMEディレクトリを取得
        home=$(docker exec -i $container $shell -c "getent passwd | tail -n 1 | cut -d: -f6")

        execCommand="docker cp ${targetFile} ${id}:${home}/.profile"
        printf "\e[33m${execCommand}\e[m\n\n" && eval $execCommand
      done
      ;;
    'docker-compose up <service>' )
      local service=$(cat docker-compose.yml | yq ".services|keys" | grep "-" | sed 's/^- //g' | fzf)
      test -z "$service" && return
      execCommand="docker-compose up $service"
      ;;
    'docker-compose up --build -d <service>' )
      local service=$(cat docker-compose.yml | yq ".services|keys" | grep "-" | sed 's/^- //g' | fzf)
      test -z "$service" && return
      execCommand="docker-compose up --build -d $service"
      ;;
    *)
      execCommand="${selectCommand}"
      ;;
  esac
  if [ -n "$execCommand" ];then
    print -s "$execCommand"
    local strLength=$(expr ${#execCommand} + 4)
    local separateStr=$(for i in `seq 1 $strLength`;do /bin/echo -n '=' ; done)
    printf "\e[33m${separateStr}\n  ${execCommand}  \n${separateStr}\e[m\n"
    eval $execCommand
  fi
}

# tmuxコマンド集
alias tt='_tmux_commands'
_tmux_commands() {
  local command=$(cat <<-EOF | fzf --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
		bg-color
		resize
		rename-window
		man
		list-keys
		list-commands
		kill-window
		kill-session
		kill-server
		capture-window
		tmux
		EOF
  )
  test -z "$command" && return

  case "${command}" in
    'bg-color')
      tmux select-pane -P 'bg=#000'
      ;;
    'resize')
      local actions=('Left' 'Right' 'Up' 'Down')
      echo "${actions[@]}" \
        | tr ' ' '\n' \
        | fzf-tmux -p \
          --prompt 'Press Ctrl-p > ' \
          --bind 'ctrl-p:execute-silent(tmux resize-pane -$(echo {} | cut -c 1-1))'
      ;;
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
      local sessionIds=($(tmux ls | fzf-tmux -p | awk -F ':' '{print $1}'))
      test -z "$sessionIds" && return
      for sessionId in ${sessionIds[@]}; do
        tmux kill-session -t $sessionId
      done
      ;;
    'capture-window')
      tmux capture-pane -pS - > ~/Desktop/tmux.txt
      ;;
    *)
      tmux $command
  esac
}

# 起動中のアプリを表示、選択して起動する
alias oaa='_open_launched_app'
_open_launched_app() {
  local app=$(ps aux | awk -F '/' '{print "/"$2"/"$3}' | grep Applications | sort -u | sed 's/\/Applications\///g' | fzf )
  test -z "$app" && return
  open "/Applications/$app"
}

# git危険コマンド集
alias dgg='_danger_git_commands'
_danger_git_commands() {
  local actions=(
    'n個前のコミットに遡って書き換えるコマンドを表示:_rebase_commit'
    'ブランチ削除:_delete_branch'
    'マージ済みのブランチ削除:_delete_merged_branch'
    'Githubでブランチ間の差分を見る:_branch_diff_on_github'
    '特定ファイルと関連する履歴を全て削除:_delete_all_histories_by_file'
    'masterのコミットを全て削除:_delete_all_git_log'
    'コミットのAuthorを全て書き換える:_change_author'
    'ローカル(特定リポジトリ)のConfigを変更:_change_config_local'
    'git_clean_df:_git_clean_df'
  )
  local action=$(echo "${actions[@]}" | tr ' ' '\n' | fzf -d ':' --with-nth=1 | cut -d ':' -f 2,2)
  [ -n "$action" ] && eval "$action"
}

# 現在のブランチとdevelopの差分をGithub上のURLで表示する
_branch_diff_on_github() {
  local current=$(git branch --show-current)
  local origin=$(git config --get remote.origin.url | sed "s/git@github://g" | sed "s/.git//g")
  local url="https://github.com/${origin}/compare/develop...$current"
  open $url
  printf "\e[33m${url}\e[m\n"
}

# ブランチをfzfで選択して削除
_delete_branch() {
  local targets=($(git branch | grep -E -v 'master|stage|stg|php7.2|renewal|develop$' | fzf --preview 'git show --color=always {1}' --preview-window=right:50%))
  test -z "$targets" && return
  echo "${targets[@]}" | tr ' ' '\n'
  printf "\e[35m上記のブランチを削除して良いですか？(y/N) > \e[m\n"
  read ok
  case "${ok}" in
    y|Y|yes)
      for target in ${targets[@]}; do
        git branch -D $target
      done
      ;;
    *)
      ;;
  esac
}

# 現在のブランチにマージされているブランチを削除する
_delete_merged_branch() {
  git branch --merged | grep -E -v '(master|develop|stage|stg|php7.2|renewal)'
  printf "\e[35m上記のブランチを削除して良いですか？(y/N) > \e[m\n"
  read isOK
  case "${isOK}" in
    y|Y|yes)
      git branch --merged | grep -E -v '(master|develop|stage|stg|php7.2|renewal)' | xargs git branch -d
      ;;
    *)
      ;;
  esac
}

# 複数個前のコミットを書き換えるコマンドの流れを表示する
_rebase_commit() {
  cat <<EOS
# 1. 修正したい変更をstashしておく
`printf "\e[33mgit stash\e[m\n"`
# 2. 遡りたい個数を指定
`printf "\e[33mgit rebase -i HEAD~3\e[m\n"`
# 3. 遡りたいコミットを'edit'にする
# 4. rebaseモードに入ったらstashを戻す
`printf "\e[33mgit stash pop\e[m\n"`
# 5. addしてcommit --amendする
`printf "\e[33mgit add -A\ngit commit --amend\e[m\n"`
# 6. rebaseモードを抜ける
`printf "\e[33mgit rebase --continue\e[m\n"`
EOS
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
  printf "env: \e[37;1m${PC_ENV}\e[m\n"
  # プライベートPCではない場合、確認を取る
  if [ "$PC_ENV" != 'private' ]; then
    printf "\e[31mThis computer is not private.\nDo you continue? (y/n)\e[m"
    read isContinue
    case "${isContinue}" in
      y|Y|yes)
        ;;
      *)
        printf "\e[33mcanceled!\e[m\n"
        return 0
        ;;
    esac
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

_git_clean_df() {
  git clean -df
}

# vim関連ファイルをfzfで選択しvimで開く
alias vimrc='_edit_vim_files'
_edit_vim_files() {
  local nvimFiles=$(find ~/dotfiles ${XDG_CONFIG_HOME}/nvim/myautoload -follow -name "*.vim" -o -name "*.lua")
  local deinToml=~/dotfiles/vim/dein.toml
  local xvimrc=~/dotfiles/vim/xvimrc
  local vimrcLocal=~/.vimrc.local
  # 文字数でソートする
  local editFile=$(echo "${nvimFiles}\n${deinToml}\n${xvimrc}\n${vimrcLocal}" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | fzf-tmux -p80% --preview "bat --color always {}")
  test -z "$editFile" && return
  vim $editFile
}

# zshrc関連ファイルをfzfで選択しvimで開く
alias zshrc='_edit_zsh_files'
_edit_zsh_files() {
  local zshFiles=$(find ~/dotfiles/zsh -type f && echo ~/.zshrc.local)
  # 文字数でソートする
  local editFiles=($(echo "$zshFiles" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | fzf-tmux -p80% --preview "bat --color always {}"))
  test -z "$editFiles" && return
  vim -p "${editFiles[@]}"
}

# git stashでよく使うコマンド集
alias gss='_git_stash_commands'
_git_stash_commands() {
  local actions=(
    'stash:_git_stash'
    'pop:_git_stash_pop'
    'stash一覧表示(list):_git_stash_list'
    'stash適用(apply):_fzf_git_stash_apply'
    'stashを名前を付けて保存(save):_git_stash_with_name'
    'stashをファイル単位で実行(push):_git_stash_each_file'
    'stashを削除(drop):_fzf_git_stash_drop'
  )
  local action=$(echo "${actions[@]}" | tr ' ' '\n' | fzf -d ':' --with-nth=1 | cut -d ':' -f 2,2)
  [ -n "$action" ] && eval "$action"
  print -s "$action"
}

_git_stash_list() {
  local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show -u --color=always -p' | awk '{print $1}' | tr -d ':' )
  [ -z "$stashNo" ] && return 130
  git stash show --color=always -p $stashNo
}

_git_stash() {
  git stash -u
}

_git_stash_pop() {
  git stash pop
}

_git_stash_with_name() {
  echo "保存名を入力してくだい"
  read name
  test -z "${name}" && return
  git stash save -u "${name}"
}

_git_stash_each_file() {
  local targets=($(git ls-files -m -o --exclude-standard | sort | fzf --preview='bat --color=always {}'))
  [ -z "$targets" ] && return
  echo "保存名を入力してくだい"
  read name
  test -z "${name}" && return
  git stash push -u "${targets[@]}" -m "${name}"
}

_fzf_git_stash_apply() {
  local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show -u --color=always -p' | awk '{print $1}' | tr -d ':' )
  test -z "${stashNo}" && return
  git stash apply "${stashNo}"
}

_fzf_git_stash_drop() {
  local stashNos=($(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show -u --color=always -p' | awk '{print $1}' | tr -d ':'  | tac))
  test -z "${stashNos}" && return
  printf "\e[36m======削除するstash一覧=====\e[m\n"
  for stashNo in ${stashNos[@]}; do
    /bin/echo -n "${stashNo} "
    git log --color=always --oneline ${stashNo} | head -n 1
  done
  printf "\e[36m============================\e[m\n"
  printf "\e[36m本当に削除してよろしいですか？(y/n)\e[m"
  read answer
  if [ "$answer" = 'y' ];then
    for stashNo in ${stashNos[@]}; do
      git stash drop "${stashNo}"
    done
  fi
}

# デスクトップ上アイコンの表示/非表示を切り替える
alias dt='_toggle_desktop_icon_display'
_toggle_desktop_icon_display() {
  local isDisplay=$(defaults read com.apple.finder CreateDesktop)
  if [ $isDisplay -eq 1 ]; then
    defaults write com.apple.finder CreateDesktop -boolean false && killall Finder
  else
    defaults write com.apple.finder CreateDesktop -boolean true && killall Finder
  fi
}

# Dockの表示/非表示を切り替える
alias dock='_toggle_dock'
_toggle_dock() {
  osascript <<EOS
  tell application "System Events"
    tell dock preferences to set autohide to not autohide
  end tell
EOS
}

# お天気情報を出力する
alias tenki='_tenki'
_tenki() {
  local place=${1:-kanagawa}
  curl -4 http://wttr.in/${place}
  # finger ${place}@graph.no
}

# コマンド実行配下にパスワードなど漏れると危険な単語が入力されていないかをチェック
alias check_danger_input='_check_danger_input'
_check_danger_input() {
  for danger_word in `cat ~/danger_words.txt`; do
  echo $danger_word
    ag --ignore-dir=vendor $danger_word ./*
  done
}

# 定義済み関数をfzfで中身を見ながら出力する
# alias func='_show_functions'
_show_functions() {
  local func=$(
     typeset -f \
     | grep ".*() {$" \
     | grep "^[a-z_]" \
     | tr -d "() {"   \
     | fzf-tmux -p80% --preview "source ~/.zshrc; typeset -f {}"
   )
  if [ -z "$func" ]; then
    return
  fi
  typeset -f $func
}

# cddの履歴クリーン。存在しないPATHを履歴から削除
alias clear_cdr_cache='_clear_cdr_cache'
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

# fzfの出力をしてからvimで開く
alias vif='_fzf_vim'
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

# git管理下のファイルのみfzfで出力をしてvimで開く
# vi"g"ではなく"p"にしているのは、vimのキーバインド(Ctrl-p)と合わせたかったため
alias vip='_fzf_vim_git'
_fzf_vim_git() {
  local files=($(git ls-files | fzf --preview "bat --color always {}"))
  [ -z "$files" ] && return
  vim -p "${files[@]}"
}

# 現在開いているfinderのディレクトリに移動
alias cdf='_cd_opend_finder'
_cd_opend_finder() {
  cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

# builtin-commandsのmanを参照
alias manzsh='_man_builtin_command_zsh'
_man_builtin_command_zsh() {
  man zshbuiltins | less -p "^       $1 "
}

alias manbash='_man_builtin_command_bash'
_man_builtin_command_bash() {
  man bash | less -p "^       $1 "
}

# pipenvコマンドをfzfで実行
alias pii='_fzf_pipenv'
_fzf_pipenv() {
  if [ -f Pipfile ]; then
    local action=$(cat Pipfile | dasel -r toml -w json | jq -r '.scripts | keys | .[]' \
      | fzf-tmux -p80% --preview "cat Pipfile | dasel -r toml -w json | jq -r '.scripts[\"{}\"]'" --preview-window=up:1)
    [ -z "$action" ] && return
    pipenv run $action
    print -s "pipenv run $action"
  else
    echo 'Not Found Pipfile'
  fi
}

# sedで一括置換
alias rsed='_replace_all'
_replace_all() {

  if [ $# -ne 2 ];then
    echo 'Usage: _replace_all $search $replace'
    return
  fi

  ag -l -0 "$1" | xargs -0 gsed -i -e "s/$1/$2/"
}

# fzfでrm
alias rmm='_rmm'
_rmm() {
  for removeFile in $(find . -maxdepth 1 -type d \( -name node_modules -o -name .git \) -prune -o -type f \
    | sort \
    |  fzf-tmux -p80% \
    --bind "f1:reload(find . -maxdepth 1 -type d \( -name node_modules -o -name .git \) -prune -o -type f | sort)" \
    --bind "f2:reload(find . -maxdepth 2 -type d \( -name node_modules -o -name .git \) -prune -o -type f | sort)" \
    --bind "f3:reload(find . -maxdepth 3 -type d \( -name node_modules -o -name .git \) -prune -o -type f | sort)" \
    --bind "f5:reload(find . -type d \( -name node_modules -o -name .git \) -prune -o -type f | sort)" \
    --preview='bat --color=always {}'
  )
  do
    echo "$removeFile"
    rm "$removeFile"
  done
}

# npmコマンドをfzfで実行
alias npp='_fzf_npm'
_fzf_npm() {
  local packageJson=$(find ./ -maxdepth 1  -name 'package.json')
  if [ -z "$packageJson" ]; then
    local gitRoot=$(git rev-parse --show-cdup)
    packageJson=$(find ${gitRoot}. -maxdepth 2  -name 'package.json')
  fi
  [ -z "$packageJson" ] && return
  local actions=($(cat ${packageJson} | jq -r '.scripts | keys | .[]' \
    | fzf-tmux -p --preview "cat ${packageJson} | jq -r '.scripts[\"{}\"]'" --preview-window=up:1))
  [ -z "$actions" ] && return
  local cmd=''
  for action in "${actions[@]}"; do
    if [ -z "$cmd" ]; then
      cmd="npm $action"
    else
      cmd="$cmd && npm $action"
    fi
  done
  printf "\e[35m$cmd\n\e[m\n"
  print -s "$cmd"
  eval "$cmd"
}

# fzfでyarn
# カレントディレクトリにpackege.jsonがある場合はそれを利用。なければgit管理化のrootにあるpackage.jsonを利用
alias yy='_fzf_yarn'
_fzf_yarn() {
  local packageJson=$(find ./ -maxdepth 1  -name 'package.json')
  if [ -z "$packageJson" ]; then
    local gitRoot=$(git rev-parse --show-cdup)
    packageJson=$(find ${gitRoot}. -maxdepth 2  -name 'package.json')
  fi
  [ -z "$packageJson" ] && return
  local actions=($(cat ${packageJson} | jq -r '.scripts | keys | .[]' \
    | fzf-tmux -p --preview "cat ${packageJson} | jq -r '.scripts[\"{}\"]'" --preview-window=up:1))
  [ -z "$actions" ] && return
  local cmd=''
  for action in "${actions[@]}"; do
    if [ -z "$cmd" ]; then
      cmd="yarn $action"
    else
      cmd="$cmd && yarn $action"
    fi
  done
  printf "\e[35m$cmd\n\e[m\n"
  print -s "$cmd"
  eval "$cmd"
}

# pnpmコマンドをfzfで実行
alias pnn='_fzf_pnpm'
_fzf_pnpm() {
  # ワークスペース一覧を取得
  local -a workspacePkgs=( "root|./package.json" )
  while IFS= read -r pkg; do
    local name
    name=$(jq -r '.name // empty' "$pkg")
    [[ -z $name ]] && name=$(basename "$(dirname "$pkg")")
    workspacePkgs+=( "$name|$pkg" )
  done < <(find . -maxdepth 4 -type f -name 'package.json' \
            -not -path './node_modules/*' -not -path './package.json')

  local pkgName pkgJson

  # rootだけなら選択をスキップ
  if [ "${#workspacePkgs[@]}" -eq 1 ]; then
    pkgName="root"
    pkgJson="./package.json"
  else
    # パッケージ選択
    pkgName=$(
      printf '%s\n' "${workspacePkgs[@]}" | cut -d'|' -f1 \
      | fzf --prompt="📦 パッケージを選択 > "
    ) || return
    [[ -z $pkgName ]] && return

    # 選択パッケージの package.json パス取得
    for entry in "${workspacePkgs[@]}"; do
      if [[ "${entry%%|*}" == "$pkgName" ]]; then
        pkgJson="${entry#*|}"
        break
      fi
    done
  fi

  # 実行コマンドのベース切り替え
  local baseCmd="pnpm run"
  [[ $pkgName != "root" ]] && baseCmd="pnpm --filter $pkgName run"

  # scripts を選択
  local selected
  selected=$(
    jq -r '.scripts | keys[]' "$pkgJson" \
    | fzf --multi \
          --prompt="⚙️ スクリプトを選択 > " \
          --preview="jq -r '.scripts[\"{}\"]' $pkgJson" \
          --preview-window=up:1
  ) || return
  [[ -z $selected ]] && return

  # 選択スクリプトを配列化し、コマンド組み立て
  local cmd=""
  while IFS= read -r act; do
    if [[ -z $cmd ]]; then
      cmd="$baseCmd $act"
    else
      cmd="$cmd && $baseCmd $act"
    fi
  done <<< "$selected"

  # 実行
  printf "\e[32m> %s\e[m\n" "$cmd"
  print -s "$cmd"
  eval "$cmd"
}

# fzfでcomposer
alias coo='_fzf_composer'
_fzf_composer() {
  local composerJson=$(find ./ -maxdepth 1  -name 'composer.json')
  if [ -z "$composerJson" ]; then
    local gitRoot=$(git rev-parse --show-cdup)
    composerJson=$(find ${gitRoot}. -maxdepth 2  -name 'composer.json')
  fi
  [ -z "$composerJson" ] && return
  local action=$(cat ${composerJson} | jq -r '.scripts | keys | .[]' \
    | fzf-tmux -p --preview "cat ${composerJson} | jq -r '.scripts[\"{}\"]'" --preview-window=up:3)
  [ -z "$action" ] && return
  composer $action
  print -s "composer $action"
}

# fzfでcarthage
alias car='_fzf_carthage'
_fzf_carthage() {
  local gitRoot=$(git rev-parse --show-cdup)
  local cartfile=$(find ${gitRoot}. -maxdepth 1  -name 'Cartfile')
  [ -z "$cartfile" ] && echo 'Carfile is not found' && return
  local packages=$(cat ${cartfile} | grep -oP '(?<=/).*(?=")')
  local target=$(echo "全てupdate\n${packages}" | fzf-tmux -p --preview "grep {} $cartfile" --preview-window=up:1)
  [ -z "$target" ] && return
  if ! grep $target $cartfile >/dev/null ; then
    carthage update --platform ios
  else
    carthage update --platform ios $target
  fi
}

# modifiedとuntrachedのファイルをfzfで選択して開く
alias vimg='_fzf_vim_git_modified_untracked'
_fzf_vim_git_modified_untracked() {
  local files=($((git ls-files -m -o --exclude-standard; git diff --staged --name-only) | sort -u | fzf-tmux -p80% --preview='git diff --exit-code {} >/dev/null && bat --color always {} || git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy') )
  [ -z "$files" ] && return
  vim -p "${files[@]}"
}

# modifiedファイルをfzfで選択して開く
alias vimgm='_fzf_vim_git_modified'
_fzf_vim_git_modified() {
  # まず -m -o --exclude-standard で modified/untracked を列挙
  # そのあと [[ -e ]] で実際に存在するものだけを残す
  local all files=()
  # read で１行ずつ取り出して存在チェック(deletedのファイルを除外するため)
  while IFS= read -r f; do
    [[ -e $f ]] && files+=("$f")
  done < <(git ls-files -m -o --exclude-standard)

  # 対象がなければ終了
  [ ${#files[@]} -eq 0 ] && return

  # fzf で選択
  local selected=($(printf '%s\n' "${files[@]}" | sort -u \
    | fzf-tmux -p80% --preview='
      git diff --exit-code {} >/dev/null && bat --color always {} \
      || git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy
    '))

  [ -z "$selected" ] && return

  # vim を開く
  vim -p "${selected[@]}"
}

# ブランチ間の差分ファイルをfzfで選択して開く
alias vimd='_fzf_vim_git_diff_branch'
_fzf_vim_git_diff_branch(){
  local parent=$(git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | awk -F'[]~^[]' '{print $2}')
  local current=$(git branch --show-current)
  local targets=($(git diff --name-only $parent $current | fzf-tmux -p80% --preview='git diff --exit-code {} >/dev/null && bat --color always {} || git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy'))
  [ -z "$targets" ] && return
  vim -p "${targets[@]}"
}

# plistファイルをjsonで出力
alias plist_to_json='_plist_to_json'
_plist_to_json() {
  plutil -convert json $1 -o -
}

# 指定のSystemPreferenceを表示する
alias sp='_show_preference'
_show_preference() {
  # @see https://developer.apple.com/documentation/devicemanagement/systempreferences
  local pane_id=$(cat << EOS | fzf --delimiter '\.' --with-nth -1
com.apple.ClassroomSettings
com.apple.Localization
com.apple.preference.datetime
com.apple.preference.desktopscreeneffect
com.apple.preference.digihub.discs
com.apple.preference.displays
com.apple.preference.dock
com.apple.preference.energysaver
com.apple.preference.expose
com.apple.preference.general
com.apple.preference.ink
com.apple.preference.keyboard
com.apple.preference.mouse
com.apple.preference.network
com.apple.preference.notifications
com.apple.preference.printfax
com.apple.preference.screentime
com.apple.preference.security
com.apple.preference.sidecar
com.apple.preference.sound
com.apple.preference.speech
com.apple.preference.spotlight
com.apple.preference.startupdisk
com.apple.preference.trackpad
com.apple.preference.universalaccess
com.apple.preferences.AppleIDPrefPane
com.apple.preferences.appstore
com.apple.preferences.Bluetooth
com.apple.preferences.configurationprofiles
com.apple.preferences.extensions
com.apple.preferences.FamilySharingPrefPane
com.apple.preferences.icloud
com.apple.preferences.internetaccounts
com.apple.preferences.parentalcontrols
com.apple.preferences.password
com.apple.preferences.sharing
com.apple.preferences.softwareupdate
com.apple.preferences.users
com.apple.preferences.wallet
com.apple.prefpanel.fibrechannel
com.apple.prefs.backup
com.apple.Xsan
EOS
)
  [ -z "$pane_id" ] && return
  osascript << EOS
    tell application "System Preferences"
      set show all to true
      activate
      set current pane to pane id "$pane_id"
    end tell
EOS
}

# ブログ用のkeynoteファイルを開く
alias bb='_open_blog_keynote'
_open_blog_keynote() {
  local targets=$(cat << EOS
$HOME/Documents/github/keynote-template/blog_header_image.key
$HOME/Documents/github/keynote-template/myshape.key
$HOME/Documents/github/keynote-template/wallpaper.key
EOS
)
  local target=$(echo "${targets}"| fzf)
  [ -z "$target" ] && return
  open "$target"
}

alias gif_to_mp4='_gif_to_mp4'
_gif_to_mp4() {
  local gif=${1}
  local mp4=${2:-video.mp4}
  [ -z "$gif" ] && return
  ffmpeg -i $gif -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" $mp4
}

# c#ファイル(.cs)をコンパイルして実行
# ln -s /Library/Frameworks/Mono.framework/Versions/Current/bin/mono /usr/local/bin
# ln -s /Library/Frameworks/Mono.framework/Versions/Current/bin/mcs /usr/local/bin
# をあらかじめ実行していること。VisualStudio2019をインストールすれば入る。
alias ms='_mcs_and_mono'
_mcs_and_mono() {
  local fileName=${1/\.*/}
  mcs $1
  mono ${fileName}.exe
}

# neovimを更新
alias neovim_update='_neovim_nightly_update'
function _neovim_nightly_update() {
  cd ~/neovim
  git fetch --tags -f
  git checkout nightly
  sudo make CMAKE_INSTALL_PREFIX=$HOME/neovim/nvim install
}

# 本日変更があったファイルのみをls
alias lt='_ls_today'
function _ls_today() {
  gls --full-time --time-style="+%Y-%m-%d %H:%M:%S" $1 | grep `date "+%F"`
}

# PRのブランチへチェックアウト
alias prr='_git_checkout_from_pr'
_git_checkout_from_pr() {
 # デフォルトのクエリ
  local default_query="NOT bump in:title is:open is:pr"
  # 引数があればそれを付け足す
  local query="$default_query ${1:+$1}"
  local pr=$(gh pr list --search "$query" --limit 100 | fzf | awk '{print $1}')
  [ -z "$pr" ] && return
  gh pr checkout $pr
}

# 自分が関連するPR一覧を取得
alias prl='_github_pr_involves'
_github_pr_involves() {
  local repos=($(git remote get-url origin | sed "s/.*://g;s/.git//g"))
  if [ $# -ne 0 ]; then
    local repos=("$@")
  fi
  for repo in "${repos[@]}";do
    gh pr list --repo "$repo" --search "NOT bump in:title is:open is:pr involves:@me" --json number,title,url,reviewDecision,author --template '{{range .}}【'"$repo"'】#{{.number}}{{"\t"}}{{.title}}{{"\t"}}{{.url}}{{"\t"}}{{.author.login}}{{"\n"}}{{end}}'

  done
}

# iOSシミュレータを起動
alias ios='_open_ios_simulator'
_open_ios_simulator() {
  local identifier=$(xcrun simctl list runtimes -j | jq -r '.runtimes[] | select(.platform == "iOS") | .identifier' | head -n 1)
  local devices=$(xcrun simctl list devices -j | jq -r ".devices[\"${identifier}\"][] | select(.isAvailable == true) | .name" | fzf)
  [ -z "$devices" ] && return
  echo "$devices" | while read device; do
    xcrun simctl boot "$device"
    open -a Simulator
  done
}

# 指定サイズのダミー画像を生成する
function create_dummy_image() {
  # 1MB
  local byte=1024000
  local tmpText=~/Desktop/dummy.txt
  local target=~/Desktop/dummy.png

  convert -size 640x640 xc:#FF6600 $target
  cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w $byte | head -n 1 > $tmpText
  exiftool -m $target -comment\<=$tmpText
  rm ${target}_original $tmpText
}

# iosシミュレータを録画
alias rec='_record_ios_simulator'
function _record_ios_simulator() {
  local name=${1:-`date +"%H%M%S"`}
  xcrun simctl io booted recordVideo ~/Desktop/${name}.mov
}

# 複数ファイル移動
# ファイルを列挙してコマンドラインに出すだけで、移動先のディレクトリは自身で入力する
alias mvv='_move_multiple_file'
function _move_multiple_file() {
  local targets=($(ls -1 | fzf --preview 'bat --color always {}'))
  [ -z "$targets" ] && return
  print -z "mv ${targets[@]} "
}

# .ssh/configにあるサーバーに接続する
alias sshl='_ssh_fzf'
function _ssh_fzf() {
  function _change_bg_color() {
    local server=$1
    # サーバーによって色を変える
    if echo "$server" | grep "admin" >/dev/null ; then
      tmux select-pane -P 'bg=colour52'
    elif echo "$server" | grep "stg" >/dev/null ; then
      tmux select-pane -P 'bg=colour17'
    else
      tmux select-pane -P 'bg=#000'
    fi
  }

  local target_servers=(`(find ~/.ssh/configs -type f -exec cat {} +; cat ~/.ssh/config) | grep "Host " | grep -v "#" | grep -v "\*" | perl -pe 's/Host\s//g' | fzf`)
  [ -z "$target_servers" ] && return 130
  local server_num=${#target_servers[@]}

  # 選択したサーバーが1つなら現在のpaneでsshを実行する
  if [ $server_num -eq 1 ]; then
      _change_bg_color ${target_servers}
      # ssh -t $target_servers  "/bin/bash --rcfile ~/tanaka/bashrc"
      ssh -t $target_servers
      return
  fi

  tmux new-window
  local count=0
  for server in ${target_servers[@]}; do
      count=$(expr $count + 1)
      tmux select-layout tiled
      _change_bg_color ${target_server}
      # tmux send-keys "ssh -t $server '/bin/bash --rcfile ~/tanaka/bashrc'" C-m
      tmux send-keys "ssh -t $server" C-m
      tmux send-keys "clear" C-m
      if [ $count -ne ${#target_servers[@]} ];then
          tmux splitw
      fi
  done

  tmux set pane-border-status top
  tmux set pane-border-format '#T'
  tmux rename-window "multi-ssh"
  tmux set-window-option synchronize-panes
}

# AWS EC2にfzfでSSHする
alias aww='_aws_ssh_fzf'
function _aws_ssh_fzf() {
  # SSO セッションの有効性を確認
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    aws sso login
  fi
  local selected_lines
  selected_lines=$(aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value | [0], InstanceId]' \
    --output text | column -t -s $'\t' | fzf)
  [ -z "$selected_lines" ] && return 130

  # 選択行の件数をカウント
  local count
  count=$(echo "$selected_lines" | wc -l | tr -d ' ')

  # 選択行が1件なら現在の pane で実行
  if [ "$count" -eq 1 ]; then
    local instance_id
    instance_id=$(echo "$selected_lines" | awk '{print $2}')
    tmux select-pane -P 'bg=colour17'
    printf "\e[33maws ssm start-session --target $instance_id\e[m\n"
    aws ssm start-session --target "$instance_id"
    return
  fi

  # 複数選択の場合は新しい tmux ウィンドウで各 pane に割り当て
  tmux new-window -n "multi-ssm"
  local total
  total=$(echo "$selected_lines" | wc -l | tr -d ' ')

  local pane_index=0
  # 各行をループ処理
  while IFS= read -r line; do
    pane_index=$((pane_index + 1))
    local instance_id
    instance_id=$(echo "$line" | awk '{print $2}')
    tmux select-layout tiled
    tmux select-pane -P 'bg=colour17'
    printf "\e[33maws ssm start-session --target $instance_id\e[m\n"
    tmux send-keys "aws ssm start-session --target $instance_id" C-m
    tmux send-keys "clear" C-m
    # 最後の pane でなければ pane を分割
    if [ $pane_index -lt $total ]; then
      tmux split-window
    fi
  done <<< "$selected_lines"

  tmux set pane-border-status top
  tmux set pane-border-format '#T'
  tmux set-window-option synchronize-panes
}

# 合計値を出す。列が一つのときのみ有効
alias tsum='_sum_from_clipboard'
function _sum_from_clipboard() {
  # クリップボードの内容を取得
  local clipboard=$(pbpaste)

  # 各行をカンマを無視して数値として足し合わせる
  sum=0
  echo "$clipboard" | while IFS= read -r line; do
    # カンマを削除して数値として扱う
    num=$(echo "$line" | tr -d ',')
    sum=$((sum + num))
  done

  # 合計を表示
  printf "%'d\n" "$sum"
}

# ブランチ最新化
# developの場合はバックアップを取る
alias gpl='_git_pull_and_backup'
function _git_pull_and_backup() {
  # 現在のブランチ名を取得
  local current_branch=$(git rev-parse --abbrev-ref HEAD)

  # develop ブランチならバックアップブランチを作る
  if [ "$current_branch" = "develop" ]; then
    local backup_branch="develop_$(date +%Y%m%d_%H%M%S)"
    # checkout せず、単にブランチだけ作成
    git branch "$backup_branch"
    echo "バックアップブランチ '$backup_branch' を作成しました"
  fi

  git pull --rebase origin "$current_branch"
}

# カレントディレクトリ配下の.envを探して開く
alias envv='_open_env'
_open_env() {
  local find_result=$(find . -name ".env" -type f)
  local target_files=($(echo "$find_result" \
    | sed 's/\.\///g' \
    | fzf-tmux -p80% --select-1 --prompt 'vim ' --preview 'bat --color always {}' --preview-window=right:70%
  ))
  [ "$target_files" = "" ] && return
  vim -p ${target_files[@]}
}

# 全てのファイルをgit checkoutする
alias gca='_git_checkout_all'
function _git_checkout_all() {
  local path_working_tree_root=$(git rev-parse --show-cdup)
  git -C "$path_working_tree_root" checkout $(git -C "$path_working_tree_root" diff --name-only)
}
