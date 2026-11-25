import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, Timer } from 'claude-code'

import type { SessionRow } from '../types'

// 各セッションは自分の状態を tmux の pane 変数 (@cc_*) に書き、
// ボードは tmux list-panes で全 pane の変数をまとめて読む。
// pane を閉じれば変数も消えるので、後片付けのファイルを持たない。
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
  shape: 'rows-2',
})
const isOpen = atom({ plugin: 'butler-board', key: 'isOpen' } as const, false)
// 「消す」を 1 回押された pane。もう一度押すと閉じる。
const killing = atom({ plugin: 'butler-board', key: 'killing' } as const, null)
// キーボードのフォーカスがある行。その行の [消す] に d キーを割り当てる。
const focused = atom({ plugin: 'butler-board', key: 'focused' } as const, null)

// このセッション自身の状態。PostToolUse のたびに tmux を叩かないために持つ。
let myState: string | undefined
let pollTimer: Timer | undefined
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
    ].join('\t'),
  ])
  if (exitCode !== 0) return

  const list: SessionRow[] = stdout
    .split('\n')
    .map(line => line.split('\t'))
    .filter(cols => cols.length >= 9 && cols[4] !== '')
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
    }))
    // 状態や時刻で並べ替えると、押そうとした瞬間に行がずれる。起動順 (pane ID) で固定する。
    .sort((a, b) => Number(a.paneId.slice(1)) - Number(b.paneId.slice(1)))

  // 変わっていないときは描き直さない (描き直しの最中のクリックを取りこぼさないため)
  await update($, rows, before => (JSON.stringify(before) === JSON.stringify(list) ? before : list))

  const count = (state: string) => list.filter(row => row.state === state).length
  $.ui.status(
    `${ICON.waiting.mark}${count('waiting')} ${ICON.running.mark}${count('running')} ${ICON.done.mark}${count('done')}`,
  )
}

const age = (now: number, since: number): string => {
  if (since === 0) return ''
  const minutes = Math.floor((now - since) / 60000)
  if (minutes < 1) return 'たった今'
  if (minutes < 60) return `${minutes}分前`

  return `${Math.floor(minutes / 60)}時間前`
}

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

const show = async ($: EngineInterface, row: SessionRow): Promise<void> => {
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
  const row =
    index < 0 ? 0 : direction === 'j' ? Math.min(index + 1, bandOrder.length - 1) : Math.max(index - 1, 0)
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
  const paneId = await read($, focused)

  return (await read($, rows)).find(row => row.paneId === paneId)
}

// 見えない WORKERS セッションに window を作り、依頼文を渡して claude を起動する
const startTask = async ($: EngineInterface, task: string): Promise<string> => {
  const name = oneLine(task, 24).replace(/[.:]/g, ' ')
  const { stdout: cwd } = await $.process.run(['pwd'])
  const launch = ['-n', name, '-c', cwd.trim(), '-P', '-F', '#{pane_id}', 'claude', task]
  const { exitCode } = await $.process.run(['tmux', 'has-session', '-t', `=${WORKERS}`])
  const paneId =
    exitCode === 0
      ? await tmux($, ['new-window', '-d', '-t', `=${WORKERS}:`, ...launch])
      : await tmux($, ['new-session', '-d', '-s', WORKERS, ...launch])
  await poll($)

  return paneId
}

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
      })
    }

    return done
  })

  on('session.end', async ($, e, next) => {
    const paneId = await $.env.get('TMUX_PANE')
    if (paneId !== undefined) {
      const argv = ['tmux']
      for (const name of ['state', 'task', 'branch', 'last', 'since']) {
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
    if (e.isInteractive) {
      const messages = await $.session.messages({ last: 50 }).catch(() => [])
      const list = Array.isArray(messages) ? messages : []
      const lastUser = list.filter(m => m.role === 'user' && m.text.trim() !== '').at(-1)
      const lastAnswer = list.filter(m => m.role === 'assistant' && m.text.trim() !== '').at(-1)
      await setState($, lastUser === undefined ? 'idle' : 'done', {
        task: oneLine(lastUser?.text, 80),
        branch: await currentBranch($),
        last: oneLine(lastAnswer?.text, 120),
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
      pollTimer ??= $.clock.every(POLL_MS, () => void poll($))
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

      return { text: 'Claude ボードを閉じました。' }
    }
    await poll($)
    pollTimer ??= $.clock.every(POLL_MS, () => void poll($))

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
    const now = await $.clock.now()
    const butler = await butlerPane($).catch(() => undefined)
    const killingPane = await read($, killing)
    // 執事自身は一覧に出さない
    const others = list.filter(row => row.paneId !== butler?.paneId)

    if (others.length === 0) {
      return (
        <Box borderStyle="round" borderDimColor paddingX={1}>
          <Text dimColor>Claude ボード: 状態を書き出している Claude はまだいません。</Text>
        </Box>
      )
    }

    bandOrder = others.map(row => row.paneId)
    bandRequestId = e.requestId
    // 枠の上下で 2 行使う。空行を挟んで全部入るなら挟み、入らなければ詰める。
    // 詰めても入らない分は切り捨てず、帯の中でスクロールさせる。
    const isSpacious = 2 + others.length * 2 - 1 <= e.props.maxRows
    return (
      <Box flexDirection="column" gap={isSpacious ? 1 : 0} borderStyle="round" borderDimColor paddingX={1}>
        {others.map(row => {
          const icon = iconOf(row.state)
          const isShown = row.windowId === butler?.windowId

          return (
            // 行全体が 1 つのボタン。クリック・Enter・l で表示する
            <Button key={`show-${row.paneId}`} plain onPress={() => show($, row)}>
              {killingPane === row.paneId && <Text color="red" bold>もう一度 d で消す </Text>}
              <Text color={icon.color} bold>
                {icon.mark} {icon.label}
              </Text>{' '}
              <Text bold>{row.branch || row.location}</Text>{' '}
              <Text dimColor>
                {isShown ? '表示中' : row.location} · {age(now, row.since)}
              </Text>{' '}
              {(row.last || row.task).slice(0, 160)}
            </Button>
          )
        })}
        {/* キー (j/k/l/d) を受けるだけのボタン。画面には出さない */}
        <Box display="none">
          {(
            [
              ['j', '↓', () => move($, 'j')],
              ['k', '↑', () => move($, 'k')],
              ['l', '表示', async () => { const row = await focusedRow($); if (row) await show($, row) }],
              ['d', '消す', async () => { const row = await focusedRow($); if (row) await kill($, row) }],
            ] as const
          ).map(([hotkey, label, onPress]) => (
            <Button key={`key-${hotkey}`} label={label} hotkey={hotkey} plain dimColor onPress={onPress} />
          ))}
        </Box>
      </Box>
    )
  })
}
