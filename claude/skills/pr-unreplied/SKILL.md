---
name: pr-unreplied
description: open な PR のうち、返信していないコメントがあるものを、そのコメントと一緒に一覧にする。自分が作った PR と、自分が関わっている他の人の PR を分けて出す。「返信してないコメントある PR 出して」「未返信のコメント一覧」「/pr-unreplied」で使う。
---

open な PR から、返信していないコメントを集める。対象は、自分が author の PR と、自分が関わっている (コメントした・メンションされた) 他の人の PR。他の人の PR は、自分の最新のレビューが Approve のものを除く。

返信していないコメントは次の 2 種類とする。bot のコメントは数えない。

- レビュースレッド: 未解決 (Resolved でない) で、最後のコメントが自分以外のもの。他の人の PR では、自分がコメントしたかメンションされたスレッドに限る
- 会話タブのコメント: 自分が最後に書いたコメントより後に、自分以外が書いたもの。他の人の PR で自分が会話タブに書いていなければ、自分をメンションしたコメントに限る

## 取得

次をそのまま実行する。`section` が `mine` なら自分の PR、`others` なら他の人の PR。

```bash
gh api graphql -f query='
fragment pr on PullRequest {
  number title url isDraft
  author { login }
  repository { nameWithOwner }
  latestReviews(first: 50) { nodes { author { login } state } }
  reviewThreads(first: 100) {
    nodes {
      isResolved isOutdated path line
      comments(first: 40) { nodes { author { login __typename } body url } }
    }
  }
  comments(last: 50) { nodes { author { login __typename } body url } }
}
query {
  viewer { login }
  mine: search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) { nodes { ...pr } }
  others: search(query: "is:pr is:open involves:@me -author:@me archived:false", type: ISSUE, first: 50) { nodes { ...pr } }
}' --jq '
  .data.viewer.login as $me
  | def other: .author.login != $me and .author.__typename != "Bot";
    def mentions_me: (.body // "") | test("@" + $me + "\\b"; "i");
    def collect($section):
      {section: $section, repo: .repository.nameWithOwner, number, title, url, isDraft, author: .author.login,
       threads: [.reviewThreads.nodes[]
         | select(.isResolved | not)
         | select(.comments.nodes[-1] | other)
         | select($section == "mine" or any(.comments.nodes[]; .author.login == $me or mentions_me))
         | {path, line, isOutdated, comments: [.comments.nodes[] | {author: .author.login, body, url}]}],
       conversation: ((.comments.nodes | map(.author.login) | rindex($me)) as $i
         | [.comments.nodes[(if $i == null then 0 else $i + 1 end):][]
            | select(other)
            | select($section == "mine" or $i != null or mentions_me)
            | {author: .author.login, body, url}])}
      | select((.threads | length) + (.conversation | length) > 0);
    (.data.mine.nodes[] | collect("mine")),
    (.data.others.nodes[]
      | select(any(.latestReviews.nodes[]; .author.login == $me and .state == "APPROVED") | not)
      | collect("others"))'
```

## 出力

- 「自分の PR」と「他の人の PR」の 2 つの節に分ける。該当が 0 件の節は「未返信のコメントはない」とだけ書く。
- PR ごとに見出しを立てる。見出しは `リポジトリ#番号 タイトル` で PR へのリンクにし、draft ならタイトルの前に「[draft]」を付ける。他の人の PR では見出しの末尾に `(author)` を添える。
- 見出しの下に、未返信のコメントを番号付きで並べる。レビュースレッドは `path:line` (outdated なら「(outdated)」を添える)、会話タブのコメントは「会話」と書き、続けてコメントへのリンクを置く。
- コメント本文は要約せずそのまま引用する。スレッドに複数のコメントがあるときは、上から順に `author: 本文` で全部出す。
- 返信はしない。一覧を出すだけにする。
