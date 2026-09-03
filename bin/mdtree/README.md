# mdtree

カレントディレクトリを **GitHub 風のファイルツリー UI** でブラウザに表示し、
Markdown はレンダリング、その他のソースはシンタックスハイライトしてプレビューする CLI。

## 使い方

```sh
mdtree              # カレントディレクトリを開く
mdtree ~/any/docs   # 指定ディレクトリを開く
mdtree -port 8765   # ポート固定(省略時は空きポートを自動割り当て)
mdtree -no-open     # ブラウザを自動で開かない
mdtree -file a/b.md # 起動時にそのファイルを自動で開く(相対パス)
```

起動するとローカル HTTP サーバが立ち上がり、ブラウザが自動で開く。`Ctrl-C` で終了。

## 機能

- 左サイドバー: ディレクトリツリー（展開/折りたたみ、絞り込み検索、幅リサイズ可能）
- 右ペイン: 選択ファイルのプレビュー
  - `.md` / `.markdown` … goldmark で GitHub 風にレンダリング（GFM・テーブル・タスクリスト対応）
  - Mermaid（` ```mermaid ` ブロック）… 図として描画（sequenceDiagram・flowchart など。mermaid.js をバイナリに同梱しオフラインで動作）
  - その他のテキスト … chroma でシンタックスハイライト
  - バイナリ … プレビュー不可の旨を表示
- 表示中のファイルを編集して保存すると、リロードなしで自動反映される（スクロール位置は維持）
- `.git` / `node_modules` / `vendor` / `dist` / `.next` などは除外
- GitHub 風のライトテーマ

## 自動反映のしくみ

サーバは表示中のファイルの mtime とサイズを 400ms 間隔で監視し、変化したら
SSE (`/api/events`) で `change` を通知する。ブラウザはその通知で本文だけを
再取得して差し替えるため、スクロール位置と選択状態はそのまま残る。
一時ファイルへ書いて `rename` するエディタの保存や、削除→再作成も更新として扱う。
`mdd` での別ファイル選択は同じ SSE の `select` で通知される。

## 構成

- `main.go` … HTTP サーバ。`static/` を `embed` で同梱した単一バイナリ
- `static/` … フロント（`index.html` / `style.css` / `app.js`）
- `build.sh` … `go build` して `~/.local/bin/mdtree` に配置（`setup.sh` から呼ばれる）

## ビルド

```sh
bash build.sh
```
