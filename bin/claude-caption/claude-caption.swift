import Cocoa

// E2E動作確認動画の撮影用の字幕オーバーレイ。
// /tmp/claude-caption.txt を監視し、内容を画面下部中央に字幕として表示する。
// 空ファイル or ファイル無しで非表示。操作は caption コマンド(bin/caption)から行う。
// クリック透過なのでE2Eの操作を邪魔しない。

let captionFile = "/tmp/claude-caption.txt"
let fontSize = CGFloat(ProcessInfo.processInfo.environment["CAPTION_FONT_SIZE"].flatMap { Double($0) } ?? 26)

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var box: NSView!
    private var label: NSTextField!
    private var lastText = ""
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.usesSingleLineMode = false

        box = NSView()
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.78).cgColor
        box.layer?.cornerRadius = 12
        // 暗い背景の上でもボックスの輪郭が分かるように縁取りする
        box.layer?.borderWidth = 1
        box.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        box.addSubview(label)

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
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = box
        panel.alphaValue = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
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
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 0
        }, completionHandler: { [self] in
            if lastText.isEmpty { panel.orderOut(nil) }
        })
    }

    private func layout() {
        // 常駐アプリはキーウィンドウを持たないため NSScreen.main が nil になりうる
        guard let screen = NSScreen.main ?? NSScreen.screens.first, let cell = label.cell else { return }
        let vf = screen.visibleFrame
        let padH: CGFloat = 28
        let padV: CGFloat = 14
        let maxTextWidth = vf.width * 0.8 - padH * 2
        let size = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: maxTextWidth, height: .greatestFiniteMagnitude))
        label.frame = NSRect(x: padH, y: padV, width: ceil(size.width), height: ceil(size.height))
        let boxSize = NSSize(width: ceil(size.width) + padH * 2, height: ceil(size.height) + padV * 2)
        let origin = NSPoint(x: vf.midX - boxSize.width / 2, y: vf.minY + 48)
        panel.setFrame(NSRect(origin: origin, size: boxSize), display: true)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
