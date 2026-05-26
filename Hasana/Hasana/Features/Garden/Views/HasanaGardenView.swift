import RealityKit
import SwiftUI
import UIKit

struct HasanaGardenView: View {
    @Bindable var store: HasanaGardenStore
    @Bindable var cameraState: HasanaGardenCameraState
    let language: HasanaLanguage
    let onPracticeSelected: (HasanaGardenPracticeID) -> Void

    var body: some View {
        let displayState = store.displayState

        ZStack {
            HasanaGardenRealityView(
                displayState: displayState,
                cameraState: cameraState,
                onPracticeSelected: onPracticeSelected
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HasanaGardenStatusBar(
                    tendedTodayCount: displayState.tendedTodayCount,
                    totalCount: displayState.practices.count,
                    totalTendedDays: displayState.totalTendedDays,
                    language: language
                )
                .padding(.top, 18)
                .padding(.horizontal, 18)

                Spacer()

                HasanaGardenHint(language: language)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
            }
            .allowsHitTesting(false)
            .environment(\.layoutDirection, language.layoutDirection)
        }
        .ignoresSafeArea()
    }
}

@MainActor
@Observable
final class HasanaGardenCameraState {
    static let storageKey = "hasana.garden.camera.v1"

    var yaw: Float
    var pitch: Float
    var distance: Float
    var revision: Int = 0

    private let userDefaults: UserDefaults
    private let defaultYaw: Float = -0.48
    private let defaultPitch: Float = 0.54
    private let defaultDistance: Float = 6.6

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let data = userDefaults.data(forKey: Self.storageKey),
           let snapshot = try? JSONDecoder().decode(HasanaGardenCameraSnapshot.self, from: data) {
            yaw = snapshot.yaw
            pitch = snapshot.pitch
            distance = snapshot.distance
        } else {
            yaw = defaultYaw
            pitch = defaultPitch
            distance = defaultDistance
        }
    }

    func update(yaw: Float? = nil, pitch: Float? = nil, distance: Float? = nil) {
        if let yaw {
            self.yaw = yaw
        }
        if let pitch {
            self.pitch = min(max(pitch, 0.24), 1.08)
        }
        if let distance {
            self.distance = min(max(distance, 3.8), 9.2)
        }

        revision += 1
    }

    func save() {
        let snapshot = HasanaGardenCameraSnapshot(
            yaw: yaw,
            pitch: pitch,
            distance: distance
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }

    func reset() {
        yaw = defaultYaw
        pitch = defaultPitch
        distance = defaultDistance
        revision += 1
        save()
    }
}

private struct HasanaGardenCameraSnapshot: Codable {
    let yaw: Float
    let pitch: Float
    let distance: Float
}

private struct HasanaGardenRealityView: UIViewRepresentable {
    let displayState: HasanaGardenDisplayState
    let cameraState: HasanaGardenCameraState
    let onPracticeSelected: (HasanaGardenPracticeID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            cameraState: cameraState,
            onPracticeSelected: onPracticeSelected
        )
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        arView.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.92, alpha: 1)
        arView.environment.background = .color(UIColor(red: 0.91, green: 0.96, blue: 0.92, alpha: 1))
        context.coordinator.configure(arView)
        context.coordinator.render(displayState)
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.cameraState = cameraState
        context.coordinator.onPracticeSelected = onPracticeSelected
        context.coordinator.render(displayState)
        context.coordinator.updateCamera()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var cameraState: HasanaGardenCameraState
        var onPracticeSelected: (HasanaGardenPracticeID) -> Void

        private weak var arView: ARView?
        private let sceneAnchor = AnchorEntity(world: .zero)
        private let cameraAnchor = AnchorEntity(world: .zero)
        private let camera = PerspectiveCamera()
        private var lastRenderedState: HasanaGardenDisplayState?
        private var panStartYaw: Float = 0
        private var panStartPitch: Float = 0
        private var pinchStartDistance: Float = 0
        private var lastCameraRevision = -1

        init(
            cameraState: HasanaGardenCameraState,
            onPracticeSelected: @escaping (HasanaGardenPracticeID) -> Void
        ) {
            self.cameraState = cameraState
            self.onPracticeSelected = onPracticeSelected
        }

        func configure(_ arView: ARView) {
            guard self.arView == nil else { return }

            self.arView = arView
            arView.scene.addAnchor(sceneAnchor)
            arView.scene.addAnchor(cameraAnchor)
            cameraAnchor.addChild(camera)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))

            tap.delegate = self
            pan.delegate = self
            pinch.delegate = self

            arView.addGestureRecognizer(tap)
            arView.addGestureRecognizer(pan)
            arView.addGestureRecognizer(pinch)

            updateCamera()
        }

        func render(_ displayState: HasanaGardenDisplayState) {
            guard displayState != lastRenderedState else { return }
            lastRenderedState = displayState

            sceneAnchor.children.removeAll()
            sceneAnchor.addChild(makeEnvironment())

            for practiceState in displayState.practices {
                sceneAnchor.addChild(makePracticeEntity(for: practiceState))
            }
        }

        func updateCamera() {
            guard lastCameraRevision != cameraState.revision || camera.transform.matrix == matrix_identity_float4x4 else {
                return
            }

            lastCameraRevision = cameraState.revision
            let distance = cameraState.distance
            let horizontalDistance = cos(cameraState.pitch) * distance
            let position = SIMD3<Float>(
                sin(cameraState.yaw) * horizontalDistance,
                sin(cameraState.pitch) * distance + 0.45,
                cos(cameraState.yaw) * horizontalDistance
            )

            camera.look(
                at: SIMD3<Float>(0, 0.28, 0),
                from: position,
                relativeTo: nil
            )
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView else { return }

            let location = recognizer.location(in: arView)
            guard let hit = arView.hitTest(location).first,
                  let practiceID = practiceID(from: hit.entity) else {
                return
            }

            onPracticeSelected(practiceID)
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: recognizer.view)

            switch recognizer.state {
            case .began:
                panStartYaw = cameraState.yaw
                panStartPitch = cameraState.pitch
            case .changed:
                cameraState.update(
                    yaw: panStartYaw - Float(translation.x) * 0.006,
                    pitch: panStartPitch - Float(translation.y) * 0.004
                )
                updateCamera()
            case .ended, .cancelled, .failed:
                cameraState.save()
            default:
                break
            }
        }

        @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            switch recognizer.state {
            case .began:
                pinchStartDistance = cameraState.distance
            case .changed:
                cameraState.update(distance: pinchStartDistance / Float(recognizer.scale))
                updateCamera()
            case .ended, .cancelled, .failed:
                cameraState.save()
            default:
                break
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private func makeEnvironment() -> Entity {
            let root = Entity()

            let ground = ModelEntity(
                mesh: .generateBox(width: 6.5, height: 0.12, depth: 4.35),
                materials: [material(UIColor(HasanaTheme.accentSoft.opacity(0.8)), roughness: 0.9)]
            )
            ground.position = [0, -0.06, 0]
            root.addChild(ground)

            let path = ModelEntity(
                mesh: .generateBox(width: 5.55, height: 0.025, depth: 0.16),
                materials: [material(UIColor(HasanaTheme.goldSoft.opacity(0.8)), roughness: 0.95)]
            )
            path.position = [0, 0.02, 0.18]
            root.addChild(path)

            let crossPath = ModelEntity(
                mesh: .generateBox(width: 0.16, height: 0.026, depth: 3.35),
                materials: [material(UIColor(HasanaTheme.goldSoft.opacity(0.58)), roughness: 0.95)]
            )
            crossPath.position = [0.25, 0.025, 0]
            root.addChild(crossPath)

            let sun = ModelEntity(
                mesh: .generateSphere(radius: 0.28),
                materials: [material(UIColor(HasanaTheme.gold.opacity(0.92)), roughness: 0.25)]
            )
            sun.position = [2.55, 2.15, -1.5]
            root.addChild(sun)

            let light = DirectionalLight()
            light.light.intensity = 2200
            light.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
            root.addChild(light)

            let fillLight = PointLight()
            fillLight.light.intensity = 850
            fillLight.light.attenuationRadius = 8
            fillLight.position = [-2.4, 2.3, 2.2]
            root.addChild(fillLight)

            return root
        }

        private func makePracticeEntity(for state: HasanaGardenPracticeState) -> Entity {
            let root = Entity()
            root.name = entityName(for: state.practice.id)
            root.position = position(for: state.practice.id)

            if let modelEntity = makeAssetBackedPracticeEntity(for: state) {
                root.addChild(modelEntity)
            } else {
                switch state.practice.visualRole {
                case .foundationalTree:
                    makeTree(for: state, in: root)
                case .plant:
                    makeLeafyPlant(for: state, in: root)
                case .flower:
                    makeFlower(for: state, in: root)
                }
            }

            if state.isTendedToday {
                root.addChild(makeTendedHalo(for: state.practice.id))
            }

            root.generateCollisionShapes(recursive: true)
            return root
        }

        private func makeAssetBackedPracticeEntity(for state: HasanaGardenPracticeState) -> Entity? {
            // Future USDZ assets can be routed through this seam using practice ID and growth stage.
            nil
        }

        private func makeTree(for state: HasanaGardenPracticeState, in root: Entity) {
            let scale = state.progress.growthStage.modelScale
            let accent = accentColor(for: state.practice, isTendedToday: state.isTendedToday)

            let trunk = namedModel(
                id: state.practice.id,
                mesh: .generateCylinder(height: 0.56 + scale * 0.46, radius: 0.075 + scale * 0.035),
                color: UIColor(HasanaTheme.finance.opacity(0.9)),
                roughness: 0.8
            )
            trunk.position = [0, 0.26 + scale * 0.2, 0]
            root.addChild(trunk)

            let canopyCount = state.progress.growthStage.canopyCount
            for index in 0..<canopyCount {
                let offset = canopyOffset(index: index, scale: scale)
                let canopy = namedModel(
                    id: state.practice.id,
                    mesh: .generateSphere(radius: 0.19 + scale * 0.17),
                    color: accent,
                    roughness: 0.65
                )
                canopy.position = offset
                root.addChild(canopy)
            }
        }

        private func makeLeafyPlant(for state: HasanaGardenPracticeState, in root: Entity) {
            let scale = state.progress.growthStage.modelScale
            let accent = accentColor(for: state.practice, isTendedToday: state.isTendedToday)

            let stem = namedModel(
                id: state.practice.id,
                mesh: .generateCylinder(height: 0.34 + scale * 0.38, radius: 0.035 + scale * 0.02),
                color: accent,
                roughness: 0.8
            )
            stem.position = [0, 0.18 + scale * 0.18, 0]
            root.addChild(stem)

            for index in 0..<state.progress.growthStage.leafCount {
                let side: Float = index.isMultiple(of: 2) ? -1 : 1
                let leaf = namedModel(
                    id: state.practice.id,
                    mesh: .generateBox(width: 0.28 + scale * 0.1, height: 0.05, depth: 0.12 + scale * 0.04),
                    color: index.isMultiple(of: 2) ? accent : UIColor(HasanaTheme.accent),
                    roughness: 0.72
                )
                leaf.position = [
                    side * (0.12 + scale * 0.07),
                    0.22 + Float(index) * 0.08,
                    Float(index) * 0.03 - 0.08
                ]
                leaf.orientation = simd_quatf(angle: side * 0.55, axis: [0, 0, 1])
                root.addChild(leaf)
            }
        }

        private func makeFlower(for state: HasanaGardenPracticeState, in root: Entity) {
            let scale = state.progress.growthStage.modelScale
            let accent = accentColor(for: state.practice, isTendedToday: state.isTendedToday)

            let stem = namedModel(
                id: state.practice.id,
                mesh: .generateCylinder(height: 0.32 + scale * 0.4, radius: 0.03 + scale * 0.014),
                color: UIColor(HasanaTheme.accent),
                roughness: 0.82
            )
            stem.position = [0, 0.16 + scale * 0.2, 0]
            root.addChild(stem)

            let centerHeight: Float = 0.36 + scale * 0.38
            let center = namedModel(
                id: state.practice.id,
                mesh: .generateSphere(radius: 0.075 + scale * 0.045),
                color: UIColor(HasanaTheme.gold),
                roughness: 0.48
            )
            center.position = [0, centerHeight, 0]
            root.addChild(center)

            let petalCount = state.progress.growthStage == .flowering ? 6 : max(2, state.progress.growthStage.leafCount)
            for index in 0..<petalCount {
                let angle = (Float(index) / Float(max(petalCount, 1))) * .pi * 2
                let petal = namedModel(
                    id: state.practice.id,
                    mesh: .generateBox(width: 0.16 + scale * 0.07, height: 0.045, depth: 0.09 + scale * 0.04),
                    color: accent,
                    roughness: 0.58
                )
                petal.position = [
                    cos(angle) * (0.12 + scale * 0.05),
                    centerHeight,
                    sin(angle) * (0.12 + scale * 0.05)
                ]
                petal.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
                root.addChild(petal)
            }
        }

        private func makeTendedHalo(for id: HasanaGardenPracticeID) -> Entity {
            let halo = namedModel(
                id: id,
                mesh: .generateCylinder(height: 0.018, radius: 0.34),
                color: UIColor(HasanaTheme.gold.opacity(0.46)),
                roughness: 0.3
            )
            halo.position = [0, 0.055, 0]
            return halo
        }

        private func namedModel(
            id: HasanaGardenPracticeID,
            mesh: MeshResource,
            color: UIColor,
            roughness: Float
        ) -> ModelEntity {
            let model = ModelEntity(
                mesh: mesh,
                materials: [material(color, roughness: roughness)]
            )
            model.name = entityName(for: id)
            return model
        }

        private func material(_ color: UIColor, roughness: Float) -> SimpleMaterial {
            SimpleMaterial(color: color, roughness: .float(roughness), isMetallic: false)
        }

        private func practiceID(from entity: Entity) -> HasanaGardenPracticeID? {
            var candidate: Entity? = entity

            while let current = candidate {
                if current.name.hasPrefix("practice:") {
                    let rawValue = current.name.replacingOccurrences(of: "practice:", with: "")
                    return HasanaGardenPracticeID(rawValue: rawValue)
                }
                candidate = current.parent
            }

            return nil
        }

        private func entityName(for id: HasanaGardenPracticeID) -> String {
            "practice:\(id.rawValue)"
        }

        private func position(for id: HasanaGardenPracticeID) -> SIMD3<Float> {
            switch id {
            case .fajr:
                [-2.35, 0.0, -1.1]
            case .dhuhr:
                [-0.85, 0.0, -1.28]
            case .asr:
                [0.82, 0.0, -1.18]
            case .maghrib:
                [2.22, 0.0, -0.72]
            case .isha:
                [1.58, 0.0, 1.08]
            case .quran:
                [-1.62, 0.0, 0.98]
            case .adhkar:
                [0.0, 0.0, 0.86]
            case .witr:
                [2.32, 0.0, 0.92]
            }
        }

        private func accentColor(for practice: HasanaGardenPractice, isTendedToday: Bool) -> UIColor {
            let opacity = isTendedToday ? 0.96 : 0.76

            switch practice.religiousStatus {
            case .obligatory:
                return UIColor(HasanaTheme.accent.opacity(opacity))
            case .quran:
                return UIColor(HasanaTheme.gold.opacity(opacity))
            case .dhikr:
                return UIColor(HasanaTheme.reflection.opacity(opacity))
            case .sunnah, .sunnahWajib:
                return UIColor(HasanaTheme.summary.opacity(opacity))
            }
        }

        private func canopyOffset(index: Int, scale: Float) -> SIMD3<Float> {
            switch index {
            case 0:
                [-0.16 * scale, 0.84 + scale * 0.28, 0.02]
            case 1:
                [0.18 * scale, 0.88 + scale * 0.3, -0.04]
            case 2:
                [0.0, 1.06 + scale * 0.36, 0.08]
            default:
                [0.0, 0.92 + scale * 0.22, 0.0]
            }
        }
    }
}

private extension HasanaGardenGrowthStage {
    var modelScale: Float {
        switch self {
        case .seed:
            0.24
        case .sprout:
            0.42
        case .young:
            0.62
        case .mature:
            0.84
        case .flowering:
            1.0
        }
    }

    var leafCount: Int {
        switch self {
        case .seed:
            1
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

    var canopyCount: Int {
        switch self {
        case .seed:
            1
        case .sprout:
            1
        case .young:
            2
        case .mature, .flowering:
            3
        }
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

private struct HasanaGardenHint: View {
    let language: HasanaLanguage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "rotate.3d")
                .font(.system(size: 12, weight: .bold))

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(HasanaTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .background(HasanaTheme.elevatedSurface.opacity(0.42), in: Capsule())
        .overlay {
            Capsule()
                .stroke(HasanaTheme.border.opacity(0.38), lineWidth: 0.7)
        }
    }

    private var text: String {
        switch language {
        case .arabic:
            "اسحب لتدوير الحديقة، وقرّب بإصبعين، واضغط على نبتة للتسجيل"
        case .english:
            "Drag to orbit, pinch to zoom, tap a plant to log"
        }
    }
}

#Preview {
    HasanaGardenView(
        store: HasanaGardenStore(),
        cameraState: HasanaGardenCameraState(),
        language: .english,
        onPracticeSelected: { _ in }
    )
}
