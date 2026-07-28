# kaisetsu

差分を「意図ごとのグループ × リスク順 × AI解説つき」で表示する、自作のレビュー画面 + Claude Codeスキル。
critのように `/kaisetsu` で呼ぶとローカルサーバが立ち、ブラウザでレビュー →「レビュー完了」で結果がセッションへ返る。

**レビュー(良し悪しの判断)は人間の仕事。AIは差分を読みやすく整理し、解説を付けるところまで。**

## 特徴

- **意図ごとのグループ分け**: rename + 関連import修正 = 1グループ。ファイル順ではなく**リスク順**に表示
- **AI解説**: グループ内を機能ごとのセクションに分けて解説。行レベルの補足が必要な箇所には 解説 / 疑問(AIにも意図がつかめなかった箇所・確認したい点) をdiff行に直接表示
- **人間のレビューを回収**: diff行への直接コメントとグループ単位のコメント(右上のボタンから一覧をサイドバー表示)。「レビュー完了」で結果JSONがClaudeへ、「まとめをコピー」で別セッション(Codex等)へ

## 構成

| ファイル | 役割 |
|---|---|
| `SKILL.md` | `/kaisetsu` スキル本体(差分整理と画面起動の手順) |
| `schema.md` | LLMが生成する `review-data.json` の仕様 |
| `template.html` | レビュー画面(自己完結・依存なし) |
| `scripts/serve.py` | ローカルサーバ(Python3標準ライブラリのみ)。`--build` で静的HTML出力も可 |
| `example/sample-data.json` | 動作確認用サンプル |

## セットアップ

`dotfiles/claude/skills/kaisetsu/` に置く(`~/.claude/skills` はdotfilesへのsymlinkなのでそのまま反映される)。
Claude Codeを再起動すると `/kaisetsu` が使えるようになる。

## 手動での動作確認

```bash
python3 scripts/serve.py example/sample-data.json          # サーバ起動 + ブラウザが開く
python3 scripts/serve.py example/sample-data.json --build  # 静的HTMLを出力するだけ
```

## フロー

```
/kaisetsu [範囲]
  → Claudeが差分を収集し、planを踏まえて意図単位にグループ化・解説付け
  → review-data.json 生成 → serve.py 起動 → ブラウザが開く
  → 人間: 行コメント / グループコメント
  → 「レビュー完了」→ サーバが review-data.result.json を書く(サーバは動き続け、追加コメントの再送信も可)
  → Claudeが結果を読み、コメントに対応 → やりとりが終わったらサーバをkill
```

過去のレビューは `~/.diff-review/<リポジトリ>/<日時>/` に残り、`/kaisetsu-list` で一覧・再開できる。
