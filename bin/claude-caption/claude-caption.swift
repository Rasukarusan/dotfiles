import Cocoa

// 画面上に字幕オーバーレイを出す常駐アプリ。手動の画面録画の実況や、E2E動画の説明に使う。
//
// /tmp/claude-caption/<番号>.txt を監視し、1ファイル=1つの字幕として表示する。
// ファイルが消えるか空になれば、その字幕を消す。文言の操作は caption コマンド(bin/caption)から行う。
//
// 字幕はドラッグで移動でき、移動先は <番号>.pos に保存して番号ごとに覚える。
// クリックするとその場編集に入り、左上に番号、右上に閉じるボタンが出る。
// Enter で確定、Escape で取り消し。録画に写り込まないよう、確定すると消える。

let stateDir = "/tmp/claude-caption"
let env = ProcessInfo.processInfo.environment
let fontSize = CGFloat(env["CAPTION_FONT_SIZE"].flatMap { Double($0) } ?? 26)

/// "#RRGGBB" 形式を読む。読めなければ fallback を使う。
func color(fromHex hex: String?, fallback: NSColor) -> NSColor {
    guard var value = hex?.trimmingCharacters(in: .whitespaces) else { return fallback }
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return fallback }
    return NSColor(
        red: CGFloat((rgb >> 16) & 0xFF) / 255,
        green: CGFloat((rgb >> 8) & 0xFF) / 255,
        blue: CGFloat(rgb & 0xFF) / 255,
        alpha: 1
    )
}

let textColor = color(fromHex: env["CAPTION_COLOR"], fallback: .white)
let badgeColor = color(fromHex: env["CAPTION_BADGE_COLOR"], fallback: color(fromHex: "#7FD4F5", fallback: .white))

/// 字幕を画面のどこに置くか。ドラッグで動かした場合はそちらが優先される。
enum Anchor: String {
    case bottom, top, center
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"

    var isTopSide: Bool { self == .top || self == .topLeft || self == .topRight }
}

/// 字幕ごとの見た目。
struct Style: Equatable {
    var alpha: CGFloat = 1
    var color: NSColor = textColor
    var anchor: Anchor = .bottom
}

let padH: CGFloat = 28
let padV: CGFloat = 16
let sideMargin: CGFloat = 24
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

/// 左上に出る番号。どの番号を指定すれば操作できるかを示す。
final class SlotBadgeView: NSView {
    var number = 1

    override func draw(_ dirtyRect: NSRect) {
        let text = NSAttributedString(
            string: "\(number)",
            attributes: [
                .font: NSFont.systemFont(ofSize: bounds.height * 0.62, weight: .regular),
                .foregroundColor: badgeColor,
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

/// キーボード入力を受け取れるパネル。borderless は既定でキーウィンドウになれない。
final class CaptionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// 字幕1つ分のウィンドウ。
final class CaptionWindow: NSObject, NSTextFieldDelegate {
    let slot: Int
    let panel: CaptionPanel
    private let box: CaptionBoxView
    private let label: NSTextField
    private let editor: NSTextField
    private let closeButton: CloseButtonView
    private let slotBadge: SlotBadgeView
    private var controlsHideTimer: Timer?

    /// ドラッグで決まった位置(中央x, 下端y)。nil なら anchor の位置に並べる。
    var pinned: NSPoint?
    private(set) var text = ""
    private(set) var style = Style()
    private(set) var isEditing = false

    var onDismiss: ((Int) -> Void)?
    var onMoved: ((Int, NSPoint) -> Void)?
    var onCommit: ((Int, String) -> Void)?
    var onEditingLayoutChange: (() -> Void)?

    init(slot: Int) {
        self.slot = slot

        label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = textColor
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.usesSingleLineMode = false

        // 見た目を label に揃えて、編集に入っても字幕がその場で変形しないようにする
        editor = NSTextField(string: "")
        editor.font = label.font
        editor.textColor = textColor
        editor.alignment = .center
        editor.isBordered = false
        editor.drawsBackground = false
        editor.focusRingType = .none
        editor.isHidden = true

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
        box.addSubview(editor)
        box.addSubview(closeButton)
        box.addSubview(slotBadge)

        panel = CaptionPanel(
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

        super.init()

        editor.delegate = self
        closeButton.onClick = { [weak self] in
            guard let self else { return }
            endEditing(commit: false)
            onDismiss?(self.slot)
        }
        box.onClick = { [weak self] in self?.beginEditing() }
        box.onDragEnd = { [weak self] in
            guard let self else { return }
            let p = NSPoint(x: panel.frame.midX, y: panel.frame.minY)
            pinned = p
            onMoved?(self.slot, p)
        }
    }

    // MARK: - 編集

    /// クリックでその場編集に入る。字幕アプリは通常フォーカスを奪わないので、
    /// ここだけ明示的にアクティブにしてキー入力を受け取る。
    func beginEditing() {
        guard !isEditing else { return }
        isEditing = true
        editor.stringValue = text
        editor.isHidden = false
        label.isHidden = true
        showControls(autoHide: false)
        onEditingLayoutChange?()

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(editor)
        editor.currentEditor()?.selectAll(nil)
    }

    func endEditing(commit: Bool) {
        guard isEditing else { return }
        isEditing = false
        let value = editor.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        editor.isHidden = true
        label.isHidden = false
        hideControls()
        panel.makeFirstResponder(nil)
        // 元のアプリにフォーカスを返す(hide だと字幕まで消えてしまう)
        NSApp.deactivate()
        if commit { onCommit?(slot, value) }
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        // ウィンドウがキーでなくなった場合など、Enter 以外の抜け方も確定として扱う
        endEditing(commit: true)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            endEditing(commit: true)
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            endEditing(commit: false)
            return true
        default:
            return false
        }
    }

    func setText(_ value: String) {
        text = value
        label.attributedStringValue = Self.styled(value, style: style)
    }

    func setStyle(_ value: Style) {
        style = value
        label.attributedStringValue = Self.styled(text, style: value)
    }

    /// 行頭の `>` が付いた行だけを不透明で描き、他は style.alpha まで落とす。
    /// 複数行は箇条書きとして読ませたいので左揃えにする。
    static func styled(_ raw: String, style: Style) -> NSAttributedString {
        let lines = raw.components(separatedBy: "\n")
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = lines.count > 1 ? .left : .center
        paragraph.lineSpacing = 3
        paragraph.lineBreakMode = .byWordWrapping

        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let result = NSMutableAttributedString()
        for (index, line) in lines.enumerated() {
            var body = line
            var alpha = style.alpha
            if body.hasPrefix(">") {
                body.removeFirst()
                if body.hasPrefix(" ") { body.removeFirst() }
                alpha = 1
            }
            if index > 0 { result.append(NSAttributedString(string: "\n")) }
            result.append(NSAttributedString(
                string: body,
                attributes: [
                    .font: font,
                    .foregroundColor: style.color.withAlphaComponent(alpha),
                    .paragraphStyle: paragraph,
                ]
            ))
        }
        return result
    }

    func measure(maxWidth: CGFloat) -> NSSize {
        guard let cell = label.cell else { return .zero }
        let bounds = NSRect(x: 0, y: 0, width: maxWidth, height: .greatestFiniteMagnitude)
        var size = cell.cellSize(forBounds: bounds)
        // 空文字だと箱が潰れて掴めなくなるので、編集中は最低幅を確保する
        if isEditing { size.width = max(size.width, 240) }
        return NSSize(width: ceil(size.width) + padH * 2, height: ceil(size.height) + padV * 2)
    }

    func place(origin: NSPoint, size: NSSize) {
        let textFrame = NSRect(
            x: padH,
            y: padV,
            width: size.width - padH * 2,
            height: size.height - padV * 2
        )
        label.frame = textFrame
        editor.frame = textFrame
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

    private func showControls(autoHide: Bool = true) {
        closeButton.isHidden = false
        slotBadge.isHidden = false
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
        guard autoHide else { return }
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
    /// ドラッグで動かした座標。--pos の指定先(.pos)とは別物
    private func xyPath(_ slot: Int) -> String { "\(stateDir)/\(slot).xy" }

    private func readValue(_ slot: Int, _ suffix: String) -> String? {
        guard let raw = try? String(contentsOfFile: "\(stateDir)/\(slot).\(suffix)", encoding: .utf8) else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func readStyle(_ slot: Int) -> Style {
        var style = Style()
        if let alpha = readValue(slot, "alpha").flatMap({ Double($0) }) {
            style.alpha = CGFloat(min(max(alpha, 0), 1))
        }
        style.color = color(fromHex: readValue(slot, "color"), fallback: textColor)
        if let anchor = readValue(slot, "pos").flatMap({ Anchor(rawValue: $0) }) {
            style.anchor = anchor
        }
        return style
    }

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

    /// 位置はディスクを正とする。caption --reset で .xy が消えれば anchor の位置に戻る。
    private func readPinned(_ slot: Int) -> NSPoint? {
        guard let raw = readValue(slot, "xy") else { return nil }
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
                // 編集中は入力を上書きしない
                if window.isEditing { continue }
                let pinned = readPinned(slot)
                if pinned != window.pinned {
                    window.pinned = pinned
                    needsRelayout = true
                }
                let style = readStyle(slot)
                if style != window.style {
                    window.setStyle(style)
                    needsRelayout = true
                }
                if window.text != text {
                    window.crossfade(to: text) { [weak self] in self?.relayout() }
                    needsRelayout = false
                }
            } else {
                let window = makeWindow(slot: slot)
                window.setStyle(readStyle(slot))
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
        window.onDismiss = { [weak self] in self?.forget(slot: $0) }
        window.onMoved = { [weak self] slot, point in
            guard let self else { return }
            try? "\(point.x) \(point.y)".write(toFile: xyPath(slot), atomically: true, encoding: .utf8)
        }
        window.onCommit = { [weak self] slot, value in
            guard let self else { return }
            if value.isEmpty {
                forget(slot: slot)
                return
            }
            // 先に画面へ反映してからファイルに書く。poll が差分なしと見なすので再フェードしない
            windows[slot]?.setText(value)
            relayout()
            try? value.write(toFile: textPath(slot), atomically: true, encoding: .utf8)
        }
        window.onEditingLayoutChange = { [weak self] in self?.relayout() }
        return window
    }

    /// 消えた字幕の状態(文言・位置・見た目)をまとめて捨てる。
    private func forget(slot: Int) {
        for suffix in ["txt", "xy", "alpha", "color", "pos"] {
            try? FileManager.default.removeItem(atPath: "\(stateDir)/\(slot).\(suffix)")
        }
    }

    // MARK: - 配置

    /// ドラッグされていない字幕は、指定された位置ごとに番号順で積む。
    private func relayout() {
        // 常駐アプリはキーウィンドウを持たないため NSScreen.main が nil になりうる
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let vf = screen.visibleFrame
        var stackOffsets: [Anchor: CGFloat] = [:]

        for slot in windows.keys.sorted() {
            guard let window = windows[slot] else { continue }
            let size = window.measure(maxWidth: vf.width * 0.8 - padH * 2)

            var origin: NSPoint
            if let pinned = window.pinned {
                origin = NSPoint(x: pinned.x - size.width / 2, y: pinned.y)
            } else {
                let anchor = window.style.anchor
                let offset = stackOffsets[anchor] ?? 0
                origin = self.origin(for: anchor, size: size, in: vf, offset: offset)
                stackOffsets[anchor] = offset + size.height + stackGap
            }
            // 文言が長くなっても画面外にはみ出さないようにする
            origin.x = min(max(origin.x, vf.minX + 8), vf.maxX - size.width - 8)
            origin.y = min(max(origin.y, vf.minY + 8), vf.maxY - size.height - 8)
            window.place(origin: origin, size: size)
        }
    }

    /// 上側の位置は下へ、下側の位置は上へ積み上げる。
    private func origin(for anchor: Anchor, size: NSSize, in vf: NSRect, offset: CGFloat) -> NSPoint {
        let x: CGFloat
        switch anchor {
        case .topLeft, .bottomLeft:
            x = vf.minX + sideMargin
        case .topRight, .bottomRight:
            x = vf.maxX - size.width - sideMargin
        case .top, .bottom, .center:
            x = vf.midX - size.width / 2
        }

        let y: CGFloat
        switch anchor {
        case .top, .topLeft, .topRight:
            y = vf.maxY - size.height - bottomMargin - offset
        case .center:
            y = vf.midY - size.height / 2 - offset
        case .bottom, .bottomLeft, .bottomRight:
            y = vf.minY + bottomMargin + offset
        }
        return NSPoint(x: x, y: y)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
