---
name: pr-approved
description: 自分が作った open な PR のうち、approve が 2 件以上ついているのにまだマージしていないものを一覧にする。「approve 2件あるのにマージしてない PR 出して」「マージ待ちの PR ある？」「/pr-approved」で使う。
---

自分が author の open な PR から、approve が 2 件以上ついているものを出す。

## 取得

次をそのまま実行する。`latestOpinionatedReviews` はレビュアーごとの最新の判定なので、approve 後に Request changes した人は数えない。

```bash
gh api graphql -f query='
query {
  search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 100) {
    nodes {
      ... on PullRequest {
        number title url isDraft mergeStateStatus
        repository { nameWithOwner }
        latestOpinionatedReviews(first: 20) { nodes { state author { login } } }
      }
    }
  }
}' --jq '.data.search.nodes[]
  | {repo: .repository.nameWithOwner, number, title, url, isDraft, mergeStateStatus,
     approvers: [.latestOpinionatedReviews.nodes[] | select(.state == "APPROVED") | .author.login]}
  | select(.approvers | length >= 2)'
```

引数で件数 (例: `/pr-approved 1`) を指定されたら、`>= 2` をその数に置き換える。

## 出力

- リポジトリごとに表にする。列は PR 番号 (リンク)・タイトル・approve した人・マージ可否。
- マージ可否は `mergeStateStatus` を次のように書く: `CLEAN` → マージ可、`BLOCKED` → ブロック中 (CI・必須レビュー待ち)、`BEHIND` → ベース遅れ、`DIRTY` → コンフリクト、`UNSTABLE` → CI 失敗あり、`UNKNOWN` → 未判定 (GitHub 側で計算中)、それ以外はそのまま。
- draft の PR はタイトルの前に「[draft]」を付ける。
- 該当が 0 件なら「該当する PR はない」とだけ書く。
- マージはしない。一覧を出すだけにする。
