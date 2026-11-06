#!/usr/bin/env python3
"""X (旧Twitter) のポスト・スレッド・記事を Markdown にして標準出力へ出す。

x.com は通常の取得をボットとして弾くため、fxtwitter API を使う。
1. /2/thread/{id}  本人の連投をまとめて取る
2. /status/{id}    1件ずつ取り、返信元を遡って本人の連投を組み立てる
3. 公式 oEmbed     最後の手段。長文は途中で切れる
"""
import json
import re
import sys
import urllib.parse
import urllib.request

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
)
X_HOSTS = {"x.com", "twitter.com", "mobile.twitter.com", "fxtwitter.com", "vxtwitter.com", "fixupx.com"}
MAX_POSTS = 50


def get_json(url):
    req = urllib.request.Request(url, headers={"user-agent": UA, "accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            return json.load(res)
    except Exception:
        return None


def parse_url(url):
    u = urllib.parse.urlparse(url if "://" in url else "https://" + url)
    host = u.hostname.removeprefix("www.").lower() if u.hostname else ""
    if host not in X_HOSTS:
        return None, None
    if m := re.search(r"/status(?:es)?/(\d+)", u.path):
        return "status", m.group(1)
    if m := re.search(r"/i/article/(\d+)", u.path):
        return "article", m.group(1)
    return None, None


def fetch_status(id_):
    data = get_json(f"https://api.fxtwitter.com/status/{id_}")
    return (data or {}).get("tweet")


def fetch_thread(id_):
    data = get_json(f"https://api.fxtwitter.com/2/thread/{id_}")
    thread = [t for t in ((data or {}).get("thread") or []) if t.get("text") is not None]
    return thread[:MAX_POSTS] or None


def parent_id(tweet):
    value = tweet.get("replying_to_status_id") or tweet.get("replying_to_status")
    if isinstance(value, (str, int)):
        m = re.search(r"\d{5,}", str(value))
        return m.group(0) if m else None
    if isinstance(value, dict):
        m = re.search(r"\d{5,}", str(value.get("id", ""))) or re.search(r"/status/(\d+)", value.get("url", ""))
        return m.group(m.lastindex or 0) if m else None
    return None


def same_author(a, b):
    aa, ba = a.get("author") or {}, b.get("author") or {}
    if aa.get("id") and ba.get("id"):
        return aa["id"] == ba["id"]
    return bool(aa.get("screen_name")) and (aa.get("screen_name", "").lower() == ba.get("screen_name", "").lower())


def ancestor_thread(tweet, id_):
    """返信元を遡り、同じ本人の連投部分を集める（v2 が使えないとき用）。"""
    thread, seen, cur = [tweet], {id_}, tweet
    while len(thread) < MAX_POSTS:
        pid = parent_id(cur)
        if not pid or pid in seen:
            break
        seen.add(pid)
        parent = fetch_status(pid)
        if not parent or not same_author(tweet, parent):
            break
        thread.insert(0, parent)
        cur = parent
    return thread


def format_article(article):
    lines = [f"# {article.get('title') or 'X の記事'}", ""]
    content = article.get("content")
    if isinstance(content, str):
        lines.append(content.strip())
    else:
        blocks = ((article.get("content_state") or content or {}).get("blocks")) or []
        for b in blocks:
            text = (b.get("text") or "").strip()
            if not text:
                continue
            kind = b.get("type") or ""
            if "header-one" in kind:
                lines += [f"## {text}", ""]
            elif "header" in kind:
                lines += [f"### {text}", ""]
            elif "list" in kind:
                lines.append(f"- {text}")
            elif "blockquote" in kind:
                lines += [f"> {text}", ""]
            else:
                lines += [text, ""]
        if not blocks and article.get("preview_text"):
            lines.append(article["preview_text"].strip())
    return "\n".join(lines).strip()


def media_lines(tweet):
    out = []
    for m in ((tweet.get("media") or {}).get("all")) or []:
        if m.get("type") == "photo":
            out.append(f"- 画像: {m.get('url')}")
        else:
            out.append(f"- 動画: {m.get('url')}（サムネ: {m.get('thumbnail_url')}）")
    return out


def header(tweet):
    a = tweet.get("author") or {}
    parts = [f"**{a.get('name', '?')}** (@{a.get('screen_name', '?')})", tweet.get("created_at") or ""]
    return " · ".join(p for p in parts if p)


def format_tweet(tweet, depth=0):
    lines = [header(tweet), "", (tweet.get("text") or "").strip()]
    if art := tweet.get("article"):
        lines += ["", format_article(art)]
    if media := media_lines(tweet):
        lines += [""] + media
    card = tweet.get("twitter_card") or tweet.get("card")
    if isinstance(card, dict) and card.get("url"):
        lines += ["", f"- リンクカード: {card.get('title') or ''} {card.get('url')}".rstrip()]
    if (quote := tweet.get("quote")) and depth == 0:
        q = format_tweet(quote, depth + 1)
        lines += ["", "引用ポスト:", ""] + [f"> {l}" if l else ">" for l in q.splitlines()]
        if quote.get("url"):
            lines.append(f"> {quote['url']}")
    if cn := tweet.get("community_note"):
        note = cn.get("text") if isinstance(cn, dict) else cn
        if note:
            lines += ["", f"コミュニティノート: {note}"]
    return "\n".join(lines).strip()


def stats(tweet):
    keys = [("likes", "いいね"), ("reposts", "RP"), ("retweets", "RP"), ("quotes", "引用"), ("replies", "返信"), ("bookmarks", "ブクマ"), ("views", "表示")]
    vals = [f"{label} {tweet[k]}" for k, label in keys if tweet.get(k) is not None]
    return " / ".join(vals)


def render_thread(thread, target_id):
    root = thread[0]
    a = root.get("author") or {}
    out = [f"# {a.get('name', '?')} (@{a.get('screen_name', '?')}) のポスト", ""]
    out.append(f"- URL: {next((t.get('url') for t in thread if t.get('id') == target_id), root.get('url'))}")
    out.append(f"- 件数: {len(thread)}")
    if s := stats(root):
        out.append(f"- 反応(先頭): {s}")
    for i, t in enumerate(thread, 1):
        mark = "（指定ポスト）" if t.get("id") == target_id and len(thread) > 1 else ""
        out += ["", "---", "", f"## {i}/{len(thread)}{mark}", "", format_tweet(t)]
    return "\n".join(out)


def oembed(url):
    u = urllib.parse.urlparse(url)
    norm = urllib.parse.urlunparse(u._replace(netloc="twitter.com", query=""))
    data = get_json("https://publish.twitter.com/oembed?" + urllib.parse.urlencode({"url": norm, "omit_script": 1, "lang": "ja", "dnt": "true"}))
    if not data or not data.get("html"):
        return None
    text = re.sub(r"<br\s*/?>", "\n", data["html"])
    text = re.sub(r"<[^>]+>", "", text)
    import html
    return f"# {data.get('author_name', '?')} のポスト（oEmbed: 長文は途中で切れる）\n\n{html.unescape(text).strip()}"


def main():
    if len(sys.argv) < 2:
        print("usage: fetch.py <x.com URL>", file=sys.stderr)
        return 2
    url = sys.argv[1]
    kind, id_ = parse_url(url)
    if not kind:
        print(f"X のポスト/記事 URL ではない: {url}", file=sys.stderr)
        return 2

    if kind == "article":
        for ep in (f"https://api.fxtwitter.com/i/article/{id_}", f"https://api.fxtwitter.com/status/{id_}"):
            data = get_json(ep) or {}
            art = data.get("article") or (data.get("tweet") or {}).get("article")
            if art:
                print(format_article(art))
                return 0
        print("記事を取得できなかった", file=sys.stderr)
        return 1

    thread = fetch_thread(id_)
    if not thread:
        tweet = fetch_status(id_)
        thread = ancestor_thread(tweet, id_) if tweet else None
    if thread:
        print(render_thread(thread, id_))
        return 0
    if text := oembed(url):
        print(text)
        return 0
    print("ポストを取得できなかった（削除・非公開・API 障害の可能性）", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
