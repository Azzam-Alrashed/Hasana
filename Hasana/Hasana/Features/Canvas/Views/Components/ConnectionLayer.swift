import SwiftUI

struct ConnectionLayer: View {
    let nodes: [HasanaCanvasNode]
    let dragOffsets: [HasanaCanvasNodeID: CGSize]
    let viewport: ViewportState
    let center: CGPoint

    var body: some View {
        Canvas { context, _ in
            let nodeByID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

            for node in nodes {
                for targetID in node.connectedNodeIDs {
                    guard let target = nodeByID[targetID] else { continue }

                    let start = screenPoint(for: node)
                    let end = screenPoint(for: target)
                    drawConnection(
                        context: context,
                        from: start,
                        to: end,
                        color: node.theme.color.opacity(0.42)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func screenPoint(for node: HasanaCanvasNode) -> CGPoint {
        let dragOffset = dragOffsets[node.id] ?? .zero
        return CGPoint(
            x: center.x + viewport.offset.width + ((node.position.x + dragOffset.width) * viewport.scale),
            y: center.y + viewport.offset.height + ((node.position.y + dragOffset.height) * viewport.scale)
        )
    }

    private func drawConnection(context: GraphicsContext, from start: CGPoint, to end: CGPoint, color: Color) {
        let distance = hypot(end.x - start.x, end.y - start.y)
        guard distance > 12 else { return }

        let midX = (start.x + end.x) / 2
        let controlOffset = min(max(distance * 0.18, 42), 120)
        let control1 = CGPoint(x: midX, y: start.y - controlOffset)
        let control2 = CGPoint(x: midX, y: end.y + controlOffset)

        var path = Path()
        path.move(to: start)
        path.addCurve(to: end, control1: control1, control2: control2)

        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: max(1.3, 2.2 * viewport.scale), lineCap: .round, lineJoin: .round)
        )

        drawArrowhead(context: context, at: end, from: control2, color: color)
    }

    private func drawArrowhead(context: GraphicsContext, at point: CGPoint, from previous: CGPoint, color: Color) {
        let angle = atan2(point.y - previous.y, point.x - previous.x)
        let length: CGFloat = 10
        let spread: CGFloat = .pi / 6

        let first = CGPoint(
            x: point.x - length * cos(angle - spread),
            y: point.y - length * sin(angle - spread)
        )
        let second = CGPoint(
            x: point.x - length * cos(angle + spread),
            y: point.y - length * sin(angle + spread)
        )

        var arrow = Path()
        arrow.move(to: point)
        arrow.addLine(to: first)
        arrow.move(to: point)
        arrow.addLine(to: second)

        context.stroke(arrow, with: .color(color), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
    }
}
