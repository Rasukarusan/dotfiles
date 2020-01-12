#!/bin/sh

# ================================= #
#               Vim                 #
# ================================= #
ln -sf ~/dotfiles/vim/init.vim ~/.vimrc
ln -sf ~/dotfiles/vim/init.vim ~/.config/nvim/init.vim
ln -sf ~/dotfiles/vim/dein.toml ~/.config/nvim/dein.toml
ln -sf ~/dotfiles/vim/plugin_settings ~/.config/nvim/plugin_settings
ln -sf ~/dotfiles/vim/coc/package.json ~/.config/coc/extensions/package.json
ln -sf ~/dotfiles/vim/.xvimrc ~/.xvimrc

# ================================= #
#               Zsh                 #
# ================================= #
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc

# ================================= #
#             Terminal              #
# ================================= #
ln -sf ~/dotfiles/terminal/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/terminal/.hyper.js ~/.hyper.js
