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
        let defaults = Self.defaultNodes()

        guard
            let data = userDefaults.data(forKey: Self.storageKey),
            let snapshot = try? decoder.decode(HasanaCanvasSnapshot.self, from: data),
            snapshot.schemaVersion == HasanaCanvasSnapshot.currentSchemaVersion
        else {
            nodes = defaults
            viewportOffset = .zero
            viewportScale = 1.0
            return
        }

        nodes = merge(defaultNodes: defaults, persistedNodes: snapshot.nodes)
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
        let persistedByID = Dictionary(uniqueKeysWithValues: persistedNodes.map { ($0.id, $0) })

        var merged = defaultNodes.map { defaultNode in
            guard let persisted = persistedByID[defaultNode.id] else { return defaultNode }
            var node = defaultNode
            node.position = persisted.position
            return node
        }

        let builtInIDs = Set(defaultNodes.map(\.id))
        let ideaNodes = persistedNodes.filter { !builtInIDs.contains($0.id) && $0.kind == .idea }
        merged.append(contentsOf: ideaNodes)

        return merged
    }

    private func visibleCenterPosition(in viewport: ViewportState) -> CGPoint {
        CGPoint(
            x: -viewport.offset.width / max(viewport.scale, 0.01),
            y: -viewport.offset.height / max(viewport.scale, 0.01)
        )
    }

    static func defaultNodes() -> [HasanaCanvasNode] {
        let positionByCommand: [HasanaCommandID: CGPoint] = [
            .openToday: .zero,
            .logGoodDeed: CGPoint(x: -280, y: -120),
            .setIntention: CGPoint(x: 280, y: -120),
            .addPriority: CGPoint(x: 0, y: -300),
            .openPrayerTimes: CGPoint(x: -300, y: 140),
            .startDhikr: CGPoint(x: 0, y: 300),
            .reflect: CGPoint(x: 300, y: 140),
            .addSadaqah: CGPoint(x: 340, y: -310)
        ]

        let connectionsByCommand: [HasanaCommandID: [HasanaCommandID]] = [
            .openToday: [.logGoodDeed, .setIntention, .addPriority, .openPrayerTimes, .startDhikr, .reflect],
            .setIntention: [.addPriority],
            .openPrayerTimes: [.startDhikr],
            .reflect: [.logGoodDeed],
            .addSadaqah: [.openToday]
        ]

        return HasanaCommand.defaults.map { command in
            HasanaCanvasNode(
                id: .command(command.id),
                kind: .command,
                position: positionByCommand[command.id] ?? .zero,
                title: command.title,
                subtitle: command.subtitle,
                icon: command.icon,
                theme: HasanaCanvasTheme(category: command.category),
                commandID: command.id,
                connectedNodeIDs: connectionsByCommand[command.id, default: []].map { .command($0) }
            )
        }
    }
}
