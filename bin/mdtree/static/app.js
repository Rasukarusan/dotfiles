'use strict';

const treeEl = document.getElementById('tree');
const contentEl = document.getElementById('content');
const breadcrumbEl = document.getElementById('breadcrumb');
const repoNameEl = document.getElementById('repo-name');
const filterEl = document.getElementById('filter');
const showAllEl = document.getElementById('show-all-files');

let currentPath = null;

// ---- ツリー描画 -----------------------------------------------------------

function fileExt(name) {
  return name.includes('.') ? name.split('.').pop().toLowerCase() : '';
}

function isMarkdown(name) {
  const ext = fileExt(name);
  return ext === 'md' || ext === 'markdown';
}

function fileIcon(name) {
  const ext = fileExt(name);
  if (ext === 'md' || ext === 'markdown') return '📝';
  if (['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'ico'].includes(ext)) return '🖼️';
  if (['json', 'yml', 'yaml', 'toml'].includes(ext)) return '⚙️';
  return '📄';
}

function renderTree(node, container, depth) {
  if (!node.children) return;
  for (const child of node.children) {
    if (child.isDir) {
      const details = document.createElement('details');
      details.className = 'dir';
      // 最上位も含めて閉じておく。表示すべきファイルがあれば openFile() 側で
      // その親フォルダだけを展開する。

      const summary = document.createElement('summary');
      summary.style.paddingLeft = (depth * 14 + 8) + 'px';
      summary.innerHTML = `<span class="twisty"></span><span class="icon">📁</span><span class="label">${escapeHtml(child.name)}</span>`;
      details.appendChild(summary);

      const inner = document.createElement('div');
      renderTree(child, inner, depth + 1);
      details.appendChild(inner);
      container.appendChild(details);
    } else {
      const a = document.createElement('a');
      a.className = 'file';
      a.dataset.path = child.path;
      a.dataset.name = child.name.toLowerCase();
      a.dataset.md = isMarkdown(child.name) ? '1' : '0';
      a.style.paddingLeft = (depth * 14 + 22) + 'px';
      a.innerHTML = `<span class="icon">${fileIcon(child.name)}</span><span class="label">${escapeHtml(child.name)}</span>`;
      a.addEventListener('click', (e) => {
        e.preventDefault();
        openFile(child.path);
      });
      container.appendChild(a);
    }
  }
}

function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// ---- ファイルプレビュー ---------------------------------------------------

async function openFile(path) {
  if (path === currentPath) return;
  currentPath = path;

  // 選択状態のハイライト
  document.querySelectorAll('.file.active').forEach((el) => el.classList.remove('active'));
  const link = document.querySelector(`.file[data-path="${cssEscape(path)}"]`);
  if (link) {
    link.classList.add('active');
    // 折りたたまれた親 details を開く
    let p = link.parentElement;
    while (p && p !== treeEl) {
      if (p.tagName === 'DETAILS') p.open = true;
      p = p.parentElement;
    }
  }

  renderBreadcrumb(path);
  contentEl.classList.add('loading');

  try {
    const res = await fetch('/api/render?path=' + encodeURIComponent(path));
    if (!res.ok) throw new Error(await res.text());
    const data = await res.json();
    contentEl.className = 'content ' + (data.type === 'markdown' ? 'markdown-body' : 'code-view');
    contentEl.innerHTML = data.html;
    contentEl.scrollTop = 0;
    document.title = data.name + ' — mdtree';
    await renderMermaid();
  } catch (err) {
    contentEl.className = 'content';
    contentEl.innerHTML = `<div class="error">読み込みに失敗しました: ${escapeHtml(String(err))}</div>`;
  }
}

// ---- Mermaid 図の描画 -----------------------------------------------------
// goldmark-mermaid が出力した <pre class="mermaid"> を、同梱の mermaid.js で描画する。
// mermaid 本体は index.html の <script> で読み込み済み(window.mermaid)。

let mermaidReady = false;

async function renderMermaid() {
  const nodes = contentEl.querySelectorAll('pre.mermaid:not([data-processed])');
  if (!nodes.length) return;
  if (!window.mermaid) return; // 読み込み失敗時は素のテキストのまま残す
  try {
    if (!mermaidReady) {
      window.mermaid.initialize({ startOnLoad: false, theme: 'default', securityLevel: 'loose' });
      mermaidReady = true;
    }
    await window.mermaid.run({ nodes });
  } catch (err) {
    nodes.forEach((n) => {
      n.dataset.processed = 'error';
      n.insertAdjacentHTML('afterend', `<div class="error">Mermaid の描画に失敗しました: ${escapeHtml(String(err))}</div>`);
    });
  }
}

function renderBreadcrumb(path) {
  const parts = path.split('/');
  breadcrumbEl.innerHTML = parts
    .map((p, i) => `<span class="${i === parts.length - 1 ? 'crumb current' : 'crumb'}">${escapeHtml(p)}</span>`)
    .join('<span class="sep">/</span>');
}

function cssEscape(s) {
  return s.replace(/["\\]/g, '\\$&');
}

// ---- フィルタ -------------------------------------------------------------

// テキスト検索(絞り込み)と「すべてのファイルを表示」チェックボックス(既定は md のみ表示)を
// 合わせて適用する。テキスト検索中は既存どおり全ディレクトリを展開する。
function applyFilters() {
  const q = filterEl.value.trim().toLowerCase();
  const showAll = showAllEl.checked;
  const searching = !!q;

  treeEl.classList.toggle('filtering', searching);

  const files = treeEl.querySelectorAll('.file');
  files.forEach((f) => {
    const matchesQuery = !q || f.dataset.name.includes(q);
    const matchesType = showAll || f.dataset.md === '1';
    f.style.display = matchesQuery && matchesType ? '' : 'none';
  });

  const dirs = treeEl.querySelectorAll('details');
  if (searching) {
    dirs.forEach((d) => { d.open = true; });
  }
  dirs.forEach((d) => {
    const visible = d.querySelector('.file:not([style*="none"])');
    d.style.display = visible ? '' : 'none';
  });
}

filterEl.addEventListener('input', applyFilters);
showAllEl.addEventListener('change', applyFilters);

// ---- サイドバーのリサイズ -------------------------------------------------

(function setupResizer() {
  const resizer = document.getElementById('resizer');
  const sidebar = document.getElementById('sidebar');
  let dragging = false;
  resizer.addEventListener('mousedown', () => { dragging = true; document.body.style.cursor = 'col-resize'; document.body.style.userSelect = 'none'; });
  window.addEventListener('mousemove', (e) => {
    if (!dragging) return;
    const w = Math.min(Math.max(e.clientX, 180), 600);
    sidebar.style.width = w + 'px';
  });
  window.addEventListener('mouseup', () => { dragging = false; document.body.style.cursor = ''; document.body.style.userSelect = ''; });
})();

// ---- 初期化 ---------------------------------------------------------------

// サーバーが選択中のファイルを切り替えたら(mdd での新しい選択、または別タブでの操作)
// リロードなしで追従して開く。
async function openPushedFile(path) {
  if (!path) return;
  if (!isMarkdown(path)) {
    showAllEl.checked = true; // md以外のファイルを開く場合はサイドバーでも見えるようにする
    applyFilters();
  }
  await openFile(path);
}

function connectEvents() {
  const es = new EventSource('/api/events');
  es.onmessage = (e) => { openPushedFile(e.data); };
  // 接続が切れてもブラウザ標準の EventSource が自動的に再接続を試みる。
}

(async function init() {
  try {
    const res = await fetch('/api/tree');
    const tree = await res.json();
    repoNameEl.textContent = tree.name;
    document.title = tree.name + ' — mdtree';
    renderTree(tree, treeEl, 0);
    applyFilters();

    // サーバー常駐中に選択されていたファイルを復元する(リロードしても消えない)。
    try {
      const cur = await (await fetch('/api/current')).json();
      await openPushedFile(cur.file);
    } catch (err) {
      // 取得に失敗しても致命的ではないので無視する。
    }

    connectEvents();
  } catch (err) {
    treeEl.innerHTML = `<div class="error">ツリーの取得に失敗しました</div>`;
  }
})();
