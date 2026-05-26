import SwiftUI
import Combine
import UIKit
import QuartzCore

/// HasanaMotion is the core namespace and runtime coordination engine for
/// motion design, transitions, and interactive physics across the Hasana app.
///
/// It provides mathematically precise spring behaviors, custom cubic Bezier curves,
/// interactive modal containers, gesture-driven physics (rubber-banding, tilt, inertia),
/// choreographical sequencing, and custom view modifiers that integrate with SwiftUI.
public enum HasanaMotion {
    
    // MARK: - Slide Direction
    
    public enum SlideDirection {
        case horizontal
        case vertical
    }
    
    // MARK: - Spring Physics Configuration
    
    /// Encapsulates spring physics settings based on response (duration) and damping fraction.
    public struct Spring {
        public let response: Double
        public let dampingFraction: Double
        public let blendDuration: Double
        
        public init(response: Double, dampingFraction: Double, blendDuration: Double = 0.0) {
            self.response = response
            self.dampingFraction = dampingFraction
            self.blendDuration = blendDuration
        }
        
        public var animation: Animation {
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
        
        // MARK: Preset Library
        
        /// A snappy, fast spring suitable for button taps, command palettes, and fast state changes.
        public static let snappy = Spring(response: 0.32, dampingFraction: 0.72)
        
        /// A bouncy, playful spring designed for celebration views, habit accomplishments, and garden milestones.
        public static let bouncy = Spring(response: 0.46, dampingFraction: 0.58)
        
        /// A smooth, organic transition spring for moving between main sections or dashboard navigation.
        public static let smooth = Spring(response: 0.55, dampingFraction: 0.88)
        
        /// A highly responsive spring optimized for real-time gesture tracking and dragging.
        public static let interactive = Spring(response: 0.26, dampingFraction: 0.84)
        
        /// A gentle, calming spring aligned with reflective spiritual moments.
        public static let gentle = Spring(response: 0.42, dampingFraction: 0.85)
        
        /// An exaggerated, expressive spring that draws attention to success animations.
        public static let expressive = Spring(response: 0.62, dampingFraction: 0.48)
        
        /// High elastic bounce, primarily for interactive elements that are pulled or stretched past bounds.
        public static let extraBouncy = Spring(response: 0.52, dampingFraction: 0.42)
        
        /// Extremely slow and soft spring for background gradients or subtle ambient motion.
        public static let whisper = Spring(response: 0.78, dampingFraction: 0.94)
    }
    
    // MARK: - Physical Spring Constants
    
    /// Defines spring dynamics using physical parameters (mass, stiffness, damping).
    public struct PhysicalSpring {
        public let mass: Double
        public let stiffness: Double
        public let damping: Double
        public let initialVelocity: Double
        
        public init(mass: Double, stiffness: Double, damping: Double, initialVelocity: Double = 0.0) {
            self.mass = mass
            self.stiffness = stiffness
            self.damping = damping
            self.initialVelocity = initialVelocity
        }
        
        public var animation: Animation {
            .interpolatingSpring(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: initialVelocity)
        }
        
        // MARK: Preset Library
        
        /// Fluid, liquid-like movement.
        public static let liquid = PhysicalSpring(mass: 1.0, stiffness: 220.0, damping: 16.0)
        
        /// Stiff, immediate reaction.
        public static let stiff = PhysicalSpring(mass: 1.0, stiffness: 350.0, damping: 26.0)
        
        /// Soft, floating animation.
        public static let soft = PhysicalSpring(mass: 1.0, stiffness: 85.0, damping: 13.0)
        
        /// Heavy, high-inertia spring.
        public static let heavy = PhysicalSpring(mass: 2.6, stiffness: 180.0, damping: 28.0)
    }
    
    // MARK: - Bezier Curve Interpolator
    
    /// Mathematical solver for 2D Cubic Bezier curve paths.
    /// Uses Newton-Raphson iteration to solve for curve values, useful for custom frame-based transitions.
    public struct BezierEvaluator {
        public let cp1: CGPoint
        public let cp2: CGPoint
        
        public init(cp1: CGPoint, cp2: CGPoint) {
            self.cp1 = cp1
            self.cp2 = cp2
        }
        
        public init(x1: Double, y1: Double, x2: Double, y2: Double) {
            self.cp1 = CGPoint(x: x1, y: y1)
            self.cp2 = CGPoint(x: x2, y: y2)
        }
        
        /// Resolves the bezier value at a normalized time parameter `targetX` (0.0 to 1.0).
        public func solve(x targetX: Double, tolerance: Double = 1e-6) -> Double {
            if targetX <= 0.0 { return 0.0 }
            if targetX >= 1.0 { return 1.0 }
            
            var t = targetX
            for _ in 0..<8 {
                let xVal = sampleCurveX(t: t)
                let derivative = sampleCurveDerivativeX(t: t)
                if abs(derivative) < 1e-6 { break }
                let diff = xVal - targetX
                t -= diff / derivative
            }
            return sampleCurveY(t: t)
        }
        
        private func sampleCurveX(t: Double) -> Double {
            let tSq = t * t
            let tCub = tSq * t
            let oneMinusT = 1.0 - t
            let oneMinusTSq = oneMinusT * oneMinusT
            return 3.0 * oneMinusTSq * t * Double(cp1.x) + 3.0 * oneMinusT * tSq * Double(cp2.x) + tCub
        }
        
        private func sampleCurveDerivativeX(t: Double) -> Double {
            let oneMinusT = 1.0 - t
            return 3.0 * oneMinusT * oneMinusT * Double(cp1.x) +
                   6.0 * oneMinusT * t * (Double(cp2.x) - Double(cp1.x)) +
                   3.0 * t * t * (1.0 - Double(cp2.x))
        }
        
        private func sampleCurveY(t: Double) -> Double {
            let tSq = t * t
            let tCub = tSq * t
            let oneMinusT = 1.0 - t
            let oneMinusTSq = oneMinusT * oneMinusT
            return 3.0 * oneMinusTSq * t * Double(cp1.y) + 3.0 * oneMinusT * tSq * Double(cp2.y) + tCub
        }
    }
    
    // MARK: - Bezier Curve Presets
    
    public enum CurvePreset {
        case easeInQuad, easeOutQuad, easeInOutQuad
        case easeInCubic, easeOutCubic, easeInOutCubic
        case easeInQuart, easeOutQuart, easeInOutQuart
        case easeInQuint, easeOutQuint, easeInOutQuint
        case easeInSine, easeOutSine, easeInOutSine
        case easeInExpo, easeOutExpo, easeInOutExpo
        case easeInCirc, easeOutCirc, easeInOutCirc
        case easeInBack, easeOutBack, easeInOutBack
        case cubicBezier(x1: Double, y1: Double, x2: Double, y2: Double)
        
        public var controlPoints: (x1: Double, y1: Double, x2: Double, y2: Double) {
            switch self {
            case .easeInQuad:      return (0.11, 0.0, 0.5, 0.0)
            case .easeOutQuad:     return (0.5, 1.0, 0.89, 1.0)
            case .easeInOutQuad:   return (0.45, 0.0, 0.55, 1.0)
            case .easeInCubic:     return (0.32, 0.0, 0.67, 0.0)
            case .easeOutCubic:    return (0.33, 1.0, 0.68, 1.0)
            case .easeInOutCubic:  return (0.65, 0.0, 0.35, 1.0)
            case .easeInQuart:     return (0.5, 0.0, 0.75, 0.0)
            case .easeOutQuart:    return (0.25, 1.0, 0.5, 1.0)
            case .easeInOutQuart:  return (0.76, 0.0, 0.24, 1.0)
            case .easeInQuint:     return (0.64, 0.0, 0.78, 0.0)
            case .easeOutQuint:    return (0.22, 1.0, 0.36, 1.0)
            case .easeInOutQuint:  return (0.83, 0.0, 0.17, 1.0)
            case .easeInSine:      return (0.12, 0.0, 0.39, 0.0)
            case .easeOutSine:     return (0.61, 1.0, 0.88, 1.0)
            case .easeInOutSine:   return (0.37, 0.0, 0.63, 1.0)
            case .easeInExpo:      return (0.7, 0.0, 0.84, 0.0)
            case .easeOutExpo:     return (0.16, 1.0, 0.3, 1.0)
            case .easeInOutExpo:   return (0.87, 0.0, 0.13, 1.0)
            case .easeInCirc:      return (0.55, 0.0, 1.0, 0.45)
            case .easeOutCirc:     return (0.0, 0.55, 0.45, 1.0)
            case .easeInOutCirc:   return (0.85, 0.0, 0.15, 1.0)
            case .easeInBack:      return (0.36, 0.0, 0.66, -0.56)
            case .easeOutBack:     return (0.34, 1.56, 0.64, 1.0)
            case .easeInOutBack:   return (0.68, -0.6, 0.32, 1.6)
            case .cubicBezier(let x1, let y1, let x2, let y2):
                return (x1, y1, x2, y2)
            }
        }
        
        public var animation: Animation {
            let cp = controlPoints
            return Animation.timingCurve(cp.x1, cp.y1, cp.x2, cp.y2)
        }
        
        public func animation(duration: Double) -> Animation {
            let cp = controlPoints
            return Animation.timingCurve(cp.x1, cp.y1, cp.x2, cp.y2, duration: duration)
        }
    }
    
    // MARK: - CADisplayLink Spring Simulation Engine
    
    /// A physics-based continuous spring simulator.
    /// Runs a custom dynamic equation on the Main Thread via CADisplayLink.
    /// Useful for custom graphics rendering, games, or high-performance canvas interfaces.
    public class SpringSimulation: ObservableObject {
        @Published public var value: Double
        @Published public var velocity: Double
        
        public var target: Double {
            didSet {
                if target != oldValue {
                    driver.start()
                }
            }
        }
        
        public var stiffness: Double
        public var damping: Double
        public var mass: Double
        
        private lazy var driver: DisplayLinkDriver = {
            DisplayLinkDriver { [weak self] dt in
                self?.update(dt: dt)
            }
        }()
        
        public init(
            initialValue: Double = 0.0,
            target: Double = 0.0,
            stiffness: Double = 180.0,
            damping: Double = 12.0,
            mass: Double = 1.0
        ) {
            self.value = initialValue
            self.velocity = 0.0
            self.target = target
            self.stiffness = stiffness
            self.damping = damping
            self.mass = mass
        }
        
        public func update(dt: Double) {
            let displacement = value - target
            let springForce = -stiffness * displacement
            let dampingForce = -damping * velocity
            let acceleration = (springForce + dampingForce) / mass
            
            velocity += acceleration * dt
            value += velocity * dt
            
            // Check for rest/snapping condition to disable screen refresh
            if abs(value - target) < 1e-4 && abs(velocity) < 1e-4 {
                value = target
                velocity = 0.0
                driver.stop()
            }
        }
        
        public func cancel() {
            driver.stop()
        }
    }
    
    // MARK: - Internal Helpers
    
    private class DisplayLinkDriver {
        private var displayLink: CADisplayLink?
        private var lastTimestamp: CFTimeInterval = 0
        private let onUpdate: (Double) -> Void
        
        init(onUpdate: @escaping (Double) -> Void) {
            self.onUpdate = onUpdate
        }
        
        func start() {
            stop()
            lastTimestamp = CACurrentMediaTime()
            displayLink = CADisplayLink(target: self, selector: #selector(tick))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        func stop() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc private func tick() {
            let now = CACurrentMediaTime()
            let dt = min(now - lastTimestamp, 0.08) // clamp delta to avoid lag jumps
            lastTimestamp = now
            onUpdate(dt)
        }
        
        deinit {
            stop()
        }
    }
}

// MARK: - SwiftUI Animation Extensions

extension Animation {
    public static var hasanaSnappy: Animation { HasanaMotion.Spring.snappy.animation }
    public static var hasanaBouncy: Animation { HasanaMotion.Spring.bouncy.animation }
    public static var hasanaSmooth: Animation { HasanaMotion.Spring.smooth.animation }
    public static var hasanaInteractive: Animation { HasanaMotion.Spring.interactive.animation }
    public static var hasanaGentle: Animation { HasanaMotion.Spring.gentle.animation }
    public static var hasanaExpressive: Animation { HasanaMotion.Spring.expressive.animation }
    public static var hasanaExtraBouncy: Animation { HasanaMotion.Spring.extraBouncy.animation }
    public static var hasanaWhisper: Animation { HasanaMotion.Spring.whisper.animation }
}

// MARK: - Custom Transitions & Modifiers

// MARK: 1. 3D Page Flip Transition

/// A transition modifier that rotates a view 180 degrees around a specified axis,
/// simulating a physical Arabic book page turning or card flipping.
public struct HasanaFlipTransitionModifier: ViewModifier, Animatable {
    public var progress: Double // ranges from -1.0 to 1.0 (or 0.0 to 1.0)
    public let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    public let anchor: UnitPoint
    public let perspective: CGFloat
    public let backfaceHidden: Bool
    
    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    public func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(progress * 180.0),
                axis: axis,
                anchor: anchor,
                perspective: perspective
            )
            .opacity(backfaceHidden && abs(progress) > 0.5 ? 0.0 : 1.0)
    }
}

extension AnyTransition {
    /// A flip transition that rotates around the Y-axis.
    public static func hasanaFlip3D(
        axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0.0, 1.0, 0.0),
        anchor: UnitPoint = .center,
        perspective: CGFloat = 0.4,
        backfaceHidden: Bool = true
    ) -> AnyTransition {
        .modifier(
            active: HasanaFlipTransitionModifier(progress: -1.0, axis: axis, anchor: anchor, perspective: perspective, backfaceHidden: backfaceHidden),
            identity: HasanaFlipTransitionModifier(progress: 0.0, axis: axis, anchor: anchor, perspective: perspective, backfaceHidden: backfaceHidden)
        )
    }
}

// MARK: 2. Perspective Card Stack Transition

/// A transitions modifier that offsets, rotates, scales, and drops shadow on a view
/// to simulate pulling cards out of an overlapping index deck or pushing them back.
public struct HasanaPerspectiveStackModifier: ViewModifier, Animatable {
    public var progress: Double // 0 when active, 1 when disappearing, -1 when appearing
    public let direction: HasanaMotion.SlideDirection
    public let depth: CGFloat
    
    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    public func body(content: Content) -> some View {
        let isDisappearing = progress > 0
        let scale: CGFloat = isDisappearing ? 0.90 : 1.0
        let opacity: Double = isDisappearing ? 0.0 : 1.0
        let offset: CGFloat = isDisappearing ? 0.0 : -progress * depth
        let zRotation: Double = isDisappearing ? 0.0 : -progress * 6.0
        
        return content
            .scaleEffect(scale)
            .offset(
                x: direction == .horizontal ? offset : 0,
                y: direction == .vertical ? offset : 0
            )
            .rotationEffect(.degrees(zRotation))
            .opacity(opacity)
            .shadow(
                color: Color.black.opacity(isDisappearing ? 0.0 : 0.16 * (1.0 - progress)),
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

extension AnyTransition {
    public static func hasanaPerspectiveStack(
        direction: HasanaMotion.SlideDirection = .horizontal,
        depth: CGFloat = 350.0
    ) -> AnyTransition {
        .modifier(
            active: HasanaPerspectiveStackModifier(progress: 1.0, direction: direction, depth: depth),
            identity: HasanaPerspectiveStackModifier(progress: 0.0, direction: direction, depth: depth)
        )
    }
}

// MARK: 3. Bloom Blur Transition

/// A transition modifier that scales, fades, and animates a Gaussian blur radius.
public struct HasanaBloomBlurModifier: ViewModifier, Animatable {
    public var progress: Double // 0 (active) to 1 (fully blurred and scaled up)
    public let maxRadius: CGFloat
    public let maxScale: CGFloat
    
    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    public func body(content: Content) -> some View {
        content
            .blur(radius: progress * maxRadius)
            .scaleEffect(1.0 + (progress * (maxScale - 1.0)))
            .opacity(1.0 - progress)
    }
}

extension AnyTransition {
    /// A soft, cinematic bloom transition.
    public static func hasanaBloom(
        maxRadius: CGFloat = 16.0,
        maxScale: CGFloat = 1.08
    ) -> AnyTransition {
        .modifier(
            active: HasanaBloomBlurModifier(progress: 1.0, maxRadius: maxRadius, maxScale: maxScale),
            identity: HasanaBloomBlurModifier(progress: 0.0, maxRadius: maxRadius, maxScale: maxScale)
        )
    }
}

// MARK: 4. Parallax Stack Transition

/// A multi-layered parallax transition. It shifts the primary view and transmits
/// the translation offset down to child elements via environment keys.
public struct HasanaParallaxModifier: ViewModifier, Animatable {
    public var progress: Double // 0 (identity) to 1 (fully shifted off-screen)
    public let edge: Edge
    public let rate: CGFloat
    
    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            let multiplier: CGFloat = (edge == .leading || edge == .top) ? -1.0 : 1.0
            let totalDist = (edge == .leading || edge == .trailing) ? size.width : size.height
            let offset: CGFloat = progress * totalDist * multiplier
            
            content
                .offset(
                    x: (edge == .leading || edge == .trailing) ? offset : 0,
                    y: (edge == .top || edge == .bottom) ? offset : 0
                )
                // Offset passed down to children to animate backgrounds in counter-direction
                .environment(\.hasanaParallaxOffset, offset * (rate - 1.0))
        }
    }
}

private struct HasanaParallaxOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0.0
}

extension EnvironmentValues {
    public var hasanaParallaxOffset: CGFloat {
        get { self[HasanaParallaxOffsetKey.self] }
        set { self[HasanaParallaxOffsetKey.self] = newValue }
    }
}

extension AnyTransition {
    public static func hasanaParallax(
        edge: Edge = .trailing,
        rate: CGFloat = 0.6
    ) -> AnyTransition {
        .modifier(
            active: HasanaParallaxModifier(progress: 1.0, edge: edge, rate: rate),
            identity: HasanaParallaxModifier(progress: 0.0, edge: edge, rate: rate)
        )
    }
}

// MARK: 5. Shake & Wobble Modifiers

public struct HasanaShakeModifier: ViewModifier, Animatable {
    public var progress: Double // 0.0 to 1.0
    public let xOffset: CGFloat
    public let yOffset: CGFloat
    public let frequency: Double
    
    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    public func body(content: Content) -> some View {
        // Linear decay of sinusoidal wobble
        let angle = progress * Double.pi * frequency
        let decay = 1.0 - progress
        let delta = sin(angle) * decay
        
        return content
            .offset(
                x: delta * xOffset,
                y: delta * yOffset
            )
    }
}

public struct HasanaShakeTriggerModifier: ViewModifier {
    let trigger: Bool
    let xOffset: CGFloat
    let yOffset: CGFloat
    let frequency: Double
    
    @State private var progress: Double = 1.0
    
    public func body(content: Content) -> some View {
        content
            .modifier(HasanaShakeModifier(progress: progress, xOffset: xOffset, yOffset: yOffset, frequency: frequency))
            .onChange(of: trigger) { _, _ in
                progress = 0.0
                withAnimation(.easeOut(duration: 0.45)) {
                    progress = 1.0
                }
            }
    }
}

public struct HasanaWobbleModifier: ViewModifier, Animatable {
    public var progress: Double // 0.0 to 1.0
    public let scaleIntensity: CGFloat
    public let angleIntensity: Double
    
    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    public func body(content: Content) -> some View {
        let decay = 1.0 - progress
        let angle = sin(progress * Double.pi * 5.0) * angleIntensity * decay
        let scale = 1.0 + sin(progress * Double.pi * 6.0) * scaleIntensity * decay
        
        return content
            .rotationEffect(.degrees(angle))
            .scaleEffect(scale)
    }
}

public struct HasanaWobbleTriggerModifier: ViewModifier {
    let trigger: Bool
    let scaleIntensity: CGFloat
    let angleIntensity: Double
    
    @State private var progress: Double = 1.0
    
    public func body(content: Content) -> some View {
        content
            .modifier(HasanaWobbleModifier(progress: progress, scaleIntensity: scaleIntensity, angleIntensity: angleIntensity))
            .onChange(of: trigger) { _, _ in
                progress = 0.0
                withAnimation(.easeOut(duration: 0.58)) {
                    progress = 1.0
                }
            }
    }
}

extension View {
    /// Shakes the view back and forth when the trigger boolean is toggled.
    public func hasanaShake(
        trigger: Bool,
        x: CGFloat = 10.0,
        y: CGFloat = 0.0,
        frequency: Double = 6.0
    ) -> some View {
        self.modifier(HasanaShakeTriggerModifier(trigger: trigger, xOffset: x, yOffset: y, frequency: frequency))
    }
    
    /// Wobbles scale and angle to produce playful tactile feedback on success/triggers.
    public func hasanaWobble(
        trigger: Bool,
        scale: CGFloat = 0.07,
        angle: Double = 6.0
    ) -> some View {
        self.modifier(HasanaWobbleTriggerModifier(trigger: trigger, scaleIntensity: scale, angleIntensity: angle))
    }
}

// MARK: 6. 3D Tilt Card Modifier

/// Automatically tilts the view in 3D perspective following the drag point location.
public struct HasanaTiltCardModifier: ViewModifier {
    public let maxTiltAngle: Double
    public let scale: CGFloat
    public let isHapticEnabled: Bool
    
    @State private var tiltOffset: CGSize = .zero
    @State private var isHovering = false
    
    public func body(content: Content) -> some View {
        GeometryReader { geo in
            let size = geo.size
            content
                .scaleEffect(isHovering ? scale : 1.0)
                .rotation3DEffect(
                    .degrees(Double(tiltOffset.height) * maxTiltAngle),
                    axis: (x: 1.0, y: 0.0, z: 0.0)
                )
                .rotation3DEffect(
                    .degrees(Double(-tiltOffset.width) * maxTiltAngle),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let xPercent = (value.location.x - (size.width / 2.0)) / (size.width / 2.0)
                            let yPercent = (value.location.y - (size.height / 2.0)) / (size.height / 2.0)
                            
                            withAnimation(.hasanaInteractive) {
                                tiltOffset = CGSize(
                                    width: min(max(xPercent, -1.0), 1.0),
                                    height: min(max(yPercent, -1.0), 1.0)
                                )
                                if !isHovering {
                                    isHovering = true
                                    if isHapticEnabled {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.hasanaSnappy) {
                                tiltOffset = .zero
                                isHovering = false
                            }
                        }
                )
        }
    }
}

extension View {
    public func hasanaTiltCard(
        maxAngle: Double = 8.0,
        hoverScale: CGFloat = 1.03,
        haptics: Bool = true
    ) -> some View {
        self.modifier(HasanaTiltCardModifier(maxTiltAngle: maxAngle, scale: hoverScale, isHapticEnabled: haptics))
    }
}

// MARK: - Press Styles & Ripple Feedback

// MARK: 1. Button Press Style

public struct HasanaPressButtonStyle: ButtonStyle {
    public let scale: CGFloat
    public let opacity: Double
    public let spring: HasanaMotion.Spring
    
    public init(
        scale: CGFloat = 0.95,
        opacity: Double = 0.88,
        spring: HasanaMotion.Spring = .snappy
    ) {
        self.scale = scale
        self.opacity = opacity
        self.spring = spring
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(spring.animation, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                if newValue {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                }
            }
    }
}

// MARK: 2. View Touch Press Modifier

public struct HasanaPressableModifier: ViewModifier {
    @State private var isPressed = false
    public let scale: CGFloat
    public let opacity: Double
    public let spring: HasanaMotion.Spring
    public let action: () -> Void
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .opacity(isPressed ? opacity : 1.0)
            .animation(spring.animation, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
                        }
                    }
                    .onEnded { _ in
                        if isPressed {
                            isPressed = false
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            action()
                        }
                    }
            )
    }
}

extension View {
    public func hasanaPressable(
        scale: CGFloat = 0.95,
        opacity: Double = 0.88,
        spring: HasanaMotion.Spring = .snappy,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(HasanaPressableModifier(scale: scale, opacity: opacity, spring: spring, action: action))
    }
}

// MARK: 3. Glow Pulse Modifier

public struct HasanaGlowPulseModifier: ViewModifier {
    @State private var isAnimating = false
    public let color: Color
    public let radius: CGFloat
    public let scale: CGFloat
    public let duration: Double
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? scale : 1.0)
            .shadow(
                color: color.opacity(isAnimating ? 0.55 : 0.22),
                radius: isAnimating ? radius : radius / 3.0,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    /// Applies a continuous breathing scale and glowing shadow pulse effect.
    public func hasanaPulse(
        color: Color = Color.accentColor,
        radius: CGFloat = 10.0,
        scale: CGFloat = 1.05,
        duration: Double = 1.6
    ) -> some View {
        self.modifier(HasanaGlowPulseModifier(color: color, radius: radius, scale: scale, duration: duration))
    }
}

// MARK: 4. Water Ripple Touch Modifier

public struct HasanaRippleModifier: ViewModifier {
    @State private var ripples: [Ripple] = []
    public let color: Color
    public let duration: Double
    
    struct Ripple: Identifiable {
        let id: UUID
        let point: CGPoint
        var progress: Double = 0.0
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        ForEach(ripples) { ripple in
                            Circle()
                                .stroke(color.opacity(1.0 - ripple.progress), lineWidth: 3.5 * (1.0 - ripple.progress))
                                .frame(width: 140.0 * ripple.progress, height: 140.0 * ripple.progress)
                                .position(ripple.point)
                        }
                    }
                }
                .allowsHitTesting(false)
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let id = UUID()
                        let newRipple = Ripple(id: id, point: value.location)
                        ripples.append(newRipple)
                        
                        withAnimation(.easeOut(duration: duration)) {
                            if let idx = ripples.firstIndex(where: { $0.id == id }) {
                                ripples[idx].progress = 1.0
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            ripples.removeAll { $0.id == id }
                        }
                    }
            )
    }
}

extension View {
    /// Spawns expanding water ripple elements at touch point location without hijacking clicks.
    public func hasanaTouchRipple(
        color: Color = Color.accentColor.opacity(0.36),
        duration: Double = 0.54
    ) -> some View {
        self.modifier(HasanaRippleModifier(color: color, duration: duration))
    }
}

// MARK: - Gesture-Driven Physics Drag

public struct HasanaPhysicsDragModifier: ViewModifier {
    @State private var dragOffset: CGSize = .zero
    @State private var velocity: CGSize = .zero
    @State private var lastDragTime = Date()
    @State private var lastDragLocation: CGPoint = .zero
    
    public let snapPoints: [CGPoint]
    public let boundary: CGRect?
    public let rubberBandLimit: CGFloat
    public let tiltAngle: Double
    public let spring: HasanaMotion.Spring
    public let onSnap: ((CGPoint, Int) -> Void)?
    
    @State private var currentPosition: CGPoint
    
    public init(
        initialPosition: CGPoint = .zero,
        snapPoints: [CGPoint] = [],
        boundary: CGRect? = nil,
        rubberBandLimit: CGFloat = 55.0,
        tiltAngle: Double = 7.0,
        spring: HasanaMotion.Spring = .snappy,
        onSnap: ((CGPoint, Int) -> Void)? = nil
    ) {
        self._currentPosition = State(initialValue: initialPosition)
        self.snapPoints = snapPoints
        self.boundary = boundary
        self.rubberBandLimit = rubberBandLimit
        self.tiltAngle = tiltAngle
        self.spring = spring
        self.onSnap = onSnap
    }
    
    public func body(content: Content) -> some View {
        let rotationDegrees = calculateTilt()
        
        return content
            .offset(x: currentPosition.x + dragOffset.width, y: currentPosition.y + dragOffset.height)
            .rotationEffect(.degrees(rotationDegrees))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let now = Date()
                        let dt = now.timeIntervalSince(lastDragTime)
                        if dt > 0 {
                            let vx = (value.location.x - lastDragLocation.x) / CGFloat(dt)
                            let vy = (value.location.y - lastDragLocation.y) / CGFloat(dt)
                            velocity = CGSize(width: vx, height: vy)
                        }
                        lastDragTime = now
                        lastDragLocation = value.location
                        
                        var proposedWidth = value.translation.width
                        var proposedHeight = value.translation.height
                        
                        if let boundary = boundary {
                            let currentX = currentPosition.x + proposedWidth
                            let currentY = currentPosition.y + proposedHeight
                            
                            if currentX < boundary.minX {
                                let diff = boundary.minX - currentX
                                proposedWidth += diff - rubberBand(diff, limit: rubberBandLimit)
                            } else if currentX > boundary.maxX {
                                let diff = currentX - boundary.maxX
                                proposedWidth -= diff - rubberBand(diff, limit: rubberBandLimit)
                            }
                            
                            if currentY < boundary.minY {
                                let diff = boundary.minY - currentY
                                proposedHeight += diff - rubberBand(diff, limit: rubberBandLimit)
                            } else if currentY > boundary.maxY {
                                let diff = currentY - boundary.maxY
                                proposedHeight -= diff - rubberBand(diff, limit: rubberBandLimit)
                            }
                        }
                        
                        withAnimation(.hasanaInteractive) {
                            dragOffset = CGSize(width: proposedWidth, height: proposedHeight)
                        }
                    }
                    .onEnded { value in
                        // Predict final landing position using momentum inertia
                        let finalX = currentPosition.x + dragOffset.width + (velocity.width * 0.12)
                        let finalY = currentPosition.y + dragOffset.height + (velocity.height * 0.12)
                        let targetPoint = CGPoint(x: finalX, y: finalY)
                        
                        var resolvedPoint = targetPoint
                        var snappedIndex = -1
                        
                        if !snapPoints.isEmpty {
                            var minDistance = CGFloat.infinity
                            for (index, point) in snapPoints.enumerated() {
                                let dist = distance(point, targetPoint)
                                if dist < minDistance {
                                    minDistance = dist
                                    resolvedPoint = point
                                    snappedIndex = index
                                }
                            }
                        } else if let boundary = boundary {
                            let clampedX = min(max(targetPoint.x, boundary.minX), boundary.maxX)
                            let clampedY = min(max(targetPoint.y, boundary.minY), boundary.maxY)
                            resolvedPoint = CGPoint(x: clampedX, y: clampedY)
                        }
                        
                        withAnimation(spring.animation) {
                            currentPosition = resolvedPoint
                            dragOffset = .zero
                            velocity = .zero
                        }
                        
                        if snappedIndex >= 0 {
                            onSnap?(resolvedPoint, snappedIndex)
                        }
                    }
            )
            .onAppear {
                lastDragLocation = .zero
            }
    }
    
    private func rubberBand(_ distance: CGFloat, limit: CGFloat) -> CGFloat {
        return (distance * limit) / (distance + limit)
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func calculateTilt() -> Double {
        if dragOffset == .zero { return 0.0 }
        let maxVel: CGFloat = 1100.0
        let normVel = min(max(velocity.width / maxVel, -1.0), 1.0)
        return Double(normVel) * tiltAngle
    }
}

extension View {
    public func hasanaPhysicsDrag(
        initialPosition: CGPoint = .zero,
        snapPoints: [CGPoint] = [],
        boundary: CGRect? = nil,
        rubberBandLimit: CGFloat = 55.0,
        tiltAngle: Double = 7.0,
        spring: HasanaMotion.Spring = .snappy,
        onSnap: ((CGPoint, Int) -> Void)? = nil
    ) -> some View {
        self.modifier(
            HasanaPhysicsDragModifier(
                initialPosition: initialPosition,
                snapPoints: snapPoints,
                boundary: boundary,
                rubberBandLimit: rubberBandLimit,
                tiltAngle: tiltAngle,
                spring: spring,
                onSnap: onSnap
            )
        )
    }
}

// MARK: - Custom Sheet / Drawer Presenter

private struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    fileprivate func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

/// A custom modal view modifier presenting contents inside an interactive bottom card drawer.
public struct HasanaModalViewModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    public let detents: [CGFloat] // Scale percentages e.g. [0.35, 0.70, 0.95]
    public let spring: HasanaMotion.Spring
    public let backdropColor: Color
    public let content: () -> ModalContent
    
    @State private var currentDetentIndex: Int = 0
    @State private var translationY: CGFloat = 0.0
    @State private var backdropOpacity: Double = 0.0
    
    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let detentHeights = detents.map { $0 * screenHeight }
            
            let baseHeight = detentHeights.indices.contains(currentDetentIndex) ? detentHeights[currentDetentIndex] : (screenHeight * 0.5)
            let activeHeight = max(0.0, baseHeight - translationY)
            
            ZStack(alignment: .bottom) {
                content
                
                if isPresented {
                    backdropColor
                        .opacity(backdropOpacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissModal()
                        }
                    
                    VStack(spacing: 0) {
                        // Interactive Top Handle
                        Capsule()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 38, height: 5.5)
                            .padding(.vertical, 10)
                        
                        self.content()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: activeHeight)
                    .background(HasanaTheme.elevatedSurface)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .shadow(color: HasanaTheme.shadow.opacity(0.16), radius: 14, x: 0, y: -5)
                    .offset(y: translationY > 0 && currentDetentIndex == 0 ? translationY : 0)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let tY = value.translation.height
                                if currentDetentIndex == detents.count - 1 && tY < 0 {
                                    translationY = -rubberBand(-tY, limit: 50.0)
                                } else {
                                    translationY = tY
                                }
                            }
                            .onEnded { value in
                                let velocityY = value.predictedEndTranslation.height - value.translation.height
                                let finalTranslationY = value.translation.height
                                
                                // Quick dismiss swipe down
                                if velocityY > 480.0 || finalTranslationY > (baseHeight * 0.4) {
                                    if currentDetentIndex == 0 {
                                        dismissModal()
                                        return
                                    } else {
                                        withAnimation(spring.animation) {
                                            currentDetentIndex = max(0, currentDetentIndex - 1)
                                            translationY = 0.0
                                        }
                                        return
                                    }
                                }
                                
                                // Quick expand swipe up
                                if velocityY < -480.0 {
                                    withAnimation(spring.animation) {
                                        currentDetentIndex = min(detents.count - 1, currentDetentIndex + 1)
                                        translationY = 0.0
                                    }
                                    return
                                }
                                
                                // Snap to nearest detent height
                                let targetHeight = baseHeight - finalTranslationY
                                var bestIndex = currentDetentIndex
                                var minDiff = CGFloat.infinity
                                
                                for (idx, h) in detentHeights.enumerated() {
                                    let diff = abs(h - targetHeight)
                                    if diff < minDiff {
                                        minDiff = diff
                                        bestIndex = idx
                                    }
                                }
                                
                                if detentHeights[bestIndex] < (screenHeight * 0.16) {
                                    dismissModal()
                                } else {
                                    withAnimation(spring.animation) {
                                        currentDetentIndex = bestIndex
                                        translationY = 0.0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .onAppear {
                if isPresented {
                    presentModal()
                }
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    presentModal()
                } else {
                    dismissModal()
                }
            }
        }
    }
    
    private func presentModal() {
        currentDetentIndex = 0
        translationY = 0.0
        withAnimation(.easeOut(duration: 0.3)) {
            backdropOpacity = 0.58
        }
    }
    
    private func dismissModal() {
        withAnimation(.easeIn(duration: 0.24)) {
            backdropOpacity = 0.0
        }
        withAnimation(spring.animation) {
            isPresented = false
            translationY = 0.0
        }
    }
    
    private func rubberBand(_ distance: CGFloat, limit: CGFloat) -> CGFloat {
        return (distance * limit) / (distance + limit)
    }
}

extension View {
    /// Replaces sheets with custom highly customizable gesture-driven bottom cards.
    public func hasanaModal<ModalContent: View>(
        isPresented: Binding<Bool>,
        detents: [CGFloat] = [0.45, 0.85],
        spring: HasanaMotion.Spring = .smooth,
        backdropColor: Color = HasanaTheme.overlayScrim,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        self.modifier(
            HasanaModalViewModifier(
                isPresented: isPresented,
                detents: detents,
                spring: spring,
                backdropColor: backdropColor,
                content: content
            )
        )
    }
}

// MARK: - Animation Coordinator & Sequencer

/// Orchestrates sequential steps of changes (animations) with optional individual delays,
/// spring timings, and durations.
public class HasanaAnimationCoordinator: ObservableObject {
    
    public struct AnimationStep {
        let delay: Double
        let duration: Double?
        let animation: Animation?
        let action: () -> Void
    }
    
    private var steps: [AnimationStep] = []
    private var cancellables = Set<AnyCancellable>()
    
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var currentStepIndex: Int = 0
    @Published public private(set) var progress: Double = 0.0
    
    public init() {}
    
    /// Appends a new animation frame step to the sequence pipeline.
    @discardableResult
    public func addStep(
        delay: Double = 0.0,
        duration: Double? = nil,
        animation: Animation? = nil,
        action: @escaping () -> Void
    ) -> HasanaAnimationCoordinator {
        steps.append(AnimationStep(delay: delay, duration: duration, animation: animation, action: action))
        return self
    }
    
    /// Triggers the coordinated sequencing pipeline execution.
    public func start(completion: (() -> Void)? = nil) {
        guard !steps.isEmpty else {
            completion?()
            return
        }
        
        isRunning = true
        currentStepIndex = 0
        progress = 0.0
        cancellables.removeAll()
        
        executeNextStep(index: 0, accumulatedTime: 0.0, completion: completion)
    }
    
    private func executeNextStep(index: Int, accumulatedTime: Double, completion: (() -> Void)?) {
        guard index < steps.count else {
            DispatchQueue.main.async {
                self.isRunning = false
                self.progress = 1.0
                completion?()
            }
            return
        }
        
        let step = steps[index]
        
        Just(())
            .delay(for: .seconds(step.delay), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.currentStepIndex = index
                self.progress = Double(index) / Double(self.steps.count)
                
                if let anim = step.animation {
                    withAnimation(anim) {
                        step.action()
                    }
                } else {
                    step.action()
                }
                
                let stepDuration = step.duration ?? 0.38
                self.executeNextStep(
                    index: index + 1,
                    accumulatedTime: accumulatedTime + step.delay + stepDuration,
                    completion: completion
                )
            }
            .store(in: &cancellables)
    }
    
    /// Cancels execution and stops all queued animation states.
    public func cancel() {
        cancellables.removeAll()
        isRunning = false
        progress = 0.0
    }
}

/// A wrapper view helper that automatically triggers an animation sequence when appearing.
public struct HasanaAnimationSequenceView<Content: View>: View {
    let coordinator: HasanaAnimationCoordinator
    let content: () -> Content
    
    public init(
        coordinator: HasanaAnimationCoordinator,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.coordinator = coordinator
        self.content = content
    }
    
    public var body: some View {
        content()
            .onAppear {
                coordinator.start()
            }
            .onDisappear {
                coordinator.cancel()
            }
    }
}
