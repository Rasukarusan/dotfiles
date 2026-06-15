# local-llm — 構築・運用手順書

Docker だけで完結する、ローカル隔離（`127.0.0.1` 束縛）の LLM 環境。
OpenAI 互換 API を `http://127.0.0.1:11434` に提供する。

> この README はそのまま手順書として使える。上から順にコマンドを実行すれば構築できる。
> 各ステップに「確認コマンド」と「期待される結果」を書いてあるので、結果が一致しない場合は
> 末尾の「トラブルシュート」を参照すること。

---

## 0. このディレクトリの構成

```
local-llm/
├── docker-compose.yml            # base: ollama(API) + model-init(自動DL) + open-webui(UI)
├── docker-compose.override.yml   # 自動マージされる「実用モード」設定
├── .env                          # モデル名・ポート設定
└── README.md                     # このファイル
```

### 隔離モデル（必読）

このリポジトリの隔離は **ポートを `127.0.0.1`（loopback）のみに束縛する** ことで担保する:

- LAN の他マシンからはアクセス不可
- 推論（チャット）は完全ローカルで動作し、プロンプトは外部送信されない
- 外向き通信が起きるのは「初回のモデル/イメージ DL」と「ollama の更新チェック等の軽微なもの」だけ

`docker-compose.override.yml` は **`docker compose up` で自動マージ**され、モデルの常駐設定
（`OLLAMA_KEEP_ALIVE`）を足すだけ。どのコマンドでもホストからアクセスできる:

| コマンド | 適用ファイル | 用途 |
|---|---|---|
| `docker compose up -d` | base + override | **普段の利用**（モデル常駐でレスポンス安定） |
| `docker compose -f docker-compose.yml up -d` | base のみ | override を外したい時（挙動はほぼ同じ） |

> **補足（重要）**: 当初は override で `internal: true`（ネットワーク遮断）にして外部を物理遮断する
> 設計だったが、**Docker Desktop では internal ネットワークだとホストへのポート公開が無効化され、
> ホストから API/UI に一切アクセスできなくなる**ため廃止した。完全な物理遮断が必要なら
> 「内部ネット + リバースプロキシ」構成を別途用意すること。
>
> 重み(モデル)は named volume `ollama-data` に保存されるので、一度DLすればオフラインでも推論できる。

---

## 1. 前提

- Docker / Docker Compose v2 が動くこと。確認:

  ```sh
  docker compose version
  ```
  → `Docker Compose version v2.x.x` 等が表示されればOK。エラーなら Docker Desktop を起動する。

- 作業ディレクトリはこのフォルダ（`local-llm/`）であること。以降のコマンドはここで実行する。

- ディスク空き容量: 既定モデル `qwen3.5:4b` で約 3.4GB（`.env` で変更可）。

- **メモリ**: モデルはロード時に重み相当のメモリを使う。Docker Desktop の割当(設定 → Resources → Memory)
  に注意。目安は `4b`≒4GB / `9b`≒7GB の空きが必要。**他にコンテナを多数動かしている場合はその分も加算**
  されるので、足りないと `llama-server process has terminated: signal: killed`（OOM）で失敗する。
  その場合は割当を増やすか、軽いモデル（`.env` の `MODEL`）に変える。

---

## 2. 初回構築（モデルDLが必要なので base のみで起動）

```sh
# 外部接続を許可して起動（override を無視して base のみ）
docker compose -f docker-compose.yml up -d

# モデルDLの進捗を見る（完了すると model-init は exit 0 で終了する）
docker compose -f docker-compose.yml logs -f model-init
```

**確認:** モデルが入ったか:

```sh
docker compose exec ollama ollama list
```
→ 一覧に `.env` の `MODEL`（既定 `qwen3.5:4b`）が出ればDL成功。

---

## 3. 普段の運用モードへ切り替え

DL完了を確認したら、override(実用モード)を適用して起動し直す:

```sh
docker compose down
docker compose up -d        # override が自動適用 = モデル常駐(KEEP_ALIVE)
```

**確認:** API がホストから叩けること:

```sh
docker compose exec ollama ollama list   # モデル一覧が出ればOK
docker port local-llm-ollama             # 11434/tcp -> 127.0.0.1:11434 と出れば公開OK
```
→ 隔離は `127.0.0.1` 束縛で担保（LAN からは不可）。DL済みなのでオフラインでも推論できる。

---

## 4. 動作確認（APIを叩く）

ホスト（Mac/PC側）のターミナルから:

```sh
curl http://127.0.0.1:11434/v1/chat/completions -d '{
  "model": "qwen3.5:4b",
  "messages": [{"role": "user", "content": "こんにちは。あなたは誰?"}]
}'
```
→ JSON で日本語の応答が返ればOK。

> **注意（qwen3.5 系は推論モデル）**: 既定の `qwen3.5` は内部で長い思考(thinking)を行うため、
> 1回の応答に時間がかかり、`max_tokens` を小さくすると思考だけで打ち切られ本文が空になることがある。
> **短く速く答えさせたい場合は thinking を切る**（OpenAI 互換ではなく ollama ネイティブ API を使う）:
>
> ```sh
> curl http://127.0.0.1:11434/api/chat -d '{
>   "model": "qwen3.5:4b",
>   "messages": [{"role": "user", "content": "日本の首都は?"}],
>   "think": false, "stream": false
> }'
> ```

ブラウザUI: http://127.0.0.1:3300 （`open-webui`。不要なら base の該当サービスを削除可）

OpenAI SDK から使う場合は `base_url` を差し替えるだけ:

```python
from openai import OpenAI
client = OpenAI(base_url="http://127.0.0.1:11434/v1", api_key="dummy")
res = client.chat.completions.create(
    model="qwen3.5:4b",
    messages=[{"role": "user", "content": "こんにちは"}],
)
print(res.choices[0].message.content)
```

---

## 5. モデルの変更・追加

### 5-1. 既定モデルを変える

`.env` の `MODEL` を書き換え、起動してDL:

```sh
# .env を編集（例: MODEL=qwen3.5:9b）
docker compose -f docker-compose.yml up -d
docker compose -f docker-compose.yml logs -f model-init   # DL待ち
docker compose down && docker compose up -d               # 実用モードに戻す
```

### 5-2. モデルを追加する（既定は変えない）

```sh
docker compose exec ollama ollama pull llama3.1:8b
```

### おすすめモデル（日本語）

| タグ | 用途 | メモリ目安 |
|---|---|---|
| `qwen3.5:4b` | 軽量・低スペック（既定） | 約3.4GB |
| `qwen3.5:9b` | バランス | 約6.6GB（空き7GB+推奨） |
| `qwen3.5:27b` | 品質重視 | 約17GB |
| `gemma3:4b` | 低スペック汎用 | 約3GB |

日本語特化モデル（Swallow等）は Hugging Face の GGUF を直接実行:
```sh
docker compose exec ollama ollama run hf.co/mmnga/Llama-3.1-Swallow-8B-Instruct-v0.3-gguf
```

---

## 6. 停止・破棄

```sh
docker compose down            # 停止（モデルは残る）
docker compose down -v         # ボリュームごと完全削除（モデルも消える）
```

---

## 7. トラブルシュート

| 症状 | 原因 | 対処 |
|---|---|---|
| `llama-server process has terminated: signal: killed` | **メモリ不足(OOM)**。モデルがロードできない | Docker Desktop の Memory 割当を増やす（設定 → Resources）。または `.env` の `MODEL` を軽いものに |
| 応答が空 / 返ってこない | qwen3.5 は推論モデルで思考が長い。`max_tokens` が小さいと思考だけで打ち切られる | `max_tokens` を増やす、または `api/chat` で `"think": false`（§4 参照） |
| `ollama list` にモデルが出ない | DL未完了 or 失敗 | `docker compose -f docker-compose.yml up -d` で起動し `logs -f model-init` で進捗確認 |
| `curl localhost:11434` が繋がらない | ollama 未起動 / 起動直後 | `docker compose ps` で `ollama` が healthy か、`docker port local-llm-ollama` で公開を確認 |
| ホストから繋がらない / `Ports` が空 | `internal: true` 等でネットワークを internal 化している | internal ネットワークは Docker Desktop でポート公開が無効化される。override から internal を外す |
| WebUI(3300) のポート衝突 | 別コンテナが同ポート使用 | `.env` の `WEBUI_PORT` を変更（例: 3300） |
| 他PCからアクセスしたい | ポートが 127.0.0.1 束縛 | 意図的な仕様（隔離）。LAN公開したい場合のみ compose の ports を `0.0.0.0:` に変更 |

---

## 8. セキュリティ要約

- ホストのディレクトリは **一切 bind mount していない** → コンテナからローカルファイルは見えない。
- 推論は完全ローカル → プロンプト/チャットは外部送信されない。
- ポートは `127.0.0.1` 束縛 → LAN の他マシンからアクセス不可（これが隔離の主軸）。
- 外部通信が発生するのは「モデル/イメージのダウンロード」と「ollama の更新チェック等の軽微なもの」だけ。
  推論そのものは一切外部に出ない。
- **完全な物理遮断（egress ゼロ）が必要な場合**: `internal: true` 単体ではホストから使えなくなるため、
  「内部ネット(ollama) + リバースプロキシ(公開担当)」の2ネットワーク構成を別途用意すること。
