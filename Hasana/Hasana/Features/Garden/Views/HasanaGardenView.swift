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
                onPracticeSelected: { id in
                    triggerGardenTapHaptic()
                    onPracticeSelected(id)
                }
            )
            .ignoresSafeArea()

            // Invisible accessibility overlay — VoiceOver can't interact with ARView entities,
            // so we layer buttons at each plant's approximate screen position.
            HasanaGardenA11yOverlay(
                displayState: displayState,
                language: language,
                onPracticeSelected: { id in
                    triggerGardenTapHaptic()
                    onPracticeSelected(id)
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HasanaGardenStatusBar(
                    tendedTodayCount: displayState.tendedTodayCount,
                    totalCount: displayState.practices.count,
                    totalTendedDays: displayState.totalTendedDays,
                    language: language
                )
                .padding(.top, 12)
                .padding(.horizontal, 16)

                Spacer()

                VStack(spacing: 10) {
                    HasanaGardenStateLegend(language: language)
                    HasanaGardenHint(language: language)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .allowsHitTesting(false)
            .environment(\.layoutDirection, language.layoutDirection)
        }
    }

    private func triggerGardenTapHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Accessibility Overlay

/// Invisible grid of buttons mapped to each plant's approximate 2D screen region.
/// Allows VoiceOver users to interact with the 3D garden without touching the ARView.
private struct HasanaGardenA11yOverlay: View {
    let displayState: HasanaGardenDisplayState
    let language: HasanaLanguage
    let onPracticeSelected: (HasanaGardenPracticeID) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(displayState.practices) { practiceState in
                    let screenPos = screenPosition(
                        for: practiceState.practice.id,
                        in: geometry.size
                    )

                    Button {
                        onPracticeSelected(practiceState.practice.id)
                    } label: {
                        Color.clear
                            .frame(width: 88, height: 88)
                            .contentShape(Rectangle())
                    }
                    .position(screenPos)
                    .accessibilityLabel(accessibilityLabel(for: practiceState))
                    .accessibilityHint(isTendedHint(for: practiceState))
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func accessibilityLabel(for state: HasanaGardenPracticeState) -> String {
        let name = state.practice.title(for: language)
        let status = state.practice.religiousStatus.title(for: language)
        let stage = state.progress.growthStage.title(for: language)
        
        let tendedState: String
        if state.isTendedToday {
            tendedState = language == .arabic ? "تم اليوم" : "Tended today"
        } else {
            tendedState = language == .arabic ? "لم يتم اليوم" : "Not tended today"
        }
        
        let restingState: String
        if state.isDormant {
            restingState = language == .arabic ? "، سكون لطيف" : ", Resting gently"
        } else {
            restingState = ""
        }
        
        return "\(name), \(status), \(stage), \(tendedState)\(restingState)"
    }

    private func isTendedHint(for state: HasanaGardenPracticeState) -> String {
        if state.isTendedToday {
            return language == .arabic
                ? "اضغط لفتح التسجيل وإلغاء التسجيل إذا لزم."
                : "Tap to open logging and untend if needed."
        } else {
            return language == .arabic
                ? "اضغط لفتح التسجيل وتسجيل هذه العبادة اليوم."
                : "Tap to open logging and tend this practice today."
        }
    }

    /// Maps each practice to an approximate 2D position that aligns with where
    /// the 3D entity appears in the default camera view.
    private func screenPosition(for id: HasanaGardenPracticeID, in size: CGSize) -> CGPoint {
        let cx = size.width / 2
        let cy = size.height / 2
        switch id {
        case .fajr:
            return CGPoint(x: cx - size.width * 0.30, y: cy - size.height * 0.12)
        case .dhuhr:
            return CGPoint(x: cx - size.width * 0.10, y: cy - size.height * 0.14)
        case .asr:
            return CGPoint(x: cx + size.width * 0.10, y: cy - size.height * 0.12)
        case .maghrib:
            return CGPoint(x: cx + size.width * 0.26, y: cy - size.height * 0.04)
        case .isha:
            return CGPoint(x: cx + size.width * 0.18, y: cy + size.height * 0.08)
        case .quran:
            return CGPoint(x: cx - size.width * 0.20, y: cy + size.height * 0.08)
        case .adhkar:
            return CGPoint(x: cx, y: cy + size.height * 0.06)
        case .witr:
            return CGPoint(x: cx + size.width * 0.28, y: cy + size.height * 0.10)
        }
    }
}

// MARK: - Camera State

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

    init(userDefaults: UserDefaults = .shared) {
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

// MARK: - RealityKit View

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
        // Disable built-in AR accessibility — our overlay handles VoiceOver.
        arView.accessibilityElementsHidden = true
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

    @MainActor
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

        private var displayLink: CADisplayLink?
        private var panVelocity: CGPoint = .zero
        private var zoomVelocity: Float = 0
        private var lastStepTime: CFTimeInterval = 0

        init(
            cameraState: HasanaGardenCameraState,
            onPracticeSelected: @escaping (HasanaGardenPracticeID) -> Void
        ) {
            self.cameraState = cameraState
            self.onPracticeSelected = onPracticeSelected
        }

        deinit {
            displayLink?.invalidate()
        }

        func configure(_ arView: ARView) {
            guard self.arView == nil else { return }

            self.arView = arView
            arView.scene.addAnchor(sceneAnchor)
            arView.scene.addAnchor(cameraAnchor)
            cameraAnchor.addChild(camera)

            // Register custom wind system and components globally in the RealityKit scene
            HasanaWindSystem.register()

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
            // Always update during deceleration — don't gate on revision alone.
            // Only skip if revision matches AND the camera already has a valid transform.
            let needsUpdate = lastCameraRevision != cameraState.revision
                || camera.transform.matrix == matrix_identity_float4x4
            guard needsUpdate else { return }

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
            let hits = arView.hitTest(location)
            for hit in hits {
                if let practiceID = practiceID(from: hit.entity) {
                    onPracticeSelected(practiceID)
                    return
                }
            }
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            switch recognizer.state {
            case .began:
                stopDeceleration()
                panStartYaw = cameraState.yaw
                panStartPitch = cameraState.pitch
            case .changed:
                let translation = recognizer.translation(in: recognizer.view)
                // Scale sensitivity by zoom distance so far-out panning feels consistent.
                let distanceFactor = cameraState.distance / 6.6
                let yawSensitivity = Float(0.005 * distanceFactor)
                let pitchSensitivity = Float(0.003 * distanceFactor)
                cameraState.update(
                    yaw: panStartYaw + Float(translation.x) * yawSensitivity,
                    pitch: panStartPitch - Float(translation.y) * pitchSensitivity
                )
                updateCamera()
            case .ended, .cancelled, .failed:
                let velocity = recognizer.velocity(in: recognizer.view)
                let distanceFactor = cameraState.distance / 6.6
                let yawSensitivity = CGFloat(0.005 * distanceFactor)
                let pitchSensitivity = CGFloat(0.003 * distanceFactor)
                panVelocity = CGPoint(
                    x: velocity.x * yawSensitivity,
                    y: -velocity.y * pitchSensitivity
                )
                // Cap inertia to prevent wild spinning.
                panVelocity.x = max(min(panVelocity.x, 8.0), -8.0)
                panVelocity.y = max(min(panVelocity.y, 5.0), -5.0)
                startDeceleration()
            default:
                break
            }
        }

        @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            switch recognizer.state {
            case .began:
                stopDeceleration()
                pinchStartDistance = cameraState.distance
            case .changed:
                let scale = max(Float(recognizer.scale), 0.01)
                let targetDistance = pinchStartDistance / scale
                cameraState.update(distance: targetDistance)
                updateCamera()
            case .ended, .cancelled, .failed:
                // Velocity from UIPinchGestureRecognizer is in scale/s.
                // Convert to distance/s: Δdistance ≈ -currentDistance * velocity_scale / scale.
                let scale = max(Float(recognizer.scale), 0.01)
                let currentDistance = pinchStartDistance / scale
                // Negative because pinching in (scale>1) should decrease distance.
                zoomVelocity = -currentDistance * Float(recognizer.velocity) / scale
                zoomVelocity = max(min(zoomVelocity, 12.0), -12.0)
                startDeceleration()
            default:
                break
            }
        }

        private func startDeceleration() {
            guard displayLink == nil else { return }
            lastStepTime = CACurrentMediaTime()
            let link = CADisplayLink(target: self, selector: #selector(stepDeceleration(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func stopDeceleration() {
            displayLink?.invalidate()
            displayLink = nil
            panVelocity = .zero
            zoomVelocity = 0
        }

        @objc private func stepDeceleration(_ link: CADisplayLink) {
            let currentTime = CACurrentMediaTime()
            let dt = Float(currentTime - lastStepTime)
            lastStepTime = currentTime

            let cappedDt = min(max(dt, 0.001), 0.05)
            var didUpdate = false

            // Pan inertia — decay exponent 0.12 gives a natural 0.6s trailing stop at 60fps.
            let panSpeedSq = panVelocity.x * panVelocity.x + panVelocity.y * panVelocity.y
            if panSpeedSq > 0.00001 {
                let decay = CGFloat(pow(0.12, Double(cappedDt)))
                let deltaYaw   = Float(panVelocity.x) * cappedDt
                let deltaPitch = Float(panVelocity.y) * cappedDt

                cameraState.update(
                    yaw: cameraState.yaw + deltaYaw,
                    pitch: cameraState.pitch + deltaPitch
                )

                panVelocity.x *= decay
                panVelocity.y *= decay
                didUpdate = true
            } else {
                panVelocity = .zero
            }

            // Zoom inertia — same decay curve.
            if abs(zoomVelocity) > 0.005 {
                let decay = Float(pow(0.12, Double(cappedDt)))
                let deltaDistance = zoomVelocity * cappedDt

                cameraState.update(distance: cameraState.distance + deltaDistance)

                zoomVelocity *= decay
                didUpdate = true
            } else {
                zoomVelocity = 0
            }

            if didUpdate {
                // Bypass revision guard during inertia — directly recompute camera position.
                let dist = cameraState.distance
                let hDist = cos(cameraState.pitch) * dist
                let pos = SIMD3<Float>(
                    sin(cameraState.yaw) * hDist,
                    sin(cameraState.pitch) * dist + 0.45,
                    cos(cameraState.yaw) * hDist
                )
                camera.look(at: SIMD3<Float>(0, 0.28, 0), from: pos, relativeTo: nil)
            }

            if panVelocity == .zero && zoomVelocity == 0 {
                stopDeceleration()
                cameraState.save()
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

            // 1. Soil base layer
            let soilColor = UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
            let soil = ModelEntity(
                mesh: .generateBox(width: 6.5, height: 0.08, depth: 4.35),
                materials: [material(soilColor, roughness: 0.95)]
            )
            soil.position = [0, -0.04, 0]
            root.addChild(soil)

            // 2. Grass lawn layer
            let grassColor = UIColor(red: 0.32, green: 0.58, blue: 0.38, alpha: 1.0)
            let lawn = ModelEntity(
                mesh: .generateBox(width: 6.42, height: 0.08, depth: 4.27),
                materials: [material(grassColor, roughness: 0.9)]
            )
            lawn.position = [0, 0.04, 0]
            root.addChild(lawn)

            // 3. Wooden Garden Retaining Border Frame
            let woodColor = UIColor(red: 0.42, green: 0.30, blue: 0.22, alpha: 1.0)
            let woodMaterial = material(woodColor, roughness: 0.7)

            // Back border
            let backBorder = ModelEntity(mesh: .generateBox(width: 6.58, height: 0.18, depth: 0.08), materials: [woodMaterial])
            backBorder.position = [0, 0.01, -2.175 - 0.04]
            root.addChild(backBorder)

            // Front border
            let frontBorder = ModelEntity(mesh: .generateBox(width: 6.58, height: 0.18, depth: 0.08), materials: [woodMaterial])
            frontBorder.position = [0, 0.01, 2.175 + 0.04]
            root.addChild(frontBorder)

            // Left border
            let leftBorder = ModelEntity(mesh: .generateBox(width: 0.08, height: 0.18, depth: 4.35), materials: [woodMaterial])
            leftBorder.position = [-3.25 - 0.04, 0.01, 0]
            root.addChild(leftBorder)

            // Right border
            let rightBorder = ModelEntity(mesh: .generateBox(width: 0.08, height: 0.18, depth: 4.35), materials: [woodMaterial])
            rightBorder.position = [3.25 + 0.04, 0.01, 0]
            root.addChild(rightBorder)

            // 4. Stepping Stones Path
            let stoneColor = UIColor(red: 0.88, green: 0.86, blue: 0.82, alpha: 1.0)
            let stoneMat = material(stoneColor, roughness: 0.85)

            // Horizontal stepping stones along z = 0.18
            let startX: Float = -2.7
            let endX: Float = 2.7
            let stepX: Float = 0.45
            var currentX = startX
            while currentX <= endX {
                let distanceToIntersection = abs(currentX - 0.25)
                if distanceToIntersection > 0.1 {
                    let stone = ModelEntity(
                        mesh: .generateBox(width: 0.24, height: 0.012, depth: 0.24),
                        materials: [stoneMat]
                    )
                    stone.position = [currentX, 0.081, 0.18]
                    root.addChild(stone)
                }
                currentX += stepX
            }

            // Cross path stepping stones along x = 0.25 (going front to back)
            let startZ: Float = -1.8
            let endZ: Float = 1.8
            let stepZ: Float = 0.45
            var currentZ = startZ
            while currentZ <= endZ {
                let stone = ModelEntity(
                    mesh: .generateBox(width: 0.24, height: 0.013, depth: 0.24),
                    materials: [stoneMat]
                )
                stone.position = [0.25, 0.081, currentZ]
                root.addChild(stone)
                currentZ += stepZ
            }

            // 5. Lighting and Sun
            let sun = ModelEntity(
                mesh: .generateSphere(radius: 0.28),
                materials: [material(UIColor(HasanaTheme.gold.opacity(0.92)), roughness: 0.25)]
            )
            sun.position = [2.55, 2.15, -1.5]
            root.addChild(sun)

            // Primary directional light (warm afternoon sun) casting soft shadows
            let light = DirectionalLight()
            light.light.intensity = 2600
            light.light.color = UIColor(red: 1.0, green: 0.97, blue: 0.90, alpha: 1.0)
            light.orientation = simd_quatf(angle: -.pi / 3, axis: [1, 0, 0]) * simd_quatf(angle: .pi / 6, axis: [0, 1, 0])
            light.shadow = DirectionalLightComponent.Shadow(
                maximumDistance: 10.0,
                depthBias: 1.0
            )
            root.addChild(light)

            // Fill light (cool sky ambient fill) to balance shadows and add color contrast
            let fillLight = PointLight()
            fillLight.light.intensity = 1100
            fillLight.light.color = UIColor(red: 0.88, green: 0.93, blue: 0.98, alpha: 1.0)
            fillLight.light.attenuationRadius = 10.0
            fillLight.position = [-2.8, 2.6, 2.4]
            root.addChild(fillLight)

            return root
        }

        private func makePracticeEntity(for state: HasanaGardenPracticeState) -> Entity {
            let root = Entity()
            root.name = entityName(for: state.practice.id)
            root.position = position(for: state.practice.id)

            // Dormant plants are slightly drooped — tilt the root entity
            if state.isDormant && !state.isTendedToday {
                root.orientation = simd_quatf(angle: 0.18, axis: [1, 0, 0.2])
            }

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
                root.addChild(makeTendedCheckmark(for: state.practice.id))
            }

            // Set up physical wind receiver properties on the plant root entity
            let windReceiver = WindReceiverComponent(
                practiceID: state.practice.id.rawValue,
                visualRole: state.practice.visualRole.rawValue,
                growthStage: state.progress.growthStage.rawValue,
                isDormant: state.isDormant && !state.isTendedToday
            )
            root.components[WindReceiverComponent.self] = windReceiver

            root.generateCollisionShapes(recursive: true)
            return root
        }

        private func makeAssetBackedPracticeEntity(for state: HasanaGardenPracticeState) -> Entity? {
            // Future USDZ assets can be routed through this seam using practice ID and growth stage.
            nil
        }

        private func makeTree(for state: HasanaGardenPracticeState, in root: Entity) {
            let tree = HasanaGardenTreeGeometry.generateEntity(for: state)
            root.addChild(tree)
        }

        private func makeLeafyPlant(for state: HasanaGardenPracticeState, in root: Entity) {
            let scale = state.progress.growthStage.modelScale
            let accent = accentColor(for: state.practice, isTendedToday: state.isTendedToday, isDormant: state.isDormant)
            let isDormantPlant = state.isDormant && !state.isTendedToday

            let stemHeight = 0.34 + scale * 0.38
            let stemRadius = 0.025 + scale * 0.015

            let stem = namedModel(
                id: state.practice.id,
                mesh: .generateCylinder(height: stemHeight, radius: stemRadius),
                color: accent,
                roughness: 0.8
            )
            stem.position = [0, stemHeight / 2, 0]
            root.addChild(stem)

            let leafCount = state.progress.growthStage.leafCount
            let minLeafHeight = stemHeight * 0.3
            let maxLeafHeight = stemHeight * 0.85

            for index in 0..<leafCount {
                let leafHeight: Float
                if leafCount > 1 {
                    leafHeight = minLeafHeight + (Float(index) / Float(leafCount - 1)) * (maxLeafHeight - minLeafHeight)
                } else {
                    leafHeight = minLeafHeight
                }

                let leafLength = 0.18 + scale * 0.12
                let leafWidth = 0.08 + scale * 0.05
                let leafThickness: Float = 0.008
                let petioleLength = 0.04 + scale * 0.03
                let petioleRadius = 0.005 + scale * 0.003

                let leafGroup = Entity()
                leafGroup.name = entityName(for: state.practice.id)
                leafGroup.position = [0, leafHeight, 0]

                // Petiole connects stem to leaf blade
                let petiole = namedModel(
                    id: state.practice.id,
                    mesh: .generateCylinder(height: petioleLength, radius: petioleRadius),
                    color: accent,
                    roughness: 0.8
                )
                // Cylinder is vertical along Y. Rotate around Z by 90 degrees to lay it along X.
                petiole.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                petiole.position = [stemRadius + petioleLength / 2, 0, 0]
                leafGroup.addChild(petiole)

                // Leaf blade
                let leafBlade = namedModel(
                    id: state.practice.id,
                    mesh: .generateBox(width: leafLength, height: leafThickness, depth: leafWidth),
                    color: index.isMultiple(of: 2) ? accent : UIColor(HasanaTheme.accent),
                    roughness: 0.72
                )
                leafBlade.position = [stemRadius + petioleLength + leafLength / 2, 0, 0]
                leafGroup.addChild(leafBlade)

                // Arrange leaves spiraling around the stem using an angle step of ~137.5 degrees (2.4 radians)
                let theta = Float(index) * 2.4
                let rotationY = simd_quatf(angle: theta, axis: [0, 1, 0])

                // Natural droop angles:
                // Active: slight natural arch down (-0.12 to -0.22 radians / -7 to -12 degrees)
                // Dormant: hangs/droops significantly more (-0.68 to -0.82 radians / -39 to -47 degrees)
                let baseDroop = isDormantPlant ? Float(-0.68) : Float(-0.12)
                let droopAngle = baseDroop - Float(index) * (isDormantPlant ? 0.04 : 0.02)
                let rotationZ = simd_quatf(angle: droopAngle, axis: [0, 0, 1])

                leafGroup.orientation = rotationY * rotationZ
                root.addChild(leafGroup)
            }
        }

        private func makeFlower(for state: HasanaGardenPracticeState, in root: Entity) {
            let scale = state.progress.growthStage.modelScale
            let accent = accentColor(for: state.practice, isTendedToday: state.isTendedToday, isDormant: state.isDormant)

            // 1. Stem
            let stemHeight = 0.32 + scale * 0.4
            let stemRadius = 0.02 + scale * 0.01
            let stem = namedModel(
                id: state.practice.id,
                mesh: .generateCylinder(height: stemHeight, radius: stemRadius),
                color: UIColor(HasanaTheme.accent), // stem green
                roughness: 0.85
            )
            stem.position = [0, stemHeight / 2.0, 0]
            root.addChild(stem)

            // Add small green stem leaves for realism if past the seed stage
            if state.progress.growthStage != .seed {
                let leafMesh = MeshResource.generateSphere(radius: 1.0)
                let leafCount = (state.progress.growthStage == .mature || state.progress.growthStage == .flowering) ? 2 : 1
                for i in 0..<leafCount {
                    let leaf = ModelEntity(
                        mesh: leafMesh,
                        materials: [material(UIColor(HasanaTheme.accent), roughness: 0.75)]
                    )
                    leaf.name = entityName(for: state.practice.id)
                    
                    let leafHeight = stemHeight * (i == 0 ? 0.35 : 0.65)
                    let leafScaleX = 0.04 + scale * 0.03
                    let leafScaleY = 0.01 + scale * 0.005
                    let leafScaleZ = 0.12 + scale * 0.08
                    leaf.scale = SIMD3<Float>(leafScaleX, leafScaleY, leafScaleZ)
                    
                    let yawAngle = Float(i) * .pi + .pi / 4.0
                    let pitchAngle: Float = -0.25 // angle outwards/upwards
                    let yawRot = simd_quatf(angle: yawAngle, axis: [0, 1, 0])
                    let pitchRot = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
                    
                    leaf.orientation = yawRot * pitchRot
                    
                    // position offset along the rotated leaf direction
                    let leafOffset = (yawRot * pitchRot).act([0, 0, leafScaleZ * 0.6])
                    leaf.position = SIMD3<Float>(0, leafHeight, 0) + leafOffset
                    
                    root.addChild(leaf)
                }
            }

            // 2. Flower Center (Receptacle / Disc)
            let centerHeight = stemHeight
            let centerRadiusX = 0.075 + scale * 0.045
            let centerRadiusY = 0.045 + scale * 0.025 // squashed for a more natural look
            let centerRadiusZ = 0.075 + scale * 0.045
            let center = namedModel(
                id: state.practice.id,
                mesh: .generateSphere(radius: 1.0),
                color: UIColor(HasanaTheme.gold),
                roughness: 0.5
            )
            center.scale = SIMD3<Float>(centerRadiusX, centerRadiusY, centerRadiusZ)
            center.position = [0, centerHeight, 0]
            root.addChild(center)

            // Extract HSBA to create variations for inner/outer petals
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            accent.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            
            let outerColor = accent
            let innerColor = UIColor(hue: h, saturation: max(0, s - 0.08), brightness: min(1, b + 0.12), alpha: a)

            // 3. Petals
            let basePetalMesh = MeshResource.generateSphere(radius: 1.0)
            
            // Build rings of petals based on growth stage
            struct PetalRing {
                let count: Int
                let isInner: Bool
                let scaleFactor: Float
                let pitchAngle: Float // tilt upward
                let radiusOffset: Float
            }
            
            var rings: [PetalRing] = []
            
            switch state.progress.growthStage {
            case .seed:
                // Seed stage: just a small closed bud, no fully formed petals yet
                break
            case .sprout:
                // Sprout: 2 tiny emerging petals
                rings.append(PetalRing(count: 2, isInner: false, scaleFactor: 0.5, pitchAngle: 0.5, radiusOffset: 0.02))
            case .young:
                // Young: 4 petals in one ring
                rings.append(PetalRing(count: 4, isInner: false, scaleFactor: 0.75, pitchAngle: 0.35, radiusOffset: 0.04))
            case .mature:
                // Mature: 6 petals in one ring
                rings.append(PetalRing(count: 6, isInner: false, scaleFactor: 0.9, pitchAngle: 0.25, radiusOffset: 0.06))
            case .flowering:
                // Flowering: 2 layers (double flower!) for high-quality lush look
                // Outer ring: 6 petals, flatter tilt
                rings.append(PetalRing(count: 6, isInner: false, scaleFactor: 1.0, pitchAngle: 0.15, radiusOffset: 0.08))
                // Inner ring: 5 petals, smaller, more upright, staggered
                rings.append(PetalRing(count: 5, isInner: true, scaleFactor: 0.75, pitchAngle: 0.38, radiusOffset: 0.04))
            }
            
            // Generate petals for each ring
            for ring in rings {
                let color = ring.isInner ? innerColor : outerColor
                let petalMaterial = material(color, roughness: 0.6)
                
                for index in 0..<ring.count {
                    // Stagger the inner ring starting angle
                    let startOffset: Float = ring.isInner ? .pi / 5.0 : 0.0
                    let angle = startOffset + (Float(index) / Float(ring.count)) * .pi * 2.0
                    
                    // Deterministic organic variation based on petal index & practice ID
                    let hash = state.practice.id.hashValue
                    let positiveHash = hash >= 0 ? hash : -hash
                    let seedVal = Float((positiveHash + index) % 7) / 7.0
                    let varScale = 0.92 + seedVal * 0.16
                    let varPitch = (seedVal - 0.5) * 0.08
                    let varYaw = (seedVal - 0.5) * 0.06
                    
                    // Dormant flowers droop/wilt
                    let activePitch = ring.pitchAngle + varPitch
                    let pitchAngle = (state.isDormant && !state.isTendedToday) ? -0.45 + varPitch : activePitch
                    
                    // Create petal ModelEntity
                    let petal = ModelEntity(mesh: basePetalMesh, materials: [petalMaterial])
                    petal.name = entityName(for: state.practice.id)
                    
                    // Dimensions: width, thickness, length
                    let petalWidth = (0.045 + scale * 0.035) * ring.scaleFactor * varScale
                    let petalThickness = (0.012 + scale * 0.008) * ring.scaleFactor
                    let petalLength = (0.13 + scale * 0.09) * ring.scaleFactor * varScale
                    
                    petal.scale = SIMD3<Float>(petalWidth, petalThickness, petalLength)
                    
                    // Rotations
                    let yawRot = simd_quatf(angle: angle + varYaw, axis: [0, 1, 0])
                    let pitchRot = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
                    petal.orientation = yawRot * pitchRot
                    
                    // Position using the orientation to offset from center
                    let petalRadius = (0.035 + scale * 0.025) + ring.radiusOffset
                    let offset = (yawRot * pitchRot).act([0, 0, petalRadius])
                    petal.position = center.position + offset
                    
                    root.addChild(petal)
                }
            }
        }

        private func makeTendedHalo(for id: HasanaGardenPracticeID) -> Entity {
            let root = Entity()

            // Outer highlight ring - acts as a tap highlight / selection ring. Shiny, metallic, and slightly wider.
            let outerRing = namedModel(
                id: id,
                mesh: .generateCylinder(height: 0.012, radius: 0.38),
                color: UIColor(HasanaTheme.gold),
                roughness: 0.15,
                isMetallic: true
            )
            outerRing.position = [0, 0.056, 0]

            // Inner halo plate - soft, translucent glow color.
            let innerPlate = namedModel(
                id: id,
                mesh: .generateCylinder(height: 0.006, radius: 0.34),
                color: UIColor(HasanaTheme.gold.opacity(0.48)),
                roughness: 0.4,
                isMetallic: false
            )
            innerPlate.position = [0, 0.055, 0]

            root.addChild(outerRing)
            root.addChild(innerPlate)
            return root
        }

        private func makeTendedCheckmark(for id: HasanaGardenPracticeID) -> Entity {
            let root = Entity()
            
            // Position the checkmark to the front-right of the plant to prevent clipping with the stem.
            root.position = [0.24, 0.08, 0.24]
            // Tilt the checkmark slightly forward to face the camera.
            root.orientation = simd_quatf(angle: -0.25, axis: [1, 0, 0])

            let shortStroke = namedModel(
                id: id,
                mesh: .generateBox(width: 0.032, height: 0.12, depth: 0.032),
                color: UIColor(HasanaTheme.gold),
                roughness: 0.15,
                isMetallic: true
            )
            shortStroke.position = [-0.035, 0.08, 0]
            shortStroke.orientation = simd_quatf(angle: .pi / 4, axis: [0, 0, 1])

            let longStroke = namedModel(
                id: id,
                mesh: .generateBox(width: 0.032, height: 0.22, depth: 0.032),
                color: UIColor(HasanaTheme.gold),
                roughness: 0.15,
                isMetallic: true
            )
            longStroke.position = [0.045, 0.11, 0]
            longStroke.orientation = simd_quatf(angle: -.pi / 4, axis: [0, 0, 1])

            root.addChild(shortStroke)
            root.addChild(longStroke)
            return root
        }

        private func namedModel(
            id: HasanaGardenPracticeID,
            mesh: MeshResource,
            color: UIColor,
            roughness: Float,
            isMetallic: Bool = false
        ) -> ModelEntity {
            let model = ModelEntity(
                mesh: mesh,
                materials: [material(color, roughness: roughness, isMetallic: isMetallic)]
            )
            model.name = entityName(for: id)
            return model
        }

        private func material(_ color: UIColor, roughness: Float, isMetallic: Bool = false) -> SimpleMaterial {
            SimpleMaterial(color: color, roughness: .float(roughness), isMetallic: isMetallic)
        }

        private func practiceID(from entity: Entity) -> HasanaGardenPracticeID? {
            var candidate: Entity? = entity

            while let current = candidate {
                if current.name.hasPrefix("practice:") {
                    let rawValue = current.name.replacingOccurrences(of: "practice:", with: "")
                    if let practiceID = HasanaGardenPracticeID(rawValue: rawValue) {
                        return practiceID
                    }
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

        /// Returns the plant's accent color, desaturated and dimmed when dormant.
        private func accentColor(for practice: HasanaGardenPractice, isTendedToday: Bool, isDormant: Bool) -> UIColor {
            // Dormant and not tended today: desaturate and reduce opacity significantly
            if isDormant && !isTendedToday {
                return dormantColor(for: practice)
            }

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

        /// A muted, grey-blue tint used for dormant plants — gentle, not punitive.
        private func dormantColor(for practice: HasanaGardenPractice) -> UIColor {
            // Blend the practice's natural color with a cool grey at ~35% saturation
            let baseColor: UIColor
            switch practice.religiousStatus {
            case .obligatory:
                baseColor = UIColor(HasanaTheme.accent)
            case .quran:
                baseColor = UIColor(HasanaTheme.gold)
            case .dhikr:
                baseColor = UIColor(HasanaTheme.reflection)
            case .sunnah, .sunnahWajib:
                baseColor = UIColor(HasanaTheme.summary)
            }

            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            baseColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

            // Reduce saturation by ~65%, drop brightness slightly, cap opacity at 0.52
            return UIColor(hue: h, saturation: s * 0.35, brightness: b * 0.78, alpha: 0.52)
        }

        private func canopyOffset(index: Int, scale: Float) -> SIMD3<Float> {
            switch index {
            case 0:
                // Left lower canopy offset, scales nicely
                [-0.22 * scale, 0.74 + scale * 0.34, 0.04 * scale]
            case 1:
                // Right middle canopy offset, slightly higher and forward
                [0.24 * scale, 0.84 + scale * 0.38, -0.05 * scale]
            case 2:
                // Top crown canopy offset
                [0.0, 1.05 + scale * 0.44, 0.08 * scale]
            default:
                [0.0, 0.92 + scale * 0.22, 0.0]
            }
        }
    }
}

// MARK: - Growth Stage 3D Geometry Helpers

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

// MARK: - Status Bar

private struct HasanaGardenStatusBar: View {
    let tendedTodayCount: Int
    let totalCount: Int
    let totalTendedDays: Int
    let language: HasanaLanguage

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
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

            VStack(spacing: 10) {
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
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HasanaTheme.elevatedSurface.opacity(0.24))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.08),
                            .clear,
                            .white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: HasanaTheme.shadow.opacity(0.08), radius: 16, x: 0, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private func statusItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.15), in: Circle())
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.25), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(HasanaTheme.textPrimary)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HasanaTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(HasanaTheme.elevatedSurfaceSoft.opacity(0.48))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.6
                )
        }
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

    private var accessibilitySummary: String {
        switch language {
        case .arabic:
            "\(tendedTodayCount) من \(totalCount) تم اليوم. إجمالي أيام الرعاية \(totalTendedDays)."
        case .english:
            "\(tendedTodayCount) of \(totalCount) tended today. \(totalTendedDays) total tended days."
        }
    }
}

private struct HasanaGardenStateLegend: View {
    let language: HasanaLanguage

    var body: some View {
        HStack(spacing: 12) {
            legendItem(icon: "checkmark.seal.fill", text: tendedText, color: HasanaTheme.gold)
            legendItem(icon: "circle", text: untendedText, color: HasanaTheme.textMuted)
            legendItem(icon: "leaf.arrow.circlepath", text: dormantText, color: HasanaTheme.reflection)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .background(
            Capsule()
                .fill(HasanaTheme.elevatedSurface.opacity(0.24))
        )
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.06),
                            .clear,
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: HasanaTheme.shadow.opacity(0.06), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }

    private func legendItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(HasanaTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var tendedText: String {
        language == .arabic ? "تم" : "Tended"
    }

    private var untendedText: String {
        language == .arabic ? "لم يتم" : "Untended"
    }

    private var dormantText: String {
        language == .arabic ? "نائمة" : "Dormant"
    }
}

// MARK: - Garden Hint

private struct HasanaGardenHint: View {
    let language: HasanaLanguage

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                hintIcon("rotate.3d")
                hintIcon("magnifyingglass")
                hintIcon("hand.tap.fill")

                Text(text)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
            }

            HStack(spacing: 8) {
                hintIcon("hand.tap.fill")

                Text(shortText)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
            }
        }
        .foregroundStyle(HasanaTheme.textMuted)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HasanaTheme.elevatedSurface.opacity(0.24))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.28),
                            .white.opacity(0.06),
                            .clear,
                            .white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: HasanaTheme.shadow.opacity(0.05), radius: 12, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }

    private func hintIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 11, weight: .bold))
            .frame(width: 22, height: 22)
            .background(HasanaTheme.elevatedSurfaceSoft.opacity(0.35), in: Circle())
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
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

    private var shortText: String {
        switch language {
        case .arabic:
            "اضغط على نبتة للتسجيل"
        case .english:
            "Tap a plant to log"
        }
    }
}

// MARK: - Preview

#Preview {
    HasanaGardenView(
        store: HasanaGardenStore(),
        cameraState: HasanaGardenCameraState(),
        language: .english,
        onPracticeSelected: { _ in }
    )
}
