import Cocoa

// E2E動作確認動画の撮影用の字幕オーバーレイ。
// /tmp/claude-caption.txt を監視し、内容を字幕として表示する。
// 空ファイル or ファイル無しで非表示。文言の操作は caption コマンド(bin/caption)から行う。
//
// 字幕はドラッグで移動でき、クリックすると右上に閉じるボタンが出る。
// ボタンは録画に写り込まないよう、クリックした時だけ現れて数秒で自動的に消える。

let captionFile = "/tmp/claude-caption.txt"
let fontSize = CGFloat(ProcessInfo.processInfo.environment["CAPTION_FONT_SIZE"].flatMap { Double($0) } ?? 26)

let padH: CGFloat = 28
let padV: CGFloat = 16
let closeSize: CGFloat = 18
// 閉じるボタンを出しっぱなしにしない。撮影中に写り込むのを防ぐ
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var box: CaptionBoxView!
    private var label: NSTextField!
    private var closeButton: CloseButtonView!
    private var lastText = ""
    private var pollTimer: Timer?
    private var closeHideTimer: Timer?

    /// ドラッグで動かされた位置。以降の文言更新でもこの位置を保つ。
    private var pinnedCenterX: CGFloat?
    private var pinnedBottomY: CGFloat?

    func applicationDidFinishLaunching(_ notification: Notification) {
        label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.usesSingleLineMode = false

        closeButton = CloseButtonView(frame: NSRect(x: 0, y: 0, width: closeSize, height: closeSize))
        closeButton.isHidden = true
        closeButton.onClick = { [weak self] in self?.dismiss() }

        box = CaptionBoxView()
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.78).cgColor
        box.layer?.cornerRadius = 12
        // 暗い背景の上でもボックスの輪郭が分かるように縁取りする
        box.layer?.borderWidth = 1
        box.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        box.addSubview(label)
        box.addSubview(closeButton)
        box.onClick = { [weak self] in self?.toggleCloseButton() }
        box.onDragEnd = { [weak self] in self?.pinCurrentPosition() }

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

        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let text = (try? String(contentsOfFile: captionFile, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text != lastText else { return }
        lastText = text
        text.isEmpty ? hide() : show(text)
    }

    // MARK: - 表示

    private func show(_ text: String) {
        let apply = { [self] in
            label.stringValue = text
            layout()
            panel.orderFrontRegardless()
        }
        if panel.isVisible && panel.alphaValue > 0 {
            // 表示中の文言切替は素早くクロスフェード
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.1
                panel.animator().alphaValue = 0
            }, completionHandler: { [self] in
                guard lastText == text else { return }
                apply()
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.12
                    panel.animator().alphaValue = 1
                }
            })
        } else {
            apply()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                panel.animator().alphaValue = 1
            }
        }
    }

    private func hide() {
        hideCloseButton()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 0
        }, completionHandler: { [self] in
            if lastText.isEmpty { panel.orderOut(nil) }
        })
    }

    /// 閉じるボタンで消す。次に caption コマンドが呼ばれれば再び表示される。
    private func dismiss() {
        try? "".write(toFile: captionFile, atomically: true, encoding: .utf8)
        lastText = ""
        hide()
    }

    // MARK: - 閉じるボタン

    private func toggleCloseButton() {
        closeButton.isHidden ? showCloseButton() : hideCloseButton()
    }

    private func showCloseButton() {
        closeButton.isHidden = false
        closeHideTimer?.invalidate()
        closeHideTimer = Timer.scheduledTimer(withTimeInterval: closeAutoHideDelay, repeats: false) { [weak self] _ in
            self?.hideCloseButton()
        }
    }

    private func hideCloseButton() {
        closeHideTimer?.invalidate()
        closeHideTimer = nil
        closeButton.isHidden = true
    }

    // MARK: - 位置

    private func pinCurrentPosition() {
        pinnedCenterX = panel.frame.midX
        pinnedBottomY = panel.frame.minY
    }

    private func layout() {
        // 常駐アプリはキーウィンドウを持たないため NSScreen.main が nil になりうる
        guard let screen = NSScreen.main ?? NSScreen.screens.first, let cell = label.cell else { return }
        let vf = screen.visibleFrame
        let maxTextWidth = vf.width * 0.8 - padH * 2
        let size = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: maxTextWidth, height: .greatestFiniteMagnitude))
        let textSize = NSSize(width: ceil(size.width), height: ceil(size.height))
        let boxSize = NSSize(width: textSize.width + padH * 2, height: textSize.height + padV * 2)

        label.frame = NSRect(origin: NSPoint(x: padH, y: padV), size: textSize)
        // 閉じるボタンは右上の余白に収める(文字には重ならない)
        closeButton.frame = NSRect(
            x: boxSize.width - closeSize - 6,
            y: boxSize.height - closeSize - 4,
            width: closeSize,
            height: closeSize
        )

        var origin = NSPoint(
            x: (pinnedCenterX ?? vf.midX) - boxSize.width / 2,
            y: pinnedBottomY ?? (vf.minY + 48)
        )
        // 文言が長くなっても画面外にはみ出さないようにする
        origin.x = min(max(origin.x, vf.minX + 8), vf.maxX - boxSize.width - 8)
        origin.y = min(max(origin.y, vf.minY + 8), vf.maxY - boxSize.height - 8)
        panel.setFrame(NSRect(origin: origin, size: boxSize), display: true)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
