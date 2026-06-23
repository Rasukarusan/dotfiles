# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリについて

macOS 向けの個人 dotfiles。`zsh` + `tmux` + `neovim` のシェル環境に加えて、Claude Code / Codex の設定を一元管理する。すべての設定は `setup.sh` がシンボリックリンクとして配置するため、**このリポジトリ内のファイルを編集すれば即座に実環境に反映される**（リンク先を直接編集してはいけない）。

## セットアップ

```shell
bash setup.sh            # Homebrew・各種パッケージ・macOS defaults・シンボリックリンクを冪等に適用
```

`setup.sh` は再実行可能。`link()` 関数が既存リンクをスキップ／再リンクし、通常ファイルは `.bak` にバックアップする。パッケージ追加時は `setup.sh` 内の `FORMULAE` / `CASKS` / `NPM_PACKAGES` 等の配列に追記する。

neovim 初回起動後に `:PlugInstall` と `:checkhealth` を実行する。coc.nvim 拡張は `vim/coc/package.json` で管理され初回起動時に自動インストールされる。

## 全体構成

シンボリックリンクのマッピングは `setup.sh` の「Symlinks」セクションが唯一の正。主要な対応は以下。

| リポジトリ内 | リンク先 | 役割 |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` | zsh エントリポイント |
| `terminal/tmux.conf` | `~/.tmux.conf` | tmux 設定（prefix は `C-s`） |
| `terminal/git/gitconfig` | `~/.gitconfig` | git 設定 |
| `vim/init.vim` | `~/.vimrc`, `~/.config/nvim/init.vim` | neovim 設定 |
| `claude/*` | `~/.claude/*` | Claude Code 設定一式 |
| `claude/CLAUDE.md`, `claude/commands`, `codex/rules` | `~/.codex/*` | Codex は Claude 設定を再利用 |

### zsh/
- `zshrc` が各ファイルを source する。実体は `alias.zsh`（エイリアス）、`function.zsh`（90以上の関数、多くが fzf 連携で `_` 始まり）、`exports.zsh`（環境変数）、`settings.zsh`、`zsh-my-theme.zsh`。
- `.zshrc.local` / `zsh/local/` は gitignore 済み（マシン固有設定）。
- fzf を多用したインタラクティブな git / docker / tmux 操作が `function.zsh` の中心。

### claude/ — Claude Code 設定（リポジトリの主要構成要素）
- `CLAUDE.md`: グローバル指示（日本語回答・一人称「私」・tmux pane 操作ルール）。`claude/local/CLAUDE.md`（gitignore 済み）を追加読み込みする。
- `settings.json`: 権限（allow/deny）、hooks、statusLine、`effortLevel: high` などのハーネス設定。
- `commands/`: スラッシュコマンド（`.md` ファイル）。`commands/local/` はマシン固有。
- `skills/`: スキル（`crit`, `review-all`, `keihi`, `humanizer-ja` など）。
- `agents/`: サブエージェント定義（`conflict-resolver`, `lint-runner` など）。
- `hooks/`: シェルスクリプトの hook（`notify-*.sh` = 通知、`track-research*.sh` = リサーチ追跡）。
- `bin/build-claude-notify.sh`: Swift 製の通知アプリをビルドして `~/.claude/bin` に配置（`setup.sh` から呼ばれる）。

### bin/ — 自作 CLI / 常駐ツール
スクリプト（zsh/bash/perl）と、`setup.sh` がビルドする Swift 製常駐ツールが混在する。
- `my-karabiner/`, `tmux-ime/`: Swift 製。`build.sh` が `swiftc` でビルドし `.app` バンドル化 + LaunchAgent 登録する（TCC 入力監視権限を確実に効かせるため `.app` 化が必須）。Swift を編集したら該当 `build.sh` を再実行する。
- `tmux-*`: tmux ペイン操作・ファイルピッカー連携スクリプト。

### local-llm/
Docker Compose によるローカル LLM 環境（`docker-compose.yml` + `.override.yml`）。詳細は `local-llm/README.md`。

## 開発時の注意

- テスト・ビルドのフレームワークは無い（個人 dotfiles のため）。動作確認は実際にシェル/tmux/nvim を起動して行う。
- シェルスクリプトは `set -euo pipefail` を基本とする（`setup.sh`, `build.sh` 群に倣う）。
- Claude 設定（`claude/`）を変更した場合、Codex 側（`~/.codex/`）にもリンク経由で反映される点に注意する。
- gitignore 対象（`zsh/.zshrc.local`, `zsh/local`, `vim/autoload/local.vim`, `claude/local/*`）はコミットしない。
