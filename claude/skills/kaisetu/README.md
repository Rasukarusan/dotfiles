# kaisetu

差分を「意図ごとのグループ × リスク順 × AI解説つき」で表示する、自作のレビュー画面 + エージェントスキル。
Claude Codeでは `/kaisetu`、Codexでは `$kaisetu` として呼ぶとローカルサーバが立ち、ブラウザでレビュー →「レビュー完了」で結果がセッションへ返る。

**レビュー(良し悪しの判断)は人間の仕事。AIは差分を読みやすく整理し、解説を付けるところまで。**

## 特徴

- **意図ごとのグループ分け**: rename + 関連import修正 = 1グループ。ファイル順ではなく**リスク順**に表示
- **AI解説**: グループ内を機能ごとのセクションに分けて解説。行レベルの補足が必要な箇所には 解説 / 疑問(AIにも意図がつかめなかった箇所・確認したい点) をdiff行に直接表示
- **人間のレビューを回収**: diff行への直接コメントとグループ単位のコメント(右上のボタンから一覧をサイドバー表示)。「レビュー完了」で結果JSONがClaudeへ、「まとめをコピー」で別セッション(Codex等)へ
- **スレッドで往復**: コメントにはAIの回答が画面上に返ってくる。回答の下の「返信」で会話を続け、再度「レビュー完了」で送り返せる。未回答のスレッドは件数表示に「未回答 N」として出る

## 構成

| ファイル | 役割 |
|---|---|
| `SKILL.md` | `/kaisetu` スキル本体(差分整理と画面起動の手順) |
| `schema.md` | LLMが生成する `review-data.json` の仕様 |
| `template.html` | レビュー画面(自己完結・依存なし) |
| `scripts/serve.py` | ローカルサーバ(Python3標準ライブラリのみ)。`--build` で静的HTML出力も可 |
| `example/sample-data.json` | 動作確認用サンプル |

## セットアップ

`dotfiles/claude/skills/kaisetu/` に置く。`~/.claude/skills` と `~/.agents/skills` はdotfilesへのsymlinkなので、Claude CodeとCodexの両方へ反映される。
各クライアントを再起動するとスキルが使えるようになる。

## 手動での動作確認

```bash
python3 scripts/serve.py example/sample-data.json          # サーバ起動 + ブラウザが開く
python3 scripts/serve.py example/sample-data.json --build  # 静的HTMLを出力するだけ
```

## フロー

```
/kaisetu [範囲]
  → Claudeが差分を収集し、planを踏まえて意図単位にグループ化・解説付け
  → review-data.json 生成 → serve.py 起動 → ブラウザが開く
  → 人間: 行コメント / グループコメント
  → 「レビュー完了」→ サーバが review-data.result.json を書く(サーバは動き続ける)
  → Claudeが結果を読み、対応して review-data.replies.json に回答を書く(画面のスレッドに出る)
  → 人間が「返信」して再送信 … を必要なだけ往復 → 終わったらサーバをkill
```

過去のレビューは `~/.kaisetu/<リポジトリ>/<日時>/` に残り、`/kaisetu-list` で一覧・再開できる。
