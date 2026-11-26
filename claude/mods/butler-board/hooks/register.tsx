import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, Timer } from 'claude-code'

import type { RecentRow, SessionRow } from '../types'

// 各セッションは自分の状態を tmux の pane 変数 (@cc_*) に書き、
// ボードは tmux list-panes で全 pane の変数をまとめて読む。
// pane を閉じれば変数も消える。閉じたセッションだけは再開できるよう ~/.claude/butler-board/recent.json に残す。
//
// 執事が始めるタスクは見えない tmux セッション (WORKERS) に 1 タスク 1 window で置く。
// 執事の window には執事のほかに「表示枠」の pane を 1 つだけ置き、ボードで選んだ
// Claude (手で立ち上げたものも含む) を swap-pane でそこへ呼び出す。表示枠にいた
// Claude は、呼び出した Claude がいた場所へ戻る。popup セッションの Claude だけは popup で見せる。

const POLL_MS = 3000
const WORKERS = 'workers'
// bin/tmux-popup-session が popup で開くセッション
const POPUP = 'popup'
type Icon = { mark: string; color: string; label: string }
const ICON = {
  running: { mark: '●', color: 'yellow', label: '実行中' },
  waiting: { mark: '⏸', color: 'red', label: '待ち' },
  done: { mark: '✓', color: 'green', label: '完了' },
  idle: { mark: '○', color: 'gray', label: '待機' },
} satisfies Record<string, Icon>
const iconOf = (state: string): Icon =>
  (ICON as Record<string, Icon>)[state] ?? { mark: '?', color: 'gray', label: state }

const rows = atom({ plugin: 'butler-board', key: 'rows' } as const, [], {
  shape: 'rows-3',
})
const recent = atom({ plugin: 'butler-board', key: 'recent' } as const, [], {
  shape: 'recent-1',
})
const isOpen = atom({ plugin: 'butler-board', key: 'isOpen' } as const, false)
// ボードに出す一覧。t で「動いている」と「最近閉じた」を切り替える。
const view = atom({ plugin: 'butler-board', key: 'view' } as const, 'live')
// d か [ × ] を 1 回押された pane。もう一度押すと閉じる。
const killing = atom({ plugin: 'butler-board', key: 'killing' } as const, null)
// キーボードのフォーカスがある行。その行の [消す] に d キーを割り当てる。
const focused = atom({ plugin: 'butler-board', key: 'focused' } as const, null)

// このセッション自身の状態。PostToolUse のたびに tmux を叩かないために持つ。
let myState: string | undefined
let pollTimer: Timer | undefined
// 3 秒ごとに tmux を読み直す。mod の読み直しで every は止まるが開いたボードは残るので、session.start でも動かす。
// ボードを開いている pane には @cc_board を付ける。通知のクリック (bin/tmux-focus-pane) が執事の表示枠を探すのに使う。
const startPolling = ($: EngineInterface): void => {
  if (pollTimer !== undefined) return
  void setPaneVars($, { board: '1' }).catch(() => undefined)
  pollTimer = $.clock.every(POLL_MS, () => void poll($).catch(() => undefined))
  void poll($).catch(() => undefined)
}
// 帯の [-] (ctrl+x ctrl+a) で折りたたまれているか。描くたびに更新する。
let isBandCollapsed = false
// 帯に描いた順の pane ID と、キーボードのフォーカスがある行の pane ID
let bandOrder: string[] = []
// 帯の id と、キーボードのフォーカスがある [表示] ボタンの key (show-<pane>)
let bandRequestId: string | undefined
let focusedKey: string | undefined

const oneLine = (text: string | undefined, max: number): string =>
  (text ?? '')
    .split('\n')
    .map(line => line.trim())
    .find(line => line !== '')
    ?.replace(/\t/g, ' ')
    .slice(0, max) ?? ''

const setPaneVars = async (
  $: EngineInterface,
  vars: Record<string, string>,
): Promise<void> => {
  const paneId = await $.env.get('TMUX_PANE')
  if (paneId === undefined) return

  const argv = ['tmux']
  for (const [name, value] of Object.entries(vars)) {
    if (argv.length > 1) argv.push(';')
    argv.push('set', '-p', '-t', paneId, `@cc_${name}`, value)
  }
  await $.process.run(argv)
}

const setState = async (
  $: EngineInterface,
  state: string,
  vars: Record<string, string> = {},
): Promise<void> => {
  myState = state
  await setPaneVars($, { state, since: String(await $.clock.now()), ...vars })
}

// process.run はセッションの作業ディレクトリで動くので、worktree に移った後も追える
const currentBranch = async ($: EngineInterface): Promise<string> => {
  const { exitCode, stdout } = await $.process.run(
    ['git', 'branch', '--show-current'],
    { timeoutMs: 5000 },
  )

  return exitCode === 0 ? stdout.trim() : ''
}

// 閉じたセッションの記録。閉じた本人と、ボードを開いている執事が書くのでファイルで共有する。
const RECENT_MAX = 20
const recentFile = async ($: EngineInterface): Promise<string> =>
  `${(await $.env.get('HOME')) ?? ''}/.claude/butler-board/recent.json`

const loadRecent = async ($: EngineInterface): Promise<RecentRow[]> => {
  try {
    const parsed: unknown = JSON.parse(await $.fs.read(await recentFile($)))

    return Array.isArray(parsed) ? (parsed as RecentRow[]) : []
  } catch {
    return []
  }
}

// 会話のないセッションは再開できないので残さない。同じセッションは新しい記録で置き換える。
const remember = async ($: EngineInterface, closed: RecentRow[]): Promise<void> => {
  const worth = closed.filter(row => row.sessionId !== '' && row.task !== '')
  if (worth.length === 0) return
  const ids = new Set(worth.map(row => row.sessionId))
  const kept = (await loadRecent($)).filter(row => !ids.has(row.sessionId))
  const next = [...worth, ...kept].sort((a, b) => b.closedAt - a.closedAt).slice(0, RECENT_MAX)
  await $.fs.write(await recentFile($), JSON.stringify(next, null, 2))
}

const poll = async ($: EngineInterface): Promise<void> => {
  const { exitCode, stdout } = await $.process.run([
    'tmux',
    'list-panes',
    '-a',
    '-F',
    [
      '#{pane_id}',
      '#{session_name}:#{window_index}.#{pane_index}',
      '#{session_name}',
      '#{window_id}',
      '#{@cc_state}',
      '#{@cc_task}',
      '#{@cc_branch}',
      '#{@cc_last}',
      '#{@cc_since}',
      '#{@cc_session}',
      '#{@cc_cwd}',
    ].join('\t'),
  ])
  if (exitCode !== 0) return

  const list: SessionRow[] = stdout
    .split('\n')
    .map(line => line.split('\t'))
    .filter(cols => cols.length >= 11 && cols[4] !== '')
    .map(cols => ({
      paneId: cols[0] ?? '',
      location: cols[1] ?? '',
      session: cols[2] ?? '',
      windowId: cols[3] ?? '',
      state: cols[4] ?? '',
      task: cols[5] ?? '',
      branch: cols[6] ?? '',
      last: cols[7] ?? '',
      since: Number(cols[8]) || 0,
      sessionId: cols[9] ?? '',
      cwd: cols[10] ?? '',
    }))
    // 状態や時刻で並べ替えると、押そうとした瞬間に行がずれる。起動順 (pane ID) で固定する。
    .sort((a, b) => Number(a.paneId.slice(1)) - Number(b.paneId.slice(1)))

  // 前回あって今回ない pane は閉じられた。閉じた本人が session.end で書けなかったとき (kill-pane など) のために残す。
  const alive = new Set(list.map(row => row.paneId))
  const now = await $.clock.now()
  const closed = (await read($, rows))
    .filter(row => !alive.has(row.paneId))
    .map(({ sessionId, cwd, branch, task, last }) => ({ sessionId, cwd, branch, task, last, closedAt: now }))
  await remember($, closed).catch(() => undefined)

  // 変わっていないときは描き直さない (描き直しの最中のクリックを取りこぼさないため)
  await update($, rows, before => (JSON.stringify(before) === JSON.stringify(list) ? before : list))
  // 再開して今動いているものは「最近閉じた」に出さない
  const liveIds = new Set(list.map(row => row.sessionId))
  const closedList = (await loadRecent($)).filter(row => !liveIds.has(row.sessionId))
  await update($, recent, before => (JSON.stringify(before) === JSON.stringify(closedList) ? before : closedList))

  const count = (state: string) => list.filter(row => row.state === state).length
  $.ui.status(
    `${ICON.waiting.mark}${count('waiting')} ${ICON.running.mark}${count('running')} ${ICON.done.mark}${count('done')}`,
  )
}

// 端末での表示幅。漢字・かな・全角記号・絵文字は 2 桁、それ以外 (✓ ● などの記号を含む) は 1 桁
const WIDE: readonly (readonly [number, number])[] = [
  [0x1100, 0x115f], [0x2e80, 0xa4cf], [0xac00, 0xd7a3], [0xf900, 0xfaff],
  [0xfe30, 0xfe4f], [0xff00, 0xff60], [0xffe0, 0xffe6], [0x1f300, 0x1faff],
]
const widthOf = (text: string): number =>
  [...text].reduce((sum, char) => {
    const code = char.codePointAt(0) ?? 0

    return sum + (WIDE.some(([from, to]) => code >= from && code <= to) ? 2 : 1)
  }, 0)

// 表示幅が columns に収まるよう末尾を切り、切ったら … を付ける
const fitWidth = (text: string, columns: number): string => {
  if (widthOf(text) <= columns) return text
  let out = ''
  for (const char of text) {
    if (widthOf(out + char) > columns - 1) break
    out += char
  }

  return `${out}…`
}

const age = (now: number, since: number): string => {
  if (since === 0) return ''
  const minutes = Math.floor((now - since) / 60000)
  if (minutes < 1) return 'たった今'
  if (minutes < 60) return `${minutes}分前`

  if (minutes < 60 * 24) return `${Math.floor(minutes / 60)}時間前`

  return `${Math.floor(minutes / (60 * 24))}日前`
}

// 何分前の表示。桁が変わっても後ろの文字がずれないよう、表示幅を 8 桁にそろえる
const ageCell = (now: number, since: number): string => {
  const text = age(now, since)

  return text + ' '.repeat(Math.max(0, 8 - widthOf(text)))
}

const dirName = (cwd: string): string => cwd.split('/').filter(part => part !== '').at(-1) ?? cwd

const tmux = async ($: EngineInterface, argv: string[]): Promise<string> => {
  const { exitCode, stdout, stderr } = await $.process.run(['tmux', ...argv])
  if (exitCode !== 0) throw new Error(oneLine(stderr, 120) || `tmux ${argv[0]} failed`)

  return stdout.trim()
}

type Butler = { paneId: string; windowId: string }

const butlerPane = async ($: EngineInterface): Promise<Butler | undefined> => {
  const paneId = await $.env.get('TMUX_PANE')
  if (paneId === undefined) return undefined

  return { paneId, windowId: await tmux($, ['display', '-p', '-t', paneId, '#{window_id}']) }
}

// 執事の window にある執事以外の pane。無ければ表示枠はまだ無い。
const slotPane = async ($: EngineInterface, butler: Butler): Promise<string | undefined> =>
  (await tmux($, ['list-panes', '-t', butler.windowId, '-F', '#{pane_id}']))
    .split('\n')
    .find(id => id !== '' && id !== butler.paneId)

const show = async ($: EngineInterface, row: Pick<SessionRow, 'paneId'>): Promise<void> => {
  try {
    const butler = await butlerPane($)
    if (butler === undefined) return
    // ボードの一覧は数秒前のものなので、今どこにいるかは押した時点で tmux に聞き直す
    const [session, windowId] = (
      await tmux($, ['display', '-p', '-t', row.paneId, '#{session_name}\t#{window_id}'])
    ).split('\t')
    // すでに表示枠にいる。フォーカスは執事に残す (ボードの操作を続けられるように)
    if (windowId === butler.windowId) {
      return
    }
    // popup セッションの Claude は、中でその pane を選んでから popup を開く。
    // switch-client で移るとメインの画面ごと popup セッションに切り替わってしまう。
    if (session === POPUP) {
      await tmux($, ['select-window', '-t', row.paneId, ';', 'select-pane', '-t', row.paneId])
      await tmux($, ['run-shell', '-b', `tmux-popup-session ${butler.paneId}`])
      return
    }
    const slot = await slotPane($, butler)
    if (slot === undefined) {
      await tmux($, ['join-pane', '-d', '-h', '-l', '50%', '-s', row.paneId, '-t', butler.paneId])
    } else {
      await tmux($, ['swap-pane', '-d', '-s', row.paneId, '-t', slot])
    }
  } catch (error) {
    $.ui.toast(`表示できませんでした: ${error instanceof Error ? error.message : String(error)}`)
  }
  await poll($)
}

// 1 回目は確認待ちにし、同じ pane をもう一度押したら閉じる。会話は残るので cldr で再開できる。
const kill = async ($: EngineInterface, row: SessionRow): Promise<void> => {
  if ((await read($, killing)) !== row.paneId) {
    await update($, killing, () => row.paneId)
    $.clock.after(2000, () => void update($, killing, id => (id === row.paneId ? null : id)))
    return
  }
  await update($, killing, () => null)
  try {
    await tmux($, ['kill-pane', '-t', row.paneId])
    $.ui.toast(`${row.branch || row.location} (${row.location}) を閉じました`)
  } catch (error) {
    $.ui.toast(`閉じられませんでした: ${error instanceof Error ? error.message : String(error)}`)
  }
  await poll($)
}

// 子の pane の入力欄に打ち込んで送信する。改行は途中で送信されるため空白にする。
// 文字の直後の Enter は貼り付けの一部として扱われ送信されないため、間を空けて送る。
const sendToTask = async ($: EngineInterface, paneId: string, message: string): Promise<void> => {
  await tmux($, ['send-keys', '-t', paneId, '-l', message.replace(/\s*\n\s*/g, ' ')])
  await $.clock.sleep(500)
  await tmux($, ['send-keys', '-t', paneId, 'Enter'])
}

const describeTasks = (list: SessionRow[], butler: string | undefined): string => {
  const others = list.filter(row => row.paneId !== butler)
  if (others.length === 0) return '動いている Claude セッションはありません。'

  return others
    .map(row =>
      [
        `- ${row.paneId} [${iconOf(row.state).label}] ${row.branch || '(ブランチなし)'} (${row.location})`,
        `  依頼: ${row.task || '(なし)'}`,
        `  最後の発言: ${row.last || '(なし)'}`,
      ].join('\n'),
    )
    .join('\n')
}

// 帯の中のキー操作。j/k で行を移り、l (Enter と同じ) で表示、d で消す。
// Claude Code のキー設定には「次へ/前へ」しか無いため、案内行のボタンにキーを割り当てて
// ここで処理する。mod が動かしたフォーカスは ui.focus として届かないので自分で覚える。
const move = async ($: EngineInterface, direction: 'j' | 'k'): Promise<void> => {
  if (bandRequestId === undefined || bandOrder.length === 0) return
  const index = bandOrder.indexOf((focusedKey ?? '').replace(/^show-/, ''))
  // 帯に入った直後は 1 行目にフォーカスがある (autoFocus。mod には届かない)
  const from = index < 0 ? 0 : index
  const row = direction === 'j' ? Math.min(from + 1, bandOrder.length - 1) : Math.max(from - 1, 0)
  // 動いたら消すの確認待ちは取り消す
  await update($, killing, () => null)
  const key = `show-${bandOrder[row] ?? ''}`
  const moved = await $.ui.focus({ requestId: bandRequestId, key })
  if (moved.deny === undefined) {
    focusedKey = key
    await update($, focused, () => bandOrder[row] ?? null)
  }
}

const focusedRow = async ($: EngineInterface): Promise<SessionRow | undefined> => {
  const paneId = (await read($, focused)) ?? bandOrder[0]

  return (await read($, rows)).find(row => row.paneId === paneId)
}

// 見えない WORKERS セッションに window を作り、claude を起動する
const openWorker = async ($: EngineInterface, title: string, cwd: string, args: string[]): Promise<string> => {
  const name = oneLine(title, 24).replace(/[.:]/g, ' ')
  const launch = ['-n', name, '-c', cwd, '-P', '-F', '#{pane_id}', 'claude', ...args]
  const { exitCode } = await $.process.run(['tmux', 'has-session', '-t', `=${WORKERS}`])
  const paneId =
    exitCode === 0
      ? await tmux($, ['new-window', '-d', '-t', `=${WORKERS}:`, ...launch])
      : await tmux($, ['new-session', '-d', '-s', WORKERS, ...launch])
  await poll($)

  return paneId
}

// 依頼文を渡して起動する
const startTask = async ($: EngineInterface, task: string): Promise<string> => {
  const { stdout: cwd } = await $.process.run(['pwd'])

  return openWorker($, task, cwd.trim(), [task])
}

const setView = async ($: EngineInterface, next: 'live' | 'recent'): Promise<void> => {
  focusedKey = undefined
  await update($, focused, () => null)
  await update($, killing, () => null)
  await update($, view, () => next)
}

// 閉じたセッションを workers で再開し、表示枠に出して「動いている」に戻る
const resume = async ($: EngineInterface, row: RecentRow): Promise<void> => {
  const { exitCode } = await $.process.run(['test', '-d', row.cwd])
  if (exitCode !== 0) {
    $.ui.toast(`${row.cwd} が無いため再開できません`)
    return
  }
  try {
    const paneId = await openWorker($, row.branch || row.task, row.cwd, ['--resume', row.sessionId])
    await setView($, 'live')
    await show($, { paneId })
  } catch (error) {
    $.ui.toast(`再開できませんでした: ${error instanceof Error ? error.message : String(error)}`)
  }
}

const focusedRecent = async ($: EngineInterface): Promise<RecentRow | undefined> => {
  const sessionId = (await read($, focused)) ?? bandOrder[0]

  return (await read($, recent)).find(row => row.sessionId === sessionId)
}

// claude --resume に渡す ID と作業ディレクトリ。/clear で ID が変わるのでターンごとに書き直す。
// 作業ディレクトリは worktree に移った先を指し、ペイン分割 (bin/tmux-pane-cwd) でも使う。
const whoAmI = async ($: EngineInterface): Promise<Record<string, string>> => ({
  session: await $.session.id(),
  cwd: await $.session.cwd(),
})

export const register: Register = on => {
  // --- 各セッション: 自分の状態を書き出す ---

  // classic.* は上位のプラグインが先に答えて届かないことがあるため、
  // エンジン本体のイベントで状態を拾う。サブエージェントのターンは数えない。

  on('turn.start', async ($, e, next) => {
    if (e.agentId === undefined) {
      await setState($, 'running', {
        task: oneLine(e.text, 80),
        branch: await currentBranch($),
        last: '',
        ...(await whoAmI($)),
      })
    }

    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    // 待ちにするのは質問とプラン承認だけ。ツールの許可は auto mode の
    // 判定中も ask になり、人を待っているのか区別できないため数えない。
    if (e.tool === 'AskUserQuestion' || e.tool === 'ExitPlanMode') {
      await setState($, 'waiting', { last: `${e.tool} の返事待ち` })
    }
    const ran = await next(e)
    if (myState === 'waiting') await setState($, 'running')

    return ran
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.agentId === undefined) {
      await setState($, 'done', {
        last: e.reason === 'refusal' ? '拒否で止まりました' : oneLine(e.answer, 120),
        // ターンの途中で worktree に移っていれば、ここで移り先に書き直す
        ...(await whoAmI($)),
      })
    }

    return done
  })

  on('session.end', async ($, e, next) => {
    const paneId = await $.env.get('TMUX_PANE')
    if (paneId !== undefined) {
      // 消す前に「最近閉じた」へ残す
      const { stdout } = await $.process.run(['tmux', 'display', '-p', '-t', paneId, '#{@cc_task}\t#{@cc_branch}\t#{@cc_last}\t#{@cc_cwd}'])
      const [task = '', branch = '', last = '', cwd = ''] = stdout.replace(/\n$/, '').split('\t')
      await remember($, [
        { sessionId: e.resume.id, cwd: cwd || (await $.session.cwd()), branch, task, last, closedAt: await $.clock.now() },
      ]).catch(() => undefined)
      const argv = ['tmux']
      for (const name of ['state', 'task', 'branch', 'last', 'since', 'session', 'cwd', 'board']) {
        if (argv.length > 1) argv.push(';')
        argv.push('set', '-p', '-u', '-t', paneId, `@cc_${name}`)
      }
      await $.process.run(argv)
    }

    return next(e)
  })

  // --- 執事: /board で一覧ボードを開く ---

  // 起動・再開した時点でボードに出す。再開 (cldr) なら会話の最後の依頼と返事を出す。
  on('session.start', async ($, e, next) => {
    if (await read($, isOpen)) startPolling($)
    if (e.isInteractive) {
      const messages = await $.session.messages({ last: 50 }).catch(() => [])
      const list = Array.isArray(messages) ? messages : []
      const lastUser = list.filter(m => m.role === 'user' && m.text.trim() !== '').at(-1)
      const lastAnswer = list.filter(m => m.role === 'assistant' && m.text.trim() !== '').at(-1)
      await setState($, lastUser === undefined ? 'idle' : 'done', {
        task: oneLine(lastUser?.text, 80),
        branch: await currentBranch($),
        last: oneLine(lastAnswer?.text, 120),
        ...(await whoAmI($)),
      }).catch(() => undefined)
    }
    await $.command.register({
      name: 'board',
      description: 'tmux 上の全 Claude セッションの状態をボードで一覧する',
    })
    await $.command.register({
      name: 'butler',
      description: 'このセッションを執事モードにする (作業は子のセッションに任せる) とともにボードを開く',
    })
    await $.command.register({
      name: 'task',
      description: '見えない workers セッションで新しい Claude にタスクを頼む',
      argumentHint: '<依頼文>',
    })
    await $.tool.register({
      name: 'start_task',
      description:
        'ユーザーから頼まれた作業を、新しい Claude Code セッションに任せる。セッションは見えない tmux セッション workers に 1 タスク 1 window で起動し、task をそのまま最初の依頼として渡す。task はスラッシュコマンドで始めてもよい。自分で作業せず任せるときに使う。',
      inputSchema: {
        type: 'object',
        properties: { task: { type: 'string', description: '新しいセッションへの最初の依頼文' } },
        required: ['task'],
      },
      isDeferred: false,
    })
    await $.tool.register({
      name: 'list_tasks',
      description:
        'tmux 上で動いている Claude Code セッション (start_task で任せたものと手で立ち上げたもの) の一覧を返す。各行は pane ID・状態 (実行中/待ち/完了/待機)・ブランチ・最後の依頼・最後の発言。タスクの状況を聞かれたときや、send_to_task の宛先を探すときに使う。',
      inputSchema: { type: 'object', properties: {} },
      isDeferred: false,
    })
    await $.tool.register({
      name: 'send_to_task',
      description:
        '動いている Claude Code セッションに追加の指示を送る。相手の入力欄に message を打ち込んで送信する。pane は list_tasks か start_task が返した pane ID (例: %12)。',
      inputSchema: {
        type: 'object',
        properties: {
          pane: { type: 'string', description: '宛先の pane ID (例: %12)' },
          message: { type: 'string', description: '送る指示' },
        },
        required: ['pane', 'message'],
      },
      isDeferred: false,
    })

    return next(e)
  })

  on('tool.run', { tool: 'mcp__butler-board__list_tasks' }, async $ => {
    await poll($)
    const butler = await butlerPane($).catch(() => undefined)
    const text = describeTasks(await read($, rows), butler?.paneId)

    return { result: text, text }
  })

  on('tool.run', { tool: 'mcp__butler-board__send_to_task' }, async ($, e) => {
    const { pane, message } = e as unknown as { pane?: unknown; message?: unknown }
    if (typeof pane !== 'string' || !/^%\d+$/.test(pane)) return { deny: 'pane は %12 のような pane ID で指定してください。' }
    if (typeof message !== 'string' || message.trim() === '') return { deny: 'message が空です。' }
    try {
      await sendToTask($, pane, message.trim())
    } catch (error) {
      return { deny: `送れませんでした: ${error instanceof Error ? error.message : String(error)}` }
    }
    const text = `${pane} に送りました。`

    return { result: text, text }
  })

  on('command.run', { command: 'task' }, async ($, e) => {
    if (e.args.trim() === '') return { text: '依頼文を付けてください。例: /task README を読みやすくして' }
    const paneId = await startTask($, e.args.trim())

    return { text: `workers セッションで起動しました (${paneId})。ボードから表示できます。` }
  })

  on('tool.run', { tool: 'mcp__butler-board__start_task' }, async ($, e) => {
    const task = (e as unknown as { task?: unknown }).task
    if (typeof task !== 'string' || task.trim() === '') return { deny: 'task が空です。' }
    const paneId = await startTask($, task.trim())

    const text = `workers セッションで起動しました (${paneId})。`

    return { result: text, text }
  })

  // 起動後に執事モードにする。cldb は起動時に --append-system-prompt で同じ指示を渡す。
  // ここでは会話に指示を差し込むので、/compact の要約で薄れたら打ち直す。
  // マシン固有の指示 (gitignore 済みの claude/local/butler-prompt.md) があれば続けて足す。
  on('command.run', { command: 'butler' }, async $ => {
    const home = (await $.env.get('HOME')) ?? ''
    const local = await $.fs.read(`${home}/dotfiles/claude/local/butler-prompt.md`).catch(() => '')
    const prompt = [await $.fs.read(`${$.plugin.root}/butler-prompt.md`), local].filter(text => text !== '').join('\n')
    if (!(await read($, isOpen))) {
      await update($, isOpen, () => true)
      await poll($)
      startPolling($)
    }

    return {
      text: '執事モードにしました。作業は子のセッションに任せます。',
      context: [`以降、このセッションでは次の指示に従う。\n\n${prompt}`],
    }
  })

  // /board で入力欄の上の帯に一覧を出す。もう一度 /board で閉じる。
  on('command.run', { command: 'board' }, async ($, e) => {
    // 折りたたみは mod から戻せないので、開閉せずに戻し方だけ伝える
    if (isBandCollapsed && (await read($, isOpen))) {
      return { text: '帯が折りたたまれています。ctrl+x ctrl+a で元に戻してください。' }
    }
    const open = !(await read($, isOpen))
    await update($, isOpen, () => open)
    if (!open) {
      pollTimer?.cancel()
      pollTimer = undefined
      $.ui.status(undefined)
      const paneId = await $.env.get('TMUX_PANE')
      if (paneId !== undefined) await $.process.run(['tmux', 'set', '-p', '-u', '-t', paneId, '@cc_board'])

      return { text: 'Claude ボードを閉じました。' }
    }
    await poll($)
    startPolling($)

    return {
      text: e.presentation.isFullscreen
        ? 'Claude ボードを開きました。'
        : 'Claude ボードを開きました。全画面表示ではないため、ボタンはクリックできません。CLAUDE_CODE_NO_FLICKER=1 を設定したシェルで起動し直してください。',
    }
  })

  // フォーカスのあるボタンを覚えておく (hjkl の移動元と、d キーを割り当てる行)
  on('ui.focus', { component: 'AbovePrompt' }, async ($, e, next) => {
    bandRequestId = e.requestId
    const element = e.element
    if (element !== undefined && element.startsWith('show-')) {
      focusedKey = element
      await update($, focused, () => element.slice('show-'.length))
    }

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    isBandCollapsed = e.props.isCollapsed
    if (e.props.hasSurvey || !(await read($, isOpen))) return next(e)

    const { Box, Text, Button } = $.ui.resolve(e)
    const list = await read($, rows)
    const closedList = await read($, recent)
    const current = await read($, view)
    const now = await $.clock.now()
    const butler = await butlerPane($).catch(() => undefined)
    const killingPane = await read($, killing)
    // 執事自身は一覧に出さない
    const others = list.filter(row => row.paneId !== butler?.paneId)

    bandRequestId = e.requestId
    bandOrder = current === 'live' ? others.map(row => row.paneId) : closedList.map(row => row.sessionId)
    // 枠の上下 2 行と見出し 1 行。空行を挟んで全部入るなら挟み、入らなければ詰める。
    // 詰めても入らない分は切り捨てず、帯の中でスクロールさせる。
    const isSpacious = 2 + (bandOrder.length + 1) * 2 - 1 <= e.props.maxRows
    // 枠の内側の幅 (罫線と左右の余白で 4 桁)
    const innerColumns = Math.max(10, e.props.bodyColumns - 4)
    // 先頭の行にフォーカスを置く (ctrl+w ctrl+w で入った直後に j/k/l を効かせるため)
    const first = (index: number) => (index === 0 ? { autoFocus: true as const } : {})
    const tab = (name: 'live' | 'recent', label: string, count: number) => (
      <Button key={`tab-${name}`} plain onPress={() => setView($, name)}>
        {current === name ? (
          <Text bold underline>
            {label} {count}
          </Text>
        ) : (
          <Text dimColor>
            {label} {count}
          </Text>
        )}
      </Button>
    )

    const liveRows = others.map((row, index) => {
      // 消す確認待ちの行は、状態を赤字の「削除」に置き換える (同じ幅なので行がずれない)
      const icon = killingPane === row.paneId ? { mark: '✗', color: 'red', label: '削除' } : iconOf(row.state)
      // 行の文字 (head + text) は 1 行に収める。[ × ] (5 桁) は文字のすぐ右、収まらなければ右端に重ねる
      // 場所 (session:window.pane) は表示枠に出すたびに変わって行がずれるので出さない
      const name = row.branch || dirName(row.cwd) || row.location
      const head = `${icon.mark} ${icon.label} ${name} ${ageCell(now, row.since)} `
      const text = fitWidth(row.last || row.task, innerColumns - widthOf(head))

      return (
        // 行全体が 1 つのボタン。クリック・Enter・l で表示する。
        // マウスを乗せた行は、右端に閉じるボタン [ × ] を重ねて出す。確認待ちの間は出したまま。
        <Box key={`row-${row.paneId}`} flexDirection="row">
          <Button key={`show-${row.paneId}`} plain {...first(index)} onPress={() => show($, row)}>
            <Text color={icon.color} bold>
              {icon.mark} {icon.label}
            </Text>{' '}
            <Text bold>{name}</Text> <Text dimColor>{ageCell(now, row.since)}</Text>{' '}
            {text}
          </Button>
          <Box
            position="absolute"
            top={0}
            left={Math.min(widthOf(head + text) + 1, innerColumns - 5)}
            {...(killingPane === row.paneId
              ? { display: 'flex' as const }
              : { display: 'none' as const, hover: { display: 'flex' as const } })}
          >
            <Button key={`close-${row.paneId}`} label="×" onPress={() => kill($, row)} />
          </Box>
        </Box>
      )
    })

    // 閉じたセッション。クリック・Enter・l で再開する。最後の依頼を出す。
    const recentRows = closedList.map((row, index) => {
      const place = dirName(row.cwd)
      const head = `↺ ${row.branch || place} ${place} ${ageCell(now, row.closedAt)} `
      const text = fitWidth(row.task, innerColumns - widthOf(head))

      return (
        <Button key={`show-${row.sessionId}`} plain {...first(index)} onPress={() => resume($, row)}>
          <Text color="cyan" bold>
            ↺
          </Text>{' '}
          <Text bold>{row.branch || place}</Text>{' '}
          <Text dimColor>
            {place} {ageCell(now, row.closedAt)}
          </Text>{' '}
          {text}
        </Button>
      )
    })

    const rowsOfView = current === 'live' ? liveRows : recentRows

    return (
      <Box flexDirection="column" gap={isSpacious ? 1 : 0} borderStyle="round" borderDimColor paddingX={1}>
        <Box flexDirection="row" gap={2}>
          {tab('live', '動いている', others.length)}
          {tab('recent', '最近閉じた', closedList.length)}
        </Box>
        {rowsOfView.length > 0 ? (
          rowsOfView
        ) : (
          <Text dimColor>
            {current === 'live' ? '状態を書き出している Claude はまだいません。' : '最近閉じたセッションはありません。'}
          </Text>
        )}
        {/* キー (j/k/l/d/r/t) を受けるだけのボタン。画面には出さない */}
        <Box display="none">
          {(
            [
              ['j', '↓', () => move($, 'j')],
              ['k', '↑', () => move($, 'k')],
              [
                'l',
                '開く',
                async () => {
                  if ((await read($, view)) === 'recent') {
                    const row = await focusedRecent($)
                    if (row) await resume($, row)
                    return
                  }
                  const row = await focusedRow($)
                  if (row) await show($, row)
                },
              ],
              [
                'd',
                '消す',
                async () => {
                  if ((await read($, view)) !== 'live') return
                  const row = await focusedRow($)
                  if (row) await kill($, row)
                },
              ],
              ['r', '更新', async () => { await poll($); $.ui.toast('ボードを更新しました') }],
              ['t', '切替', async () => setView($, (await read($, view)) === 'live' ? 'recent' : 'live')],
            ] as const
          ).map(([hotkey, label, onPress]) => (
            <Button key={`key-${hotkey}`} label={label} hotkey={hotkey} plain dimColor onPress={onPress} />
          ))}
        </Box>
      </Box>
    )
  })
}
