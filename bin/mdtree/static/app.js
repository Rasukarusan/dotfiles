'use strict';

const treeEl = document.getElementById('tree');
const contentEl = document.getElementById('content');
const breadcrumbEl = document.getElementById('breadcrumb');
const repoNameEl = document.getElementById('repo-name');
const filterEl = document.getElementById('filter');

let currentPath = null;

// ---- ツリー描画 -----------------------------------------------------------

function fileIcon(name) {
  const ext = name.includes('.') ? name.split('.').pop().toLowerCase() : '';
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
      if (depth < 1) details.open = true; // 最上位だけ開いておく

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
// goldmark-mermaid が出力した <pre class="mermaid"> を、CDN の mermaid.js で描画する。
// ライブラリは初回の図表示時に動的 import で遅延ロードする。

let mermaidLib = null;

async function renderMermaid() {
  const nodes = contentEl.querySelectorAll('pre.mermaid:not([data-processed])');
  if (!nodes.length) return;
  try {
    if (!mermaidLib) {
      mermaidLib = (await import('https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs')).default;
      mermaidLib.initialize({ startOnLoad: false, theme: 'default', securityLevel: 'loose' });
    }
    await mermaidLib.run({ nodes });
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

filterEl.addEventListener('input', () => {
  const q = filterEl.value.trim().toLowerCase();
  const files = treeEl.querySelectorAll('.file');
  if (!q) {
    treeEl.classList.remove('filtering');
    files.forEach((f) => (f.style.display = ''));
    treeEl.querySelectorAll('details').forEach((d) => (d.style.display = ''));
    return;
  }
  treeEl.classList.add('filtering');
  // まず全ディレクトリを開く
  treeEl.querySelectorAll('details').forEach((d) => { d.open = true; d.style.display = ''; });
  files.forEach((f) => {
    f.style.display = f.dataset.name.includes(q) ? '' : 'none';
  });
  // マッチを含まないディレクトリは隠す
  treeEl.querySelectorAll('details').forEach((d) => {
    const visible = d.querySelector('.file:not([style*="none"])');
    d.style.display = visible ? '' : 'none';
  });
});

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

(async function init() {
  try {
    const res = await fetch('/api/tree');
    const tree = await res.json();
    repoNameEl.textContent = tree.name;
    document.title = tree.name + ' — mdtree';
    renderTree(tree, treeEl, 0);
  } catch (err) {
    treeEl.innerHTML = `<div class="error">ツリーの取得に失敗しました</div>`;
  }
})();
