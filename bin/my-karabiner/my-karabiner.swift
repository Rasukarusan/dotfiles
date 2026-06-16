// ターミナルで Ctrl + S を押した瞬間、入力ソースを ABC(英字)に切り替える常駐ツール。
//
// 仕組み:
//   - CGEventTap で keyDown を監視する
//   - Control を押しながらトリガーキー(既定: S)を押し、最前面が対象ターミナルなら
//     ABC 入力ソースを選択する
//   - 入力ソースの切替は TISSelectInputSource を使う(イベント送出ではないので
//     アクセシビリティ権限は不要。必要なのは入力監視のみ)
//   - イベントは横取りしない(listenOnly)ので、元の Ctrl+S はそのまま端末に届く
//   - Karabiner のような仮想HIDドライバは使わず、ユーザー空間で完結する
//
// 必要権限: 入力監視(Input Monitoring) のみ
//
// 環境変数:
//   MYKARABINER_KEYCODE : トリガーキーの keycode(10進)。既定 1 (= S)
//   MYKARABINER_DEBUG   : 1 で詳細ログ

import Cocoa
import IOKit.hid
import Carbon

// 対象とするターミナルの bundle identifier
let terminalBundleIDs: Set<String> = [
    "com.googlecode.iterm2", // iTerm2
    "com.apple.Terminal",    // Terminal.app
    "co.zeit.hyper",         // Hyper
]

// 切替先の入力ソースID(ABCキーボードレイアウト)
let abcInputSourceID = "com.apple.keylayout.ABC"

// トリガーキーの keycode(既定: S = 0x01)。環境変数で上書き可能。
let triggerKeyCode: Int64 = {
    if let s = ProcessInfo.processInfo.environment["MYKARABINER_KEYCODE"], let v = Int64(s) {
        return v
    }
    return 0x01 // kVK_ANSI_S
}()

var tapRef: CFMachPort?
var cachedABCSource: TISInputSource?
// 環境変数 MYKARABINER_DEBUG=1 で詳細ログを出す
let debugEnabled = ProcessInfo.processInfo.environment["MYKARABINER_DEBUG"] == "1"

func log(_ message: String) {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
}

/// ABC 入力ソースを取得する(一度見つけたらキャッシュ)
func abcInputSource() -> TISInputSource? {
    if let s = cachedABCSource { return s }
    let filter = [kTISPropertyInputSourceID as String: abcInputSourceID] as CFDictionary
    guard let cfList = TISCreateInputSourceList(filter, false)?.takeRetainedValue(),
          let list = cfList as? [TISInputSource],
          let src = list.first
    else { return nil }
    cachedABCSource = src
    return src
}

/// 入力ソースを ABC に切り替える
func switchToABC() {
    guard let src = abcInputSource() else {
        if debugEnabled { log("[debug] ABC 入力ソースが見つかりません") }
        return
    }
    let status = TISSelectInputSource(src)
    if debugEnabled { log("[debug] TISSelectInputSource status=\(status)") }
}

let eventCallback: CGEventTapCallBack = { _, type, event, _ in
    // タップが無効化されたら再有効化する
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = tapRef {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    if type == .keyDown {
        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        let hasControl = event.flags.contains(.maskControl)
        if keycode == triggerKeyCode, hasControl {
            let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "(unknown)"
            if debugEnabled {
                log("[debug] Ctrl+key keycode=\(keycode) front=\(front)")
            }
            if terminalBundleIDs.contains(front) {
                switchToABC()
            }
        }
    }

    return Unmanaged.passUnretained(event)
}

func createTap() -> CFMachPort? {
    let mask = (1 << CGEventType.keyDown.rawValue)
    return CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: CGEventMask(mask),
        callback: eventCallback,
        userInfo: nil
    )
}

/// 入力監視(Input Monitoring)権限を要求する。キー入力の監視(CGEventTap)に必要。
func requestPermissions() {
    let listen = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
    log("権限状態: 入力監視=\(listen == kIOHIDAccessTypeGranted ? "OK" : "NG(\(listen.rawValue))")")
    if listen != kIOHIDAccessTypeGranted {
        log("入力監視(Input Monitoring)の権限が必要です。システム設定 > プライバシーとセキュリティ > 入力監視 で my-karabiner を許可してください。")
        _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }
}

func main() {
    requestPermissions()

    // タップ作成を試みる。権限付与待ちのため、失敗したらリトライする
    // (権限を付与すると macOS がプロセスを再起動するため、通常はここで成功する)。
    var tap = createTap()
    while tap == nil {
        log("イベントタップ作成に失敗。権限付与を待っています...")
        sleep(3)
        tap = createTap()
    }

    guard let tap = tap else { exit(1) }
    tapRef = tap

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    log("my-karabiner started")
    CFRunLoopRun()
}

main()
