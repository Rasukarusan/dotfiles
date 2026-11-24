# zsh + tmux + Neovim

macOS の作業環境を再構築するための dotfiles です。

## セットアップ

リポジトリのルートで実行します。

```shell
bash setup.sh
```

`setup.sh` は次の処理をおこないます。何度実行しても同じ結果になります。

- Homebrew と開発ツール・GUI アプリのインストール
- macOS のシステム設定の変更
- Zsh・tmux・Neovim・Claude Code・Codex などの設定ファイルへのシンボリックリンク作成（既存のファイルは `.bak` を付けて退避）
- coc.nvim 拡張機能のインストール（[`vim/coc/package.json`](vim/coc/package.json) の `dependencies`）

システム設定も変更するため、初回は実行前に [`setup.sh`](setup.sh) の内容を確認してください。

実行後に Neovim を起動し、次のコマンドを順に実行します。

```vim
:PlugInstall
:checkhealth
```

## Claude Code・Codex のスキル

[`claude/skills`](claude/skills) に置きます。`~/.claude/skills` と `~/.agents/skills` の両方からリンクされるため、Claude Code と Codex で同じスキルを使えます。

## Chrome の設定

拡張機能ツールバーメニューを有効にします。

1. Chrome で `chrome://flags/` を開きます。
2. `Extensions Toolbar Menu` を有効にします。
