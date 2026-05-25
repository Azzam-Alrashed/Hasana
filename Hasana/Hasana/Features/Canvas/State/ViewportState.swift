import Observation
import SwiftUI

@Observable
final class ViewportState {
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0

    let minScale: CGFloat = 0.1
    let maxScale: CGFloat = 2.0

    init(offset: CGSize = .zero, scale: CGFloat = 1.0) {
        self.offset = offset
        self.lastOffset = offset
        self.scale = scale
        self.lastScale = scale
    }

    func reset(offset: CGSize, scale: CGFloat) {
        let clampedScale = min(max(scale, minScale), maxScale)
        self.offset = offset
        self.lastOffset = offset
        self.scale = clampedScale
        self.lastScale = clampedScale
    }

    func handleDragTranslation(_ translation: CGSize) {
        offset = CGSize(
            width: lastOffset.width + translation.width,
            height: lastOffset.height + translation.height
        )
    }

    func handleDragChanged(_ value: DragGesture.Value) {
        handleDragTranslation(value.translation)
    }

    func handleDragEnded() {
        lastOffset = offset
    }

    func handleMagnificationChanged(_ magnification: CGFloat, at location: CGPoint, in viewSize: CGSize) {
        let newScale = min(max(lastScale * magnification, minScale), maxScale)
        let centerX = viewSize.width / 2
        let centerY = viewSize.height / 2
        let pointX = (location.x - centerX - lastOffset.width) / lastScale
        let pointY = (location.y - centerY - lastOffset.height) / lastScale

        scale = newScale
        offset = CGSize(
            width: location.x - centerX - (pointX * newScale),
            height: location.y - centerY - (pointY * newScale)
        )
    }

    func handleMagnificationEnded() {
        lastScale = scale
        lastOffset = offset
    }

    func flyTo(nodePosition: CGPoint, targetScale: CGFloat = 1.0) {
        let clampedScale = min(max(targetScale, minScale), maxScale)
        let newOffset = CGSize(
            width: -nodePosition.x * clampedScale,
            height: -nodePosition.y * clampedScale
        )

        scale = clampedScale
        lastScale = clampedScale
        offset = newOffset
        lastOffset = newOffset
    }
}
