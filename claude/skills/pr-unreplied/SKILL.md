---
name: pr-unreplied
description: 自分が作った open な PR のうち、返信していないコメントがあるものを、そのコメントと一緒に一覧にする。「返信してないコメントある PR 出して」「未返信のコメント一覧」「/pr-unreplied」で使う。
---

自分が author の open な PR から、返信していないコメントを集める。返信していないコメントは次の 2 種類とする。

- レビュースレッド: 未解決 (Resolved でない) で、最後のコメントが自分でも bot でもないもの
- 会話タブのコメント: 自分が最後に書いたコメントより後に、自分以外 (bot を除く) が書いたもの

## 取得

次をそのまま実行する。

```bash
gh api graphql -f query='
query {
  viewer { login }
  search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) {
    nodes {
      ... on PullRequest {
        number title url isDraft
        repository { nameWithOwner }
        reviewThreads(first: 100) {
          nodes {
            isResolved isOutdated path line
            comments(first: 50) { nodes { author { login __typename } body url } }
          }
        }
        comments(last: 50) { nodes { author { login __typename } body url } }
      }
    }
  }
}' --jq '
  .data.viewer.login as $me
  | .data.search.nodes[]
  | {repo: .repository.nameWithOwner, number, title, url, isDraft,
     threads: [.reviewThreads.nodes[]
       | select(.isResolved | not)
       | select(.comments.nodes[-1].author.login != $me)
       | select(.comments.nodes[-1].author.__typename != "Bot")
       | {path, line, isOutdated, comments: [.comments.nodes[] | {author: .author.login, body, url}]}],
     conversation: ((.comments.nodes | map(.author.login) | rindex($me)) as $i
       | [.comments.nodes[(if $i == null then 0 else $i + 1 end):][]
          | select(.author.login != $me and .author.__typename != "Bot")
          | {author: .author.login, body, url}])}
  | select((.threads | length) + (.conversation | length) > 0)'
```

## 出力

- PR ごとに見出しを立てる。見出しは `リポジトリ#番号 タイトル` で PR へのリンクにし、draft ならタイトルの前に「[draft]」を付ける。
- 見出しの下に、未返信のコメントを番号付きで並べる。レビュースレッドは `path:line` (outdated なら「(outdated)」を添える)、会話タブのコメントは「会話」と書き、続けてコメントへのリンクを置く。
- コメント本文は要約せずそのまま引用する。スレッドに複数のコメントがあるときは、上から順に `author: 本文` で全部出す。
- 該当が 0 件なら「未返信のコメントはない」とだけ書く。
- 返信はしない。一覧を出すだけにする。
