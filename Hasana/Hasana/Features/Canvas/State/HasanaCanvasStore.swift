import CoreGraphics
import Foundation
import Observation

@Observable
@MainActor
final class HasanaCanvasStore {
    static let storageKey = "hasana.canvas.snapshot.v1"

    var nodes: [HasanaCanvasNode] = []
    var viewportOffset: CGSize = .zero
    var viewportScale: CGFloat = 1.0
    var focusRequest: HasanaCanvasFocusRequest?

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func focusNode(for commandID: HasanaCommandID) -> CGPoint? {
        nodes.first { $0.commandID == commandID }?.position
    }

    func requestFocus(on commandID: HasanaCommandID) {
        focusRequest = HasanaCanvasFocusRequest(commandID: commandID)
    }

    func updateNodePosition(id: HasanaCanvasNodeID, position: CGPoint) {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].position = position
        save()
    }

    func updateViewport(offset: CGSize, scale: CGFloat) {
        viewportOffset = offset
        viewportScale = scale
        save()
    }

    @discardableResult
    func addIdea(prompt: String, viewport: ViewportState) -> HasanaCanvasNode {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedPrompt.isEmpty ? "New Idea" : trimmedPrompt
        let node = HasanaCanvasNode(
            id: .idea(),
            kind: .idea,
            position: visibleCenterPosition(in: viewport),
            title: title,
            subtitle: "Captured from the command palette",
            icon: "text.bubble.fill",
            theme: .idea
        )

        nodes.append(node)
        save()
        return node
    }

    private func load() {
        guard
            let data = userDefaults.data(forKey: Self.storageKey),
            let snapshot = try? decoder.decode(HasanaCanvasSnapshot.self, from: data),
            snapshot.schemaVersion == HasanaCanvasSnapshot.currentSchemaVersion
        else {
            nodes = []
            viewportOffset = .zero
            viewportScale = 1.0
            return
        }

        nodes = snapshot.nodes.filter { $0.kind == .idea }
        viewportOffset = snapshot.viewportOffset
        viewportScale = snapshot.viewportScale
    }

    private func save() {
        let snapshot = HasanaCanvasSnapshot(
            schemaVersion: HasanaCanvasSnapshot.currentSchemaVersion,
            nodes: nodes,
            viewportOffset: viewportOffset,
            viewportScale: viewportScale
        )

        guard let data = try? encoder.encode(snapshot) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }

    private func merge(defaultNodes: [HasanaCanvasNode], persistedNodes: [HasanaCanvasNode]) -> [HasanaCanvasNode] {
        persistedNodes.filter { $0.kind == .idea }
    }

    private func visibleCenterPosition(in viewport: ViewportState) -> CGPoint {
        CGPoint(
            x: -viewport.offset.width / max(viewport.scale, 0.01),
            y: -viewport.offset.height / max(viewport.scale, 0.01)
        )
    }

    static func defaultNodes() -> [HasanaCanvasNode] {
        []
    }
}
