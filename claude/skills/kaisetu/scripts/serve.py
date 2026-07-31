#!/usr/bin/env python3
"""kaisetu サーバ。

review-data.json を埋め込んだレビュー画面をローカル配信し、ブラウザを開く。
画面の「レビュー完了」ボタンで結果JSONを書き出す。サーバは終了せず、
画面はその後も閲覧・追加コメント・再送信ができる。
呼び出し側のエージェントは結果JSONの出現を監視して読み、不要になったらプロセスをkillする。

Usage:
  serve.py <review-data.json> [--port N] [--result PATH] [--no-open]
  serve.py <review-data.json> --build [output.html]   # 静的HTMLを出すだけ(サーバなし)

依存: Python 3 標準ライブラリのみ。
"""
import argparse
import json
import os
import pathlib
import socket
import sys
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = pathlib.Path(__file__).resolve().parent.parent


def render(data: dict, state_text: str = "null") -> str:
    template = (ROOT / "template.html").read_text(encoding="utf-8")
    payload = json.dumps(data, ensure_ascii=False)
    # <script>内埋め込みのため、終了タグとして解釈されうる並びをエスケープ
    payload = payload.replace("</", "<\\/")
    state_payload = state_text.replace("</", "<\\/")
    if "__REVIEW_DATA__" not in template or "__REVIEW_STATE__" not in template:
        sys.exit("template.html に __REVIEW_DATA__ / __REVIEW_STATE__ プレースホルダがありません")
    return template.replace("__REVIEW_DATA__", payload).replace("__REVIEW_STATE__", state_payload)


def free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def main() -> None:
    ap = argparse.ArgumentParser(description="kaisetu server")
    ap.add_argument("data", help="review-data.json のパス")
    ap.add_argument("--port", type=int, default=0)
    ap.add_argument("--result", help="結果JSONの出力先(既定: <data>.result.json)")
    ap.add_argument("--no-open", action="store_true", help="ブラウザを自動で開かない")
    ap.add_argument("--build", nargs="?", const="-", metavar="OUT",
                    help="静的HTMLを出力して終了(OUT省略時は <data>.html)")
    args = ap.parse_args()

    data_path = pathlib.Path(args.data).resolve()
    data = json.loads(data_path.read_text(encoding="utf-8"))
    state_path = data_path.with_suffix(".state.json")    # 自動保存(途中経過)。画面はここから復元できる

    def state_text() -> str:
        return state_path.read_text(encoding="utf-8") if state_path.is_file() else "null"

    if args.build is not None:
        out = data_path.with_suffix(".html") if args.build == "-" else pathlib.Path(args.build)
        out.write_text(render(data, state_text()), encoding="utf-8")
        print(out)
        return

    result_path = pathlib.Path(args.result) if args.result else data_path.with_suffix(".result.json")
    replies_path = data_path.with_suffix(".replies.json")  # AIからのコメント回答(画面がポーリングで拾う)
    port = args.port or free_port()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):  # アクセスログは出さない
            pass

        def _json_body(self) -> dict:
            length = int(self.headers.get("Content-Length", 0))
            return json.loads(self.rfile.read(length) or b"{}")

        def _respond(self, code=200, body=b"ok", ctype="text/plain; charset=utf-8"):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path in ("/", "/index.html"):
                # 毎回レンダリングし、最新のstate(コメント途中経過)を埋め込む
                self._respond(200, render(data, state_text()).encode("utf-8"), "text/html; charset=utf-8")
            elif self.path == "/api/replies":
                body = replies_path.read_bytes() if replies_path.is_file() else b"{}"
                self._respond(200, body, "application/json; charset=utf-8")
            elif self.path == "/plan":
                plan = data.get("plan")
                if not plan:
                    self._respond(404, b"plan not set")
                    return
                # 絶対パス / サーバ起動時CWD相対 / データファイル相対 の順で解決
                for base in (pathlib.Path(plan), pathlib.Path.cwd() / plan, data_path.parent / plan):
                    if base.is_file():
                        self._respond(200, base.read_text(encoding="utf-8").encode("utf-8"))
                        return
                self._respond(404, f"plan not found: {plan}".encode("utf-8"))
            else:
                self._respond(404, b"not found")

        def do_POST(self):
            if self.path == "/api/state":
                state_path.write_text(
                    json.dumps(self._json_body(), ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )
                self._respond()
            elif self.path == "/api/finish":
                result_path.write_text(
                    json.dumps(self._json_body(), ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )
                self._respond()
                print(f"finished: {result_path}", flush=True)
            else:
                self._respond(404, b"not found")

    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    url = f"http://127.0.0.1:{port}/"
    print(f"kaisetu: {url}", flush=True)
    print(f"result: {result_path}", flush=True)
    print(f"pid: {os.getpid()}", flush=True)
    if not args.no_open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
