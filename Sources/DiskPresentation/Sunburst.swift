import SwiftUI
import DiskDomain

struct Segment {
    let node: Node
    let depth: Int        // 1 = first ring
    let start: Double     // fraction of full circle, 0...1
    let end: Double
}

func segments(of root: Node, maxDepth: Int) -> [Segment] {
    var out: [Segment] = []
    func walk(_ n: Node, depth: Int, start: Double, span: Double) {
        guard depth <= maxDepth, n.size > 0 else { return }
        var s = start
        for c in n.children {
            let w = span * Double(c.size) / Double(n.size)
            if w < 0.002 { break }   // children are sorted desc; the rest are slivers
            out.append(Segment(node: c, depth: depth, start: s, end: s + w))
            walk(c, depth: depth + 1, start: s, span: w)
            s += w
        }
    }
    walk(root, depth: 1, start: 0, span: 1)
    return out
}

struct Sunburst: View {
    let root: Node
    var onSelect: (Node) -> Void
    var onBack: () -> Void
    @State private var hovered: Node?
    private let maxDepth = 5

    var body: some View {
        GeometryReader { geo in
            let segs = segments(of: root, maxDepth: maxDepth)
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let R = min(geo.size.width, geo.size.height) / 2 - 8
            let r0 = R * 0.25, ring = (R - r0) / CGFloat(maxDepth)

            ZStack {
                Canvas { ctx, _ in
                    for s in segs {
                        let inner = r0 + ring * CGFloat(s.depth - 1), outer = inner + ring
                        var p = Path()
                        p.addArc(center: c, radius: outer, startAngle: .radians(s.start * 2 * .pi - .pi / 2), endAngle: .radians(s.end * 2 * .pi - .pi / 2), clockwise: false)
                        p.addArc(center: c, radius: inner, startAngle: .radians(s.end * 2 * .pi - .pi / 2), endAngle: .radians(s.start * 2 * .pi - .pi / 2), clockwise: true)
                        p.closeSubpath()
                        let color = s.node.isDir
                            ? Color(hue: (s.start + s.end) / 2, saturation: 0.6, brightness: 1 - 0.08 * Double(s.depth))
                            : Color.gray.opacity(0.5)
                        ctx.fill(p, with: .color(s.node === hovered ? color.opacity(0.6) : color))
                        ctx.stroke(p, with: .color(Color(nsColor: .windowBackgroundColor)), lineWidth: 1)
                    }
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r0 + 2, y: c.y - r0 + 2, width: 2 * r0 - 4, height: 2 * r0 - 4)),
                             with: .color(Color.secondary.opacity(0.15)))
                }
                VStack(spacing: 2) {
                    let n = hovered ?? root
                    Text(n.name).font(.headline).lineLimit(1)
                    Text(formatSize(n.size)).font(.title3.monospacedDigit())
                    if root.parent != nil && hovered == nil { Text("click to go up").font(.caption).foregroundStyle(.secondary) }
                }
                .frame(width: r0 * 1.6)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                if case .active(let p) = phase { hovered = hit(p, c, r0, ring, segs) } else { hovered = nil }
            }
            .gesture(SpatialTapGesture().onEnded { e in
                let d = hypot(e.location.x - c.x, e.location.y - c.y)
                if d < r0 { onBack() } else if let n = hit(e.location, c, r0, ring, segs) { onSelect(n) }
            })
        }
    }

    private func hit(_ p: CGPoint, _ c: CGPoint, _ r0: CGFloat, _ ring: CGFloat, _ segs: [Segment]) -> Node? {
        let dx = p.x - c.x, dy = p.y - c.y
        let d = hypot(dx, dy)
        guard d >= r0 else { return nil }
        let depth = Int((d - r0) / ring) + 1
        var a = (atan2(dy, dx) + .pi / 2) / (2 * .pi)
        if a < 0 { a += 1 }
        return segs.first { $0.depth == depth && a >= $0.start && a < $0.end }?.node
    }
}

