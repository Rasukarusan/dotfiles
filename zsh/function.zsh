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

alias cee='_easy_change_dir'
function _easy_change_dir() {
  local findOptions="-maxdepth 3 -type d -not -path './.git/*'"
  local targetDir=$(eval "find . $findOptions" | fzf --bind "tab:reload(find {} $findOptions),ctrl-p:reload(find `dirname {}` $findOptions)" --preview 'tree -L 3 {}')
  [ -z "$targetDir" ] && return
  cd $targetDir
}

# ag & view
alias jump='_jump'
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

alias lkk='_look_all'
_look_all() {
  local target_files=($(find . -type f -not -path "./node_modules/*" \
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

# あらかじめ指定したGitディレクトリを全て最新にする
alias upd='_update_dotfile'
_update_dotfile() {
  ls -1 ~/Documents/github | while read dir; do
    local dir=~/Documents/github/${dir}
    printf "\e[33m${dir}\e[m\n"
    git -C ${dir} pull --rebase origin master
  done
}
# あらかじめ指定したGitディレクトリを全てpushする
alias psd='_push_dotfile'
_push_dotfile() {
  ls -1 ~/Documents/github | while read dir; do
    local dir=~/Documents/github/${dir}
    printf "\e[33m${dir}\e[m\n"
    git -C ${dir} add -A
    git -C ${dir} commit -v
    git -C ${dir} push origin master
  done
}
# あらかじめ指定したGitディレクトリのgit statusを表示
alias std='_show_git_status_dotfile'
_show_git_status_dotfile() {
  for targetDir in ${MY_TARGET_GIT_DIR[@]}; do
    printf "\e[33m`basename ${targetDir}`\e[m\n"
    git -C ${targetDir} status
    echo ""
  done
}
# 選択したディレクトリのgit diffを表示
alias stdd='_preview_my_git_diff'
_preview_my_git_diff() {
  local target_dir=$(echo ${MY_TARGET_GIT_DIR[@]} | tr ' ' '\n' | fzf --preview 'git -C {} diff --color=always')
  if [ -z "$target_dir" ]; then
    return
  fi
  git -C $target_dir add -p && git -C $target_dir commit
}

# git管理しているディレクトリすべてでgit statusを実行
alias sgs='_show_git_status'
_show_git_status() {
  ls -1 ~/Documents/github | while read dir; do
    local dir=~/Documents/github/${dir}
    if [ -n "$(git -C ${dir} status --porcelain)" ]; then
      printf "\e[33m${dir}\e[m\n"
      git -C ${dir} status -s
    fi
  done
}

# bcコマンドを簡単にかつ小数点時に.3333となるのを0.3333に直す(0を付け足す)
alias bcc='_bcc'
_bcc() {
  echo "scale=2;$1" | bc | sed 's/^\./0\./g'
}
# agの結果をfzfで絞り込み選択するとvimで開く
alias agg='_ag_and_vim'
_ag_and_vim() {
  if [ -z "$1" ]; then
    echo 'Usage: agg PATTERN'
    return 0
  fi
  ag $1 | fzf-tmux -p80% | IFS=':' read -A selected
  [ ${#selected[@]} -lt 2 ] && return
  vim ${selected[1]} +${selected[2]}
}


# ファイルパス:行番号のようなものをvimで開く
viml() {
  pbpaste | IFS=':' read -A selected
  vim ${selected[1]} +${selected[2]}
}

alias maillog='_show_mail_log'
_show_mail_log() {
  log stream --predicate '(process == "smtpd") || (process == "smtp")' --info
}

# 記事メモコマンド
alias art='_write_article'
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
# 投稿した記事を別ディレクトリに移動
alias post='_move_posted_articles'
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

# Redmine記法からmarkdown形式へ変換
alias rtm='_redmine_to_markdown'
_redmine_to_markdown() {
  sed "s/^# /1. /g" | \
  sed "s/h2./##/g"  | \
  sed "s/h3./###/g" | \
  sed "s/<pre>/\`\`\`zsh/g" | \
  sed "s/<\/pre>/\`\`\`/g"
}

# markdown記法からRedmine形式へ変換
alias mtr='_markdown_to_redmine'
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
		docker-compose up
		docker-compose up --build
		docker-compose up -d
		docker-compose up --build -d
		docker-compose up --build -d <service>
		docker-compose --compatibility up -d
		docker-compose up --force-recreate
		docker-compose stop
		docker rm
		docker rmi
		docker cp
		docker system prune -a
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
    'docker-compose up --build -d <service>' )
      local service=$(cat docker-compose.yml | yq --yaml-roundtrip ".services|keys" | sed 's/^- //g' | fzf)
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

# docker危険コマンド集
alias ddc='_danger_docker_commands'
_danger_docker_commands() {
  local actions=(
    'minrc配置:_copy_minrc'
  )
  local action=$(echo "${actions[@]}" | tr ' ' '\n' | fzf -d ':' --with-nth=1 | cut -d ':' -f 2,2)
  [ -n "$action" ] && eval "$action"
}

# minrc配置
_copy_minrc() {
  targetFile="${HOME}/dotfiles/zsh/minrc"

  containers=($(docker ps --format "{{.Names}}" | fzf-tmux -p80%))
  for container in ${containers[@]};do
    printf "\e[35m${container}\e[m\n"
    filename=".profile"
    shell="ash"

    # bashが使えるか判定
    if docker exec -it $container cat /etc/shells | grep bash >/dev/null ; then
      filename=".bashrc"
      shell="bash"
    fi

    # コンテナにコピー
    id=$(docker ps -aq --filter "name=$container")
    test -z "$id" && echo "Not found $container's Container ID." && continue

    # コンテナのHOMEディレクトリを取得
    home=$(docker exec -i $container $shell -c "getent passwd | tail -n 1 | cut -d: -f6")

    echo "$targetFile =====> ${container}(${id})"
    execCommand="docker cp ${targetFile} ${id}:${home}/${filename}"
    print -s "$execCommand"
    printf "\e[33m${execCommand}\e[m\n\n" && eval $execCommand
  done
}

# 自作スクリプト編集時、fzfで選択できるようにする
alias scc='_edit_my_script'
_edit_my_script() {
  local targetFiles=$(find ~/scripts -follow -maxdepth 1 -name "*.sh";ls -1 ~/.zshrc.local ~/.xvimrc)
  local selected=$(echo "$targetFiles" | fzf-tmux -p80% --preview '{bat --color always {}}')
  [ -z "$selected" ] && return
  vim $selected
}

# 自作スクリプトをfzfで選んで実行
alias ss='_source_my_script'
_source_my_script() {
  local targetFiles=$(find ~/scripts -follow -maxdepth 1 -name "*.sh")
  local selected=$(echo "$targetFiles" | fzf-tmux -p80% --preview '{bat --color always {}}')
  [ -z "$selected" ] && return
  sh $selected
}

# tmuxコマンド集
alias tt='_tmux_commands'
_tmux_commands() {
  local command=$(cat <<-EOF | fzf --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
		resize
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
    'マージ済みのブランチ削除:_delete_merged_branch'
    '特定ファイルと関連する履歴を全て削除:_delete_all_histories_by_file'
    'masterのコミットを全て削除:_delete_all_git_log'
    'コミットのAuthorを全て書き換える:_change_author'
    'ローカル(特定リポジトリ)のConfigを変更:_change_config_local'
    'git_clean_df:_git_clean_df'
  )
  local action=$(echo "${actions[@]}" | tr ' ' '\n' | fzf -d ':' --with-nth=1 | cut -d ':' -f 2,2)
  [ -n "$action" ] && eval "$action"
}

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
  local nvimFiles=$(find ~/dotfiles ${XDG_CONFIG_HOME}/nvim/myautoload -follow -name "*.vim")
  local deinToml=~/dotfiles/vim/dein.toml
  local xvimrc=~/dotfiles/vim/xvimrc
  # 文字数でソートする
  local editFile=$(echo "${nvimFiles}\n${deinToml}\n${xvimrc}" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | fzf-tmux -p80% --preview "bat --color always {}")
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
  local stashNo=$(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':' )
  test -z "${stashNo}" && return
  git stash apply "${stashNo}"
}

_fzf_git_stash_drop() {
  local stashNos=($(git stash list | fzf --preview 'echo {} | awk "{print \$1}" | tr -d ":" | xargs git stash show --color=always -p' | awk '{print $1}' | tr -d ':'  | tac))
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

alias cld='_clipboard_diff'
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
alias dt='_toggle_desktop_icon_display'
_toggle_desktop_icon_display() {
  local isDisplay=$(defaults read com.apple.finder CreateDesktop)
  if [ $isDisplay -eq 1 ]; then
    defaults write com.apple.finder CreateDesktop -boolean false && killall Finder
  else
    defaults write com.apple.finder CreateDesktop -boolean true && killall Finder
  fi
}

# 囲まれた文字のみを抽出
alias tgrep='_grep_surround_word'
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
alias sell='_fzf_selenium'
_fzf_selenium() {
  local action=`cat <<- EOF | fzf-tmux -p
		status
		log
		up
		stop
	EOF`
  [ -z "$action" ] && return
  local execCommand
  case $action in
    'status' )
      execCommand="ps aux | grep -v grep | grep -c selenium"
      ;;
    'log' )
      local LOG_DIR=~/.selenium-log
      local latest_selenium_log=$(echo $(ls -t $LOG_DIR | head -n 1))
      execCommand="tail -f $LOG_DIR/$latest_selenium_log"
      ;;
    'up' )
      local LOG_DIR=~/.selenium-log
      if [ ! -e $LOG_DIR ]; then
        mkdir $LOG_DIR
      fi
      local is_run=`ps aux | grep -v grep | grep -c selenium`
      local today=`date +%Y-%m-%d`
      if [ $is_run -eq 0 ]; then
        execCommand="java -jar /Library/java/Extensions/selenium-server-standalone-3.4.0.jar > ${LOG_DIR}/${today}.log 2>&1 &"
      fi
      ;;
    'stop' )
      execCommand="ps aux | grep selenium | grep -v grep | awk '{print \$2}' | xargs kill -9"
      ;;
  esac
  print -s "$execCommand"
  eval "$execCommand"
}

# masterブランチを最新にする
alias update_master='_update_master'
_update_master() {
  git checkout master
  git fetch --all
  git pull --rebase origin master
}

# お天気情報を出力する
alias tenki='_tenki'
_tenki() {
  local place=${1:-kanagawa}
  curl -4 http://wttr.in/${place}
  # finger ${place}@graph.no
}

# vagrantのコマンドをfzfで選択
alias vgg='_fzf_vagrant'
_fzf_vagrant() {
  local selectCommand=`cat <<- EOF | fzf-tmux -p
		vagrant ssh
		vagrant up
		vagrant provision
		vagrant reload
		vagrant halt
		vagrant reload&provision
		vagrant global-status
	EOF`
  test -z "$selectCommand" && return
  local arg=`echo $selectCommand | sed "s/vagrant //g"`
  case "${arg}" in
    'ssh' )
      vagrant ssh
      ;;
    'up' )
      vagrant up
      ;;
    'provision' )
      vagrant provision
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
alias check_danger_input='_check_danger_input'
_check_danger_input() {
  for danger_word in `cat ~/danger_words.txt`; do
  echo $danger_word
    ag --ignore-dir=vendor $danger_word ./*
  done
}

# 文字画像を生成。第一引数に生成したい文字を指定。
alias create_bg_img='_create_bg_img'
_create_bg_img() {
  local sizeList=(75x75 100x100 320x240 360x480 500x500 600x390 640x480 720x480 1000x1000 1024x768 1280x960)
  local sizes=($(echo ${sizeList} | tr ' ' '\n' | fzf-tmux -p))
  local backgroundColor="#000000"
  local fillColor="#ff8ad8" # 文字色
  # フォントによっては日本語対応しておらず「?」になってしまうので注意
  local fontPath=/System/Library/Fonts/ヒラギノ丸ゴ\ ProN\ W4.ttc
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
alias gmail='_gmail'
_gmail() {
  local USER_ID=`cat ~/account.json | jq -r '.gmail.user_id'`
  local PASS=`cat ~/account.json | jq -r '.gmail.pass'`
  curl -u ${USER_ID}:${PASS} --silent "https://mail.google.com/mail/feed/atom" \
    | tr -d '\n' \
    | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' \
    | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\2 - \1/p"
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

alias viw='_open_path_by_vim'
_open_path_by_vim() {
  vim "$(which -p "$1")"
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

# gitコマンドのmanを参照
alias mangit='_fzf_man_git'
_fzf_man_git() {
  local target=$(git help -a | awk '{print $1}' | grep -Ev '^[A-Z]' | sed '/^$/d' \
    | fzf \
      --preview "git help {} | head -n 100 " \
      --preview-window=right:80%
    )
  [ -z "$target" ] && return
  git help $target
  print -s "git help $target"
}

# ログインShellを切り替える
alias shell='_switch_login_shell'
_switch_login_shell() {
  local target=$(cat /etc/shells | grep '^/' | fzf-tmux -p)
  [ -z "$target" ] && return
  chsh -s $target
}

# インストール一覧コマンド集
alias list='_show_installed_list'
_show_installed_list() {
  local targets=`cat <<-EOS | fzf-tmux -p
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
alias phpp='_fzf_phpbrew'
_fzf_phpbrew() {
  local currentVersion=$(php -v)
  local selected=$(phpbrew list \
    | grep php \
    | tr -d ' ' \
    | tr -d '*' \
    | currentVersion=$(php -v) fzf-tmux -p --preview="echo '$(php -v)'" --preview-window=down:50%
  )
  [ -z "$selected" ] && return
  phpbrew use $selected
  echo '$ php -v' && php -v
}

# npmコマンドをfzfで実行
alias npp='_fzf_npm'
_fzf_npm() {
  if [ -f package.json ]; then
    local action=$(cat package.json | jq -r '.scripts | keys | .[]' \
      | fzf-tmux -p80% --preview "cat package.json | jq -r '.scripts[\"{}\"]'" --preview-window=up:1)
    [ -z "$action" ] && return
    npm run $action
    print -s "npm run $action"
  else
    echo 'Not Found package.json'
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
  local files=($(git ls-files -m -o --exclude-standard | sort | fzf-tmux -p80% --preview='git diff --exit-code {} >/dev/null && bat --color always {} || git diff --color=always $(git rev-parse --show-cdup){} | diff-so-fancy') )
  [ -z "$files" ] && return
  vim -p "${files[@]}"
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

# vimメモ帳
alias memo='_memo'
_memo() {
  local MEMO_PATH=~/memo.md
  local today=`date '+%Y/%m/%d(%a)'`
  if ! grep "# $today" $MEMO_PATH >/dev/null ; then
    echo "\n# $today" >> $MEMO_PATH
  fi
  # 最下行を一番上にしてvimを開く (:help scroll-cursor)
  echo "Gzt" | vim -s - $MEMO_PATH
}

alias pmux='_popuptmux'
_popuptmux() {
  if [ "$(\tmux display-message -p -F "#{session_name}")" = "popup" ];then
    tmux detach-client
  else
    tmux popup -E "\tmux attach -t popup || \tmux new -s popup"
  fi
}

alias imgcatt='_imgcat_for_tmux'
_imgcat_for_tmux() {
  # @See: https://qastack.jp/unix/88296/get-vertical-cursor-position
  get_cursor_position() {
    old_settings=$(stty -g) || exit
    stty -icanon -echo min 0 time 3 || exit
    printf '\033[6n'
    pos=$(dd count=1 2> /dev/null)
    pos=${pos%R*}
    pos=${pos##*\[}
    x=${pos##*;} y=${pos%%;*}
    stty "$old_settings"
  }
  clear
  command imgcat "$1"
  [ $? -ne 0 ] && return
  [ ! "$TMUX" ] && return
  get_cursor_position
  # 2行分画像が残ってしまうためtputで再描画判定させて消す
  read && tput cup `expr $y - 2` 0
}

_show_commit_only_current_branch() {
  local currentBranch=$(git branch --show-current)
  local compareBranch=$(git branch -a | grep -v $currentBranch | tr -d ' ' | fzf --prompt "Select the branch to compare >" --preview "git cherry -v {}")
  [ -z "$compareBranch" ] && return
  git cherry -v $compareBranch
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

# 禅モード
# Dock非表示、Desktopアイコン非表示、itermの大きさ変更
alias goyo='_goyo'
_goyo() {
  . ~/Documents/github/macos-scripts/desktop_background "/System/Library/Desktop Pictures/Solid Colors/Black.png"
  . ~/Documents/github/macos-scripts/menu_bar 0
  . ~/Documents/github/macos-scripts/dock
  . ~/Documents/github/macos-scripts/desktop_icon 0
  sh ~/Documents/github/iterm-scripts/iterm.sh window large
}

alias goyo!='_goyo!'
_goyo!() {
  . ~/Documents/github/macos-scripts/menu_bar 1
  . ~/Documents/github/macos-scripts/dock
  . ~/Documents/github/macos-scripts/desktop_icon 1
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
  osascript <<EOS
tell application "Keynote"
  activate
  open "$target"
end tell
EOS
}

alias gif_to_mp4='_gif_to_mp4'
_gif_to_mp4() {
  local gif=${1}
  local mp4=${2:-video.mp4}
  [ -z "$gif" ] && return
  ffmpeg -i $gif -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" $mp4
}

alias terr="_terraform_execute"
_terraform_execute() {
  local cmd=$(terraform -help | grep '^  \S' | sed 's/  //' | fzf --with-nth=1 --preview='echo {2..}' --preview-window=up:1  | awk '{print $1}')
  [ -z "$cmd" ] && return
  print -s "terraform $cmd $1"
  terraform $cmd $1
}

alias opp="_open_localhost"
_open_localhost() {
  local port=$(netstat -Watnlv | grep 'LISTEN' | awk '{"ps -ww -o args= -p" $9 | getline procname; print $4 "||" procname}' | column -t -s '||' \
  | fzf --with-nth 1.. --preview="echo {1} | awk -F '.' '{print \$NF}' | xargs -I{} curl -I http://localhost:{}"  --preview-window=up:10 \
  | awk '{print $1}' | awk -F '.' '{print $NF}')
  [ -z "$port" ] && return
  open http://localhost:$port
}

alias gbd='_git_branch_diff'
_git_branch_diff() {
  local current=$(git branch --show-current)
  local target=$(git branch -a | tr -d ' ' | fzf --preview="git diff --color=always {} ${current}")
  [ -z "$target" ] && return
  git diff $target $current | delta --side-by-side
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

# 画像に枠線を追加
alias imgBorder='_add_border_to_image'
_add_border_to_image() {
  local image=$1
  local color=${2:-a0a8a9}
  local borderWeight=${3:-10}
  local width=$(sips -g pixelWidth $1 | awk -F ' ' '{print $2}' | tr -d '\n')
  local height=$(sips -g pixelHeight $1 | awk -F ' ' '{print $2}' | tr -d '\n')
  local borderWidth=$(expr $width + $borderWeight)
  local borderHeight=$(expr $height + $borderWeight) 
  sips -p $borderHeight $borderWidth --padColor $color $image -o border_${image}
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
  local pr=$(gh pr list --search "NOT bump in:title" | fzf | awk '{print $1}')
  [ -z "$pr" ] && return
  gh pr checkout $pr
}

# iOSシミュレータを起動
alias ios='_open_ios_simulator'
_open_ios_simulator() {
  # simulatorが起動していると他のiosデバイスが起動できないのでKILL
  killall Simulator
  local deviceIds=(
    'iPhone12\t940B4E26-E147-4B02-88EA-3C7958DC581B'
    'iPadPro\t48ED061E-D78C-43C3-A8F7-33F029BC4CCC'
    'iPadAir\t769A6774-44F2-42CF-B114-C73CA09616A0'
  )
  local deviceId=$(echo "$deviceIds" | tr " " "\n" | fzf --delimiter='\t' --with-nth 1 | awk '{print $2}')
  [ -z "$deviceId" ] && return
  open -a Simulator --args -CurrentDeviceUDID $deviceId
}
