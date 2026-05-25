import SwiftUI

struct NodeFrameData: Equatable {
    let nodeID: HasanaCanvasNodeID
    let frame: CGRect
}

struct NodeFramePreferenceKey: PreferenceKey {
    static var defaultValue: [HasanaCanvasNodeID: NodeFrameData] = [:]

    static func reduce(value: inout [HasanaCanvasNodeID: NodeFrameData], nextValue: () -> [HasanaCanvasNodeID: NodeFrameData]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
