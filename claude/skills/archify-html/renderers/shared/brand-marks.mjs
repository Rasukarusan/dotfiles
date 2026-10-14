import net from 'node:net';
import { BRAND_MARKS } from './generated-brand-marks.mjs';
import { throwDiagnosticError } from './diagnostics.mjs';
import { esc, textUnits } from './utils.mjs';

const COLLECTIONS = Object.freeze({
  architecture: 'components',
  workflow: 'nodes',
  sequence: 'participants',
  dataflow: 'nodes',
  lifecycle: 'states',
});
const MARK_BY_LOOKUP = new Map();
const MARK_BY_DOMAIN = new Map();
const RESOLVED_BY_NODE = new WeakMap();
const RESOLVED_MARK = Symbol('archify.brandMark');
const MAX_CAPTURE_CONCURRENCY = 3;

function lookupForms(value) {
  const raw = String(value ?? '').trim().toLocaleLowerCase('en-US');
  if (!raw) return [];
  const dashed = raw.replace(/[\s_]+/g, '-');
  const compact = raw.replace(/[\s_.-]+/g, '');
  return [...new Set([raw, dashed, compact])];
}

for (const mark of BRAND_MARKS) {
  for (const value of [mark.id, mark.title, ...mark.aliases]) {
    for (const form of lookupForms(value)) {
      if (!MARK_BY_LOOKUP.has(form)) MARK_BY_LOOKUP.set(form, mark);
    }
  }
  for (const domain of mark.domains) MARK_BY_DOMAIN.set(domain, mark);
}

function asUrl(value) {
  try {
    const url = new URL(String(value));
    return ['https:', 'http:'].includes(url.protocol) ? url : null;
  } catch {
    return null;
  }
}

function domainMark(hostname) {
  const host = hostname.toLocaleLowerCase('en-US').replace(/\.$/, '');
  const candidates = [...MARK_BY_DOMAIN.entries()]
    .filter(([domain]) => host === domain || host.endsWith(`.${domain}`))
    .sort(([left], [right]) => right.length - left.length);
  return candidates[0]?.[1] || null;
}

export function findBrandMark(value) {
  const url = asUrl(value);
  if (url) return domainMark(url.hostname);
  for (const form of lookupForms(value)) {
    const mark = MARK_BY_LOOKUP.get(form);
    if (mark) return mark;
  }
  return null;
}

export function listBrandMarks(query = '') {
  const needle = String(query).trim().toLocaleLowerCase('en-US');
  return BRAND_MARKS.filter((mark) => {
    if (!needle) return true;
    return [mark.id, mark.title, mark.category, ...mark.aliases, ...mark.domains]
      .some((value) => String(value).toLocaleLowerCase('en-US').includes(needle));
  }).map(({ path, ...mark }) => mark);
}

function ipv4Private(address) {
  const parts = address.split('.').map(Number);
  if (parts.length !== 4 || parts.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) return true;
  const [a, b, c] = parts;
  return a === 0 || a === 10 || a === 127 || a >= 224
    || (a === 100 && b >= 64 && b <= 127)
    || (a === 169 && b === 254)
    || (a === 172 && b >= 16 && b <= 31)
    || (a === 192 && b === 0 && (c === 0 || c === 2))
    || (a === 192 && b === 88 && c === 99)
    || (a === 192 && b === 168)
    || (a === 198 && (b === 18 || b === 19))
    || (a === 198 && b === 51 && c === 100)
    || (a === 203 && b === 0 && c === 113);
}

function ipv6Private(address) {
  const normalized = address.toLocaleLowerCase('en-US').split('%')[0];
  if (normalized === '::' || normalized === '::1') return true;
  if (normalized.startsWith('fc') || normalized.startsWith('fd') || normalized.startsWith('ff') || /^fe[89ab]/.test(normalized)) return true;
  if (normalized.startsWith('64:ff9b:') || normalized.startsWith('100:')
    || normalized.startsWith('2001:db8:') || normalized.startsWith('2002:')) return true;
  const mappedDotted = normalized.match(/::ffff:(\d+\.\d+\.\d+\.\d+)$/);
  if (mappedDotted) return ipv4Private(mappedDotted[1]);
  const mappedHex = normalized.match(/::ffff:([0-9a-f]{1,4}):([0-9a-f]{1,4})$/);
  if (mappedHex) {
    const high = Number.parseInt(mappedHex[1], 16);
    const low = Number.parseInt(mappedHex[2], 16);
    return ipv4Private(`${high >>> 8}.${high & 255}.${low >>> 8}.${low & 255}`);
  }
  const compatibleHex = normalized.match(/^::([0-9a-f]{1,4}):([0-9a-f]{1,4})$/);
  if (compatibleHex) {
    const high = Number.parseInt(compatibleHex[1], 16);
    const low = Number.parseInt(compatibleHex[2], 16);
    return ipv4Private(`${high >>> 8}.${high & 255}.${low >>> 8}.${low & 255}`);
  }
  return false;
}

export function isPrivateBrandAddress(address) {
  const family = net.isIP(address);
  return family === 4 ? ipv4Private(address) : (family === 6 ? ipv6Private(address) : true);
}

function validateUrlShape(url, allowPrivate = process.env.ARCHIFY_BRAND_ALLOW_PRIVATE === '1') {
  if (!['https:', 'http:'].includes(url.protocol)) throw new Error('only HTTP(S) brand links are supported');
  if (url.username || url.password) throw new Error('brand links cannot contain credentials');
  const expectedPort = url.protocol === 'https:' ? '443' : '80';
  if (!allowPrivate && url.port && url.port !== expectedPort) {
    throw new Error('brand links must use a standard web port');
  }
  const host = url.hostname.toLocaleLowerCase('en-US').replace(/\.$/, '').replace(/^\[|\]$/g, '');
  if (!allowPrivate && (host === 'localhost' || host.endsWith('.localhost') || host.endsWith('.local'))) {
    throw new Error('private brand links are not fetched');
  }
  return host;
}

export async function captureBrandReference(value) {
  const url = asUrl(value);
  if (!url) throw new Error('brand capture requires one HTTP(S) URL');
  validateUrlShape(url);
  const preset = findBrandMark(url.href);
  if (preset) return { brand: preset.id, resolved: { ...preset, kind: 'preset', status: 'preset' } };
  throw new Error('brand capture failed: remote brand capture is disabled; choose an ID from `archify brands`');
}

function suggestions(value) {
  const needle = lookupForms(value)[0] || '';
  return BRAND_MARKS.map((mark) => ({
    id: mark.id,
    score: lookupForms(mark.id).some((form) => form.includes(needle) || needle.includes(form)) ? 0 : 1,
  })).sort((left, right) => left.score - right.score || left.id.localeCompare(right.id))
    .slice(0, 5)
    .map((entry) => entry.id);
}

async function mapConcurrent(values, limit, visit) {
  let cursor = 0;
  const workers = Array.from({ length: Math.min(limit, values.length) }, async () => {
    while (cursor < values.length) {
      const index = cursor;
      cursor += 1;
      await visit(values[index], index);
    }
  });
  await Promise.all(workers);
}

export async function prepareDiagramBrandMarks(diagramType, diagram) {
  const collection = COLLECTIONS[diagramType];
  const nodes = collection && Array.isArray(diagram[collection]) ? diagram[collection] : [];
  const unknown = [];
  await mapConcurrent(nodes, MAX_CAPTURE_CONCURRENCY, async (node, index) => {
    if (!node.brand) return;
    if (typeof node.brand === 'object') {
      unknown.push(`/${collection}/${index}/brand could not reproduce the pinned capture: remote brand capture is disabled`);
      return;
    }
    const preset = findBrandMark(node.brand);
    if (preset) {
      const resolved = { ...preset, kind: 'preset', status: 'preset', sourceUrl: preset.provenance.source };
      node[RESOLVED_MARK] = resolved;
      RESOLVED_BY_NODE.set(node, resolved);
      return;
    }
    const url = asUrl(node.brand);
    if (url) {
      unknown.push(`/${collection}/${index}/brand ${JSON.stringify(node.brand)} is an unpinned URL; capture it first with \`archify brands capture ${url.href} --json\``);
      return;
    }
    unknown.push(`/${collection}/${index}/brand ${JSON.stringify(node.brand)} is not a built-in brand; closest IDs: ${suggestions(node.brand).join(', ')}`);
  });
  if (unknown.length) {
    throwDiagnosticError(`Brand mark validation failed:\n- ${unknown.join('\n- ')}`, unknown.map((message) => ({
      code: message.includes('is an unpinned URL') ? 'brand/unpinned-url'
        : (message.includes('digest changed') ? 'brand/digest-mismatch'
          : (message.includes('could not reproduce') ? 'brand/capture-unavailable' : 'brand/unknown')),
      severity: 'error',
      message,
      subject: { diagramType, collection },
      evidence: {},
      supportedFixes: message.includes('is an unpinned URL')
        ? ['run `archify brands capture <url> --json` and author the returned digest-pinned brand object']
        : ['choose an ID from `archify brands`', 'run `archify brands capture <url> --json` for an unknown official site'],
    })));
  }
}

export function brandMarkFor(node) {
  return node?.[RESOLVED_MARK] || RESOLVED_BY_NODE.get(node) || null;
}

export function brandMetadataFor(node) {
  const mark = brandMarkFor(node);
  return mark ? {
    brand: mark.title,
    brandId: mark.id,
    brandStatus: mark.status,
    brandSource: mark.sourceUrl,
  } : {};
}

export function brandLabelFitWidth(node, width) {
  return brandMarkFor(node) ? Math.max(1, width - 48) : width;
}

export function brandTopRailProblem(node, width, minimumFontSize, subject = 'Node') {
  if (!brandMarkFor(node)) return null;
  const available = width - 48;
  const required = textUnits(node.label) * minimumFontSize * 0.6;
  if (available >= required) return null;
  return `${subject} "${node.id}" brand top rail leaves ${Math.max(0, available)}px for its label, but `
    + `"${node.label}" needs ~${Math.ceil(required)}px at the ${minimumFontSize}px legible minimum — widen the node or shorten the label.`;
}

function markAttrs(mark) {
  return [
    `data-brand-mark="${esc(mark.id)}"`,
    `data-brand-title="${esc(mark.title)}"`,
    `data-brand-status="${esc(mark.status)}"`,
    mark.sourceUrl ? `data-brand-source="${esc(mark.sourceUrl)}"` : '',
    mark.sha256 ? `data-brand-sha256="${esc(mark.sha256)}"` : '',
  ].filter(Boolean).join(' ');
}

export function renderBrandMark(node, { x, y, size = 16 } = {}) {
  const mark = brandMarkFor(node);
  if (!mark) return '';
  const inset = 3;
  let content;
  if (mark.kind === 'preset') {
    const scale = (size - inset * 2) / mark.viewBox;
    content = `<path d="${esc(mark.path)}" transform="translate(${inset} ${inset}) scale(${scale})" fill="#${esc(mark.hex)}"/>`;
  } else if (mark.kind === 'remote') {
    content = `<image href="${esc(mark.dataUrl)}" x="${inset}" y="${inset}" width="${size - inset * 2}" height="${size - inset * 2}" preserveAspectRatio="xMidYMid meet"/>`;
  } else {
    const scale = size / 20;
    content = `<g transform="scale(${scale})" class="brand-mark-fallback"><circle cx="10" cy="10" r="5.2"/><path d="M4.8 10h10.4M10 4.8c1.6 1.6 2.4 3.3 2.4 5.2s-.8 3.6-2.4 5.2M10 4.8C8.4 6.4 7.6 8.1 7.6 10s.8 3.6 2.4 5.2"/></g>`;
  }
  return `<g aria-hidden="true" ${markAttrs(mark)} class="brand-mark" transform="translate(${x} ${y})">
            <rect width="${size}" height="${size}" rx="4" class="brand-mark-badge"/>
            ${content}
            <rect width="${size}" height="${size}" rx="4" class="brand-mark-frame"/>
          </g>`;
}
