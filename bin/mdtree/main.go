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
	flag.Parse()

	// 表示対象ディレクトリを決定(引数 > カレント)。
	target := "."
	if flag.NArg() > 0 {
		target = flag.Arg(0)
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
