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
}

declare module 'claude-code' {
  interface PluginState {
    'butler-board': { rows: Shaped<SessionRow[]>; isOpen: boolean; killing: string | null; focused: string | null }
  }
}
