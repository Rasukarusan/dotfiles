# zsh + tmux + Neovim

macOS の作業環境を再構築するための dotfiles です。

`setup.sh` を実行すると、Homebrew と各種パッケージを導入し、macOS の設定を変更したうえで、このリポジトリの設定ファイルへシンボリックリンクを張ります。
既存の設定ファイルがある場合は、同じ場所に `.bak` を付けて退避します。

## セットアップ

リポジトリのルートで、次のコマンドを実行します。

```shell
bash setup.sh
```

このスクリプトは、開発ツールや GUI アプリのインストールに加え、Zsh、tmux、Vim、Neovim、Claude Code、Codex などの設定を所定の場所へリンクします。
Homebrew の導入やシステム設定の変更も含むため、実行前に [`setup.sh`](setup.sh) の内容を確認してください。

Claude Code のカスタムスキルは [`claude/skills`](claude/skills) で管理します。
このディレクトリは `~/.claude/skills` と `~/.agents/skills` の両方から参照されるため、同じスキルをClaude CodeとCodexで利用できます。

## Neovim の初期設定

スクリプトの実行後に Neovim を起動し、次のコマンドを順に実行します。

```vim
:PlugInstall
:checkhealth
```

coc.nvim の拡張機能は [`vim/coc/package.json`](vim/coc/package.json) で管理しています。
このファイルは所定の場所へリンクされ、拡張機能は Neovim の初回起動時に自動でインストールされます。

## Chrome の設定

拡張機能ツールバーメニューを有効にします。

1. Chrome で `chrome://flags/` を開きます。
2. `Extensions Toolbar Menu` を有効にします。
