zsh + tmux + neovim
====

Build environment by shell script.

## Setup

```shell
# Install Homebrew, packages, macOS defaults and symlinks
$ bash setup.sh
```

## After setup

Should run following command in `nvim`.

```vim
:PlugInstall
:checkhealth
```

coc.nvim extensions are listed in `vim/coc/package.json` and installed
automatically on the first `nvim` launch.

## Chrome Setup

- extension toolbar menu

1. Access `chrome://flags/`.
2. Enable `Extensions Toolbar Menu`.
