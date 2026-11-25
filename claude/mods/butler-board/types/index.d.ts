export type SessionRow = {
  paneId: string
  session: string
  windowId: string
  location: string
  state: string
  task: string
  branch: string
  last: string
  since: number
  // claude --resume に渡す ID と、再開するときの作業ディレクトリ
  sessionId: string
  cwd: string
}

// 閉じたセッション。ボードの「最近閉じた」から claude --resume で再開する。
export type RecentRow = {
  sessionId: string
  cwd: string
  branch: string
  task: string
  last: string
  closedAt: number
}

declare module 'claude-code' {
  interface PluginState {
    'butler-board': {
      rows: Shaped<SessionRow[]>
      recent: Shaped<RecentRow[]>
      isOpen: boolean
      view: 'live' | 'recent'
      killing: string | null
      focused: string | null
    }
  }
}
