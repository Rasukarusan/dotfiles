// NoSleep.app のアイコン素材を描き、引数の .iconset ディレクトリに書き出す。
// iconutil で .icns にまとめる前提で、iconset が要求するサイズとファイル名で出力する。

import Cocoa

let outDir = CommandLine.arguments[1]

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // macOS のアイコングリッドに合わせ、四辺に余白を取った角丸の板に描く
    let s = CGFloat(px)
    let body = NSBezierPath(roundedRect: NSRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8),
                            xRadius: s * 0.18, yRadius: s * 0.18)
    NSGradient(starting: NSColor(srgbRed: 0.45, green: 0.33, blue: 0.80, alpha: 1),
               ending: NSColor(srgbRed: 0.13, green: 0.15, blue: 0.38, alpha: 1))!.draw(in: body, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: s * 0.36, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    let size = symbol.size
    symbol.draw(in: NSRect(x: (s - size.width) / 2, y: (s - size.height) / 2, width: size.width, height: size.height))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: URL(fileURLWithPath: "\(outDir)/icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: URL(fileURLWithPath: "\(outDir)/icon_\(base)x\(base)@2x.png"))
}
