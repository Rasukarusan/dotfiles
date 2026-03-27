#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 必要なディレクトリを作成
mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/.config/nvim/plugin"
mkdir -p "$HOME/.config/coc/extensions"
mkdir -p "$HOME/.cache/cdr"
mkdir -p "$HOME/.vim"

# シンボリックリンクを作成する関数
# 既にリンクが存在する場合はスキップ、通常ファイルが存在する場合はバックアップ
link() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "  skip: $dest (already linked)"
      return
    fi
    echo "  relink: $dest -> $src (was $current)"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  backup: $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  ln -s "$src" "$dest"
  echo "  link: $dest -> $src"
}

# Zsh
echo "==> Zsh"
link "$DOTFILES_DIR/zsh/zshrc"       "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/.zshrc.local" "$HOME/.zshrc.local"

# Terminal
echo "==> Terminal"
link "$DOTFILES_DIR/terminal/tmux.conf"             "$HOME/.tmux.conf"
link "$DOTFILES_DIR/terminal/hyper.js"               "$HOME/.hyper.js"
link "$DOTFILES_DIR/terminal/agignore"               "$HOME/.agignore"
link "$DOTFILES_DIR/terminal/git/gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES_DIR/terminal/git/gitignore_global"   "$HOME/.gitignore_global"

# Vim
echo "==> Vim"
link "$DOTFILES_DIR/vim/xvimrc"                "$HOME/.xvimrc"
link "$DOTFILES_DIR/vim/init.vim"              "$HOME/.vimrc"
link "$DOTFILES_DIR/vim/init.vim"              "$HOME/.config/nvim/init.vim"
link "$DOTFILES_DIR/vim/colors"                "$HOME/.config/nvim/colors"
link "$DOTFILES_DIR/vim/colors"                "$HOME/.vim/colors"
link "$DOTFILES_DIR/vim/textlintrc"            "$HOME/.textlintrc"
link "$DOTFILES_DIR/vim/plugin_settings"       "$HOME/.config/nvim/plugin_settings"
link "$DOTFILES_DIR/vim/coc/coc-settings.json" "$HOME/.config/nvim/coc-settings.json"
link "$DOTFILES_DIR/vim/coc/package.json"      "$HOME/.config/coc/extensions/package.json"
link "$DOTFILES_DIR/vim/UltiSnips"             "$HOME/.config/nvim/UltiSnips"
link "$DOTFILES_DIR/vim/autoload"              "$HOME/.config/nvim/myautoload"
link "$DOTFILES_DIR/vim/lua"                   "$HOME/.config/nvim/lua"

# Claude (~/.config/claude)
echo "==> ~/.config/claude"
mkdir -p "$HOME/.config/claude"
link "$DOTFILES_DIR/claude/CLAUDE.md"     "$HOME/.config/claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json" "$HOME/.config/claude/settings.json"
link "$DOTFILES_DIR/claude/commands"      "$HOME/.config/claude/commands"

# Claude (~/.claude)
echo "==> ~/.claude"
mkdir -p "$HOME/.claude"
link "$DOTFILES_DIR/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/agents"        "$HOME/.claude/agents"
link "$DOTFILES_DIR/claude/commands"      "$HOME/.claude/commands"
link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/claude/skills"        "$HOME/.claude/skills"
link "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusLine.sh"

# ~/.codex
echo "==> ~/.codex"
mkdir -p "$HOME/.codex"
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"
link "$DOTFILES_DIR/claude/commands"  "$HOME/.codex/prompts"
link "$DOTFILES_DIR/codex/rules"      "$HOME/.codex/rules"

echo "Done."
