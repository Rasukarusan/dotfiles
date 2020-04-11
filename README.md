zsh + tmux + neovim
====

Build environment by Ansible.

## Setup

```shell
# Install Homebrew and run ansible
$ sh initial.sh
```

## After setup

Should run following command in `nvim`.

```vim
:call dein#install()
:CocInstall
:checkhealth
```
- Global npm package
```sh
npm install -g dockerfile-language-server-nodejs
npm install -g eslint
npm install -g eslint_d
```

## Chrome Setup

- extension toolbar menu

1. Access `chrome://flags/`.
2. Enable `Extensions Toolbar Menu`.
