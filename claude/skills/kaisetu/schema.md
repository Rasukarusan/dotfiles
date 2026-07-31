# review-data.json スキーマ

`scripts/serve.py` に渡すレビューデータの仕様。LLMはこのJSONだけを生成し、HTMLはテンプレートが描画する。

```jsonc
{
  "title": "app/system URL整理の未ステージ差分レビュー", // 画面タイトル
  // tagline / overview は「技術的な説明 ＝ その結果どうなるか」の形で書く(＝は全角)。
  // ＝ の右側は画面上で別スタイルになる。詳しくは下の「概要の書き方」を参照。
  "tagline": "URLの組み立てを1か所に集約するリファクタリング ＝ 移行後もリンク切れが起きないようにする準備",
  "overview": "- URL生成とhost判定をresolveAppUrlに集約 ＝ URLの作り方が1か所になり直し忘れがなくなる\n- …",
  "generatedAt": "2026-07-25 09:30",                    // 生成日時(手で書く。JSでは取らない)
  "base": "main..HEAD + unstaged",                      // 差分の取得範囲の説明
  "plan": "plans/url-cleanup.md",                       // 参照したplan(リポジトリルートからの相対パス)。無ければ null。画面ではリンクになり /plan で中身が開く
  "repoRoot": "/Users/me/repos/myapp",                  // 対象リポジトリの絶対パス(/kaisetu-list がレビュー再開時の基準パスに使う)
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

## 概要の書き方(tagline / overview)

**1行に「エンジニアに分かる説明」と「非エンジニアにも伝わる結果」の両方を書き、全角の `＝` で結ぶ。**

```
散在していたURL生成とホスト判定を resolveAppUrl に集約 ＝ URLの作り方が1か所になり、直し忘れによるリンク切れがなくなる
```

- `＝` の左: 今までどおりの技術的な説明(関数名・モジュール名を使ってよい)
- `＝` の右: **その結果どうなるのか**を、コードを読まない人に分かる言葉で。
  機能・利用者・運用にとって何が変わるかを書く。専門用語・ファイル名・関数名は使わない
- `tagline` は右側が2行目として、`overview` の各行は右側が続きとして、それぞれ別スタイルで表示される
- 半角の `=` では分割されない(コード中の `=` を巻き込まないため)。結果が書けない行は `＝` なしでよい

## 粒度の指針

- **group** = 変更の意図(リスク評価の単位)
- **section** = 機能ごとのまとまり(解説の単位)。「このセクションを読めばその機能の変更が一通り分かる」大きさにする
- **annotation** = 行レベルの補足。全hunkに付ける必要はない

## 一覧用メタ(meta.json)

`/kaisetu-list` が一覧表示に使う小さなファイル。review-data.json と同じディレクトリに置く。
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
スレッドの該当位置に「AI 回答」として表示される(サーバ配信時のみ)。

コメントは**スレッド**になっている。`replies[i]` が、そのスレッドの i 番目(0始まり)の人間発言への回答。
人間が回答に返信すると人間発言が増えるので、**既存の replies.json を読んで `replies` 配列に追記する**
(過去の回答を消すと画面から消える)。

```jsonc
{
  "comments": [
    {
      "key": "h081:2",            // key は result.json の comments[].key をそのまま使う
      "replies": [
        "修正済み: ポート付きhostも許容するようにしました。",  // 1つ目の指摘への回答
        "IPv6は未対応です。必要ならURL.hostnameで正規化します。" // 返信への回答
      ]
    }
  ],
  "groupComments": [
    { "group": "g1", "replies": ["ご指摘のとおりです。設計は〜"] }
  ],
  "docComments": [
    { "target": "overview", "replies": ["3点に絞り、legacy-pathの話を先頭にしました。"] }
  ]
}
```

## 解説文へのコメント

diff行と同じように、AIが書いた解説文にもマウスを乗せると `+` が出てコメントできる。
コメントの置き場所は3つ:

| 対象 | 結果JSON | 書き直すフィールド |
|---|---|---|
| 概要 | `docComments` の `target: "overview"` | `tagline` / `overview` |
| グループの意図 | `groupComments` の `group: "<gid>"` | そのグループの `intent` / `impact` |
| AI解説(セクション) | `docComments` の `target: "section:<sid>"` | そのセクションの `title` / `explain` |

「ここ分かりにくい、書き直して」という依頼なら、**review-data.json の該当フィールドを書き直して保存するだけ**。
サーバがファイルを読み直し、画面が更新を検知して作り直す(コメントは保持される)。

**`groups[].id` / `sections[].id` / `hunks` の構成は変えない。**
コメントは hunk ID と行番号にぶら下がっているので、差分の構成を変えると位置がずれる。

## 結果ファイル(review-data.result.json)

画面の「レビュー完了」で書き出される。コメントは人間発言とAI回答を交互に並べたスレッドで入る。

```jsonc
{
  "title": "…",
  "finished": true,
  "comments": [
    {
      "key": "h081:2",
      "file": "webapp/src/lib/url-config.ts",
      "line": "L12",
      "code": " export const userUrlMode = env.USER_URL_MODE;",
      "messages": [
        { "role": "human", "text": "ここ、ポート付きhostだと弾かれない?" },
        { "role": "ai",    "text": "修正済み: 〜" },
        { "role": "human", "text": "ではIPv6は?" }   // ← 末尾が human = 未回答
      ],
      "resolved": false,
      "awaiting": true            // 未解決かつ末尾が人間発言(=回答が必要)
    }
  ],
  "groupComments": [
    { "group": "g1", "messages": [ … ], "resolved": false, "awaiting": true }
  ],
  "docComments": [                // AIが書いた解説文(概要・セクション解説)へのコメント
    { "target": "overview", "label": "概要", "messages": [ … ], "resolved": false, "awaiting": true }
  ],
  "markdown": "…"                 // 人間可読なまとめ(スレッドを入れ子の箇条書きで表現)
}
```

## 描画ルール(テンプレート側の挙動)

- グループは `risk` 順 (high → medium → low) に表示される。JSON内の順序はリスク順に並べておくこと(同リスク内の順序はJSONの順序を維持)。
- sectionの `explain` は、そのsectionの最初のhunkの先頭に「AI解説」コメントとして表示される。
- `annotations` の `type: "question"` があるグループは一覧で「疑問」バッジが付く。
- 人間コメントは localStorage とサーバの state.json に保存される。localStorageのキーは差分の構成
  (hunk IDと本文)から作るので、解説文を書き直してもコメントは保持される。
- コメントはスレッド。AI回答の下に「返信」ボタンが出て、人間が続けて書ける。
  末尾が人間発言のスレッドには「AIの回答待ち」と表示され、ヘッダーのコメント件数に「未回答 N」が出る。
- review-data.json を書き直すと、画面が数秒で検知して作り直す(コメント入力中は
  「画面に反映する」バーが出るだけで、勝手には作り直さない)。
