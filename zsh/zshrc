# PATHがsource ~/.zshrcする度に重複して登録されないようにする
typeset -U path PATH
alias vim='nvim'
[ -f ~/dotfiles/zsh/settings.zsh ] && source ~/dotfiles/zsh/settings.zsh
[ -f ~/dotfiles/zsh/exports.zsh ] && source ~/dotfiles/zsh/exports.zsh
[ -f ~/dotfiles/zsh/function.zsh ] && source ~/dotfiles/zsh/function.zsh
[ -f ~/dotfiles/zsh/alias_script.zsh ] && source ~/dotfiles/zsh/alias_script.zsh
[ -f ~/dotfiles/zsh/alias_command.zsh ] && source ~/dotfiles/zsh/alias_command.zsh
[ -f ~/dotfiles/zsh/alias_function.zsh ] && source ~/dotfiles/zsh/alias_function.zsh
[ -f ~/.phpbrew/bashrc ] && source /Users/$(whoami)/.phpbrew/bashrc
# zshrc.localを読み込む(行末に書くことで設定を上書きする)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

