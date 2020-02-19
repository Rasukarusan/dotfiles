# ============================== #
#       alias-to-script          #
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
# ディスプレイ明るさを0に
alias 00='osascript ~/scripts/up_or_down_brightness.sh 1'
alias 11='osascript ~/scripts/up_or_down_brightness.sh 0'
alias gg='sh ~/scripts/githubAPI.sh'
alias cw='sh ~/scripts/chatwork.sh'
alias ctt='sh ~/scripts/chromeSelectTab.sh'
alias sqq='sh ~/scripts/fzf_sequel_pro.sh'
