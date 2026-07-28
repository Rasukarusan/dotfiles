# review-data.json スキーマ

`scripts/serve.py` に渡すレビューデータの仕様。LLMはこのJSONだけを生成し、HTMLはテンプレートが描画する。

```jsonc
{
  "title": "app/system URL整理の未ステージ差分レビュー", // 画面タイトル
  "tagline": "URLの組み立てを1か所に集約するリファクタリング", // PRの一言説明。多少不正確でも全体が掴める粒度で。概要の最初に大きく表示される
  "overview": "- URL生成とhost判定をresolveAppUrlに集約\n- …", // 全体で何をやっているかの箇条書き(- 始まり・改行区切りで3〜5点)。taglineの下に表示される
  "generatedAt": "2026-07-25 09:30",                    // 生成日時(手で書く。JSでは取らない)
  "base": "main..HEAD + unstaged",                      // 差分の取得範囲の説明
  "plan": "plans/url-cleanup.md",                       // 参照したplan(リポジトリルートからの相対パス)。無ければ null。画面ではリンクになり /plan で中身が開く
  "repoRoot": "/Users/me/repos/myapp",                  // 対象リポジトリの絶対パス(/kaisetsu-list がレビュー再開時の基準パスに使う)
  "stats": { "files": 107, "hunks": 268, "additions": 1468, "deletions": 812 },
  "groups": [
    {
      "id": "g1",                       // 一意なID (g1, g2, ...)
      "title": "URL・ホスト判定の共通基盤",
      "intent": "deployment modeごとのURL生成とhost判定を一か所に集約し…", // 変更の意図(1〜3文)
      "impact": "legacy-pathでも通る基盤コードなので、影響範囲は広め。",     // 影響範囲の補足(任意)
      "risk": "high",                   // "high"(要注意) | "medium"(注意) | "low"(低リスク)
      "tags": ["refactor"],             // feat / fix / refactor / test / docs / chore など
      "sections": [
        // 機能ごとのまとまった単位。解説はこの単位で書く。
        // 同じファイルのhunkが複数のセクション/グループに分かれて登場してよい。
        {
          "id": "s1",                              // 一意なID (s1, s2, ...)
          "title": "URL生成の共通入口 resolveAppUrl の新設",
          "explain": "URL生成をこの関数に一元化し、subdomain/legacy-pathの分岐を集約しています。呼び出し側は…", // まとまった解説(数文)
          "hunks": [
            {
              "id": "h079",                                    // 一意なID (h001, h002, ...)
              "file": "webapp/src/lib/auth.subdomain.test.ts", // リポジトリルートからのパス
              "diff": "@@ -1,10 +1,13 @@\n import Cookies from 'js-cookie';\n+import { vi } from 'vitest';\n-import { save } from './auth';",
              // ↑ 1行目が @@ ヘッダ、以降がhunk本文の unified diff (git diff の該当hunkをそのまま)
              "annotations": [
                // 行レベルの補足が必要な箇所だけに付ける(まとまった説明はsectionのexplainへ)
                {
                  "type": "explain",              // "explain"(解説) | "question"(疑問・人間に確認したい点)
                  "match": "import { vi }",       // アンカー: この文字列を含む最初のhunk本文行の直後に表示
                  "line": 2,                      // または hunk本文の行番号(1始まり、@@行は含まない)。matchが優先
                  "text": "vitestのモックAPIへ移行するためのimport追加。"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## 粒度の指針

- **group** = 変更の意図(リスク評価の単位)
- **section** = 機能ごとのまとまり(解説の単位)。「このセクションを読めばその機能の変更が一通り分かる」大きさにする
- **annotation** = 行レベルの補足。全hunkに付ける必要はない

## 一覧用メタ(meta.json)

`/kaisetsu-list` が一覧表示に使う小さなファイル。review-data.json と同じディレクトリに置く。
値はすべて review-data.json の同名フィールドの複製(一覧側がdiff全文をパースせずに済むようにするためのもの)。

```jsonc
{
  "title": "app/system URL整理の未ステージ差分レビュー",
  "tagline": "URLの組み立てを1か所に集約するリファクタリング",
  "repoRoot": "/Users/me/repos/myapp",
  "generatedAt": "2026-07-25 09:30"
}
```

## 回答ファイル(review-data.replies.json)

人間コメントへのAI回答。レビューデータと同じディレクトリに置くと、画面が数秒ごとに自動で拾い、
該当コメントの下に「回答」として表示される(サーバ配信時のみ)。

```jsonc
{
  "comments": [
    { "key": "h081:2", "text": "修正済み: ポート付きhostも許容するようにしました。" }
    // key は result.json の comments[].key をそのまま使う
  ],
  "groupComments": [
    { "group": "g1", "text": "ご指摘のとおりです。設計は〜" }
  ]
}
```

## 描画ルール(テンプレート側の挙動)

- グループは `risk` 順 (high → medium → low) に表示される。JSON内の順序はリスク順に並べておくこと(同リスク内の順序はJSONの順序を維持)。
- sectionの `explain` は、そのsectionの最初のhunkの先頭に「AI解説」コメントとして表示される。
- `annotations` の `type: "question"` があるグループは一覧で「疑問」バッジが付く。
- 人間コメント(diff行・グループ)は localStorage に保存される(キーはJSON内容のハッシュ。データを作り直すと状態はリセットされる)。
