#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ====================
# Homebrew
# ====================
echo "==> Homebrew"
if ! command -v brew &>/dev/null; then
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Tap
echo "==> Homebrew tap"
TAPS=(
  homebrew/cask
  homebrew/core
  heroku/brew
  Rasukarusan/tap
  homebrew/cask-fonts
  homebrew/cask-versions
)
for tap in "${TAPS[@]}"; do
  brew tap "$tap" 2>/dev/null || true
done

# Formulae
echo "==> Homebrew formulae"
FORMULAE=(
  autoconf bat composer coreutils ctags curl diff-so-fancy
  exiftool fzf gawk gcc git gitblamer global glow
  gnu-sed go grep imagemagick jq mas mitmproxy ncdu neovim nkf
  node nodebrew pyenv pyenv-virtualenv python3 ripgrep ruby
  the_silver_searcher tmux tree vim w3m watch wget yarn zsh swiftformat
  cocoapods chromedriver tokei ffmpeg rga pastel git-ftp silicon git-delta
  python-yq st jc gh gron lolcat azure-cli rust dasel kind
)
for pkg in "${FORMULAE[@]}"; do
  brew install "$pkg" 2>/dev/null || true
done

# Cask
echo "==> Homebrew cask"
CASKS=(
  google-chrome firefox google-japanese-ime visual-studio-code iterm2
  docker wireshark virtualbox sequel-ace ngrok java11 couleurs
  keycastr another-redis-desktop-manager font-hackgen font-hackgen-nerd
)
for pkg in "${CASKS[@]}"; do
  brew install --cask "$pkg" 2>/dev/null || true
done

# ====================
# npm packages
# ====================
echo "==> npm packages"
NPM_PACKAGES=(
  typescript neovim dockerfile-language-server-nodejs eslint eslint_d
  textlint textlint-rule-preset-jtf-style textlint-rule-preset-ja-technical-writing
  textlint-rule-spellcheck-tech-word chokidar-cli
)
for pkg in "${NPM_PACKAGES[@]}"; do
  npm install -g "$pkg" 2>/dev/null || true
done

# ====================
# yarn global packages
# ====================
echo "==> yarn global packages"
YARN_PACKAGES=(
  tailwindcss-language-server
)
for pkg in "${YARN_PACKAGES[@]}"; do
  yarn global add "$pkg" 2>/dev/null || true
done

# ====================
# pip packages
# ====================
echo "==> pip packages"
PIP_PACKAGES=(
  jedi-language-server imgcat flake8 black
)
for pkg in "${PIP_PACKAGES[@]}"; do
  pip install -U "$pkg" 2>/dev/null || true
done

# ====================
# macOS defaults
# ====================
echo "==> macOS defaults"
defaults write com.apple.iphonesimulator AllowFullscreenMode -bool TRUE
defaults write com.apple.iphonesimulator ShowSingleTouches -bool TRUE
defaults write com.apple.finder QuitMenuItem -bool TRUE
defaults write com.apple.screencapture show-thumbnail -bool FALSE
defaults write com.apple.screencapture name -string "screenshot_"
killall SystemUIServer 2>/dev/null || true

# ====================
# chmod
# ====================
echo "==> chmod"
chmod 755 /usr/local/share/zsh 2>/dev/null || true
chmod 755 /usr/local/share/zsh/site-functions 2>/dev/null || true

# ====================
# Git clone
# ====================
echo "==> Git clone"
clone() {
  local repo="$1"
  local dest="$2"
  if [ -d "$dest" ]; then
    echo "  skip: $dest (already exists)"
  else
    echo "  clone: $repo -> $dest"
    git clone "$repo" "$dest"
  fi
}
clone https://github.com/Rasukarusan/chrome-extension-packs.git "$HOME/Documents/chrome-extension-packs"
clone https://github.com/Rasukarusan/keynote-template.git   "$HOME/Documents/keynote-template"
clone https://github.com/Rasukarusan/scripts.git            "$HOME/scripts"
clone https://github.com/Rasukarusan/articles.git           "$HOME/Documents/articles"

# ====================
# Symlinks
# ====================

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

# Claude (~/.claude)
echo "==> ~/.claude"
mkdir -p "$HOME/.claude"
link "$DOTFILES_DIR/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/agents"        "$HOME/.claude/agents"
link "$DOTFILES_DIR/claude/commands"      "$HOME/.claude/commands"
link "$DOTFILES_DIR/claude/docs"         "$HOME/.claude/docs"
link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/claude/skills"        "$HOME/.claude/skills"
link "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusLine.sh"
link "$DOTFILES_DIR/claude/hooks"        "$HOME/.claude/hooks"

# claude-notify (通知アプリのビルド)
echo "==> claude-notify"
mkdir -p "$HOME/.claude/bin"
bash "$DOTFILES_DIR/claude/bin/build-claude-notify.sh"

# my-karabiner (ターミナルでCtrl+S押下時に入力ソースをABCへ切り替える常駐ツール)
echo "==> my-karabiner"
bash "$DOTFILES_DIR/bin/my-karabiner/build.sh"

# tmux-ime (tmuxペインのclaude有無で入力ソースを切替する imselect をビルド)
echo "==> tmux-ime"
bash "$DOTFILES_DIR/bin/tmux-ime/build.sh"

# mdtree (カレントディレクトリをGitHub風ファイルツリーUIでブラウザ表示するCLIをビルド)
echo "==> mdtree"
bash "$DOTFILES_DIR/bin/mdtree/build.sh"

# ~/.codex
echo "==> ~/.codex"
mkdir -p "$HOME/.codex"
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"
link "$DOTFILES_DIR/claude/commands"  "$HOME/.codex/prompts"
link "$DOTFILES_DIR/codex/rules"      "$HOME/.codex/rules"

echo "Done."
