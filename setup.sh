#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# ~/.claude
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
