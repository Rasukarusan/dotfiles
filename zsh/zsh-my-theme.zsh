export LSCOLORS="dxfxcxdxbxegedabagacad"
export LS_COLORS='di=33;:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'
export GREP_COLOR='1;33'

# PROMPTテーマ
setopt prompt_subst #プロンプト表示する度に変数を展開

precmd () { 
  if [ -n "$(git status --short 2>/dev/null)" ];then
    export GIT_HAS_DIFF="✗"
    export GIT_NON_DIFF=""
  else 
    export GIT_HAS_DIFF=""
    export GIT_NON_DIFF="✔"
  fi
  # git管理されているか確認
  git status --porcelain >/dev/null 2>&1
  if [ $? -ne 0 ];then
    export GIT_HAS_DIFF=""
    export GIT_NON_DIFF=""
  fi
  export BRANCH_NAME=$(git branch --show-current 2>/dev/null)
}
# 末尾に空白をつけることで改行される
PROMPT=" 
%F{cyan}%~%f"
PROMPT=${PROMPT}'%F{green}  ${BRANCH_NAME} ${GIT_NON_DIFF}%F{red}${GIT_HAS_DIFF} 
%f$ '
