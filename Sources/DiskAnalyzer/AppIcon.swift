import AppKit

/// Dock icon drawn in code: rounded tile with two sunburst rings.
func appIcon() -> NSImage {
    NSImage(size: NSSize(width: 512, height: 512), flipped: false) { r in
        NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
        NSBezierPath(roundedRect: r.insetBy(dx: 40, dy: 40), xRadius: 90, yRadius: 90).fill()
        let c = NSPoint(x: r.midX, y: r.midY)
        let rings: [(inner: CGFloat, outer: CGFloat, spans: [CGFloat])] = [
            (70, 125, [0.45, 0.3, 0.25]),
            (130, 180, [0.25, 0.15, 0.2, 0.1, 0.12]),
        ]
        for ring in rings {
            var start: CGFloat = 90
            for (i, span) in ring.spans.enumerated() {
                let end = start - span * 360
                let p = NSBezierPath()
                p.appendArc(withCenter: c, radius: ring.outer, startAngle: start, endAngle: end, clockwise: true)
                p.appendArc(withCenter: c, radius: ring.inner, startAngle: end, endAngle: start, clockwise: false)
                p.close()
                NSColor(hue: CGFloat(i) / CGFloat(ring.spans.count) * 0.8 + 0.05, saturation: 0.65,
                        brightness: ring.inner < 100 ? 0.95 : 0.8, alpha: 1).setFill()
                p.fill()
                start = end - 2   // small gap between segments
            }
        }
        return true
    }
}

/// 1024px PNG of the icon, used by bundle.sh to build AppIcon.icns.
func writeIconPNG(to path: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 512, height: 512)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    appIcon().draw(in: NSRect(x: 0, y: 0, width: 512, height: 512))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
