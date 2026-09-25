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
  python-yq st jc gh gron lolcat azure-cli rust dasel kind libsixel pipx
  awscli
)
for pkg in "${FORMULAE[@]}"; do
  brew install "$pkg" 2>/dev/null || true
done

# Cask
echo "==> Homebrew cask"
CASKS=(
  google-chrome firefox visual-studio-code iterm2
  docker sequel-ace ngrok java11 couleurs
  another-redis-desktop-manager elasticvue postico
)
for pkg in "${CASKS[@]}"; do
  brew install --cask "$pkg" 2>/dev/null || true
done

# ====================
# nodebrew
# ====================
# formula を入れただけでは ~/.nodebrew が無く node も入らないため、ここで初期化する。
echo "==> nodebrew"
if [ ! -d "$HOME/.nodebrew/src" ]; then
  nodebrew setup
fi
export PATH="$HOME/.nodebrew/current/bin:$PATH"
if ! nodebrew ls | grep -q '^v'; then
  nodebrew install-binary latest
fi
if nodebrew ls | grep -q '^current: none'; then
  nodebrew use latest
fi

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
# Python CLI packages
# ====================
echo "==> Python CLI packages"
PYTHON_CLI_PACKAGES=(
  jedi-language-server flake8 black
)
for pkg in "${PYTHON_CLI_PACKAGES[@]}"; do
  if pipx list --short | grep -q "^$pkg "; then
    pipx upgrade "$pkg"
  else
    pipx install "$pkg"
  fi
done

# ====================
# AWS Session Manager plugin
# ====================
echo "==> AWS Session Manager plugin"
if ! command -v session-manager-plugin &>/dev/null; then
  SSM_PKG="$(mktemp -d)/session-manager-plugin.pkg"
  curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/session-manager-plugin.pkg" -o "$SSM_PKG"
  sudo installer -pkg "$SSM_PKG" -target /
  rm -f "$SSM_PKG"
  sudo ln -sfn /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin
fi

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

# coc.nvim 拡張 (vim/coc/package.json の dependencies を実体としてインストールする)
# coc 起動時の自動インストールは黙って失敗することがあるため、ここで確実に入れる。
echo "==> coc.nvim extensions"
COC_EXT_DIR="$HOME/.config/coc/extensions"
if COC_EXT_DIR="$COC_EXT_DIR" node -e '
  const fs = require("fs");
  const dir = process.env.COC_EXT_DIR;
  const depsOf = (p) => Object.keys(JSON.parse(fs.readFileSync(p + "/package.json", "utf8")).dependencies || {});
  // :CocUpdate は拡張本体だけを差し替えて依存を入れないため、各拡張の dependencies まで確認する
  const installed = (d, from) => fs.existsSync(from + "/node_modules/" + d) || fs.existsSync(dir + "/node_modules/" + d);
  const ok = depsOf(dir).every((ext) => {
    const extDir = dir + "/node_modules/" + ext;
    return fs.existsSync(extDir) && depsOf(extDir).every((d) => installed(d, extDir));
  });
  process.exit(ok ? 0 : 1);
' 2>/dev/null; then
  echo "  skip: all extensions already installed"
else
  # --no-save: package.json は dotfiles へのシンボリックリンクなので npm に書き換えさせない
  npm install --prefix "$COC_EXT_DIR" --omit=dev --no-save --no-package-lock --no-fund --no-audit
fi

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

# kaisetu スキル (別リポジトリ ~/Documents/github/kaisetu で管理)
KAISETU_DIR="$HOME/Documents/github/kaisetu"
if [ -d "$KAISETU_DIR" ]; then
  link "$KAISETU_DIR/kaisetu"      "$DOTFILES_DIR/claude/skills/kaisetu"
  link "$KAISETU_DIR/kaisetu-list" "$DOTFILES_DIR/claude/skills/kaisetu-list"
  link "$KAISETU_DIR/kaisetu-html" "$DOTFILES_DIR/claude/skills/kaisetu-html"
else
  echo "  skip: kaisetu ($KAISETU_DIR not found)"
fi

# claude-notify (通知アプリのビルド)
echo "==> claude-notify"
mkdir -p "$HOME/.claude/bin"
bash "$DOTFILES_DIR/claude/bin/build-claude-notify.sh"

# tmux-ime (tmuxペインのclaude有無で入力ソースを切替する imselect をビルド)
echo "==> tmux-ime"
bash "$DOTFILES_DIR/bin/tmux-ime/build.sh"

# mdtree (カレントディレクトリをGitHub風ファイルツリーUIでブラウザ表示するCLIをビルド)
echo "==> mdtree"
bash "$DOTFILES_DIR/bin/mdtree/build.sh"

# claude-caption (E2E動作確認動画用の字幕オーバーレイをビルド。caption コマンドで操作)
echo "==> claude-caption"
bash "$DOTFILES_DIR/bin/claude-caption/build.sh"

# ~/.codex
echo "==> ~/.codex"
mkdir -p "$HOME/.codex"
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"
link "$DOTFILES_DIR/claude/commands"  "$HOME/.codex/prompts"
link "$DOTFILES_DIR/codex/rules"      "$HOME/.codex/rules"

# Claude Code のカスタムスキルを Codex でも共有する
mkdir -p "$HOME/.agents"
link "$DOTFILES_DIR/claude/skills" "$HOME/.agents/skills"

# ====================
# 前のPCから持ってくるもの
# ====================
# git 管理外でこのスクリプトでも生成できないため、旧マシンから手でコピーする必要があるもの。
echo ""
echo "==> 前のPCから持ってくるもの"
MANUAL_ITEMS=(
  "$HOME/.ssh|SSH 鍵・config"
  "$HOME/.aws|AWS の認証情報・プロファイル設定"
  "$DOTFILES_DIR/zsh/.zshrc.local|マシン固有の zsh 設定 (~/.zshrc.local の実体)"
  "$DOTFILES_DIR/claude/local|Claude のマシン固有設定 (CLAUDE.md / commands)"
  "$HOME/scripts/local|scripts リポジトリのマシン固有スクリプト"
  "$HOME/Documents/プロフィール画像|プロフィール画像"
  "$HOME/docs|調査書・仕様書の保存先"
  "$HOME/account.json|各種サービスのAPIトークン (bin/github, bin/chatwork などが参照)"
  "$HOME/danger_words.txt|check_danger_input が検査する流出禁止ワード一覧"
)
MISSING_COUNT=0
for item in "${MANUAL_ITEMS[@]}"; do
  path="${item%%|*}"
  desc="${item#*|}"
  display="${path/#$HOME/~}"
  if [ -e "$path" ]; then
    echo "  ok  : $display"
  else
    echo "  要コピー: $display  ($desc)"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done
if [ "$MISSING_COUNT" -gt 0 ]; then
  echo ""
  echo "  上記 $MISSING_COUNT 件を旧マシンからコピーしてください。例:"
  echo "    rsync -av --progress <旧マシン>:<コピー元> <コピー先>"
fi

echo "Done."
