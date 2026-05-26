import SwiftUI
import UIKit

struct HasanaCanvasView: View {
    @Bindable var store: HasanaCanvasStore
    @Binding var viewport: ViewportState
    let onNodeAction: (HasanaCommandID) -> Void

    @State private var nodeDragOffsets: [HasanaCanvasNodeID: CGSize] = [:]
    @State private var isDraggingNode = false

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                Color.clear.coordinateSpace(name: "hasanaCanvas")

                DottedBackground(offset: viewport.offset, scale: viewport.scale)

                ConnectionLayer(
                    nodes: store.nodes,
                    dragOffsets: nodeDragOffsets,
                    viewport: viewport,
                    center: center
                )

                ZStack {
                    ForEach(store.nodes) { node in
                        let currentOffset = nodeDragOffsets[node.id] ?? .zero
                        let isDraggingThisNode = nodeDragOffsets[node.id] != nil

                        HasanaNodeView(node: node, isDragging: isDraggingThisNode)
                            .offset(
                                x: node.position.x + currentOffset.width,
                                y: node.position.y + currentOffset.height
                            )
                            .onTapGesture {
                                if let commandID = node.commandID {
                                    onNodeAction(commandID)
                                }
                            }
                            .gesture(nodeDragGesture(for: node))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(viewport.scale)
                .offset(viewport.offset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                TrackpadPanGesture(
                    onChanged: { translation in
                        guard !isDraggingNode else { return }
                        viewport.handleDragTranslation(translation)
                    },
                    onEnded: {
                        guard !isDraggingNode else { return }
                        viewport.handleDragEnded()
                        persistViewport()
                    }
                )
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard !isDraggingNode else { return }
                        viewport.handleDragChanged(value)
                    }
                    .onEnded { _ in
                        guard !isDraggingNode else { return }
                        viewport.handleDragEnded()
                        persistViewport()
                    }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        let location = CGPoint(
                            x: value.startAnchor.x * geometry.size.width,
                            y: value.startAnchor.y * geometry.size.height
                        )
                        viewport.handleMagnificationChanged(value.magnification, at: location, in: geometry.size)
                    }
                    .onEnded { _ in
                        viewport.handleMagnificationEnded()
                        persistViewport()
                    }
            )
            .onChange(of: store.focusRequest) { _, request in
                guard let request, let position = store.focusNode(for: request.commandID) else { return }

                withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                    viewport.flyTo(nodePosition: position, targetScale: max(viewport.scale, 0.9))
                }
                persistViewport()
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .ignoresSafeArea()
    }

    private func nodeDragGesture(for node: HasanaCanvasNode) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                isDraggingNode = true
                nodeDragOffsets[node.id] = CGSize(
                    width: value.translation.width / max(viewport.scale, 0.01),
                    height: value.translation.height / max(viewport.scale, 0.01)
                )
            }
            .onEnded { value in
                let scaledTranslation = CGSize(
                    width: value.translation.width / max(viewport.scale, 0.01),
                    height: value.translation.height / max(viewport.scale, 0.01)
                )
                let finalPosition = CGPoint(
                    x: node.position.x + scaledTranslation.width,
                    y: node.position.y + scaledTranslation.height
                )

                withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) {
                    store.updateNodePosition(id: node.id, position: finalPosition)
                    nodeDragOffsets[node.id] = nil
                    isDraggingNode = false
                }
            }
    }

    private func persistViewport() {
        store.updateViewport(offset: viewport.offset, scale: viewport.scale)
    }
}

private struct TrackpadPanGesture: UIGestureRecognizerRepresentable {
    var onChanged: (CGSize) -> Void
    var onEnded: () -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.allowedScrollTypesMask = .continuous
        recognizer.delegate = context.coordinator
        recognizer.cancelsTouchesInView = false
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view)
        let canvasTranslation = CGSize(width: translation.x, height: translation.y)

        switch recognizer.state {
        case .began, .changed:
            onChanged(canvasTranslation)
        case .ended, .cancelled, .failed:
            onEnded()
        default:
            break
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
