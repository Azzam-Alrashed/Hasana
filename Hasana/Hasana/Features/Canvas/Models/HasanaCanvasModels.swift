import CoreGraphics
import Foundation
import SwiftUI

struct HasanaCanvasNodeID: RawRepresentable, Codable, Hashable, Identifiable {
    let rawValue: String

    var id: String { rawValue }

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static func command(_ commandID: HasanaCommandID) -> HasanaCanvasNodeID {
        HasanaCanvasNodeID(rawValue: "command.\(commandID.rawValue)")
    }

    static func idea(_ uuid: UUID = UUID()) -> HasanaCanvasNodeID {
        HasanaCanvasNodeID(rawValue: "idea.\(uuid.uuidString)")
    }
}

enum HasanaCanvasNodeKind: String, Codable, Equatable {
    case command
    case idea
    case summary
}

enum HasanaCanvasTheme: String, Codable, CaseIterable {
    case today
    case worship
    case reflection
    case finance
    case idea
    case summary

    var color: Color {
        HasanaTheme.canvasColor(self)
    }

    var glowOpacity: Double {
        switch self {
        case .idea, .summary:
            0.18
        default:
            0.14
        }
    }
}

struct HasanaCanvasNode: Identifiable, Codable, Equatable {
    let id: HasanaCanvasNodeID
    var kind: HasanaCanvasNodeKind
    var position: CGPoint
    var title: String
    var subtitle: String
    var icon: String
    var theme: HasanaCanvasTheme
    var commandID: HasanaCommandID?
    var connectedNodeIDs: [HasanaCanvasNodeID]

    init(
        id: HasanaCanvasNodeID,
        kind: HasanaCanvasNodeKind,
        position: CGPoint,
        title: String,
        subtitle: String,
        icon: String,
        theme: HasanaCanvasTheme,
        commandID: HasanaCommandID? = nil,
        connectedNodeIDs: [HasanaCanvasNodeID] = []
    ) {
        self.id = id
        self.kind = kind
        self.position = position
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.theme = theme
        self.commandID = commandID
        self.connectedNodeIDs = connectedNodeIDs
    }
}

struct HasanaCanvasSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var nodes: [HasanaCanvasNode]
    var viewportOffset: CGSize
    var viewportScale: CGFloat
}

struct HasanaCanvasFocusRequest: Equatable {
    let id = UUID()
    let commandID: HasanaCommandID
}

enum HasanaCanvasSheet: Identifiable, Equatable {
    case command(HasanaCommandID)
    case idea(String)

    var id: String {
        switch self {
        case .command(let commandID):
            "command.\(commandID.rawValue)"
        case .idea(let text):
            "idea.\(text)"
        }
    }
}

extension HasanaCanvasTheme {
    init(category: HasanaCommandCategory) {
        switch category {
        case .canvas:
            self = .idea
        case .giving:
            self = .finance
        case .app:
            self = .summary
        }
    }
}
