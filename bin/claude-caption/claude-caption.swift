import Cocoa

// 画面上に字幕オーバーレイを出す常駐アプリ。手動の画面録画の実況や、E2E動画の説明に使う。
//
// /tmp/claude-caption/<番号>.txt を監視し、1ファイル=1つの字幕として表示する。
// ファイルが消えるか空になれば、その字幕を消す。文言の操作は caption コマンド(bin/caption)から行う。
//
// 字幕はドラッグで移動でき、移動先は <番号>.pos に保存して番号ごとに覚える。
// クリックすると左上に番号バッジ、右上に閉じるボタンが出る。
// 録画に写り込まないよう、どちらも数秒で自動的に消える。

let stateDir = "/tmp/claude-caption"
let fontSize = CGFloat(ProcessInfo.processInfo.environment["CAPTION_FONT_SIZE"].flatMap { Double($0) } ?? 26)

let padH: CGFloat = 28
let padV: CGFloat = 16
let closeSize: CGFloat = 18
let stackGap: CGFloat = 8
let bottomMargin: CGFloat = 48
let closeAutoHideDelay: TimeInterval = 4

/// 字幕ボックス本体。ドラッグでの移動と、クリックでの閉じるボタン表示を受け持つ。
final class CaptionBoxView: NSView {
    var onClick: (() -> Void)?
    var onDragEnd: (() -> Void)?

    private var grabOffset: NSPoint = .zero
    private var didDrag = false

    override func mouseDown(with event: NSEvent) {
        // ウィンドウ内座標をそのまま掴み位置として覚えておく
        grabOffset = event.locationInWindow
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let mouse = NSEvent.mouseLocation
        let origin = NSPoint(x: mouse.x - grabOffset.x, y: mouse.y - grabOffset.y)
        if !didDrag {
            let moved = hypot(origin.x - window.frame.minX, origin.y - window.frame.minY)
            if moved < 3 { return }
            didDrag = true
        }
        window.setFrameOrigin(origin)
    }

    override func mouseUp(with event: NSEvent) {
        didDrag ? onDragEnd?() : onClick?()
    }
}

/// 左上に出る番号バッジ。どの番号を指定すれば操作できるかを示す。
final class SlotBadgeView: NSView {
    var number = 1

    override func draw(_ dirtyRect: NSRect) {
        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
        NSColor.white.withAlphaComponent(0.25).setFill()
        circle.fill()
        NSColor.white.withAlphaComponent(0.5).setStroke()
        circle.lineWidth = 1
        circle.stroke()

        let text = NSAttributedString(
            string: "\(number)",
            attributes: [
                .font: NSFont.systemFont(ofSize: bounds.height * 0.62, weight: .bold),
                .foregroundColor: NSColor.white,
            ]
        )
        let size = text.size()
        text.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
    }
}

/// 右上に出る閉じるボタン。
final class CloseButtonView: NSView {
    var onClick: (() -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
        NSColor.white.withAlphaComponent(0.25).setFill()
        circle.fill()
        NSColor.white.withAlphaComponent(0.5).setStroke()
        circle.lineWidth = 1
        circle.stroke()

        let inset = bounds.width * 0.32
        let cross = NSBezierPath()
        cross.move(to: NSPoint(x: inset, y: inset))
        cross.line(to: NSPoint(x: bounds.width - inset, y: bounds.height - inset))
        cross.move(to: NSPoint(x: bounds.width - inset, y: inset))
        cross.line(to: NSPoint(x: inset, y: bounds.height - inset))
        cross.lineWidth = 1.8
        cross.lineCapStyle = .round
        NSColor.white.setStroke()
        cross.stroke()
    }

    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) { onClick?() }
    }
}

/// 字幕1つ分のウィンドウ。
final class CaptionWindow {
    let slot: Int
    let panel: NSPanel
    private let box: CaptionBoxView
    private let label: NSTextField
    private let closeButton: CloseButtonView
    private let slotBadge: SlotBadgeView
    private var controlsHideTimer: Timer?

    /// ドラッグで決まった位置(中央x, 下端y)。nil なら既定位置に並べる。
    var pinned: NSPoint?
    private(set) var text = ""

    var onDismiss: ((Int) -> Void)?
    var onMoved: ((Int, NSPoint) -> Void)?

    init(slot: Int) {
        self.slot = slot

        label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.usesSingleLineMode = false

        closeButton = CloseButtonView(frame: NSRect(x: 0, y: 0, width: closeSize, height: closeSize))
        closeButton.isHidden = true

        slotBadge = SlotBadgeView(frame: NSRect(x: 0, y: 0, width: closeSize, height: closeSize))
        slotBadge.number = slot
        slotBadge.isHidden = true

        box = CaptionBoxView()
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.78).cgColor
        box.layer?.cornerRadius = 12
        // 暗い背景の上でもボックスの輪郭が分かるように縁取りする
        box.layer?.borderWidth = 1
        box.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        box.addSubview(label)
        box.addSubview(closeButton)
        box.addSubview(slotBadge)

        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        // ウィンドウは字幕ボックスと同じ大きさなので、ここ以外のクリックは下のアプリに届く
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = box
        panel.alphaValue = 0

        closeButton.onClick = { [weak self] in
            guard let self else { return }
            onDismiss?(self.slot)
        }
        box.onClick = { [weak self] in self?.toggleControls() }
        box.onDragEnd = { [weak self] in
            guard let self else { return }
            let p = NSPoint(x: panel.frame.midX, y: panel.frame.minY)
            pinned = p
            onMoved?(self.slot, p)
        }
    }

    func setText(_ value: String) {
        text = value
        label.stringValue = value
    }

    func measure(maxWidth: CGFloat) -> NSSize {
        guard let cell = label.cell else { return .zero }
        let bounds = NSRect(x: 0, y: 0, width: maxWidth, height: .greatestFiniteMagnitude)
        let size = cell.cellSize(forBounds: bounds)
        return NSSize(width: ceil(size.width) + padH * 2, height: ceil(size.height) + padV * 2)
    }

    func place(origin: NSPoint, size: NSSize) {
        label.frame = NSRect(
            x: padH,
            y: padV,
            width: size.width - padH * 2,
            height: size.height - padV * 2
        )
        // 番号バッジと閉じるボタンは上端の余白に収める(文字には重ならない)
        slotBadge.frame = NSRect(x: 6, y: size.height - closeSize - 4, width: closeSize, height: closeSize)
        closeButton.frame = NSRect(
            x: size.width - closeSize - 6,
            y: size.height - closeSize - 4,
            width: closeSize,
            height: closeSize
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    func fadeIn() {
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 1
        }
    }

    func fadeOut(completion: @escaping () -> Void) {
        hideControls()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 0
        }, completionHandler: completion)
    }

    /// 表示中の文言差し替え。素早くクロスフェードする。
    func crossfade(to value: String, relayout: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.1
            panel.animator().alphaValue = 0
        }, completionHandler: { [self] in
            setText(value)
            relayout()
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                panel.animator().alphaValue = 1
            }
        })
    }

    func destroy() {
        hideControls()
        panel.orderOut(nil)
    }

    private func toggleControls() {
        closeButton.isHidden ? showControls() : hideControls()
    }

    private func showControls() {
        closeButton.isHidden = false
        slotBadge.isHidden = false
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: closeAutoHideDelay, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }

    private func hideControls() {
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
        closeButton.isHidden = true
        slotBadge.isHidden = true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windows: [Int: CaptionWindow] = [:]
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    // MARK: - 状態の読み取り

    private func textPath(_ slot: Int) -> String { "\(stateDir)/\(slot).txt" }
    private func posPath(_ slot: Int) -> String { "\(stateDir)/\(slot).pos" }

    private func readTexts() -> [Int: String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: stateDir)) ?? []
        var result: [Int: String] = [:]
        for name in names where name.hasSuffix(".txt") {
            guard let slot = Int(name.dropLast(4)) else { continue }
            let text = (try? String(contentsOfFile: "\(stateDir)/\(name)", encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !text.isEmpty { result[slot] = text }
        }
        return result
    }

    /// 位置はディスクを正とする。caption --reset で .pos が消えれば既定位置に戻る。
    private func readPinned(_ slot: Int) -> NSPoint? {
        guard let raw = try? String(contentsOfFile: posPath(slot), encoding: .utf8) else { return nil }
        let parts = raw.split(separator: " ").compactMap { Double($0) }
        guard parts.count == 2 else { return nil }
        return NSPoint(x: parts[0], y: parts[1])
    }

    private func poll() {
        let texts = readTexts()
        var needsRelayout = false

        for (slot, window) in windows where texts[slot] == nil {
            windows[slot] = nil
            window.fadeOut { window.destroy() }
            needsRelayout = true
        }

        for (slot, text) in texts {
            if let window = windows[slot] {
                let pinned = readPinned(slot)
                if pinned != window.pinned {
                    window.pinned = pinned
                    needsRelayout = true
                }
                if window.text != text {
                    window.crossfade(to: text) { [weak self] in self?.relayout() }
                    needsRelayout = false
                }
            } else {
                let window = makeWindow(slot: slot)
                window.setText(text)
                window.pinned = readPinned(slot)
                windows[slot] = window
                relayout()
                window.fadeIn()
                needsRelayout = false
            }
        }

        if needsRelayout { relayout() }
    }

    private func makeWindow(slot: Int) -> CaptionWindow {
        let window = CaptionWindow(slot: slot)
        window.onDismiss = { [weak self] slot in
            // ファイルを消せば、次の poll で通常の消去経路に乗る
            try? FileManager.default.removeItem(atPath: self?.textPath(slot) ?? "")
        }
        window.onMoved = { [weak self] slot, point in
            guard let self else { return }
            try? "\(point.x) \(point.y)".write(toFile: posPath(slot), atomically: true, encoding: .utf8)
        }
        return window
    }

    // MARK: - 配置

    /// 位置を指定されていない字幕は、番号順に下中央から上へ積む。
    private func relayout() {
        // 常駐アプリはキーウィンドウを持たないため NSScreen.main が nil になりうる
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let vf = screen.visibleFrame
        var stackOffset: CGFloat = 0

        for slot in windows.keys.sorted() {
            guard let window = windows[slot] else { continue }
            let size = window.measure(maxWidth: vf.width * 0.8 - padH * 2)

            var origin: NSPoint
            if let pinned = window.pinned {
                origin = NSPoint(x: pinned.x - size.width / 2, y: pinned.y)
            } else {
                origin = NSPoint(x: vf.midX - size.width / 2, y: vf.minY + bottomMargin + stackOffset)
                stackOffset += size.height + stackGap
            }
            // 文言が長くなっても画面外にはみ出さないようにする
            origin.x = min(max(origin.x, vf.minX + 8), vf.maxX - size.width - 8)
            origin.y = min(max(origin.y, vf.minY + 8), vf.maxY - size.height - 8)
            window.place(origin: origin, size: size)
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
