# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリについて

macOS 向けの個人 dotfiles。すべての設定は `setup.sh` がシンボリックリンクとして配置するため、**このリポジトリ内のファイルを編集すれば即座に実環境に反映される**（リンク先を直接編集してはいけない）。リンクの対応は `setup.sh` の「Symlinks」セクションが唯一の正。

## セットアップ

```shell
bash setup.sh            # Homebrew・各種パッケージ・macOS defaults・シンボリックリンクを冪等に適用
```

`setup.sh` は再実行可能。`link()` 関数が既存リンクをスキップ／再リンクし、通常ファイルは `.bak` にバックアップする。パッケージ追加時は `setup.sh` 内の `FORMULAE` / `CASKS` / `NPM_PACKAGES` 等の配列に追記する。

neovim 初回起動後に `:PlugInstall` と `:checkhealth` を実行する。coc.nvim 拡張は `vim/coc/package.json` の `dependencies` で管理し、`setup.sh` が `~/.config/coc/extensions` へインストールする（全て揃っていればスキップする）。

## 規約

- スラッシュコマンドもすべて `claude/skills/` にスキルとして置き、手動でだけ呼ぶものは frontmatter に `disable-model-invocation: true` を付ける。`local-*` は `claude/local/skills/` の実体へのリンクで、マシン固有（gitignore 済み）。
- `bin/tmux-ime/` の Swift を編集したら `build.sh` を再実行する（`swiftc` でビルドして `~/.local/bin` に配置する）。

## 開発時の注意

- テスト・ビルドのフレームワークは無い（個人 dotfiles のため）。動作確認は実際にシェル/tmux/nvim を起動して行う。
- シェルスクリプトは `set -euo pipefail` を基本とする（`setup.sh`, `build.sh` 群に倣う）。
- Claude 設定（`claude/`）を変更した場合、Codex 側（`~/.codex/`）にもリンク経由で反映される点に注意する。`claude/skills` は `~/.agents/skills` として Codex と共有している。
- gitignore 対象（`zsh/.zshrc.local`, `zsh/local`, `vim/autoload/local.vim`, `claude/local/*`）はコミットしない。
