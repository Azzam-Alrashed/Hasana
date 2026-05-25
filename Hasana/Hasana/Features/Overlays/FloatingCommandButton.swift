import SwiftUI
import UIKit

struct FloatingCommandButton: View {
    @State private var position: CGPoint = .zero
    @State private var startPosition: CGPoint = .zero
    @State private var isDragging = false
    @State private var isExpanded = false
    @State private var activeAction: CommandAction?

    var onTap: () -> Void
    var onLogGoodDeed: () -> Void
    var onSetIntention: () -> Void
    var onReflect: () -> Void

    private let padding: CGFloat = 28
    private let buttonSize: CGFloat = 64

    private enum CommandAction {
        case goodDeed
        case intention
        case reflect
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let currentPosition = position == .zero ? initialPosition(in: size) : position

            ZStack {
                if isExpanded {
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                isExpanded = false
                            }
                        }
                }

                quickActionBubbles(around: currentPosition, in: size)

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.24), lineWidth: 0.5)
                        )
                        .shadow(
                            color: Color.black.opacity(isDragging || isExpanded ? 0.28 : 0.18),
                            radius: isDragging || isExpanded ? 16 : 10,
                            x: 0,
                            y: isDragging || isExpanded ? 8 : 5
                        )

                    Image(systemName: isExpanded ? "xmark" : "command")
                        .font(.system(size: 24, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .frame(width: buttonSize, height: buttonSize)
                .scaleEffect(isDragging ? 1.14 : (isExpanded ? 0.92 : 1))
                .position(currentPosition)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.25)
                        .onEnded { _ in
                            guard !isDragging else { return }

                            triggerHapticFeedback(.heavy)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.64)) {
                                isExpanded = true
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("floatingLayer"))
                        .onChanged { value in
                            if isExpanded {
                                updateActiveAction(at: value.location, center: currentPosition, size: size)
                            } else {
                                updatePosition(with: value, currentPosition: currentPosition)
                            }
                        }
                        .onEnded { _ in
                            if isExpanded {
                                if let activeAction {
                                    executeAction(activeAction)
                                }

                                withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                    isExpanded = false
                                    activeAction = nil
                                }
                            } else if isDragging {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                                    isDragging = false
                                    snapToNearestPoint(in: size)
                                }
                            } else {
                                triggerHapticFeedback(.medium)
                                onTap()
                            }
                        }
                )
            }
            .coordinateSpace(name: "floatingLayer")
            .onAppear {
                if position == .zero {
                    position = initialPosition(in: size)
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                withAnimation(.spring()) {
                    snapToNearestPoint(in: newSize)
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func quickActionBubbles(around position: CGPoint, in size: CGSize) -> some View {
        let direction = sproutDirection(for: position, in: size)
        let distance: CGFloat = 76
        let angle: CGFloat = 45

        ZStack {
            QuickActionBubble(
                icon: "heart.fill",
                color: .green,
                isExpanded: isExpanded,
                isHighlighted: activeAction == .goodDeed,
                size: 48,
                delay: 0.05
            ) {
                triggerHapticFeedback(.medium)
                withAnimation(.spring()) { isExpanded = false }
                onLogGoodDeed()
            }
            .offset(
                x: isExpanded ? direction.x * distance : 0,
                y: isExpanded ? direction.y * distance : 0
            )

            QuickActionBubble(
                icon: "sparkles",
                color: .indigo,
                isExpanded: isExpanded,
                isHighlighted: activeAction == .intention,
                size: 42,
                delay: 0
            ) {
                triggerHapticFeedback(.medium)
                withAnimation(.spring()) { isExpanded = false }
                onSetIntention()
            }
            .offset(
                x: isExpanded ? direction.rotated(by: -angle).x * distance : 0,
                y: isExpanded ? direction.rotated(by: -angle).y * distance : 0
            )

            QuickActionBubble(
                icon: "moon.stars",
                color: .orange,
                isExpanded: isExpanded,
                isHighlighted: activeAction == .reflect,
                size: 42,
                delay: 0.1
            ) {
                triggerHapticFeedback(.medium)
                withAnimation(.spring()) { isExpanded = false }
                onReflect()
            }
            .offset(
                x: isExpanded ? direction.rotated(by: angle).x * distance : 0,
                y: isExpanded ? direction.rotated(by: angle).y * distance : 0
            )
        }
        .position(position)
    }

    private func updatePosition(with value: DragGesture.Value, currentPosition: CGPoint) {
        let dragThreshold: CGFloat = 10
        let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))

        guard dragDistance > dragThreshold else { return }

        if !isDragging {
            startPosition = currentPosition

            withAnimation(.interactiveSpring()) {
                isDragging = true
            }

            triggerHapticFeedback(.light)
        }

        position = CGPoint(
            x: startPosition.x + value.translation.width,
            y: startPosition.y + value.translation.height
        )
    }

    private func updateActiveAction(at location: CGPoint, center: CGPoint, size: CGSize) {
        let direction = sproutDirection(for: center, in: size)
        let actionDistance: CGFloat = 76
        let angle: CGFloat = 45
        let threshold: CGFloat = 42

        let intentionPosition = CGPoint(
            x: center.x + direction.rotated(by: -angle).x * actionDistance,
            y: center.y + direction.rotated(by: -angle).y * actionDistance
        )
        let goodDeedPosition = CGPoint(
            x: center.x + direction.x * actionDistance,
            y: center.y + direction.y * actionDistance
        )
        let reflectPosition = CGPoint(
            x: center.x + direction.rotated(by: angle).x * actionDistance,
            y: center.y + direction.rotated(by: angle).y * actionDistance
        )

        let previousAction = activeAction

        if distance(from: location, to: intentionPosition) < threshold {
            activeAction = .intention
        } else if distance(from: location, to: goodDeedPosition) < threshold {
            activeAction = .goodDeed
        } else if distance(from: location, to: reflectPosition) < threshold {
            activeAction = .reflect
        } else {
            activeAction = nil
        }

        if activeAction != previousAction, activeAction != nil {
            triggerHapticFeedback(.light)
        }
    }

    private func executeAction(_ action: CommandAction) {
        triggerHapticFeedback(.medium)

        switch action {
        case .goodDeed:
            onLogGoodDeed()
        case .intention:
            onSetIntention()
        case .reflect:
            onReflect()
        }
    }

    private func sproutDirection(for position: CGPoint, in size: CGSize) -> CGPoint {
        let dx = size.width / 2 - position.x
        let dy = size.height / 2 - position.y
        let length = sqrt(dx * dx + dy * dy)

        return length > 0 ? CGPoint(x: dx / length, y: dy / length) : CGPoint(x: 0, y: -1)
    }

    private func initialPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width - padding - buttonSize / 2,
            y: size.height - padding - buttonSize / 2
        )
    }

    private func snapToNearestPoint(in size: CGSize) {
        let minX = padding + buttonSize / 2
        let maxX = size.width - padding - buttonSize / 2
        let minY = 56 + buttonSize / 2
        let maxY = size.height - padding - buttonSize / 2
        let centerX = size.width / 2
        let centerY = size.height / 2

        let points = [
            CGPoint(x: minX, y: minY),
            CGPoint(x: centerX, y: minY),
            CGPoint(x: maxX, y: minY),
            CGPoint(x: minX, y: centerY),
            CGPoint(x: maxX, y: centerY),
            CGPoint(x: minX, y: maxY),
            CGPoint(x: centerX, y: maxY),
            CGPoint(x: maxX, y: maxY)
        ]

        position = points.min { first, second in
            distance(from: first, to: position) < distance(from: second, to: position)
        } ?? points[7]

        triggerHapticFeedback(.rigid)
    }

    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
    }

    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

private struct QuickActionBubble: View {
    let icon: String
    let color: Color
    let isExpanded: Bool
    var isHighlighted = false
    var size: CGFloat = 48
    let delay: Double
    let action: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(isHighlighted ? color : color.opacity(0.32), lineWidth: isHighlighted ? 2 : 1)
                )
                .shadow(color: color.opacity(isHighlighted ? 0.48 : 0.2), radius: isHighlighted ? 12 : 8)

            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .scaleEffect(isExpanded ? (isHighlighted ? 1.24 : 1) : 0.01)
        .opacity(isExpanded ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.64), value: isHighlighted)
        .animation(.spring(response: 0.4, dampingFraction: 0.64).delay(isExpanded ? delay : 0), value: isExpanded)
        .onTapGesture {
            guard isExpanded else { return }
            action()
        }
    }
}

private extension CGPoint {
    func rotated(by degrees: CGFloat) -> CGPoint {
        let radians = degrees * .pi / 180
        let sinTheta = sin(radians)
        let cosTheta = cos(radians)

        return CGPoint(
            x: x * cosTheta - y * sinTheta,
            y: x * sinTheta + y * cosTheta
        )
    }
}
