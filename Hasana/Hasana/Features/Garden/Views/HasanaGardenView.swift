import SwiftUI
import UIKit

struct HasanaGardenView: View {
    @Bindable var store: HasanaGardenStore
    @Binding var viewport: ViewportState
    let language: HasanaLanguage
    let onPracticeSelected: (HasanaGardenPracticeID) -> Void

    var body: some View {
        GeometryReader { geometry in
            let displayState = store.displayState

            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                    .coordinateSpace(name: "hasanaGarden")

                DottedBackground(offset: viewport.offset, scale: viewport.scale)

                ZStack {
                    HasanaGardenGround()
                        .fill(HasanaTheme.accentSoft.opacity(0.72))
                        .frame(width: 860, height: 320)
                        .offset(y: 150)

                    HasanaGardenSun()
                        .frame(width: 116, height: 116)
                        .offset(x: 270, y: -250)

                    ForEach(displayState.practices) { practiceState in
                        Button {
                            onPracticeSelected(practiceState.practice.id)
                        } label: {
                            HasanaGardenPlantView(
                                practice: practiceState.practice,
                                progress: practiceState.progress,
                                isTendedToday: practiceState.isTendedToday,
                                language: language
                            )
                        }
                        .buttonStyle(GardenPlantPressButtonStyle())
                        .offset(
                            x: practiceState.practice.defaultPosition.x,
                            y: practiceState.practice.defaultPosition.y
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(viewport.scale)
                .offset(viewport.offset)

                VStack {
                    HasanaGardenStatusBar(
                        tendedTodayCount: displayState.tendedTodayCount,
                        totalCount: displayState.practices.count,
                        totalTendedDays: displayState.totalTendedDays,
                        language: language
                    )
                    .padding(.top, 18)
                    .padding(.horizontal, 18)

                    Spacer()
                }
                .allowsHitTesting(false)
                .environment(\.layoutDirection, language.layoutDirection)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                GardenTrackpadPanGesture(
                    onChanged: { translation in
                        viewport.handleDragTranslation(translation)
                    },
                    onEnded: {
                        viewport.handleDragEnded()
                        persistViewport()
                    }
                )
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        viewport.handleDragChanged(value)
                    }
                    .onEnded { _ in
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
            .onAppear {
                viewport.reset(offset: store.viewportOffset, scale: store.viewportScale)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .ignoresSafeArea()
    }

    private func persistViewport() {
        store.updateViewport(offset: viewport.offset, scale: viewport.scale)
    }
}

private struct GardenPlantPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct HasanaGardenPlantView: View {
    let practice: HasanaGardenPractice
    let progress: HasanaGardenProgress
    let isTendedToday: Bool
    let language: HasanaLanguage

    private var accentColor: Color {
        switch practice.religiousStatus {
        case .obligatory:
            HasanaTheme.accent
        case .quran:
            HasanaTheme.gold
        case .dhikr:
            HasanaTheme.reflection
        case .sunnah, .sunnahWajib:
            HasanaTheme.summary
        }
    }

    private var plantSize: CGSize {
        switch practice.visualRole {
        case .foundationalTree:
            CGSize(width: 136, height: 166)
        case .plant:
            CGSize(width: 128, height: 142)
        case .flower:
            CGSize(width: 122, height: 132)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                Circle()
                    .fill(accentColor.opacity(isTendedToday ? 0.2 : 0.08))
                    .frame(width: plantSize.width * 0.78, height: plantSize.width * 0.78)
                    .offset(y: -plantSize.height * 0.18)

                HasanaGardenPlantIllustration(
                    role: practice.visualRole,
                    stage: progress.growthStage,
                    accentColor: accentColor,
                    isTendedToday: isTendedToday
                )
                .frame(width: plantSize.width, height: plantSize.height)

                if isTendedToday {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(HasanaTheme.gold)
                        .background(HasanaTheme.elevatedSurface.opacity(0.84), in: Circle())
                        .offset(x: plantSize.width * 0.34, y: -plantSize.height * 0.68)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: plantSize.width, height: plantSize.height)

            VStack(spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: practice.icon)
                        .font(.system(size: 10, weight: .bold))

                    Text(practice.title(for: language))
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(HasanaTheme.textPrimary)

                Text(progress.growthStage.title(for: language))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isTendedToday ? accentColor : HasanaTheme.textMuted)
                    .lineLimit(1)
            }
            .frame(width: 144)
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(HasanaTheme.elevatedSurface.opacity(0.48), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isTendedToday ? accentColor.opacity(0.78) : HasanaTheme.border.opacity(0.54), lineWidth: isTendedToday ? 1.1 : 0.7)
            }
            .shadow(color: accentColor.opacity(isTendedToday ? 0.24 : 0.1), radius: isTendedToday ? 16 : 9, x: 0, y: 8)
        }
        .frame(width: 160, height: 230)
        .animation(.spring(response: 0.36, dampingFraction: 0.78), value: isTendedToday)
        .animation(.spring(response: 0.36, dampingFraction: 0.78), value: progress.growthStage)
    }
}

private struct HasanaGardenStatusBar: View {
    let tendedTodayCount: Int
    let totalCount: Int
    let totalTendedDays: Int
    let language: HasanaLanguage

    var body: some View {
        HStack(spacing: 10) {
            statusItem(
                icon: "checkmark.seal.fill",
                value: "\(tendedTodayCount)/\(totalCount)",
                label: todayLabel,
                color: HasanaTheme.accent
            )

            statusItem(
                icon: "leaf.fill",
                value: "\(totalTendedDays)",
                label: totalLabel,
                color: HasanaTheme.gold
            )
        }
        .padding(7)
        .background(.ultraThinMaterial, in: Capsule())
        .background(HasanaTheme.elevatedSurface.opacity(0.56), in: Capsule())
        .overlay {
            Capsule()
                .stroke(HasanaTheme.border.opacity(0.58), lineWidth: 0.8)
        }
        .shadow(color: HasanaTheme.shadow.opacity(0.1), radius: 14, x: 0, y: 8)
    }

    private func statusItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(HasanaTheme.textPrimary)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HasanaTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(HasanaTheme.elevatedSurfaceSoft.opacity(0.52), in: Capsule())
    }

    private var todayLabel: String {
        switch language {
        case .arabic:
            "اليوم"
        case .english:
            "today"
        }
    }

    private var totalLabel: String {
        switch language {
        case .arabic:
            "إجمالي"
        case .english:
            "total"
        }
    }
}

private struct HasanaGardenPlantIllustration: View {
    let role: HasanaGardenVisualRole
    let stage: HasanaGardenGrowthStage
    let accentColor: Color
    let isTendedToday: Bool

    private var scale: CGFloat {
        switch stage {
        case .seed:
            0.32
        case .sprout:
            0.48
        case .young:
            0.68
        case .mature:
            0.88
        case .flowering:
            1.0
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(HasanaTheme.goldSoft.opacity(0.84))
                .frame(width: 82, height: 18)
                .offset(y: 3)

            if stage == .seed {
                seed
            } else {
                switch role {
                case .foundationalTree:
                    tree
                case .plant:
                    leafyPlant
                case .flower:
                    flower
                }
            }

            if isTendedToday {
                Image(systemName: "drop.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(HasanaTheme.accent)
                    .offset(x: -42, y: -20)
            }
        }
    }

    private var seed: some View {
        ZStack {
            Capsule()
                .fill(accentColor.opacity(0.45))
                .frame(width: 24, height: 18)
                .rotationEffect(.degrees(-18))

            Capsule()
                .fill(HasanaTheme.gold.opacity(0.82))
                .frame(width: 18, height: 14)
                .rotationEffect(.degrees(22))
                .offset(x: 11, y: 4)
        }
        .offset(y: -12)
    }

    private var tree: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(HasanaTheme.finance.opacity(0.82))
                .frame(width: 18 + scale * 12, height: 62 + scale * 34)

            Circle()
                .fill(accentColor.opacity(0.9))
                .frame(width: 72 * scale, height: 72 * scale)
                .offset(x: -24 * scale, y: -(68 + scale * 24))

            Circle()
                .fill(accentColor.opacity(0.74))
                .frame(width: 82 * scale, height: 82 * scale)
                .offset(x: 22 * scale, y: -(74 + scale * 28))

            Circle()
                .fill(HasanaTheme.gold.opacity(stage == .flowering ? 0.9 : 0))
                .frame(width: 16, height: 16)
                .offset(x: 22, y: -116)
        }
    }

    private var leafyPlant: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(accentColor.opacity(0.78))
                .frame(width: 12, height: 86 * scale)

            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index.isMultiple(of: 2) ? accentColor : HasanaTheme.accent)
                    .frame(width: 28 + scale * 18, height: 16 + scale * 9)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -34 : 34))
                    .offset(
                        x: index.isMultiple(of: 2) ? -20 * scale : 20 * scale,
                        y: -(24 + CGFloat(index) * 15) * scale
                    )
                    .opacity(index < visibleLeafCount ? 1 : 0)
            }

            if stage == .flowering {
                Circle()
                    .fill(HasanaTheme.gold)
                    .frame(width: 18, height: 18)
                    .offset(y: -92)
            }
        }
    }

    private var flower: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(HasanaTheme.accent.opacity(0.76))
                .frame(width: 10, height: 78 * scale)

            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(accentColor.opacity(0.9))
                    .frame(width: 28 * scale, height: 14 * scale)
                    .rotationEffect(.degrees(Double(index) * 60))
                    .offset(y: -74 * scale)
                    .opacity(stage == .flowering ? 1 : 0)
            }

            Circle()
                .fill(stage == .flowering ? HasanaTheme.gold : accentColor)
                .frame(width: stage == .flowering ? 20 : 16, height: stage == .flowering ? 20 : 16)
                .offset(y: -74 * scale)
        }
    }

    private var visibleLeafCount: Int {
        switch stage {
        case .seed:
            0
        case .sprout:
            2
        case .young:
            3
        case .mature:
            4
        case .flowering:
            5
        }
    }
}

private struct HasanaGardenSun: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(HasanaTheme.gold.opacity(0.16))

            Circle()
                .fill(HasanaTheme.gold.opacity(0.2))
                .frame(width: 72, height: 72)

            Image(systemName: "sparkle")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(HasanaTheme.gold)
        }
    }
}

private struct HasanaGardenGround: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.42))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.34),
            control1: CGPoint(x: rect.width * 0.25, y: rect.height * 0.04),
            control2: CGPoint(x: rect.width * 0.68, y: rect.height * 0.62)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct GardenTrackpadPanGesture: UIGestureRecognizerRepresentable {
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

#Preview {
    HasanaGardenView(
        store: HasanaGardenStore(),
        viewport: .constant(ViewportState()),
        language: .english,
        onPracticeSelected: { _ in }
    )
}
