# crit セットアップ手順

[crit](https://github.com/tomasz-tomczyk/crit) を**手動ビルド**し、**公式プラグイン(`claude plugin install`)を使わず**に
dotfiles(git管理下)へ直接組み込む手順。Plan Mode承認時の自動レビューフックまで再現する。

## 全体像

| 項目 | 場所 | 役割 |
|---|---|---|
| バイナリ | `~/.local/bin/crit` | 手動ビルドしたCLI本体(PATH上に置く) |
| スキル | `dotfiles/claude/skills/crit/`, `crit-cli/` | `/crit` コマンド + crit-cli スキル |
| 自動フック | `dotfiles/claude/settings.json` の `hooks.PermissionRequest` | ExitPlanMode時に `crit plan-hook` を自動起動 |

`~/.claude/skills` と `~/.claude/settings.json` は dotfiles へのsymlinkなので、
dotfiles側を編集すればそのままClaude Codeに反映される。

## 前提

- Go(`brew install go`)。crit は `go.mod` で **Go 1.26+** を要求するが、
  `GOTOOLCHAIN=auto`(デフォルト)なら古いGoでも必要ツールチェーンを自動DLしてビルドできる。
- `~/.local/bin` が PATH に通っていること(フック/スキルは「PATH上の `crit`」を呼ぶため必須)。

## 1. clone & build

```bash
mkdir -p ~/Documents/github
cd ~/Documents/github
git clone https://github.com/tomasz-tomczyk/crit.git
cd crit
git checkout v0.16.3          # ← タグ固定(セキュリティ/再現性のため)
make build                    # = go generate ./... + go build。素の go build は不可
```

> 最新タグは `git ls-remote --tags --sort=-v:refname https://github.com/tomasz-tomczyk/crit.git` で確認。
> バイナリのリリースは v0.16.x 系。プラグインのバージョン(1.7.x)とは別物。

## 2. バイナリをPATHへ

```bash
cp ~/Documents/github/crit/crit ~/.local/bin/crit
crit --version                # 動作確認
```

## 3. スキルをdotfilesへ

```bash
SRC=~/Documents/github/crit/integrations/claude-code/skills
DST=~/dotfiles/claude/skills
mkdir -p "$DST/crit" "$DST/crit-cli"
cp "$SRC/crit/SKILL.md"     "$DST/crit/SKILL.md"
cp "$SRC/crit-cli/SKILL.md" "$DST/crit-cli/SKILL.md"
```

## 4. 自動フックをsettings.jsonへ

`dotfiles/claude/settings.json` の `hooks` に以下を追加(既存設定済み):

```json
"PermissionRequest": [
  {
    "matcher": "ExitPlanMode",
    "hooks": [
      { "type": "command", "command": "crit plan-hook", "timeout": 345600 }
    ]
  }
]
```

- `timeout` は 345600秒(4日)。プラグイン定義に忠実な値。レビュー完了までClaudeは待機する。
  長すぎる場合は短縮可(例: `1800` で30分)。

## 5. 反映

settings.json/スキルの変更は**Claude Codeを再起動**してから有効になる。

## 動作確認

- Plan Modeで計画を立てさせ、承認の瞬間にブラウザでcritのレビュー画面が開けばOK。
- 手動: 任意のgitリポジトリで `crit` を実行 → ブラウザでコメント → Finish Review。

## 更新方法

```bash
cd ~/Documents/github/crit
git fetch --tags
git checkout <新しいタグ>
make build
cp crit ~/.local/bin/crit
# スキルが更新されていれば手順3を再実行。`crit check` でスキルの陳腐化を検出できる。
```

## CLI 利用フロー(参考)

```bash
crit                       # 現在のgit差分をレビュー(デフォルト)
crit plan.md               # 特定ファイル(計画書など)
crit --pr 123              # GitHub PR
crit --range main..HEAD    # コミット範囲
crit live http://localhost:3000   # 起動中Webアプリ
crit preview index.html    # ローカルHTML

# レビュー後、コメントに返信(サーバ不要)
crit comment --reply-to <id> --author '自分' '修正しました'
crit stop --all            # デーモン停止
```

レビューは「`crit` で開く → ブラウザでコメント → Finish Review → 出力JSONを読んで直す → 同じ引数で `crit` 再実行」の反復ループ。
同じ引数で再実行すると既存デーモンに再接続する(引数が違うと別デーモンが立つ)。

## プライバシー / セキュリティ

- デフォルトで `127.0.0.1` バインド・テレメトリなし。外部送信は起動時のバージョンチェックのみ
  (`CRIT_NO_UPDATE_CHECK=1` で無効化)。
- `crit share` は明示的に叩いた時だけ crit.md へdiff/コードをアップロードする。機密リポジトリでは使わない。
