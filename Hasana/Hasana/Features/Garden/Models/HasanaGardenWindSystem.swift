//
//  HasanaGardenWindSystem.swift
//  Hasana
//
//  Created by Azzam Developer on 2026-05-26.
//

import Foundation
import RealityKit
import SwiftUI
import Combine
import simd

// MARK: - Mathematical Background & Physics Formulations
/*
   =============================================================================
   AERODYNAMIC & BIOMECHANICAL WIND SYSTEM DESIGN
   =============================================================================
   
   This file implements a high-fidelity wind simulation engine for the RealityKit
   3D Garden in the Hasana app. It uses fluid dynamics approximations and second-order
   differential equations to model the physical sway of plants and high-frequency
   fluttering of leaves under dynamic wind forces.

   1. Spatial-Temporal Wind Field Model:
      The local wind vector W(x, t) at any 3D coordinate x and time t is composed of:
         W(x, t) = W_base(t) + W_gust(x, t) + W_turb(x, t) + W_vortex(x, t)
      
      - Base Wind W_base: Steady, slowly shifting atmospheric flow.
      - Gusts W_gust: A transient, localized pulse propagating through the garden.
        Propagates along the wind heading, introducing a phase delay:
           t_delay = dot(x, W_dir) / W_speed
      - Turbulence W_turb: Procedural turbulence using Fractional Brownian Motion (fBm)
        to simulate atmospheric boundary layer eddies.
      - Vortex Field W_vortex: Localized, spinning turbulent eddies (micro-eddies)
        simulated via curl noise or explicit vortex dynamics that drift across the scene.

   2. Plant Biomechanics: Damped Harmonic Oscillator (RK4 Integration):
      We model each plant (trunk or stem) as a cantilever beam with rotational stiffness (k),
      mass moment of inertia (I), damping (c), and cross-sectional drag area.
      The angular displacement θ = [pitch, roll] satisfies:
         I * d²θ/dt² + c * dθ/dt + k * θ = Torque_wind(t)
      
      Where torque is derived from the aerodynamic drag equation:
         Drag_Force = 0.5 * ρ * C_d * A * (W_local - V_tip) * ||W_local - V_tip||
         Torque_wind = Drag_Force * height
         
      To ensure numerical stability at 60 FPS, we solve this second-order system
      using Runge-Kutta 4th Order (RK4) integration rather than Euler integration.

   3. Leaf & Petal Fluttering (Aerodynamic Instability):
      Leaves exhibit fluttering caused by vortex shedding (von Kármán vortex street).
      This is modeled as high-frequency angular oscillations on 3 axes, driven by local
      wind speed, with spatial phase offsets:
         θ_leaf = A_flutter * sin(ω_flutter * t + phase_offset)
         where ω_flutter ∝ ||W_local|| and A_flutter ∝ ||W_local|| (saturated)
*/

// MARK: - Seeded Random Number Generator
/// A lightweight, deterministic seeded random number generator based on the LCG algorithm.
/// Ensures consistent procedural generation for wind fields across app launches.
struct HasanaWindSeededRNG: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: Int) {
        // Avoid seed = 0
        self.state = seed == 0 ? 5489 : UInt64(seed)
    }
    
    mutating func next() -> UInt64 {
        // LCG multiplier from Knuth / MMIX
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Procedural Perlin Noise Engine
/// A complete pure Swift implementation of 3D Perlin Noise, including Fractional Brownian Motion (fBm)
/// and vector-valued curl noise for fluid-like wind turbulence.
final class HasanaPerlinNoise {
    private var p: [Int] = []
    
    init(seed: Int = 42) {
        var permutation = Array(0...255)
        var rng = HasanaWindSeededRNG(seed: seed)
        permutation.shuffle(using: &rng)
        self.p = permutation + permutation
    }
    
    private func fade(_ t: Float) -> Float {
        // 6t^5 - 15t^4 + 10t^3 (Improved fade curve)
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
    }
    
    private func lerp(_ t: Float, _ a: Float, _ b: Float) -> Float {
        return a + t * (b - a)
    }
    
    private func grad(_ hash: Int, _ x: Float, _ y: Float, _ z: Float) -> Float {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
    
    /// Generates 3D Perlin noise in the range [-1.0, 1.0].
    func noise(x: Float, y: Float, z: Float) -> Float {
        let X = Int(floor(x)) & 255
        let Y = Int(floor(y)) & 255
        let Z = Int(floor(z)) & 255
        
        let xf = x - floor(x)
        let yf = y - floor(y)
        let zf = z - floor(z)
        
        let u = fade(xf)
        let v = fade(yf)
        let w = fade(zf)
        
        let aaa = p[p[p[X] + Y] + Z]
        let aba = p[p[p[X] + Y + 1] + Z]
        let aab = p[p[p[X] + Y] + Z + 1]
        let abb = p[p[p[X] + Y + 1] + Z + 1]
        let baa = p[p[p[X + 1] + Y] + Z]
        let bba = p[p[p[X + 1] + Y + 1] + Z]
        let bab = p[p[p[X + 1] + Y] + Z + 1]
        let bbb = p[p[p[X + 1] + Y + 1] + Z + 1]
        
        let x1 = lerp(u, grad(aaa, xf, yf, zf), grad(baa, xf - 1, yf, zf))
        let x2 = lerp(u, grad(aba, xf, yf - 1, zf), grad(bba, xf - 1, yf - 1, zf))
        let y1 = lerp(v, x1, x2)
        
        let x3 = lerp(u, grad(aab, xf, yf, zf - 1), grad(bab, xf - 1, yf, zf - 1))
        let x4 = lerp(u, grad(abb, xf, yf - 1, zf - 1), grad(bbb, xf - 1, yf - 1, zf - 1))
        let y2 = lerp(v, x3, x4)
        
        return lerp(w, y1, y2)
    }
    
    /// Generates Fractional Brownian Motion (fBm) by summing octaves of noise.
    /// Simulates cascading atmospheric turbulence.
    func fBm(x: Float, y: Float, z: Float, octaves: Int, lacunarity: Float = 2.0, gain: Float = 0.5) -> Float {
        var total: Float = 0.0
        var amplitude: Float = 1.0
        var frequency: Float = 1.0
        var maxValue: Float = 0.0
        
        for _ in 0..<octaves {
            total += noise(x: x * frequency, y: y * frequency, z: z * frequency) * amplitude
            maxValue += amplitude
            amplitude *= gain
            frequency *= lacunarity
        }
        
        return total / maxValue
    }
    
    /// Multi-dimensional vector noise. Returns a 3D flow vector.
    func vectorNoise(x: Float, y: Float, z: Float) -> SIMD3<Float> {
        let nx = noise(x: x, y: y, z: z)
        let ny = noise(x: x + 31.415, y: y + 59.265, z: z + 27.182)
        let nz = noise(x: x - 42.123, y: y - 13.567, z: z + 88.910)
        return SIMD3<Float>(nx, ny, nz)
    }
    
    /// Generates divergence-free Curl Noise to represent realistic circular eddies.
    func curlNoise(x: Float, y: Float, z: Float) -> SIMD3<Float> {
        let eps: Float = 0.02
        
        // Sample surrounding fields to calculate partial derivatives
        let f_x_py = vectorNoise(x: x, y: y + eps, z: z)
        let f_x_my = vectorNoise(x: x, y: y - eps, z: z)
        let f_x_pz = vectorNoise(x: x, y: y, z: z + eps)
        let f_x_mz = vectorNoise(x: x, y: y, z: z - eps)
        
        let f_y_px = vectorNoise(x: x + eps, y: y, z: z)
        let f_y_mx = vectorNoise(x: x - eps, y: y, z: z)
        let f_y_pz = vectorNoise(x: x, y: y, z: z + eps)
        let f_y_mz = vectorNoise(x: x, y: y, z: z - eps)
        
        let f_z_px = vectorNoise(x: x + eps, y: y, z: z)
        let f_z_mx = vectorNoise(x: x - eps, y: y, z: z)
        let f_z_py = vectorNoise(x: x, y: y + eps, z: z)
        let f_z_my = vectorNoise(x: x, y: y - eps, z: z)
        
        // Curl formula: curl F = [dFz/dy - dFy/dz, dFx/dz - dFz/dx, dFy/dx - dFx/dy]
        let cx = ((f_z_py.z - f_z_my.z) - (f_y_pz.y - f_y_mz.y)) / (2.0 * eps)
        let cy = ((f_x_pz.x - f_x_mz.x) - (f_z_px.z - f_z_mx.z)) / (2.0 * eps)
        let cz = ((f_y_px.y - f_y_mx.y) - (f_x_py.x - f_x_my.x)) / (2.0 * eps)
        
        return SIMD3<Float>(cx, cy, cz)
    }
}

// MARK: - Wind Profiles & Configuration
/// Presets of various wind conditions, from a serene morning to a severe storm.
enum HasanaWindProfile: String, CaseIterable, Codable {
    case calm
    case gentleBreeze
    case moderateWind
    case gustyAutumn
    case galeStorm
    case desertSirocco
    
    var displayName: String {
        switch self {
        case .calm: return "Calm Morning"
        case .gentleBreeze: return "Gentle Breeze"
        case .moderateWind: return "Moderate Wind"
        case .gustyAutumn: return "Gusty Autumn"
        case .galeStorm: return "Stormy Gale"
        case .desertSirocco: return "Desert Sirocco"
        }
    }
    
    var configuration: HasanaWindConfig {
        switch self {
        case .calm:
            return HasanaWindConfig(
                baseSpeed: 0.4,
                baseDirection: SIMD3<Float>(1.0, 0.0, 0.2).safeNormalized,
                turbulenceIntensity: 0.15,
                gustFrequency: 0.05,
                gustAmplitude: 0.3,
                microTurbulenceScale: 0.5,
                dampingFactor: 0.95
            )
        case .gentleBreeze:
            return HasanaWindConfig(
                baseSpeed: 1.5,
                baseDirection: SIMD3<Float>(0.9, 0.0, 0.44).safeNormalized,
                turbulenceIntensity: 0.35,
                gustFrequency: 0.12,
                gustAmplitude: 1.2,
                microTurbulenceScale: 0.8,
                dampingFactor: 0.90
            )
        case .moderateWind:
            return HasanaWindConfig(
                baseSpeed: 3.2,
                baseDirection: SIMD3<Float>(0.8, 0.0, -0.6).safeNormalized,
                turbulenceIntensity: 0.45,
                gustFrequency: 0.18,
                gustAmplitude: 2.2,
                microTurbulenceScale: 1.2,
                dampingFactor: 0.85
            )
        case .gustyAutumn:
            return HasanaWindConfig(
                baseSpeed: 4.5,
                baseDirection: SIMD3<Float>(-0.7, 0.0, 0.71).safeNormalized,
                turbulenceIntensity: 0.70,
                gustFrequency: 0.25,
                gustAmplitude: 5.0,
                microTurbulenceScale: 2.0,
                dampingFactor: 0.78
            )
        case .galeStorm:
            return HasanaWindConfig(
                baseSpeed: 8.5,
                baseDirection: SIMD3<Float>(-0.98, 0.0, 0.2).safeNormalized,
                turbulenceIntensity: 0.90,
                gustFrequency: 0.35,
                gustAmplitude: 9.5,
                microTurbulenceScale: 3.5,
                dampingFactor: 0.70
            )
        case .desertSirocco:
            return HasanaWindConfig(
                baseSpeed: 5.2,
                baseDirection: SIMD3<Float>(0.3, 0.1, 0.95).safeNormalized,
                turbulenceIntensity: 0.60,
                gustFrequency: 0.20,
                gustAmplitude: 4.0,
                microTurbulenceScale: 2.5,
                dampingFactor: 0.82
            )
        }
    }
}

/// Parameters defining the physics of the wind field.
struct HasanaWindConfig: Codable, Equatable {
    var baseSpeed: Float          // m/s
    var baseDirection: SIMD3<Float> // normalized vector
    var turbulenceIntensity: Float  // scale of turbulence force
    var gustFrequency: Float      // average frequency of gusts (Hz)
    var gustAmplitude: Float      // multiplier for gust strength
    var microTurbulenceScale: Float // spatial scale of micro-eddies
    var dampingFactor: Float      // system damping
}

// MARK: - Wind Gust Engine
/// Represents phases of a natural wind gust event.
enum WindGustState: String, Codable {
    case idle
    case rampUp
    case peak
    case decay
    case cooldown
}

/// Generates wind gusts using a state-machine that varies gust intensity over time.
final class WindGustEngine {
    private(set) var currentState: WindGustState = .idle
    private var timer: Float = 0.0
    private var stateDuration: Float = 0.0
    
    private(set) var currentStrength: Float = 0.0
    private(set) var currentDirection: SIMD3<Float> = SIMD3<Float>(1, 0, 0)
    
    private var baseDirection: SIMD3<Float> = SIMD3<Float>(1, 0, 0)
    private var gustFrequency: Float = 0.1
    private var gustAmplitude: Float = 1.0
    
    init() {}
    
    func configure(baseDir: SIMD3<Float>, frequency: Float, amplitude: Float) {
        self.baseDirection = baseDir
        self.gustFrequency = frequency
        self.gustAmplitude = amplitude
    }
    
    func triggerManualGust() {
        if currentState == .idle || currentState == .cooldown {
            startGust()
        }
    }
    
    private func startGust() {
        currentState = .rampUp
        timer = 0.0
        stateDuration = Float.random(in: 1.0...2.2)
        
        // Randomize gust direction slightly around base wind direction (within +/- 30 degrees)
        let angle = Float.random(in: -0.52...0.52)
        let rot = simd_quatf(angle: angle, axis: [0, 1, 0])
        currentDirection = rot.act(baseDirection)
    }
    
    func update(dt: Float) {
        timer += dt
        
        switch currentState {
        case .idle:
            // Poisson-like activation logic
            let activationChance = gustFrequency * dt
            if Float.random(in: 0.0...1.0) < activationChance {
                startGust()
            } else {
                currentStrength = 0.0
            }
            
        case .rampUp:
            let progress = min(timer / stateDuration, 1.0)
            // Smoothstep curve for rise
            currentStrength = progress * progress * (3.0 - 2.0 * progress) * gustAmplitude
            
            if timer >= stateDuration {
                currentState = .peak
                timer = 0.0
                stateDuration = Float.random(in: 0.8...2.5)
            }
            
        case .peak:
            // Maintain peak strength with high-frequency fluttering fluctuations
            let noise = sin(timer * 12.0) * 0.15 * gustAmplitude
            currentStrength = (1.0 * gustAmplitude) + noise
            
            if timer >= stateDuration {
                currentState = .decay
                timer = 0.0
                stateDuration = Float.random(in: 1.5...3.5)
            }
            
        case .decay:
            let progress = min(timer / stateDuration, 1.0)
            // Smooth decay to rest
            let falloff = 1.0 - progress
            currentStrength = falloff * falloff * gustAmplitude
            
            if timer >= stateDuration {
                currentState = .cooldown
                timer = 0.0
                stateDuration = Float.random(in: 4.0...10.0) // quiet period between gusts
            }
            
        case .cooldown:
            currentStrength = 0.0
            if timer >= stateDuration {
                currentState = .idle
                timer = 0.0
            }
        }
    }
    
    func gustFactor(atLocalDelay delay: Float) -> Float {
        // Approximate gust strength offset in space for propagation delay
        let delayedTimer = timer - delay
        if delayedTimer < 0 { return 0.0 }
        
        switch currentState {
        case .idle, .cooldown:
            return 0.0
        case .rampUp:
            let progress = min(delayedTimer / stateDuration, 1.0)
            return progress * progress * (3.0 - 2.0 * progress)
        case .peak:
            return 1.0 + sin(delayedTimer * 10.0) * 0.1
        case .decay:
            let progress = min(delayedTimer / stateDuration, 1.0)
            return (1.0 - progress) * (1.0 - progress)
        }
    }
}

// MARK: - Vortex particle
/// Represents a micro-vortex spinning eddy drifting across the garden.
struct WindVortex: Codable, Equatable {
    var center: SIMD3<Float>
    var radius: Float
    var strength: Float
    var rotationSpeed: Float // rad/s
    var lifetime: Float      // remaining lifetime in seconds
    var velocity: SIMD3<Float> // translation vector
}

/// Simulates micro-eddies drifting through the garden space to induce unique swirling motions.
final class WindVortexField {
    private(set) var vortices: [WindVortex] = []
    
    init() {}
    
    func update(dt: Float) {
        vortices = vortices.compactMap { vortex in
            var v = vortex
            v.lifetime -= dt
            if v.lifetime <= 0 { return nil }
            v.center += v.velocity * dt
            return v
        }
    }
    
    func addVortex(_ vortex: WindVortex) {
        vortices.append(vortex)
    }
    
    func clearAll() {
        vortices.removeAll()
    }
    
    /// Calculates rotational wind vector induced by active vortices at a given position.
    func force(at position: SIMD3<Float>) -> SIMD3<Float> {
        var totalForce = SIMD3<Float>(0, 0, 0)
        
        for vortex in vortices {
            let offset = position - vortex.center
            // Check Y-independent distance (XZ plane vortex cylindrical column)
            let horizontalOffset = SIMD3<Float>(offset.x, 0.0, offset.z)
            let dist = simd_length(horizontalOffset)
            
            if dist < vortex.radius && dist > 0.001 {
                // Swirling vector perpendicular to offset
                let perp = SIMD3<Float>(-horizontalOffset.z, 0.0, horizontalOffset.x).safeNormalized
                
                // Falloff: strongest in the core, dropping to 0 at boundary
                let falloff = 1.0 - (dist / vortex.radius)
                let scale = vortex.strength * falloff * falloff
                
                totalForce += perp * scale
            }
        }
        
        return totalForce
    }
}

// MARK: - Global Wind System Coordinator
/// A singleton tracking the runtime state of the global wind system.
/// Combines base speed, gusts, Perlin noise fields, and vortices.
final class HasanaWindState {
    static let shared = HasanaWindState()
    
    var isEnabled: Bool = true
    var config: HasanaWindConfig = HasanaWindProfile.gentleBreeze.configuration
    var customConfig: HasanaWindConfig = HasanaWindProfile.gentleBreeze.configuration
    var useCustomConfig: Bool = false
    
    // Components
    let noise = HasanaPerlinNoise(seed: 1337)
    let gustEngine = WindGustEngine()
    let vortexField = WindVortexField()
    
    private var timeline: Float = 0.0
    
    private init() {
        resetWithProfile(.gentleBreeze)
    }
    
    func resetWithProfile(_ profile: HasanaWindProfile) {
        config = profile.configuration
        gustEngine.configure(
            baseDir: config.baseDirection,
            frequency: config.gustFrequency,
            amplitude: config.gustAmplitude
        )
        vortexField.clearAll()
        useCustomConfig = false
    }
    
    func setProfile(_ profile: HasanaWindProfile) {
        resetWithProfile(profile)
    }
    
    func triggerManualGust() {
        gustEngine.triggerManualGust()
    }
    
    func update(dt: Float, time: Float) {
        guard isEnabled else { return }
        timeline = time
        
        let activeConfig = useCustomConfig ? customConfig : config
        
        gustEngine.configure(
            baseDir: activeConfig.baseDirection,
            frequency: activeConfig.gustFrequency,
            amplitude: activeConfig.gustAmplitude
        )
        
        gustEngine.update(dt: dt)
        vortexField.update(dt: dt)
        
        // Expose telemetry
        let sampleWind = windVector(at: SIMD3<Float>(0, 0.5, 0), time: time)
        let sampleSpeed = simd_length(sampleWind)
        let sampleTurbulence = activeConfig.baseSpeed * activeConfig.turbulenceIntensity * 0.4
        
        HasanaWindTelemetry.shared.record(
            speed: sampleSpeed,
            isGusting: gustEngine.currentState != .idle && gustEngine.currentState != .cooldown,
            progress: gustEngine.currentStrength / max(activeConfig.gustAmplitude, 0.01),
            turbulence: sampleTurbulence
        )
    }
    
    /// Computes the exact 3D wind velocity vector at a specific coordinate and timestamp.
    func windVector(at position: SIMD3<Float>, time: Float) -> SIMD3<Float> {
        guard isEnabled else { return .zero }
        
        let activeConfig = useCustomConfig ? customConfig : config
        
        // 1. Base wind component
        let baseFlow = activeConfig.baseDirection * activeConfig.baseSpeed
        
        // 2. Gust propagation delay: gust moves as a wavefront along the base wind vector direction
        let windHeading = activeConfig.baseDirection
        let travelDistance = simd_dot(position, windHeading)
        let speed = max(activeConfig.baseSpeed, 0.5)
        let propagationDelay = travelDistance / speed
        
        // Evaluate the gust factor with delay
        let gustFactor = gustEngine.gustFactor(atLocalDelay: propagationDelay)
        let gustVector = gustEngine.currentDirection * (activeConfig.gustAmplitude * gustFactor)
        
        // 3. Medium-frequency turbulence (spatial-temporal wave using fBm)
        let scaleSpace: Float = 0.25
        let scaleTime: Float = 0.8
        let lowFreqTurbulenceX = noise.fBm(
            x: position.x * scaleSpace + time * scaleTime,
            y: position.y * scaleSpace,
            z: position.z * scaleSpace + time * scaleTime * 0.5,
            octaves: 3
        )
        let lowFreqTurbulenceZ = noise.fBm(
            x: position.x * scaleSpace + 23.4,
            y: position.y * scaleSpace + time * scaleTime * 0.7,
            z: position.z * scaleSpace + time * scaleTime * 0.9,
            octaves: 3
        )
        let spatialTurbulence = SIMD3<Float>(lowFreqTurbulenceX, 0.0, lowFreqTurbulenceZ) * (activeConfig.baseSpeed * activeConfig.turbulenceIntensity * 0.6)
        
        // 4. Divergence-free Curl Noise (representing swirling vortices)
        let curlScaleSpace = activeConfig.microTurbulenceScale * 0.5
        let curlScaleTime = time * 2.0
        let flowVortex = noise.curlNoise(
            x: position.x * curlScaleSpace,
            y: position.y * curlScaleSpace + curlScaleTime,
            z: position.z * curlScaleSpace
        ) * (activeConfig.baseSpeed * activeConfig.turbulenceIntensity * 0.3)
        
        // 5. Drift of discrete, explicit micro-vortices in XZ space
        let driftVortices = vortexField.force(at: position)
        
        // Composite wind vector
        return baseFlow + gustVector + spatialTurbulence + flowVortex + driftVortices
    }
}

// MARK: - Wind Telemetry Data Logger
/// Records real-time wind speed history and gust statistics for diagnostics and UI overlays.
final class HasanaWindTelemetry {
    static let shared = HasanaWindTelemetry()
    
    var windSpeedHistory: [Float] = Array(repeating: 0.0, count: 60)
    var gustActive: Bool = false
    var gustProgress: Float = 0.0
    var averageSpeed: Float = 0.0
    var turbulenceIndex: Float = 0.0
    
    private init() {}
    
    func record(speed: Float, isGusting: Bool, progress: Float, turbulence: Float) {
        windSpeedHistory.removeFirst()
        windSpeedHistory.append(speed)
        gustActive = isGusting
        gustProgress = progress
        averageSpeed = windSpeedHistory.reduce(0, +) / Float(windSpeedHistory.count)
        turbulenceIndex = turbulence
    }
}

// MARK: - RealityKit Wind Components
/// A RealityKit Component attached to entities to register them in the physical wind simulation loop.
/// Stores static biomechanical parameters and dynamic states (for RK4 integration).
struct WindReceiverComponent: Component, Codable {
    var practiceID: String
    var visualRole: String
    var growthStage: String
    var isDormant: Bool
    
    // Biomechanical properties
    var mass: Float = 1.0             // Inertia factor (kg)
    var stiffness: Float = 35.0        // Resistance to trunk bending (N/m)
    var damping: Float = 2.2           // Torsional damping constant (N*s/m)
    var dragCoefficient: Float = 0.18  // Drag coefficient C_d * Area
    var height: Float = 1.0            // Height of tip from pivot (meters)
    
    // Dynamic RK4 Integrator States (Yaw and Pitch axes)
    // theta[0] -> Pitch (angular tilt around X-axis in radians)
    // theta[1] -> Roll (angular tilt around Z-axis in radians)
    var theta: SIMD2<Float> = .zero
    var omega: SIMD2<Float> = .zero    // Angular velocities (dθ/dt)
    
    // Unique phase offset to randomize individual leaf fluttering and sway start times
    var phaseOffset: Float = 0.0
    var isInitialized: Bool = false
    
    // Caches the original local transforms of all child components to prevent accumulation drift.
    // Maps Entity.id (represented as a String for JSON serialization conformance) to Transform.
    var originalTransforms: [String: Transform] = [:]
    
    init(practiceID: String, visualRole: String, growthStage: String, isDormant: Bool) {
        self.practiceID = practiceID
        self.visualRole = visualRole
        self.growthStage = growthStage
        self.isDormant = isDormant
    }
    
    mutating func cacheTransform(for entityId: UInt64, transform: Transform) {
        let key = String(entityId)
        if originalTransforms[key] == nil {
            originalTransforms[key] = transform
        }
    }
    
    func originalTransform(for entityId: UInt64) -> Transform? {
        return originalTransforms[String(entityId)]
    }
}

// MARK: - RealityKit Wind System (ECS)
/// The RealityKit custom system that updates on every scene frame tick.
/// Automatically queries entities having `WindReceiverComponent` and simulates swaying and fluttering.
@available(iOS 13.0, macOS 10.15, *)
final class HasanaWindSystem: RealityKit.System {
    
    // ECS Entity Query
    private static let windReceiverQuery = EntityQuery(where: .has(WindReceiverComponent.self))
    
    private var lastUpdateTime: CFTimeInterval = 0.0
    
    required init(scene: RealityKit.Scene) {
        // Register entities and load state
        lastUpdateTime = CACurrentMediaTime()
    }
    
    /// Global registration helper. Call this when initiating the RealityKit scene.
    static func register() {
        WindReceiverComponent.registerComponent()
        HasanaWindSystem.registerSystem()
    }
    
    func update(context: RealityKit.SceneUpdateContext) {
        let currentTime = CACurrentMediaTime()
        let dt = Float(context.deltaTime)
        
        // Guard against zero-time frames or extreme lags
        guard dt > 0.0001 else { return }
        
        // 1. Advance the global wind state tracker
        HasanaWindState.shared.update(dt: dt, time: Float(currentTime))
        
        // 2. Query and process each plant entity
        context.scene.performQuery(Self.windReceiverQuery).forEach { entity in
            guard var receiver = entity.components[WindReceiverComponent.self] as? WindReceiverComponent else { return }
            
            // Initialization: Populate structural parameters and cache transforms
            if !receiver.isInitialized {
                initializeReceiver(entity: entity, receiver: &receiver)
            }
            
            // Physics Simulation: Calculate sway angles via RK4 solver
            let worldPos = entity.position(relativeTo: nil)
            let localWind = HasanaWindState.shared.windVector(at: worldPos, time: Float(currentTime))
            
            let (nextTheta, nextOmega) = solveRK4(receiver: receiver, localWind: localWind, dt: dt)
            receiver.theta = nextTheta
            receiver.omega = nextOmega
            
            // Write modified component value back to entity
            entity.components[WindReceiverComponent.self] = receiver
            
            // Render: Recursively apply rotations to children based on classification
            applyRotations(root: entity, receiver: receiver, time: Float(currentTime), localWind: localWind)
        }
        
        lastUpdateTime = currentTime
    }
    
    // MARK: - Setup and Property Initialization
    private func initializeReceiver(entity: Entity, receiver: inout WindReceiverComponent) {
        receiver.phaseOffset = Float.random(in: 0.0...Float.pi * 2.0)
        
        // Parse scale from visual properties
        let scale = modelScale(for: receiver.growthStage)
        
        // Set physical biomechanical properties matching visual roles
        switch receiver.visualRole {
        case "foundationalTree":
            receiver.mass = 4.5 * scale
            receiver.stiffness = 45.0 / scale
            receiver.damping = 3.6
            receiver.dragCoefficient = 0.28 * scale
            receiver.height = 0.56 + scale * 0.46
            
        case "plant":
            receiver.mass = 1.2 * scale
            receiver.stiffness = 28.0 / scale
            receiver.damping = 1.9
            receiver.dragCoefficient = 0.16 * scale
            receiver.height = 0.34 + scale * 0.38
            
        case "flower":
            receiver.mass = 0.7 * scale
            receiver.stiffness = 22.0 / scale
            receiver.damping = 1.4
            receiver.dragCoefficient = 0.12 * scale
            receiver.height = 0.32 + scale * 0.4
            
        default:
            receiver.mass = 1.0
            receiver.stiffness = 30.0
            receiver.damping = 2.0
            receiver.dragCoefficient = 0.15
            receiver.height = 1.0
        }
        
        // Traverse and cache original coordinates of all children recursively
        cacheHierarchy(entity: entity, receiver: &receiver)
        receiver.isInitialized = true
    }
    
    private func cacheHierarchy(entity: Entity, receiver: inout WindReceiverComponent) {
        for child in entity.children {
            // Only animate child parts designed for sway (tagged with "practice:")
            if child.name.hasPrefix("practice:") {
                receiver.cacheTransform(for: child.id, transform: child.transform)
                cacheHierarchy(entity: child, receiver: &receiver)
            }
        }
    }
    
    // MARK: - RK4 Integration Solver
    private func solveRK4(receiver: WindReceiverComponent, localWind: SIMD3<Float>, dt: Float) -> (SIMD2<Float>, SIMD2<Float>) {
        let k = receiver.stiffness
        let c = receiver.damping
        let m = receiver.mass
        let CdA = receiver.dragCoefficient
        let h = receiver.height
        
        let theta = receiver.theta
        let omega = receiver.omega
        
        // Define system torque: T = F_drag * height
        // Relative wind is wind velocity minus tip velocity (omega * height)
        func systemTorque(thetaEst: SIMD2<Float>, omegaEst: SIMD2<Float>) -> SIMD2<Float> {
            let tipVelocity = omegaEst * h
            let horizontalWind = SIMD2<Float>(localWind.x, localWind.z)
            let relativeWind = horizontalWind - tipVelocity
            let speed = simd_length(relativeWind)
            
            // Drag equation: F_d = 0.5 * rho * C_d * A * v^2
            let dragForce = 0.5 * 1.225 * CdA * relativeWind * speed
            
            // Torque acting at the tip pivot
            var torque = dragForce * h
            
            // Structural restoration limits: add geometric nonlinearity to stiffen as bending increases
            let thetaLength = simd_length(thetaEst)
            if thetaLength > 0.01 {
                let limitStiffener = 1.0 + (thetaLength * thetaLength * 8.0)
                torque -= (thetaEst * (k * limitStiffener))
            } else {
                torque -= (thetaEst * k)
            }
            
            return torque
        }
        
        // ODE derivatives: dθ/dt = ω, dω/dt = (Torque - damping * ω) / mass
        func derivatives(thetaVal: SIMD2<Float>, omegaVal: SIMD2<Float>) -> (SIMD2<Float>, SIMD2<Float>) {
            let torque = systemTorque(thetaEst: thetaVal, omegaEst: omegaVal)
            let dTheta = omegaVal
            let dOmega = (torque - c * omegaVal) / m
            return (dTheta, dOmega)
        }
        
        // Cap time step to avoid numerical divergence during heavy lag spikes
        let step = min(dt, 0.033)
        
        // RK4 Coefficients
        let (dTheta1, dOmega1) = derivatives(thetaVal: theta, omegaVal: omega)
        
        let t2 = theta + 0.5 * step * dTheta1
        let w2 = omega + 0.5 * step * dOmega1
        let (dTheta2, dOmega2) = derivatives(thetaVal: t2, omegaVal: w2)
        
        let t3 = theta + 0.5 * step * dTheta2
        let w3 = omega + 0.5 * step * dOmega2
        let (dTheta3, dOmega3) = derivatives(thetaVal: t3, omegaVal: w3)
        
        let t4 = theta + step * dTheta3
        let w4 = omega + step * dOmega3
        let (dTheta4, dOmega4) = derivatives(thetaVal: t4, omegaVal: w4)
        
        // Weighted sum composition
        let nextTheta = theta + (step / 6.0) * (dTheta1 + 2.0 * dTheta2 + 2.0 * dTheta3 + dTheta4)
        let nextOmega = omega + (step / 6.0) * (dOmega1 + 2.0 * dOmega2 + 2.0 * dOmega3 + dOmega4)
        
        return (nextTheta, nextOmega)
    }
    
    // MARK: - Rotation Renderer & Traverse
    private func applyRotations(root: Entity, receiver: WindReceiverComponent, time: Float, localWind: SIMD3<Float>) {
        // Construct the global bend tilt quaternion.
        // Pitch (angular tilt about X-axis) and Roll (angular tilt about Z-axis).
        let pitchQuat = simd_quatf(angle: receiver.theta.x, axis: [1, 0, 0])
        let rollQuat = simd_quatf(angle: receiver.theta.y, axis: [0, 0, 1])
        let globalBend = pitchQuat * rollQuat
        
        // We do not rotate the root itself to prevent the selection halo/checkmark from shifting.
        // Instead, we rotate each child model entity that is part of the plant geometry.
        for child in root.children {
            guard child.name.hasPrefix("practice:") else { continue }
            guard let baseTrans = receiver.originalTransform(for: child.id) else { continue }
            
            let role = classify(entity: child, visualRole: receiver.visualRole)
            var currentTrans = baseTrans
            
            // 1. Position and rotate the element by the primary trunk bending
            // Offset position vector rotated around origin [0,0,0]
            currentTrans.translation = globalBend.act(baseTrans.translation)
            currentTrans.rotation = globalBend * baseTrans.rotation
            
            // 2. Layer role-specific secondary movements
            let windSpeed = simd_length(localWind)
            
            switch role {
            case .trunk:
                // Primary trunk model, only tilts
                break
                
            case .canopy, .branch:
                // Mid-frequency secondary oscillation (flexing relative to stem)
                let flexFreq = 2.2 + receiver.phaseOffset * 0.1
                let flexAmp = 0.08 * (windSpeed / 5.0)
                let fx = sin(time * flexFreq + receiver.phaseOffset) * flexAmp
                let fz = cos(time * flexFreq * 1.1 + receiver.phaseOffset) * flexAmp
                
                let branchRot = simd_quatf(angle: fx, axis: [1, 0, 0]) * simd_quatf(angle: fz, axis: [0, 0, 1])
                currentTrans.rotation = currentTrans.rotation * branchRot
                
            case .leafGroup:
                // Leaves sway in a slightly higher frequency
                let swayFreq = 3.0 + receiver.phaseOffset * 0.2
                let swayAmp = 0.15 * (windSpeed / 5.0)
                let fx = sin(time * swayFreq + receiver.phaseOffset) * swayAmp
                let fz = cos(time * swayFreq * 0.95 + receiver.phaseOffset) * swayAmp
                
                let leafGroupRot = simd_quatf(angle: fx, axis: [1, 0, 0]) * simd_quatf(angle: fz, axis: [0, 0, 1])
                currentTrans.rotation = currentTrans.rotation * leafGroupRot
                
                // Recurse to flutter individual nested leaves
                flutterNestedLeaves(entity: child, receiver: receiver, time: time, windSpeed: windSpeed)
                
            case .flowerCenter:
                // Flower disc wobbles slightly
                let wobble = sin(time * 3.5 + receiver.phaseOffset) * 0.03
                currentTrans.rotation = currentTrans.rotation * simd_quatf(angle: wobble, axis: [0, 1, 0])
                
            case .petal:
                // Flower petals flutter
                let flutter = leafFlutter(time: time, phase: receiver.phaseOffset, speed: windSpeed)
                currentTrans.rotation = currentTrans.rotation * flutter
                
            case .leaf:
                // Standalone leaves
                let flutter = leafFlutter(time: time, phase: receiver.phaseOffset, speed: windSpeed)
                currentTrans.rotation = currentTrans.rotation * flutter
                
            case .unknown:
                break
            }
            
            // Assign calculated transform
            child.transform = currentTrans
        }
    }
    
    private func flutterNestedLeaves(entity: Entity, receiver: WindReceiverComponent, time: Float, windSpeed: Float) {
        for child in entity.children {
            guard child.name.hasPrefix("practice:") else { continue }
            guard let baseTrans = receiver.originalTransform(for: child.id) else { continue }
            
            // Nested leaf gets a unique phase offset based on entity ID to staggered flutter
            let uniquePhase = receiver.phaseOffset + Float(child.id & 127) * 0.05
            let flutter = leafFlutter(time: time, phase: uniquePhase, speed: windSpeed)
            
            var trans = baseTrans
            trans.rotation = baseTrans.rotation * flutter
            child.transform = trans
            
            // Continue recursion
            flutterNestedLeaves(entity: child, receiver: receiver, time: time, windSpeed: windSpeed)
        }
    }
    
    private func leafFlutter(time: Float, phase: Float, speed: Float) -> simd_quatf {
        // High frequency fluttering scales with local wind velocity
        let freq = 13.0 + speed * 7.0
        let amp = 0.03 + min(speed * 0.06, 0.24)
        
        let xAngle = sin(time * freq + phase) * amp
        let yAngle = cos(time * freq * 0.88 + phase + 1.2) * amp * 0.4
        let zAngle = sin(time * freq * 1.12 + phase + 2.4) * amp * 0.25
        
        let rx = simd_quatf(angle: xAngle, axis: [1, 0, 0])
        let ry = simd_quatf(angle: yAngle, axis: [0, 1, 0])
        let rz = simd_quatf(angle: zAngle, axis: [0, 0, 1])
        
        return rx * ry * rz
    }
    
    // MARK: - Classifier Heuristic
    private func classify(entity: Entity, visualRole: String) -> ChildRole {
        let pos = entity.position
        
        switch visualRole {
        case "foundationalTree":
            // Cylinder centered at origin Y = trunkHeight/2
            if abs(pos.x) < 0.001 && abs(pos.z) < 0.001 {
                return .trunk
            } else {
                // Heuristic: Spherical canopy sits higher up
                if pos.y > 0.6 {
                    return .canopy
                } else {
                    return .branch
                }
            }
            
        case "plant":
            if abs(pos.x) < 0.001 && abs(pos.z) < 0.001 {
                return .trunk // Stem
            } else {
                return .leafGroup // Leaves are grouped
            }
            
        case "flower":
            if abs(pos.x) < 0.001 && abs(pos.z) < 0.001 {
                if pos.y > 0.25 {
                    return .flowerCenter
                } else {
                    return .trunk // Stem
                }
            } else {
                return .petal
            }
            
        default:
            return .unknown
        }
    }
    
    // MARK: - Geometry Constants Helpers
    private func modelScale(for growthStage: String) -> Float {
        switch growthStage {
        case "seed": return 0.24
        case "sprout": return 0.42
        case "young": return 0.62
        case "mature": return 0.84
        case "flowering": return 1.0
        default: return 1.0
        }
    }
}

// MARK: - Classifier Roles enum
private enum ChildRole {
    case trunk
    case branch
    case canopy
    case leaf
    case leafGroup
    case flowerCenter
    case petal
    case unknown
}

// MARK: - SwiftUI Wind System Bridge Manager
/// Managed bridge communicating between the iOS RealityKit scene loop and SwiftUI.
/// Declared as `@Observable` for direct, high-performance bindings in iOS 17+.
@MainActor
@Observable
final class HasanaGardenWindManager {
    static let shared = HasanaGardenWindManager()
    
    var currentProfile: HasanaWindProfile = .gentleBreeze {
        didSet {
            HasanaWindState.shared.setProfile(currentProfile)
        }
    }
    
    var customBaseSpeed: Float = 1.5 {
        didSet {
            HasanaWindState.shared.customConfig.baseSpeed = customBaseSpeed
            HasanaWindState.shared.useCustomConfig = true
        }
    }
    
    var customBaseDirectionYaw: Float = 0.0 { // Angle in radians
        didSet {
            let x = cos(customBaseDirectionYaw)
            let z = sin(customBaseDirectionYaw)
            HasanaWindState.shared.customConfig.baseDirection = SIMD3<Float>(x, 0.0, z).safeNormalized
            HasanaWindState.shared.useCustomConfig = true
        }
    }
    
    var customTurbulenceIntensity: Float = 0.35 {
        didSet {
            HasanaWindState.shared.customConfig.turbulenceIntensity = customTurbulenceIntensity
            HasanaWindState.shared.useCustomConfig = true
        }
    }
    
    var customGustAmplitude: Float = 1.2 {
        didSet {
            HasanaWindState.shared.customConfig.gustAmplitude = customGustAmplitude
            HasanaWindState.shared.useCustomConfig = true
        }
    }
    
    var customDampingFactor: Float = 0.9 {
        didSet {
            HasanaWindState.shared.customConfig.dampingFactor = customDampingFactor
            HasanaWindState.shared.useCustomConfig = true
        }
    }
    
    var isWindEnabled: Bool = true {
        didSet {
            HasanaWindState.shared.isEnabled = isWindEnabled
        }
    }
    
    // Telemetry bindings
    var averageSpeed: Float {
        return HasanaWindTelemetry.shared.averageSpeed
    }
    
    var gustActive: Bool {
        return HasanaWindTelemetry.shared.gustActive
    }
    
    var gustProgress: Float {
        return HasanaWindTelemetry.shared.gustProgress
    }
    
    var turbulenceIndex: Float {
        return HasanaWindTelemetry.shared.turbulenceIndex
    }
    
    var activeVorticesCount: Int {
        return HasanaWindState.shared.vortexField.vortices.count
    }
    
    var speedHistory: [Float] {
        return HasanaWindTelemetry.shared.windSpeedHistory
    }
    
    init() {
        HasanaWindState.shared.setProfile(currentProfile)
    }
    
    func triggerGust() {
        HasanaWindState.shared.triggerManualGust()
    }
    
    func applyProfile(_ profile: HasanaWindProfile) {
        currentProfile = profile
    }
    
    /// Spawns a mini-vortex particle that moves across the garden and perturbs plants locally.
    func spawnMicroVortex() {
        let center = SIMD3<Float>(
            Float.random(in: -2.8...2.8),
            0.0,
            Float.random(in: -1.8...1.8)
        )
        
        let targetSpeedX = Float.random(in: -0.8...0.8)
        let targetSpeedZ = Float.random(in: -0.8...0.8)
        
        let vortex = WindVortex(
            center: center,
            radius: Float.random(in: 0.8...1.6),
            strength: Float.random(in: 2.2...4.5),
            rotationSpeed: Float.random(in: 3.0...8.0),
            lifetime: Float.random(in: 4.0...7.5),
            velocity: SIMD3<Float>(targetSpeedX, 0.0, targetSpeedZ)
        )
        
        HasanaWindState.shared.vortexField.addVortex(vortex)
    }
    
    func clearVortices() {
        HasanaWindState.shared.vortexField.clearAll()
    }
}
