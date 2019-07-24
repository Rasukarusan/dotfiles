export LSCOLORS="dxfxcxdxbxegedabagacad"
export LS_COLORS='di=33;:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'
export GREP_COLOR='1;33'

# PROMPTテーマ
setopt prompt_subst #プロンプト表示する度に変数を展開
local BLACK=$'%{\e[30m%}'
local RED=$'%{\e[31m%}'
local GREEN=$'%{\e[32m%}'
local YELLOW=$'%{\e[33m%}'
local BLUE=$'%{\e[34m%}'
local PURPLE=$'%{\e[35m%}'
local CYAN=$'%{\e[36m%}'
local GRAY=$'%{\e[37m%}'
local WHITE=$'%{\e[1;37m%}'
local DEFAULT=$'%{\e[1;m%}'
local RAINBOW=$'%{\e[$[color=$[31+$RANDOM%6]]m%}'

autoload -Uz vcs_info
zstyle ':vcs_info:git:*' check-for-changes true      # formats 設定項目で %c,%u が使用可
zstyle ':vcs_info:git:*' stagedstr "%F{red}"         # commit されていないファイルがある
zstyle ':vcs_info:git:*' unstagedstr "%F{red}"       # add されていないファイルがある
zstyle ':vcs_info:*' formats "%F{green}%b %c%u%m %f" # 通常
zstyle ':vcs_info:*' actionformats '[%b|%a]'         # rebase 途中,merge コンフリクト等 formats 外の表示
precmd () { vcs_info }
PROMPT="
${CYAN}%~%f"
PROMPT=$PROMPT'  ${vcs_info_msg_0_}
${GRAY}$ %f'

zstyle ':vcs_info:git+set-message:*' hooks git-is_clean git-untracked
# 状態がクリーンか判定
function +vi-git-is_clean(){
    if [ -z "$(git status --short 2>/dev/null)" ];then
        hook_com[misc]+="✔"
    fi
}
# unstaged, untrackedの検知
function +vi-git-untracked() {
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        hook_com[unstaged]+='%F{red}✗%f'
    fi
}
