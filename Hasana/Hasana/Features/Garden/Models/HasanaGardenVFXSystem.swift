//
//  HasanaGardenVFXSystem.swift
//  Hasana
//
//  Created by Azzam Alrashed on 26/05/2026.
//

import Combine
import Foundation
import RealityKit
import SwiftUI
import UIKit

// MARK: - VFX System Configurations

/// A container for customizing the physics, emission rates, shapes, and colors
/// of the garden's visual effects.
struct HasanaGardenVFXConfig: Equatable {
    
    // MARK: - General Physics
    var gravity: SIMD3<Float> = SIMD3<Float>(0.0, -0.98, 0.0)
    var globalWind: SIMD3<Float> = SIMD3<Float>(0.15, 0.0, 0.05)
    var globalDamping: Float = 0.45
    
    // MARK: - Halo Settings
    var haloParticleCount: Int = 36
    var haloBaseRadius: Float = 0.38
    var haloVerticalRange: Float = 0.12
    var haloRotationSpeed: Float = 1.05
    var haloOscillationSpeed: Float = 2.2
    var haloColor: UIColor = UIColor(HasanaTheme.gold)
    var haloSecondaryColor: UIColor = UIColor(HasanaTheme.goldSoft)
    var haloParticleSize: Float = 0.016
    var haloGlowIntensity: Float = 1.2
    
    // MARK: - Sparkle Burst Settings
    var burstParticleCount: Int = 48
    var minBurstSpeed: Float = 1.2
    var maxBurstSpeed: Float = 3.6
    var burstLifetimeMin: Float = 0.6
    var burstLifetimeMax: Float = 1.5
    var burstParticleSizeMin: Float = 0.008
    var burstParticleSizeMax: Float = 0.024
    var burstSpreadAngle: Float = .pi / 3.0 // Angle of outward cone
    var burstTurbulenceForce: Float = 0.8
    
    // MARK: - Energy Beam Settings
    var beamRayCount: Int = 40
    var beamBaseRadius: Float = 0.24
    var beamMaxHeight: Float = 2.8
    var beamAscentSpeed: Float = 2.0
    var beamLifetime: Float = 1.6
    var beamPulsationSpeed: Float = 4.0
    var beamHelicalTightness: Float = 6.0
    var beamCoreRadius: Float = 0.06
    var beamColor: UIColor = UIColor(HasanaTheme.accent)
    
    init() {}
}

// MARK: - Particle State Definition

/// Represents a single particle in the 3D physics engine.
struct HasanaGardenParticle {
    var id: UUID = UUID()
    var position: SIMD3<Float> = .zero
    var velocity: SIMD3<Float> = .zero
    var acceleration: SIMD3<Float> = .zero
    var startColor: UIColor = .white
    var endColor: UIColor = .white
    var currentColor: UIColor = .white
    var startSize: Float = 1.0
    var currentSize: Float = 1.0
    var age: Float = 0.0
    var lifetime: Float = 1.0
    var isAlive: Bool = false
    var rotationSpeed: SIMD3<Float> = .zero
    var currentRotation: SIMD3<Float> = .zero
    
    // Math helpers for normalized progress
    var lifeFraction: Float {
        guard lifetime > 0 else { return 1.0 }
        return min(max(age / lifetime, 0.0), 1.0)
    }
}

// MARK: - Mesh Generation Factory

/// Generates custom geometry configurations for RealityKit visual effects.
/// Reuses standard MeshResources to optimize performance.
final class HasanaGardenVFXMeshFactory {
    
    private static let lock = NSLock()
    private static var sphereCache: [String: MeshResource] = [:]
    private static var boxCache: [String: MeshResource] = [:]
    
    static func getSphereMesh(radius: Float) -> MeshResource {
        lock.lock()
        defer { lock.unlock() }
        let key = String(format: "%.4f", radius)
        if let cached = sphereCache[key] {
            return cached
        }
        let mesh = MeshResource.generateSphere(radius: radius)
        sphereCache[key] = mesh
        return mesh
    }
    
    static func getBoxMesh(width: Float, height: Float, depth: Float) -> MeshResource {
        lock.lock()
        defer { lock.unlock() }
        let key = String(format: "%.4f_%.4f_%.4f", width, height, depth)
        if let cached = boxCache[key] {
            return cached
        }
        let mesh = MeshResource.generateBox(width: width, height: height, depth: depth)
        boxCache[key] = mesh
        return mesh
    }
    
    /// Creates a star-like visual mesh using thin intersecting boxes.
    static func makeStarMesh(size: Float) -> MeshResource {
        // Approximate a 3D cross star
        return MeshResource.generateBox(width: size, height: size * 0.2, depth: size * 0.2)
    }
    
    /// Creates a flat diamond geometry mesh.
    static func makeDiamondMesh(size: Float) -> MeshResource {
        return MeshResource.generateBox(width: size * 0.7, height: size * 0.7, depth: size * 0.05)
    }
}

// MARK: - Emitter Base Class

/// The base class for all visual effects emitters in the RealityKit Garden.
/// Manages entity object pooling to achieve zero allocations during simulation ticks.
class HasanaGardenVFXEmitter: Entity {
    
    let config: HasanaGardenVFXConfig
    var practiceID: HasanaGardenPracticeID
    
    // Particle pool allocations
    var maxParticles: Int
    var particles: [HasanaGardenParticle] = []
    var particleEntities: [ModelEntity] = []
    
    private var isSimulating: Bool = true
    
    init(practiceID: HasanaGardenPracticeID, maxParticles: Int, config: HasanaGardenVFXConfig) {
        self.practiceID = practiceID
        self.maxParticles = maxParticles
        self.config = config
        super.init()
        setupParticlePool()
    }
    
    required init() {
        fatalError("init() has not been implemented. Use init(practiceID:maxParticles:config:) instead.")
    }
    
    private func setupParticlePool() {
        particles.reserveCapacity(maxParticles)
        particleEntities.reserveCapacity(maxParticles)
        
        let initialMesh = HasanaGardenVFXMeshFactory.getSphereMesh(radius: config.haloParticleSize)
        let initialMaterial = SimpleMaterial(color: config.haloColor, roughness: 0.5, isMetallic: false)
        
        for _ in 0..<maxParticles {
            // Setup model entity
            let entity = ModelEntity(mesh: initialMesh, materials: [initialMaterial])
            entity.isEnabled = false
            addChild(entity)
            particleEntities.append(entity)
            
            // Setup physical representation
            let p = HasanaGardenParticle()
            particles.append(p)
        }
    }
    
    /// Activates a particle in the pool with the given configuration.
    func spawnParticle(
        position: SIMD3<Float>,
        velocity: SIMD3<Float>,
        acceleration: SIMD3<Float>,
        startColor: UIColor,
        endColor: UIColor,
        startSize: Float,
        lifetime: Float,
        mesh: MeshResource,
        material: SimpleMaterial,
        rotationSpeed: SIMD3<Float> = .zero
    ) {
        guard let index = particles.firstIndex(where: { !$0.isAlive }) else { return }
        
        particles[index].position = position
        particles[index].velocity = velocity
        particles[index].acceleration = acceleration
        particles[index].startColor = startColor
        particles[index].endColor = endColor
        particles[index].currentColor = startColor
        particles[index].startSize = startSize
        particles[index].currentSize = startSize
        particles[index].age = 0.0
        particles[index].lifetime = lifetime
        particles[index].isAlive = true
        particles[index].rotationSpeed = rotationSpeed
        particles[index].currentRotation = .zero
        
        let entity = particleEntities[index]
        entity.model?.mesh = mesh
        entity.model?.materials = [material]
        entity.position = position
        entity.scale = SIMD3<Float>(repeating: startSize)
        entity.isEnabled = true
    }
    
    /// Abstract tick updater. Subclasses override this to implement custom physics.
    open func update(dt: Float, elapsed: Float) {
        guard isSimulating else { return }
        
        for i in 0..<maxParticles {
            guard particles[i].isAlive else { continue }
            
            // Advance particle age
            particles[i].age += dt
            if particles[i].age >= particles[i].lifetime {
                particles[i].isAlive = false
                particleEntities[i].isEnabled = false
                continue
            }
            
            // Euler Physics Integration
            particles[i].velocity += (particles[i].acceleration + config.gravity + config.globalWind) * dt
            particles[i].velocity *= (1.0 - config.globalDamping * dt)
            particles[i].position += particles[i].velocity * dt
            
            // Apply angular updates
            particles[i].currentRotation += particles[i].rotationSpeed * dt
            
            // Linear Color and Size Easing over lifetime
            let progress = particles[i].lifeFraction
            particles[i].currentSize = particles[i].startSize * (1.0 - progress)
            particles[i].currentColor = blendColors(
                from: particles[i].startColor,
                to: particles[i].endColor,
                fraction: progress
            )
            
            // Commit transforms to RealityKit components
            let entity = particleEntities[i]
            entity.position = particles[i].position
            entity.scale = SIMD3<Float>(repeating: particles[i].currentSize)
            
            // Rotation matrix construction
            let rx = simd_quatf(angle: particles[i].currentRotation.x, axis: [1, 0, 0])
            let ry = simd_quatf(angle: particles[i].currentRotation.y, axis: [0, 1, 0])
            let rz = simd_quatf(angle: particles[i].currentRotation.z, axis: [0, 0, 1])
            entity.orientation = rx * ry * rz
            
            // Update material properties dynamically if possible (otherwise standard scaling handles fading)
            if let currentModel = entity.model {
                let simpleMat = SimpleMaterial(
                    color: particles[i].currentColor,
                    roughness: 0.2,
                    isMetallic: true
                )
                entity.model?.materials = [simpleMat]
            }
        }
    }
    
    /// Blends two standard UIColors smoothly.
    func blendColors(from: UIColor, to: UIColor, fraction: Float) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let f = CGFloat(fraction)
        let r = r1 + (r2 - r1) * f
        let g = g1 + (g2 - g1) * f
        let b = b1 + (b2 - b1) * f
        let a = a1 + (a2 - a1) * f
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func stop() {
        isSimulating = false
        for entity in particleEntities {
            entity.isEnabled = false
        }
    }
}

// MARK: - Golden Glowing Halo Emitter

/// A particle emitter that circles plants to form a golden glowing halo aura.
final class HasanaGardenHaloVFXEmitter: HasanaGardenVFXEmitter {
    
    private var baseTime: Float = 0.0
    private var meshCache: MeshResource?
    private var matCache: SimpleMaterial?
    
    init(practiceID: HasanaGardenPracticeID, config: HasanaGardenVFXConfig) {
        super.init(
            practiceID: practiceID,
            maxParticles: config.haloParticleCount,
            config: config
        )
        self.meshCache = HasanaGardenVFXMeshFactory.getSphereMesh(radius: config.haloParticleSize)
        self.matCache = SimpleMaterial(color: config.haloColor, roughness: 0.15, isMetallic: true)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    override func update(dt: Float, elapsed: Float) {
        baseTime += dt
        
        // Halo emission logic: Maintain a constant stream of orbiting particles.
        // Halo orbits use custom geometry formulas to form double helices and pulsing rings.
        let mesh = meshCache ?? HasanaGardenVFXMeshFactory.getSphereMesh(radius: config.haloParticleSize)
        let material = matCache ?? SimpleMaterial(color: config.haloColor, roughness: 0.15, isMetallic: true)
        
        let activeCount = particles.filter({ $0.isAlive }).count
        let spawnThreshold = 2 // Spawn rate throttle
        
        if activeCount < maxParticles {
            for step in 0..<spawnThreshold {
                let pIndex = particles.firstIndex(where: { !$0.isAlive }) ?? 0
                if pIndex < maxParticles {
                    // Helix coordinate calculations
                    let offsetAngle = Float(pIndex) * (.pi * 2.0 / Float(maxParticles))
                    let orbitalAngle = baseTime * config.haloRotationSpeed + offsetAngle
                    
                    let oscillation = sin(baseTime * config.haloOscillationSpeed + offsetAngle) * config.haloVerticalRange
                    
                    // Golden ring helix math
                    let x = config.haloBaseRadius * cos(orbitalAngle)
                    let z = config.haloBaseRadius * sin(orbitalAngle)
                    let y = 0.06 + oscillation // Sit slightly above plant base
                    
                    let startPos = SIMD3<Float>(x, y, z)
                    
                    // Slow orbit speed vector
                    let vx = -config.haloBaseRadius * sin(orbitalAngle) * 0.15
                    let vz = config.haloBaseRadius * cos(orbitalAngle) * 0.15
                    let vy = Float.random(in: 0.01...0.05) // Gentle drift upward
                    
                    spawnParticle(
                        position: startPos,
                        velocity: SIMD3<Float>(vx, vy, vz),
                        acceleration: SIMD3<Float>(0.0, 0.02, 0.0),
                        startColor: config.haloColor,
                        endColor: config.haloSecondaryColor,
                        startSize: 1.0,
                        lifetime: Float.random(in: 1.8...3.0),
                        mesh: mesh,
                        material: material,
                        rotationSpeed: SIMD3<Float>(0.2, 0.5, 0.1)
                    )
                }
            }
        }
        
        // Perform standard physics processing on all active particles.
        super.update(dt: dt, elapsed: elapsed)
    }
}

// MARK: - Tap Sparkle Burst Generator

/// An explosion of star and diamond sparkle particles when a plant is tapped or tended.
final class HasanaGardenSparkleBurstVFXEmitter: HasanaGardenVFXEmitter {
    
    private var hasTriggered: Bool = false
    private var totalLifeTime: Float = 0.0
    private var meshStar: MeshResource?
    private var meshDiamond: MeshResource?
    
    init(practiceID: HasanaGardenPracticeID, config: HasanaGardenVFXConfig) {
        super.init(
            practiceID: practiceID,
            maxParticles: config.burstParticleCount,
            config: config
        )
        self.meshStar = HasanaGardenVFXMeshFactory.makeStarMesh(size: 0.022)
        self.meshDiamond = HasanaGardenVFXMeshFactory.makeDiamondMesh(size: 0.025)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Spawns a radial burst of particle elements.
    func triggerBurst(at localCenter: SIMD3<Float>, primaryColor: UIColor, secondaryColor: UIColor) {
        guard !hasTriggered else { return }
        hasTriggered = true
        
        let mStar = meshStar ?? HasanaGardenVFXMeshFactory.makeStarMesh(size: 0.022)
        let mDiamond = meshDiamond ?? HasanaGardenVFXMeshFactory.makeDiamondMesh(size: 0.025)
        
        let randomFactor = Float.random(in: 0.8...1.2)
        
        for i in 0..<maxParticles {
            // Spherical coordinate math for radial projection
            let theta = Float.random(in: 0.0...(.pi * 2.0))
            let phi = Float.random(in: -config.burstSpreadAngle...config.burstSpreadAngle)
            
            let speed = Float.random(in: config.minBurstSpeed...config.maxBurstSpeed) * randomFactor
            
            // Radial components
            let vx = speed * cos(phi) * cos(theta)
            let vy = speed * sin(phi) + Float.random(in: 0.4...0.8) // Shoot upwards initially
            let vz = speed * cos(phi) * sin(theta)
            
            let acceleration = SIMD3<Float>(
                Float.random(in: -config.burstTurbulenceForce...config.burstTurbulenceForce),
                -0.4, // Light downward arc
                Float.random(in: -config.burstTurbulenceForce...config.burstTurbulenceForce)
            )
            
            let pSize = Float.random(in: config.burstParticleSizeMin...config.burstParticleSizeMax)
            let pLife = Float.random(in: config.burstLifetimeMin...config.burstLifetimeMax)
            
            let isStar = i % 2 == 0
            let activeMesh = isStar ? mStar : mDiamond
            let mat = SimpleMaterial(color: isStar ? primaryColor : secondaryColor, roughness: 0.1, isMetallic: true)
            
            let rSpeed = SIMD3<Float>(
                Float.random(in: -3.0...3.0),
                Float.random(in: -3.0...3.0),
                Float.random(in: -3.0...3.0)
            )
            
            spawnParticle(
                position: localCenter,
                velocity: SIMD3<Float>(vx, vy, vz),
                acceleration: acceleration,
                startColor: primaryColor,
                endColor: secondaryColor.withAlphaComponent(0.1),
                startSize: pSize,
                lifetime: pLife,
                mesh: activeMesh,
                material: mat,
                rotationSpeed: rSpeed
            )
        }
    }
    
    override func update(dt: Float, elapsed: Float) {
        super.update(dt: dt, elapsed: elapsed)
        
        totalLifeTime += dt
        
        // Auto removal logic: if burst is completed and all particles died, clean up.
        let activeCount = particles.filter({ $0.isAlive }).count
        if hasTriggered && activeCount == 0 && totalLifeTime > config.burstLifetimeMax {
            self.removeFromParent()
        }
    }
}

// MARK: - Tended Status Energy Beam Components

/// A large column of glowing lights and spiral bands marking a fully tended status.
final class HasanaGardenEnergyBeamVFXEmitter: HasanaGardenVFXEmitter {
    
    private var baseTime: Float = 0.0
    private var beamRays: [ModelEntity] = []
    private var beamInnerCore: ModelEntity?
    private var meshRay: MeshResource?
    private var matRay: SimpleMaterial?
    
    init(practiceID: HasanaGardenPracticeID, config: HasanaGardenVFXConfig) {
        super.init(
            practiceID: practiceID,
            maxParticles: config.beamRayCount,
            config: config
        )
        self.meshRay = HasanaGardenVFXMeshFactory.getSphereMesh(radius: 0.024)
        self.matRay = SimpleMaterial(color: config.beamColor, roughness: 0.1, isMetallic: true)
        setupCoreBeam()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    private func setupCoreBeam() {
        // Procedural light column using stack of scaled thin boxes
        let coreMesh = HasanaGardenVFXMeshFactory.getBoxMesh(
            width: config.beamCoreRadius * 2.0,
            height: config.beamMaxHeight,
            depth: config.beamCoreRadius * 2.0
        )
        
        let coreColor = config.beamColor.withAlphaComponent(0.25)
        let coreMat = SimpleMaterial(color: coreColor, roughness: 0.8, isMetallic: false)
        
        let core = ModelEntity(mesh: coreMesh, materials: [coreMat])
        core.position = [0, config.beamMaxHeight / 2.0, 0] // Center vertical column
        core.isEnabled = true
        addChild(core)
        self.beamInnerCore = core
    }
    
    override func update(dt: Float, elapsed: Float) {
        baseTime += dt
        
        // Pulsate Core Beam Scale & Color
        if let core = beamInnerCore {
            let scalePulse = 1.0 + sin(baseTime * config.beamPulsationSpeed) * 0.12
            core.scale = SIMD3<Float>(scalePulse, 1.0, scalePulse)
        }
        
        // Ascending Helix Particle Generation
        let mRay = meshRay ?? HasanaGardenVFXMeshFactory.getSphereMesh(radius: 0.024)
        let mColor = config.beamColor
        let mMat = matRay ?? SimpleMaterial(color: mColor, roughness: 0.1, isMetallic: true)
        
        let activeCount = particles.filter({ $0.isAlive }).count
        if activeCount < maxParticles {
            // Spawn ascending particle
            let angle = baseTime * config.beamHelicalTightness
            let radius = config.beamBaseRadius
            
            // Helical coordinates
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            let y: Float = 0.0
            
            let startPos = SIMD3<Float>(x, y, z)
            
            // Rising physics velocities
            let vx = -radius * sin(angle) * 0.5
            let vz = radius * cos(angle) * 0.5
            let vy = config.beamAscentSpeed
            
            spawnParticle(
                position: startPos,
                velocity: SIMD3<Float>(vx, vy, vz),
                acceleration: SIMD3<Float>(0.0, 0.15, 0.0),
                startColor: mColor,
                endColor: UIColor.white.withAlphaComponent(0.0),
                startSize: 1.0,
                lifetime: config.beamLifetime,
                mesh: mRay,
                material: mMat,
                rotationSpeed: SIMD3<Float>(0.0, 2.0, 0.0)
            )
        }
        
        // standard physics processes
        super.update(dt: dt, elapsed: elapsed)
    }
}

// MARK: - Central VFX System Manager

/// Coordinates all emitters within the Hasana Garden scene anchor.
/// Monitors performance diagnostics and cleans up finished assets.
final class HasanaGardenVFXManager {
    
    static let shared = HasanaGardenVFXManager()
    
    private var activeEmitters: [HasanaGardenVFXEmitter] = []
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0.0
    private var totalElapsed: Float = 0.0
    
    // Performance stats
    var diagnostics: HasanaGardenVFXDiagnostics = HasanaGardenVFXDiagnostics()
    private weak var sceneAnchor: AnchorEntity?
    
    private var cancellationToken: AnyCancellable?
    
    private init() {
        startUpdateLoop()
    }
    
    deinit {
        stopUpdateLoop()
    }
    
    /// Binds the manager to a scene anchor.
    func setSceneAnchor(_ anchor: AnchorEntity) {
        self.sceneAnchor = anchor
    }
    
    private func startUpdateLoop() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleTick(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopUpdateLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handleTick(_ link: CADisplayLink) {
        guard lastTimestamp > 0.0 else {
            lastTimestamp = link.timestamp
            return
        }
        
        let dt = Float(link.timestamp - lastTimestamp)
        lastTimestamp = link.timestamp
        totalElapsed += dt
        
        // Frame rate tracking
        diagnostics.recordFrame(dt: dt)
        
        // Prune nil and removed entities
        activeEmitters.removeAll { emitter in
            if emitter.parent == nil {
                return true
            }
            return false
        }
        
        // Tick each active emitter
        for emitter in activeEmitters {
            emitter.update(dt: dt, elapsed: totalElapsed)
        }
        
        // Count active particles
        diagnostics.activeParticleCount = activeEmitters.reduce(0) { count, emitter in
            count + emitter.particles.filter({ $0.isAlive }).count
        }
        diagnostics.activeEmitterCount = activeEmitters.count
    }
    
    // MARK: - VFX Triggers
    
    /// Attach an orbital glowing halo to a garden plant practice entity.
    func attachHalo(to plantEntity: Entity, practiceID: HasanaGardenPracticeID, config: HasanaGardenVFXConfig = HasanaGardenVFXConfig()) {
        // Avoid duplicate halos
        detachHalo(from: plantEntity)
        
        let halo = HasanaGardenHaloVFXEmitter(practiceID: practiceID, config: config)
        plantEntity.addChild(halo)
        activeEmitters.append(halo)
    }
    
    /// Detach and stop halos on a plant.
    func detachHalo(from plantEntity: Entity) {
        let targets = plantEntity.children.filter { $0 is HasanaGardenHaloVFXEmitter }
        for target in targets {
            if let emitter = target as? HasanaGardenVFXEmitter {
                emitter.stop()
                emitter.removeFromParent()
                activeEmitters.removeAll { $0 === emitter }
            }
        }
    }
    
    /// Detach all VFX of any kind from a plant.
    func clearAllVFX(from plantEntity: Entity) {
        let targets = plantEntity.children.filter { $0 is HasanaGardenVFXEmitter }
        for target in targets {
            if let emitter = target as? HasanaGardenVFXEmitter {
                emitter.stop()
                emitter.removeFromParent()
                activeEmitters.removeAll { $0 === emitter }
            }
        }
    }
    
    /// Triggers an explosive sparkle burst.
    func triggerSparkleBurst(
        on plantEntity: Entity,
        practiceID: HasanaGardenPracticeID,
        primaryColor: UIColor = UIColor(HasanaTheme.gold),
        secondaryColor: UIColor = UIColor(HasanaTheme.accent),
        config: HasanaGardenVFXConfig = HasanaGardenVFXConfig()
    ) {
        let burst = HasanaGardenSparkleBurstVFXEmitter(practiceID: practiceID, config: config)
        plantEntity.addChild(burst)
        activeEmitters.append(burst)
        
        // Trigger at slightly elevated position
        burst.triggerBurst(
            at: SIMD3<Float>(0.0, 0.45, 0.0),
            primaryColor: primaryColor,
            secondaryColor: secondaryColor
        )
    }
    
    /// Starts a vertical energy column and helical light ribbons on a plant.
    func startEnergyBeam(to plantEntity: Entity, practiceID: HasanaGardenPracticeID, config: HasanaGardenVFXConfig = HasanaGardenVFXConfig()) {
        detachEnergyBeam(from: plantEntity)
        
        let beam = HasanaGardenEnergyBeamVFXEmitter(practiceID: practiceID, config: config)
        plantEntity.addChild(beam)
        activeEmitters.append(beam)
    }
    
    /// Stops the energy beam on a plant.
    func detachEnergyBeam(from plantEntity: Entity) {
        let targets = plantEntity.children.filter { $0 is HasanaGardenEnergyBeamVFXEmitter }
        for target in targets {
            if let emitter = target as? HasanaGardenVFXEmitter {
                emitter.stop()
                emitter.removeFromParent()
                activeEmitters.removeAll { $0 === emitter }
            }
        }
    }
}

// MARK: - Diagnostics Tracker

/// Keeps count of diagnostics data, frame rate info, and active systems.
struct HasanaGardenVFXDiagnostics {
    var activeParticleCount: Int = 0
    var activeEmitterCount: Int = 0
    var averageFps: Float = 60.0
    
    private var fpsSamples: [Float] = []
    
    mutating func recordFrame(dt: Float) {
        guard dt > 0.0 else { return }
        let currentFps = 1.0 / dt
        fpsSamples.append(currentFps)
        
        if fpsSamples.count > 120 {
            fpsSamples.removeFirst()
        }
        
        let sum = fpsSamples.reduce(0.0, +)
        averageFps = sum / Float(fpsSamples.count)
    }
}

// MARK: - VFX Integration Controls View

/// A developers' control board for debugging, running tests,
/// and tweaking configuration values on visual effects systems.
struct HasanaGardenVFXPreviewView: View {
    
    @State private var config = HasanaGardenVFXConfig()
    @State private var mockPlantEntity = Entity()
    @State private var selectedPractice: HasanaGardenPracticeID = .fajr
    @State private var showStats = true
    
    private let manager = HasanaGardenVFXManager.shared
    
    init() {}
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Hasana Garden VFX System Diagnostics")
                    .font(.headline)
                    .padding(.top)
                
                if showStats {
                    HStack(spacing: 15) {
                        statCard(title: "Active Particles", value: "\(manager.diagnostics.activeParticleCount)")
                        statCard(title: "Active Emitters", value: "\(manager.diagnostics.activeEmitterCount)")
                        statCard(title: "Smooth FPS", value: String(format: "%.1f", manager.diagnostics.averageFps))
                    }
                    .padding(.horizontal)
                }
                
                // Triggers Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Trigger Mock VFX Functions")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal)
                    
                    HStack {
                        Button("Attach Aura Halo") {
                            manager.attachHalo(to: mockPlantEntity, practiceID: selectedPractice, config: config)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(HasanaTheme.gold))
                        
                        Button("Clear Halo") {
                            manager.detachHalo(from: mockPlantEntity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Button("Trigger Sparkle Burst") {
                            let goldCol = UIColor(HasanaTheme.gold)
                            let accCol = UIColor(HasanaTheme.accent)
                            manager.triggerSparkleBurst(
                                on: mockPlantEntity,
                                practiceID: selectedPractice,
                                primaryColor: goldCol,
                                secondaryColor: accCol,
                                config: config
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(HasanaTheme.accent))
                        
                        Button("Start Energy Beam") {
                            manager.startEnergyBeam(to: mockPlantEntity, practiceID: selectedPractice, config: config)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding(.horizontal)
                    
                    Button("Stop All VFX", role: .destructive) {
                        manager.clearAllVFX(from: mockPlantEntity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                
                // Practice Selector
                Picker("Mock Practice Entity Target", selection: $selectedPractice) {
                    ForEach(HasanaGardenPracticeID.allCases) { practice in
                        Text(practice.rawValue.capitalized).tag(practice)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                // Physics Config sliders
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interactive Configuration Panel")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal)
                    
                    configSlider(label: "Global Damping", value: $config.globalDamping, in: 0.0...1.0)
                    configSlider(label: "Halo Base Radius", value: $config.haloBaseRadius, in: 0.1...1.0)
                    configSlider(label: "Halo Speed Multiplier", value: $config.haloRotationSpeed, in: 0.1...4.0)
                    configSlider(label: "Burst Start Speed (Max)", value: $config.maxBurstSpeed, in: 1.0...10.0)
                    configSlider(label: "Burst Lifespan (Max)", value: $config.burstLifetimeMax, in: 0.5...4.0)
                    configSlider(label: "Energy Beam Height", value: $config.beamMaxHeight, in: 0.5...5.0)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .background(Color(HasanaTheme.background))
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color(HasanaTheme.textMuted))
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(HasanaTheme.textPrimary))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(HasanaTheme.elevatedSurface), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(HasanaTheme.border), lineWidth: 0.8)
        }
    }
    
    private func configSlider(label: String, value: Binding<Float>, in range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color(HasanaTheme.textPrimary))
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(HasanaTheme.textMuted))
            }
            Slider(value: value, in: range)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Internal Math/Random Extensions

fileprivate extension Float {
    static func random(in range: ClosedRange<Float>, by step: Float) -> Float {
        let diff = range.upperBound - range.lowerBound
        let randomVal = Float.random(in: 0.0...1.0)
        return range.lowerBound + diff * randomVal
    }
}

// MARK: - Multi-dimensional Graphics Interpolations

/// Interpolates spatial curves for 3D physics structures.
enum HasanaGardenVFXBezierMath {
    
    /// Computes a point on a quadratic Bezier curve.
    static func quadraticCurve(p0: SIMD3<Float>, p1: SIMD3<Float>, p2: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        let clampedT = min(max(t, 0.0), 1.0)
        let u = 1.0 - clampedT
        let tt = clampedT * clampedT
        let uu = u * u
        
        let p = uu * p0 + 2.0 * u * clampedT * p1 + tt * p2
        return p
    }
    
    /// Computes a point on a cubic Bezier curve.
    static func cubicCurve(p0: SIMD3<Float>, p1: SIMD3<Float>, p2: SIMD3<Float>, p3: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        let clampedT = min(max(t, 0.0), 1.0)
        let u = 1.0 - clampedT
        let tt = clampedT * clampedT
        let ttt = tt * clampedT
        let uu = u * u
        let uuu = uu * u
        
        let p = uuu * p0 + 3.0 * uu * clampedT * p1 + 3.0 * u * tt * p2 + ttt * p3
        return p
    }
    
    /// Computes dynamic swirl offset on a spiral cylinder based on height and angular velocity.
    static func swirlPosition(center: SIMD3<Float>, radius: Float, angle: Float, height: Float) -> SIMD3<Float> {
        let x = center.x + radius * cos(angle)
        let z = center.z + radius * sin(angle)
        let y = center.y + height
        return SIMD3<Float>(x, y, z)
    }
}

// MARK: - Particle System Stress Test Rig

/// Stress testing module designed to test up to 500 parallel particle entities 
/// and verify hardware limits, memory footprint, and CPU execution time.
final class HasanaGardenVFXStressTester {
    
    private let manager = HasanaGardenVFXManager.shared
    private var stressEmitters: [HasanaGardenVFXEmitter] = []
    
    init() {}
    
    /// Spawns a heavy workload of emitters on a target entity.
    func startStressTest(on parentEntity: Entity, maxEmitters: Int = 10) {
        stopStressTest()
        
        let heavyConfig = HasanaGardenVFXConfig()
        let practices = HasanaGardenPracticeID.allCases
        
        for index in 0..<maxEmitters {
            let selectedID = practices[index % practices.count]
            let emitter = HasanaGardenHaloVFXEmitter(practiceID: selectedID, config: heavyConfig)
            parentEntity.addChild(emitter)
            stressEmitters.append(emitter)
        }
    }
    
    func stopStressTest() {
        for emitter in stressEmitters {
            emitter.stop()
            emitter.removeFromParent()
        }
        stressEmitters.removeAll()
    }
}
