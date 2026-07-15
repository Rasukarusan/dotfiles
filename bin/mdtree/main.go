// mdtree — カレントディレクトリを GitHub 風のファイルツリー UI でブラウザに表示し、
// Markdown はレンダリング、その他のテキストはシンタックスハイライトしてプレビューする CLI。
//
//	mdtree            # カレントディレクトリを開く
//	mdtree ~/any/docs # 指定ディレクトリを開く
//	mdtree -port 8765 # ポート固定(省略時は空きポート自動割り当て)
//	mdtree -no-open   # ブラウザを自動で開かない
package main

import (
	"bytes"
	"embed"
	"encoding/json"
	"flag"
	"fmt"
	"html"
	"io/fs"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"

	chromahtml "github.com/alecthomas/chroma/v2/formatters/html"
	"github.com/alecthomas/chroma/v2/lexers"
	"github.com/alecthomas/chroma/v2/styles"
	"github.com/yuin/goldmark"
	highlighting "github.com/yuin/goldmark-highlighting/v2"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/parser"
	gmhtml "github.com/yuin/goldmark/renderer/html"
	"go.abhg.dev/goldmark/mermaid"
)

//go:embed static
var staticFS embed.FS

// ツリー走査時に除外するディレクトリ/ファイル。zsh の tree エイリアスと揃える。
var ignored = map[string]bool{
	".git":         true,
	"node_modules": true,
	"vendor":       true,
	".next":        true,
	"dist":         true,
	".DS_Store":    true,
}

// root は表示対象のルート絶対パス。サーバ全体で共有する。
var root string

// currentFile はブラウザに表示させたいファイルの root からの相対パス(空なら未選択)。
// サーバーは常駐させ、`/api/open` で切り替えるたびに SSE (`/api/events`) 経由で
// 接続中の全クライアントへ即座にプッシュする。ブラウザをリロードしても
// `/api/current` から今の値を取得できるので表示が消えない。
var (
	currentMu   sync.Mutex
	currentFile string
)

// subscribers は /api/events に接続中の各クライアントへの通知チャネル。
var (
	subMu       sync.Mutex
	subscribers = map[chan string]bool{}
)

// md はコードブロックをハイライトする goldmark インスタンス。
var md = goldmark.New(
	goldmark.WithExtensions(
		extension.GFM,
		extension.Table,
		extension.Strikethrough,
		extension.TaskList,
		highlighting.NewHighlighting(
			highlighting.WithStyle("github"),
		),
		// ```mermaid を <pre class="mermaid"> に変換する。描画は app.js が mermaid.js で行うため
		// ライブラリ側の <script> 挿入は抑止する(innerHTML 挿入では script が実行されないため)。
		&mermaid.Extender{
			RenderMode: mermaid.RenderModeClient,
			NoScript:   true,
		},
	),
	goldmark.WithParserOptions(parser.WithAutoHeadingID()),
	goldmark.WithRendererOptions(gmhtml.WithUnsafe()),
)

func main() {
	port := flag.Int("port", 0, "listen port (0 = auto)")
	noOpen := flag.Bool("no-open", false, "do not open the browser automatically")
	file := flag.String("file", "", "file to open automatically on startup (relative path)")
	// flag.Parse は最初の非フラグ引数でパースを打ち切るため、`mdtree <dir> -file x` のように
	// ディレクトリを先に書くと以降のフラグが無視される。フラグと位置引数を先に振り分けておく。
	flagArgs, posArgs := partitionArgs(os.Args[1:])
	flag.CommandLine.Parse(flagArgs)
	currentFile = filepath.ToSlash(*file)

	// 表示対象ディレクトリを決定(引数 > カレント)。
	target := "."
	if len(posArgs) > 0 {
		target = posArgs[0]
	}
	abs, err := filepath.Abs(target)
	if err != nil {
		log.Fatalf("mdtree: %v", err)
	}
	info, err := os.Stat(abs)
	if err != nil || !info.IsDir() {
		log.Fatalf("mdtree: not a directory: %s", abs)
	}
	root = abs

	sub, err := fs.Sub(staticFS, "static")
	if err != nil {
		log.Fatal(err)
	}

	mux := http.NewServeMux()
	mux.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.FS(sub))))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		data, _ := fs.ReadFile(sub, "index.html")
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Write(data)
	})
	mux.HandleFunc("/api/tree", handleTree)
	mux.HandleFunc("/api/render", handleRender)
	mux.HandleFunc("/api/current", handleCurrent)
	mux.HandleFunc("/api/open", handleOpen)
	mux.HandleFunc("/api/events", handleEvents)

	// 空きポートを取得してから listen。-port 指定時はそれを使う。
	ln, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", *port))
	if err != nil {
		log.Fatalf("mdtree: %v", err)
	}
	url := fmt.Sprintf("http://%s", ln.Addr().String())
	fmt.Printf("mdtree: serving %s\n         %s  (Ctrl-C to quit)\n", root, url)

	if !*noOpen {
		openBrowser(url)
	}
	if err := http.Serve(ln, mux); err != nil {
		log.Fatal(err)
	}
}

// node は JSON で返すツリーノード。
type node struct {
	Name     string  `json:"name"`
	Path     string  `json:"path"` // root からの相対パス("/" 区切り)
	IsDir    bool    `json:"isDir"`
	Children []*node `json:"children,omitempty"`
}

func handleTree(w http.ResponseWriter, r *http.Request) {
	tree, err := buildTree(root, "")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	tree.Name = filepath.Base(root)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(tree)
}

// buildTree は dir 配下を再帰的に走査してツリーを構築する。rel は root からの相対パス。
func buildTree(dir, rel string) (*node, error) {
	n := &node{Name: filepath.Base(dir), Path: rel, IsDir: true}
	entries, err := os.ReadDir(dir)
	if err != nil {
		return n, nil // 読めないディレクトリは空のまま返す(権限エラー等で全体を止めない)
	}
	// ディレクトリ優先、その後名前昇順。
	sort.Slice(entries, func(i, j int) bool {
		di, dj := entries[i].IsDir(), entries[j].IsDir()
		if di != dj {
			return di
		}
		return strings.ToLower(entries[i].Name()) < strings.ToLower(entries[j].Name())
	})
	for _, e := range entries {
		name := e.Name()
		if ignored[name] || strings.HasPrefix(name, ".") && name != ".github" {
			continue
		}
		childRel := name
		if rel != "" {
			childRel = rel + "/" + name
		}
		if e.IsDir() {
			child, _ := buildTree(filepath.Join(dir, name), childRel)
			n.Children = append(n.Children, child)
		} else {
			n.Children = append(n.Children, &node{Name: name, Path: childRel, IsDir: false})
		}
	}
	return n, nil
}

// resolve は root からの相対パスを安全な絶対パスに解決する(path traversal 防止)。
func resolve(rel string) (string, bool) {
	clean := filepath.Clean("/" + filepath.FromSlash(rel))
	abs := filepath.Join(root, clean)
	if abs != root && !strings.HasPrefix(abs, root+string(os.PathSeparator)) {
		return "", false
	}
	return abs, true
}

type renderResp struct {
	Name string `json:"name"`
	Path string `json:"path"`
	Type string `json:"type"` // "markdown" | "code" | "binary"
	HTML string `json:"html"`
}

func handleRender(w http.ResponseWriter, r *http.Request) {
	rel := r.URL.Query().Get("path")
	abs, ok := resolve(rel)
	if !ok {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	info, err := os.Stat(abs)
	if err != nil || info.IsDir() {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	data, err := os.ReadFile(abs)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp := renderResp{Name: filepath.Base(abs), Path: rel}
	ext := strings.ToLower(filepath.Ext(abs))
	switch {
	case ext == ".md" || ext == ".markdown":
		var buf bytes.Buffer
		if err := md.Convert(data, &buf); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		resp.Type = "markdown"
		resp.HTML = buf.String()
	case isBinary(data):
		resp.Type = "binary"
		resp.HTML = fmt.Sprintf("<p class=\"binary-note\">バイナリファイル (%d bytes) はプレビューできません</p>", len(data))
	default:
		resp.Type = "code"
		resp.HTML = highlightCode(abs, string(data))
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(resp)
}

// handleCurrent は現在ブラウザに表示させたいファイルを返す。ページ読み込み直後に呼ばれ、
// サーバー常駐中に(別のタブ/リロード後でも)表示状態を復元するために使う。
func handleCurrent(w http.ResponseWriter, r *http.Request) {
	currentMu.Lock()
	file := currentFile
	currentMu.Unlock()
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]string{"file": file})
}

// handleOpen は表示ファイルを切り替え、接続中の全クライアントへ SSE でプッシュする。
// サーバーを再起動せずにファイルを切り替えられるようにするための API。
func handleOpen(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var body struct {
		Path string `json:"path"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Path == "" {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	path := filepath.ToSlash(body.Path)
	if _, ok := resolve(path); !ok {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	currentMu.Lock()
	currentFile = path
	currentMu.Unlock()
	broadcast(path)
	w.WriteHeader(http.StatusNoContent)
}

// broadcast は接続中の全 SSE クライアントへ path を送る。バッファが詰まっている購読者はスキップする。
func broadcast(path string) {
	subMu.Lock()
	defer subMu.Unlock()
	for ch := range subscribers {
		select {
		case ch <- path:
		default:
		}
	}
}

// handleEvents は Server-Sent Events で表示ファイルの切り替えをブラウザへプッシュする。
// これによりページをリロードしなくても `mdd` での新しい選択が即座に反映される。
func handleEvents(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	ch := make(chan string, 4)
	subMu.Lock()
	subscribers[ch] = true
	subMu.Unlock()
	defer func() {
		subMu.Lock()
		delete(subscribers, ch)
		subMu.Unlock()
	}()

	for {
		select {
		case path := <-ch:
			fmt.Fprintf(w, "data: %s\n\n", path)
			flusher.Flush()
		case <-r.Context().Done():
			return
		}
	}
}

// highlightCode は chroma でソースをハイライトした HTML を返す。レキサ不明時は素のエスケープ。
func highlightCode(path, source string) string {
	lexer := lexers.Match(filepath.Base(path))
	if lexer == nil {
		lexer = lexers.Analyse(source)
	}
	if lexer == nil {
		return "<pre class=\"plain\"><code>" + html.EscapeString(source) + "</code></pre>"
	}
	style := styles.Get("github")
	formatter := chromahtml.New(
		chromahtml.WithClasses(false),
		chromahtml.TabWidth(2),
		chromahtml.WithLineNumbers(true),
	)
	it, err := lexer.Tokenise(nil, source)
	if err != nil {
		return "<pre class=\"plain\"><code>" + html.EscapeString(source) + "</code></pre>"
	}
	var buf bytes.Buffer
	if err := formatter.Format(&buf, style, it); err != nil {
		return "<pre class=\"plain\"><code>" + html.EscapeString(source) + "</code></pre>"
	}
	return buf.String()
}

// isBinary は先頭バイトに NUL が含まれるかでバイナリ判定する。
func isBinary(data []byte) bool {
	n := len(data)
	if n > 8000 {
		n = 8000
	}
	return bytes.IndexByte(data[:n], 0) != -1
}

// partitionArgs は引数を「フラグ(値付きも含む)」と「位置引数」に振り分ける。
// 呼び出し順(`mdtree -file x dir` / `mdtree dir -file x`)に依存させないための前処理。
func partitionArgs(args []string) (flagArgs, posArgs []string) {
	valueFlags := map[string]bool{"-port": true, "--port": true, "-file": true, "--file": true}
	for i := 0; i < len(args); i++ {
		a := args[i]
		if a == "--" {
			posArgs = append(posArgs, args[i+1:]...)
			break
		}
		if strings.HasPrefix(a, "-") {
			flagArgs = append(flagArgs, a)
			if !strings.Contains(a, "=") && valueFlags[a] && i+1 < len(args) {
				i++
				flagArgs = append(flagArgs, args[i])
			}
			continue
		}
		posArgs = append(posArgs, a)
	}
	return
}

// openBrowser は OS に応じたコマンドでブラウザを開く。
func openBrowser(url string) {
	var cmd string
	var args []string
	switch runtime.GOOS {
	case "darwin":
		cmd = "open"
	case "windows":
		cmd, args = "rundll32", []string{"url.dll,FileProtocolHandler"}
	default:
		cmd = "xdg-open"
	}
	args = append(args, url)
	_ = exec.Command(cmd, args...).Start()
}
