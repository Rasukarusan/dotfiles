// メニューバーから `pmset -a disablesleep` を切り替える常駐アプリ。
// 無効化中は蓋を閉じてもスリープせず、Claude Code 等の作業が続く。
// pmset は root 権限が要るので、build.sh が置く sudoers 設定でパスワードなしの sudo を使う。

import Cocoa

let pmset = "/usr/bin/pmset"

@discardableResult
func run(_ path: String, _ args: [String]) -> (status: Int32, output: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return (-1, "\(error)") }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

// disablesleep が 0 のときは `pmset -g` に SleepDisabled 行が出ないことがある
func isSleepDisabled() -> Bool {
    for line in run(pmset, ["-g"]).output.split(separator: "\n") {
        let cols = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
        if cols.count >= 2, cols[0] == "SleepDisabled" { return cols[1] == "1" }
    }
    return false
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let toggleItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        stateItem.isEnabled = false
        toggleItem.target = self
        menu.addItem(stateItem)
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        refresh()
        // ターミナルから pmset を直接叩いた場合にも表示を追従させる
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        let disabled = isSleepDisabled()
        let symbol = disabled ? "cup.and.saucer.fill" : "moon.zzz"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = disabled ? "スリープ無効化中" : "通常（スリープする）"
        stateItem.title = disabled ? "スリープ無効化中（蓋を閉じても動く）" : "通常（蓋を閉じるとスリープ）"
        toggleItem.title = disabled ? "スリープを有効に戻す" : "スリープを無効化する"
    }

    @objc func toggle() {
        let next = isSleepDisabled() ? "0" : "1"
        let result = run("/usr/bin/sudo", ["-n", pmset, "-a", "disablesleep", next])
        if result.status != 0 {
            let alert = NSAlert()
            alert.messageText = "切り替えに失敗しました"
            alert.informativeText = "sudoers の設定を確認してください（bin/nosleep/build.sh を再実行）。\n\n\(result.output)"
            alert.runModal()
        }
        refresh()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
