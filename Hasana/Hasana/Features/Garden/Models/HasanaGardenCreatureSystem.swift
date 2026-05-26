//
//  HasanaGardenCreatureSystem.swift
//  Hasana
//
//  Created by Azzam Developer on 2026-05-26.
//  Copyright © 2026 Azzam-Alrashed. All rights reserved.
//

import Foundation
import SwiftUI
import RealityKit
import Combine
import CoreGraphics

// MARK: - Aerodynamic & Simulation Metrics
/// A namespace detailing standard environmental constants for our flight model simulation.
enum HasanaGardenEcosystemConstants {
    /// Gravitational acceleration affecting heavy creatures (birds).
    static let gravity: Float = 0.98
    /// Air density constant for aerodynamic drag calculations.
    static let airDensity: Float = 1.225
    /// Standard Ground level offset in the AR world space.
    static let groundY: Float = 0.08
    /// High-frequency update interval standard.
    static let simulationHz: Float = 60.0
}

// MARK: - Mathematical Vector & Interpolation Extensions

extension SIMD3 where Scalar == Float {
    /// The length (magnitude) of the 3D vector.
    var length: Float {
        let sq = x*x + y*y + z*z
        return sq > 0 ? sqrt(sq) : 0
    }
    
    /// The squared length of the vector, useful for fast distance comparisons.
    var lengthSquared: Float {
        return x*x + y*y + z*z
    }
    
    /// Returns the normalized unit vector.
    var normalized: SIMD3<Float> {
        let len = length
        return len > 0.0001 ? self / len : SIMD3<Float>(0, 0, 0)
    }
    
    /// Calculates the Euclidean distance between this vector and another.
    func distance(to other: SIMD3<Float>) -> Float {
        return (self - other).length
    }
    
    /// Calculates the squared Euclidean distance between this vector and another.
    func distanceSquared(to other: SIMD3<Float>) -> Float {
        return (self - other).lengthSquared
    }
    
    /// Linearly interpolates between this vector and another.
    func lerp(to target: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        let clampedT = Swift.max(0.0, Swift.min(1.0, t))
        return self + (target - self) * clampedT
    }
    
    /// Limits the vector magnitude to a maximum value.
    func limit(to maxVal: Float) -> SIMD3<Float> {
        let len = length
        if len > maxVal && len > 0.0001 {
            return (self / len) * maxVal
        }
        return self
    }
    
    /// Generates a random vector within a unit sphere.
    static func randomInUnitSphere() -> SIMD3<Float> {
        while true {
            let vec = SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -1...1)
            )
            if vec.length <= 1.0 {
                return vec
            }
        }
    }
    
    /// Generates a random vector in a hemisphere aligned with the normal.
    static func randomInHemisphere(normal: SIMD3<Float>) -> SIMD3<Float> {
        let unit = randomInUnitSphere().normalized
        if simd_dot(unit, normal) > 0.0 {
            return unit
        } else {
            return -unit
        }
    }
}

// MARK: - Procedural Noise Generator
/// A lightweight deterministic pseudo-random 3D noise generator
/// used to calculate wind turbulence and butterfly flutter patterns.
final class HasanaGardenNoise {
    private static let permutation: [Int32] = {
        var arr = Array(0...255).map { Int32($0) }
        // Deterministic shuffle using a fixed seed to keep noise consistent
        var seed: UInt64 = 0xDEADC0DE
        func nextSeed() -> UInt64 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return seed
        }
        for i in (1...255).reversed() {
            let j = Int(nextSeed() % UInt64(i + 1))
            arr.swapAt(i, j)
        }
        return arr + arr
    }()
    
    private static func fade(_ t: Float) -> Float {
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
    }
    
    private static func lerp(_ t: Float, _ a: Float, _ b: Float) -> Float {
        return a + t * (b - a)
    }
    
    private static func grad(_ hash: Int32, _ x: Float, _ y: Float, _ z: Float) -> Float {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
    
    /// Evaluates 3D Perlin noise at the specified coordinates.
    static func perlin3D(x: Float, y: Float, z: Float) -> Float {
        let X = Int32(floor(x)) & 255
        let Y = Int32(floor(y)) & 255
        let Z = Int32(floor(z)) & 255
        
        let xf = x - floor(x)
        let yf = y - floor(y)
        let zf = z - floor(z)
        
        let u = fade(xf)
        let v = fade(yf)
        let w = fade(zf)
        
        let p = permutation
        let A  = p[Int(X)] + Y
        let AA = p[Int(A)] + Z
        let AB = p[Int(A + 1)] + Z
        let B  = p[Int(X + 1)] + Y
        let BA = p[Int(B)] + Z
        let BB = p[Int(B + 1)] + Z
        
        return lerp(w,
            lerp(v,
                lerp(u, grad(p[Int(AA)],     xf,     yf,     zf),
                        grad(p[Int(BA)],     xf - 1, yf,     zf)),
                lerp(u, grad(p[Int(AB)],     xf,     yf - 1, zf),
                        grad(p[Int(BB)],     xf - 1, yf - 1, zf))),
            lerp(v,
                lerp(u, grad(p[Int(AA + 1)], xf,     yf,     zf - 1),
                        grad(p[Int(BA + 1)], xf - 1, yf,     zf - 1)),
                lerp(u, grad(p[Int(AB + 1)], xf,     yf - 1, zf - 1),
                        grad(p[Int(BB + 1)], xf - 1, yf - 1, zf - 1))
            )
        )
    }
    
    /// Evaluates fractional Brownian motion (fBm) over multiple octaves.
    static func fBm(x: Float, y: Float, z: Float, octaves: Int = 3, lacunarity: Float = 2.0, gain: Float = 0.5) -> Float {
        var total: Float = 0.0
        var frequency: Float = 1.0
        var amplitude: Float = 1.0
        var maxValue: Float = 0.0
        
        for _ in 0..<octaves {
            total += perlin3D(x: x * frequency, y: y * frequency, z: z * frequency) * amplitude
            maxValue += amplitude
            amplitude *= gain
            frequency *= lacunarity
        }
        
        return total / maxValue
    }
}

// MARK: - Catmull-Rom Spline Path Calculation
/// Computes smooth flying paths passing through a sequence of target landing points.
public final class HasanaGardenSplinePath {
    var controlPoints: [SIMD3<Float>] = []
    
    init(points: [SIMD3<Float>]) {
        guard points.count >= 2 else {
            self.controlPoints = points
            return
        }
        // Duplicate start and end to form control points for Catmull-Rom equations
        self.controlPoints = [points[0]] + points + [points[points.count - 1]]
    }
    
    /// Evaluates the position along the spline.
    /// - Parameter t: Progress through the spline, from 0.0 to 1.0.
    func evaluate(at t: Float) -> SIMD3<Float> {
        guard controlPoints.count >= 4 else {
            if controlPoints.count == 2 {
                return controlPoints[0].lerp(to: controlPoints[1], t: t)
            } else if controlPoints.count == 3 {
                return controlPoints[0].lerp(to: controlPoints[1], t: t)
            }
            return .zero
        }
        
        let clampedT = Swift.max(0.0, Swift.min(0.9999, t))
        let segmentsCount = Float(controlPoints.count - 3)
        let scaledT = clampedT * segmentsCount
        let segmentIndex = Int(floor(scaledT))
        let localT = scaledT - Float(segmentIndex)
        
        let p0 = controlPoints[segmentIndex]
        let p1 = controlPoints[segmentIndex + 1]
        let p2 = controlPoints[segmentIndex + 2]
        let p3 = controlPoints[segmentIndex + 3]
        
        return catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: localT)
    }
    
    /// Evaluates the tangent vector (heading) along the spline.
    func evaluateTangent(at t: Float) -> SIMD3<Float> {
        let delta: Float = 0.01
        let t1 = Swift.max(0.0, t - delta)
        let t2 = Swift.min(1.0, t + delta)
        let pos1 = evaluate(at: t1)
        let pos2 = evaluate(at: t2)
        let dir = pos2 - pos1
        return dir.lengthSquared > 0.0001 ? dir.normalized : SIMD3<Float>(0, 0, 1)
    }
    
    private func catmullRom(p0: SIMD3<Float>, p1: SIMD3<Float>, p2: SIMD3<Float>, p3: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        let t2 = t * t
        let t3 = t2 * t
        
        let f0 = -0.5 * t3 + t2 - 0.5 * t
        let f1 = 1.5 * t3 - 2.5 * t2 + 1.0
        let f2 = -1.5 * t3 + 2.0 * t2 + 0.5 * t
        let f3 = 0.5 * t3 - 0.5 * t2
        
        return p0 * f0 + p1 * f1 + p2 * f2 + p3 * f3
    }
}

// MARK: - Creature Types & Core Configurations

/// Defines the types of procedural creatures modeled in the Hasana garden ecosystem.
public enum GardenCreatureType: String, Codable, CaseIterable {
    case butterfly
    case bee
    case bird
}

/// Defines the operational flight states for the procedural creatures.
public enum GardenCreatureState: String, Codable {
    case spawning
    case flying
    case flocking
    case seekingTarget
    case landing
    case resting
    case pollinating
    case takeoff
}

/// Configuration settings defining flight dynamics, steering weights, and landing behaviors.
public struct GardenCreatureConfig: Codable {
    var maxSpeed: Float
    var maxForce: Float
    
    // Flocking parameters (Reynolds' weights)
    var separationWeight: Float
    var cohesionWeight: Float
    var alignmentWeight: Float
    var obstacleAvoidanceWeight: Float
    var boundaryWeight: Float
    var targetAttractionWeight: Float
    
    // Perception radii
    var separationRadius: Float
    var neighborRadius: Float
    var obstacleDetectionDistance: Float
    
    // Physical traits for flight dynamics
    var mass: Float
    var wingsFlapFrequency: Float
    var glideDecay: Float // Glide aerodynamic friction factor
    var windSensitivity: Float
    var dragCoefficient: Float
    var liftCoefficient: Float
    
    // Resting & Energy cycles
    var minRestDuration: TimeInterval
    var maxRestDuration: TimeInterval
    var energyDepletionRate: Float // Energy drain per second flying
    var energyRestorationRate: Float // Energy gain per second resting
    
    public static func defaultConfig(for type: GardenCreatureType) -> GardenCreatureConfig {
        switch type {
        case .butterfly:
            return GardenCreatureConfig(
                maxSpeed: 0.65,
                maxForce: 1.2,
                separationWeight: 1.5,
                cohesionWeight: 0.2,
                alignmentWeight: 0.1,
                obstacleAvoidanceWeight: 2.2,
                boundaryWeight: 1.8,
                targetAttractionWeight: 1.4,
                separationRadius: 0.25,
                neighborRadius: 0.8,
                obstacleDetectionDistance: 0.35,
                mass: 0.15,
                wingsFlapFrequency: 7.5,
                glideDecay: 1.0,
                windSensitivity: 2.8,
                dragCoefficient: 0.8,
                liftCoefficient: 1.4,
                minRestDuration: 4.0,
                maxRestDuration: 8.0,
                energyDepletionRate: 0.08,
                energyRestorationRate: 0.25
            )
        case .bee:
            return GardenCreatureConfig(
                maxSpeed: 1.25,
                maxForce: 2.8,
                separationWeight: 1.8,
                cohesionWeight: 1.5,
                alignmentWeight: 1.2,
                obstacleAvoidanceWeight: 2.8,
                boundaryWeight: 2.0,
                targetAttractionWeight: 1.9,
                separationRadius: 0.18,
                neighborRadius: 0.6,
                obstacleDetectionDistance: 0.3,
                mass: 0.35,
                wingsFlapFrequency: 25.0,
                glideDecay: 1.0,
                windSensitivity: 0.65,
                dragCoefficient: 0.3,
                liftCoefficient: 0.8,
                minRestDuration: 2.0,
                maxRestDuration: 5.0,
                energyDepletionRate: 0.12,
                energyRestorationRate: 0.4
            )
        case .bird:
            return GardenCreatureConfig(
                maxSpeed: 2.6,
                maxForce: 3.5,
                separationWeight: 2.0,
                cohesionWeight: 1.2,
                alignmentWeight: 1.8,
                obstacleAvoidanceWeight: 3.5,
                boundaryWeight: 2.5,
                targetAttractionWeight: 1.6,
                separationRadius: 0.65,
                neighborRadius: 1.6,
                obstacleDetectionDistance: 1.0,
                mass: 1.15,
                wingsFlapFrequency: 5.0,
                glideDecay: 0.95,
                windSensitivity: 0.3,
                dragCoefficient: 0.15,
                liftCoefficient: 1.2,
                minRestDuration: 6.0,
                maxRestDuration: 14.0,
                energyDepletionRate: 0.05,
                energyRestorationRate: 0.18
            )
        }
    }
}

// MARK: - Pollination Structs

/// A pollen structure carrying the genetic print of the visited plant.
public struct GardenPollen: Codable, Equatable, Hashable {
    public let sourcePlantID: HasanaGardenPracticeID
    public let timestamp: Date
    public let quality: Float // Determined by the growth stage and status of the source plant
}

/// A record representing a successful cross-pollination event in the garden.
public struct GardenPollinationRecord: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let pollinatorID: UUID
    public let pollinatorType: GardenCreatureType
    public let targetPlantID: HasanaGardenPracticeID
    public let sourcePlantID: HasanaGardenPracticeID
    public let pollenQuality: Float
    public let timestamp: Date
    
    public init(pollinatorID: UUID, pollinatorType: GardenCreatureType, targetPlantID: HasanaGardenPracticeID, sourcePlantID: HasanaGardenPracticeID, pollenQuality: Float) {
        self.id = UUID()
        self.pollinatorID = pollinatorID
        self.pollinatorType = pollinatorType
        self.targetPlantID = targetPlantID
        self.sourcePlantID = sourcePlantID
        self.pollenQuality = pollenQuality
        self.timestamp = Date()
    }
}

// MARK: - Landing Point Configuration

public enum GardenLandingType: String, Codable {
    case flower
    case tree
    case stone
    public var title: String { rawValue }
}

public struct GardenLandingPoint {
    public let id: UUID = UUID()
    public let position: SIMD3<Float>
    public let normal: SIMD3<Float>
    public let type: GardenLandingType
    public let associatedPracticeID: HasanaGardenPracticeID?
    
    /// Attractiveness multiplier based on the plant's growth stage and dormancy.
    func attractivenessScore(displayState: HasanaGardenDisplayState) -> Float {
        guard let practiceID = associatedPracticeID else {
            // Static landing points (like stones) have base attractiveness
            return type == .stone ? 0.35 : 0.1
        }
        
        guard let practiceState = displayState.practices.first(where: { $0.practice.id == practiceID }) else {
            return 0.0
        }
        
        // Ignore seed stage entirely, creatures cannot land on non-sprouted seeds
        if practiceState.progress.growthStage == .seed {
            return 0.0
        }
        
        var baseScore: Float = 0.0
        switch practiceState.progress.growthStage {
        case .sprout:
            baseScore = 0.25
        case .young:
            baseScore = 0.5
        case .mature:
            baseScore = 0.85
        case .flowering:
            baseScore = 1.4
        case .seed:
            baseScore = 0.0
        }
        
        // Dormant plants are less attractive
        if practiceState.isDormant && !practiceState.isTendedToday {
            baseScore *= 0.35
        }
        
        // Tended plants today get an attractive boost!
        if practiceState.isTendedToday {
            baseScore *= 1.5
        }
        
        return baseScore
    }
}

// MARK: - Core Creature Class

/// Represents a single active procedural creature in the simulation.
public final class GardenCreature: Identifiable {
    public let id: UUID = UUID()
    public let type: GardenCreatureType
    public var config: GardenCreatureConfig
    
    // Kinematic parameters
    public var position: SIMD3<Float>
    public var velocity: SIMD3<Float>
    public var acceleration: SIMD3<Float> = .zero
    public var orientation: simd_quatf = simd_quatf(angle: 0.0, axis: [0, 1, 0])
    
    // Physics and Aerodynamics
    public var energy: Float = 1.0 // Range: 0.0 (exhausted) to 1.0 (fully rested)
    public var liftForce: SIMD3<Float> = .zero
    public var dragForce: SIMD3<Float> = .zero
    
    // Animation properties
    var wingAngle: Float = 0.0
    var wingFlapTimer: Float = 0.0
    public var isGliding: Bool = false
    
    // Behavior and State
    public var state: GardenCreatureState = .spawning
    public var targetLandingPoint: GardenLandingPoint?
    var restTimer: TimeInterval = 0.0
    var targetRestDuration: TimeInterval = 0.0
    
    // Spline-based paths for flight path calculations
    public var splinePath: HasanaGardenSplinePath?
    public var splineProgress: Float = 0.0
    public var splineSpeed: Float = 1.0
    
    // Pollination capability
    public var pollenSack: GardenPollen?
    public var totalPollinatedCount: Int = 0
    public var recentlyVisitedPracticeIDs: [HasanaGardenPracticeID] = []
    
    // Wind drift seed
    let noiseOffset: SIMD3<Float> = SIMD3<Float>(
        Float.random(in: -100...100),
        Float.random(in: -100...100),
        Float.random(in: -100...100)
    )
    
    // Weak reference to RealityKit representation
    weak var visualEntity: Entity?
    
    init(type: GardenCreatureType, spawnPosition: SIMD3<Float>) {
        self.type = type
        self.config = GardenCreatureConfig.defaultConfig(for: type)
        self.position = spawnPosition
        
        // Random initial velocity vector
        let dir = SIMD3<Float>.randomInUnitSphere().normalized
        self.velocity = dir * (config.maxSpeed * 0.5)
        self.wingFlapTimer = Float.random(in: 0...10.0)
    }
    
    func cleanUp() {
        visualEntity?.removeFromParent()
    }
}

// MARK: - Simulation Config & Box Constraints

struct GardenSimulationBounds {
    // Coordinate limits matching the HasanaGardenView frame:
    // Soil base is x in [-3.25, 3.25], z in [-2.175, 2.175].
    var minX: Float = -3.4
    var maxX: Float = 3.4
    var minY: Float = 0.12 // Ground clearance
    var maxY: Float = 2.8  // Maximum height
    var minZ: Float = -2.3
    var maxZ: Float = 2.3
    
    func isOutside(_ pos: SIMD3<Float>) -> Bool {
        return pos.x < minX || pos.x > maxX || pos.y < minY || pos.y > maxY || pos.z < minZ || pos.z > maxZ
    }
    
    /// Computes steering force to push creatures back inside boundaries.
    func steeringForce(for position: SIMD3<Float>, velocity: SIMD3<Float>, maxSpeed: Float) -> SIMD3<Float> {
        let margin: Float = 0.5
        var desired: SIMD3<Float> = .zero
        
        if position.x < minX + margin {
            desired.x = maxSpeed
        } else if position.x > maxX - margin {
            desired.x = -maxSpeed
        }
        
        if position.y < minY + margin {
            desired.y = maxSpeed * 0.8
        } else if position.y > maxY - margin {
            desired.y = -maxSpeed * 0.8
        }
        
        if position.z < minZ + margin {
            desired.z = maxSpeed
        } else if position.z > maxZ - margin {
            desired.z = -maxSpeed
        }
        
        if desired != .zero {
            desired = desired.normalized * maxSpeed
            let steer = desired - velocity
            return steer
        }
        
        return .zero
    }
}

// MARK: - RealityKit Visual Entity Builders
/// A helper class to procedurally construct and animate RealityKit model entities representing creatures.
final class HasanaGardenCreatureVisualBuilder {
    
    private static func createMaterial(color: UIColor, roughness: Float, isMetallic: Bool = false) -> SimpleMaterial {
        return SimpleMaterial(color: color, roughness: .float(roughness), isMetallic: isMetallic)
    }
    
    /// Builds a composite Entity for a butterfly with animatable wings.
    static func buildButterfly(accentColor: UIColor) -> Entity {
        let root = Entity()
        root.name = "butterfly"
        
        // 1. Thorax & Body (Tiny cylinder)
        let bodyColor = UIColor.black
        let bodyMat = createMaterial(color: bodyColor, roughness: 0.8)
        let bodyMesh = MeshResource.generateCylinder(height: 0.05, radius: 0.005)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMat])
        body.name = "body"
        // Rotate body cylinder so it lies along the flight direction (Z axis is forward in RealityKit).
        body.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        root.addChild(body)
        
        // 2. Wings Container
        let leftWingPivot = Entity()
        leftWingPivot.name = "leftPivot"
        leftWingPivot.position = SIMD3<Float>(-0.003, 0.0, 0.0)
        
        let rightWingPivot = Entity()
        rightWingPivot.name = "rightPivot"
        rightWingPivot.position = SIMD3<Float>(0.003, 0.0, 0.0)
        
        // Wing shape (Very thin boxes)
        let wingMesh = MeshResource.generateBox(width: 0.045, height: 0.001, depth: 0.038)
        let wingMat = createMaterial(color: accentColor.withAlphaComponent(0.85), roughness: 0.3)
        
        let leftWing = ModelEntity(mesh: wingMesh, materials: [wingMat])
        leftWing.position = SIMD3<Float>(-0.0225, 0.0, 0.0)
        leftWingPivot.addChild(leftWing)
        
        let rightWing = ModelEntity(mesh: wingMesh, materials: [wingMat])
        rightWing.position = SIMD3<Float>(0.0225, 0.0, 0.0)
        rightWingPivot.addChild(rightWing)
        
        root.addChild(leftWingPivot)
        root.addChild(rightWingPivot)
        
        // Scale down the entire butterfly to match garden proportions
        root.scale = SIMD3<Float>(0.65, 0.65, 0.65)
        return root
    }
    
    /// Builds a composite Entity for a bumblebee.
    static func buildBee() -> Entity {
        let root = Entity()
        root.name = "bee"
        
        // Bee body (Yellow-Black striped cylinders)
        let bodyContainer = Entity()
        bodyContainer.name = "bodyContainer"
        bodyContainer.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        
        let blackMat = createMaterial(color: .black, roughness: 0.9)
        let yellowMat = createMaterial(color: .systemYellow, roughness: 0.8)
        
        // Thorax
        let thoraxMesh = MeshResource.generateCylinder(height: 0.02, radius: 0.012)
        let thorax = ModelEntity(mesh: thoraxMesh, materials: [yellowMat])
        thorax.position = [0, 0.015, 0]
        bodyContainer.addChild(thorax)
        
        // Abdomen
        let abdomenMesh = MeshResource.generateCylinder(height: 0.03, radius: 0.015)
        let abdomen = ModelEntity(mesh: abdomenMesh, materials: [blackMat])
        abdomen.position = [0, -0.005, 0]
        bodyContainer.addChild(abdomen)
        
        // Head
        let headMesh = MeshResource.generateSphere(radius: 0.01)
        let head = ModelEntity(mesh: headMesh, materials: [blackMat])
        head.position = [0, 0.03, 0]
        bodyContainer.addChild(head)
        
        root.addChild(bodyContainer)
        
        // Translucent wings
        let wingMesh = MeshResource.generateBox(width: 0.025, height: 0.0005, depth: 0.012)
        let wingMat = createMaterial(color: UIColor(white: 0.9, alpha: 0.6), roughness: 0.1)
        
        let leftWingPivot = Entity()
        leftWingPivot.name = "leftPivot"
        leftWingPivot.position = [-0.01, 0.01, 0.005]
        let leftWing = ModelEntity(mesh: wingMesh, materials: [wingMat])
        leftWing.position = [-0.0125, 0.0, 0.0]
        leftWing.orientation = simd_quatf(angle: -0.2, axis: [0, 1, 0])
        leftWingPivot.addChild(leftWing)
        
        let rightWingPivot = Entity()
        rightWingPivot.name = "rightPivot"
        rightWingPivot.position = [0.01, 0.01, 0.005]
        let rightWing = ModelEntity(mesh: wingMesh, materials: [wingMat])
        rightWing.position = [0.0125, 0.0, 0.0]
        rightWing.orientation = simd_quatf(angle: 0.2, axis: [0, 1, 0])
        rightWingPivot.addChild(rightWing)
        
        root.addChild(leftWingPivot)
        root.addChild(rightWingPivot)
        
        root.scale = SIMD3<Float>(0.6, 0.6, 0.6)
        return root
    }
    
    /// Builds a composite Entity for a bird (e.g., small finch).
    static func buildBird() -> Entity {
        let root = Entity()
        root.name = "bird"
        
        // Main body (Egg-shaped sphere)
        let bodyColor = UIColor(red: 0.2, green: 0.55, blue: 0.85, alpha: 1.0)
        let bodyMat = createMaterial(color: bodyColor, roughness: 0.5)
        let bodyMesh = MeshResource.generateSphere(radius: 0.035)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMat])
        body.name = "body"
        body.scale = SIMD3<Float>(0.8, 0.8, 1.4) // Elongate along Z axis
        root.addChild(body)
        
        // Head
        let headMesh = MeshResource.generateSphere(radius: 0.024)
        let head = ModelEntity(mesh: headMesh, materials: [bodyMat])
        head.position = SIMD3<Float>(0, 0.024, 0.035)
        root.addChild(head)
        
        // Beak (Tiny cone/cylinder pointing forward)
        let beakColor = UIColor.systemOrange
        let beakMat = createMaterial(color: beakColor, roughness: 0.4)
        let beakMesh = MeshResource.generateCylinder(height: 0.018, radius: 0.004)
        let beak = ModelEntity(mesh: beakMesh, materials: [beakMat])
        beak.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        beak.position = SIMD3<Float>(0, 0.022, 0.062)
        root.addChild(beak)
        
        // Wings pivots
        let leftWingPivot = Entity()
        leftWingPivot.name = "leftPivot"
        leftWingPivot.position = SIMD3<Float>(-0.026, 0.005, 0.0)
        
        let rightWingPivot = Entity()
        rightWingPivot.name = "rightPivot"
        rightWingPivot.position = SIMD3<Float>(0.026, 0.005, 0.0)
        
        // Wing shape
        let wingMesh = MeshResource.generateBox(width: 0.12, height: 0.002, depth: 0.065)
        let wingMat = createMaterial(color: bodyColor.withAlphaComponent(0.95), roughness: 0.6)
        
        let leftWing = ModelEntity(mesh: wingMesh, materials: [wingMat])
        leftWing.position = SIMD3<Float>(-0.06, 0.0, 0.0)
        leftWingPivot.addChild(leftWing)
        
        let rightWing = ModelEntity(mesh: wingMesh, materials: [wingMat])
        rightWing.position = SIMD3<Float>(0.06, 0.0, 0.0)
        rightWingPivot.addChild(rightWing)
        
        root.addChild(leftWingPivot)
        root.addChild(rightWingPivot)
        
        // Tail feathers
        let tailMesh = MeshResource.generateBox(width: 0.022, height: 0.002, depth: 0.075)
        let tail = ModelEntity(mesh: tailMesh, materials: [wingMat])
        tail.position = SIMD3<Float>(0, -0.005, -0.07)
        tail.orientation = simd_quatf(angle: -0.15, axis: [1, 0, 0])
        root.addChild(tail)
        
        root.scale = SIMD3<Float>(0.7, 0.7, 0.7)
        return root
    }
    
    /// Performs procedural wing flap animations and heading adjustments.
    static func animateCreature(creature: GardenCreature, deltaTime: Float) {
        guard let root = creature.visualEntity else { return }
        
        // 1. Update orientation toward velocity vector with bank angle (roll) on turns
        let speed = creature.velocity.length
        if speed > 0.01 {
            let heading = creature.velocity.normalized
            
            // Calculate yaw (heading angle in horizontal XZ plane)
            let yawAngle = atan2(-heading.x, -heading.z) + .pi
            let yawRot = simd_quatf(angle: yawAngle, axis: [0, 1, 0])
            
            // Calculate pitch (climb/descent tilt)
            let pitchAngle = asin(heading.y)
            let pitchRot = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
            
            // Calculate bank angle (roll) proportional to centripetal turning force
            let lateralTurning = simd_dot(simd_normalize(creature.velocity), SIMD3<Float>(1, 0, 0))
            let targetRoll = -lateralTurning * 0.45 * (speed / creature.config.maxSpeed)
            let rollRot = simd_quatf(angle: targetRoll, axis: [0, 0, 1])
            
            // Smoothly interpolate current rotation to match flight dynamics
            let targetRot = yawRot * pitchRot * rollRot
            root.orientation = simd_slerp(root.orientation, targetRot, deltaTime * 8.0)
        }
        
        // 2. Animate Wings
        creature.wingFlapTimer += deltaTime * creature.config.wingsFlapFrequency
        
        if creature.isGliding {
            // Glide state: wings flat or slightly raised
            let targetFlap: Float = 0.05
            creature.wingAngle = creature.wingAngle + (targetFlap - creature.wingAngle) * deltaTime * 3.0
        } else {
            // Flapping state: sinusoidal oscillations
            switch creature.type {
            case .butterfly:
                // Butterflies flap deeply and erratically
                creature.wingAngle = sin(creature.wingFlapTimer) * 1.15
            case .bee:
                // Bees buzz at very high frequencies, smaller amplitude
                creature.wingAngle = sin(creature.wingFlapTimer) * 0.35
            case .bird:
                // Birds flap smoothly, slower frequency
                creature.wingAngle = sin(creature.wingFlapTimer) * 0.72
            }
        }
        
        // Apply rotation to left and right wings around Z axis
        if let leftPivot = root.findEntity(named: "leftPivot") {
            leftPivot.orientation = simd_quatf(angle: creature.wingAngle, axis: [0, 0, 1])
        }
        if let rightPivot = root.findEntity(named: "rightPivot") {
            rightPivot.orientation = simd_quatf(angle: -creature.wingAngle, axis: [0, 0, 1])
        }
    }
}

// MARK: - Simulation System Engine

@Observable
@MainActor
public final class HasanaGardenCreatureSystem {
    
    // Configs & Environmental variables
    private var simulationBounds = GardenSimulationBounds()
    private var isWindActive: Bool = false
    private var windDirection: SIMD3<Float> = SIMD3<Float>(1, 0, 0.2).normalized
    private var windStrength: Float = 0.0
    private var windTimer: TimeInterval = 0.0
    
    // Active simulation models
    public var creatures: [GardenCreature] = []
    public private(set) var pollinationRecords: [GardenPollinationRecord] = []
    
    // State metrics
    public var totalPollinationCount: Int = 0
    public var crossPollinationEfficiency: Float = 0.0
    
    // Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Weak reference to the scene anchor in RealityView to handle visual updates
    private weak var sceneAnchor: AnchorEntity?
    private var landingPoints: [GardenLandingPoint] = []
    
    public init() {}
    
    /// Connects the simulation to the RealityKit scene anchor.
    public func setSceneAnchor(_ anchor: AnchorEntity) {
        self.sceneAnchor = anchor
        rebuildVisuals()
    }
    
    /// Updates the collection of available landing/resting locations in the garden.
    public func updateLandingPoints(from displayState: HasanaGardenDisplayState) {
        var points: [GardenLandingPoint] = []
        
        // Coordinate mappings corresponding to Model positions in HasanaGardenView:
        let positions: [HasanaGardenPracticeID: SIMD3<Float>] = [
            .fajr:    [-2.35, 0.0, -1.1],
            .dhuhr:   [-0.85, 0.0, -1.28],
            .asr:     [0.82, 0.0, -1.18],
            .maghrib: [2.22, 0.0, -0.72],
            .isha:    [1.58, 0.0, 1.08],
            .quran:   [-1.62, 0.0, 0.98],
            .adhkar:  [0.0, 0.0, 0.86],
            .witr:    [2.32, 0.0, 0.92]
        ]
        
        for practiceState in displayState.practices {
            let practice = practiceState.practice
            guard let pos = positions[practice.id] else { continue }
            
            // Adjust landing height depending on visual role and growth stage
            let growthScale = practiceState.progress.growthStage.modelScale
            var landingHeight: Float = 0.0
            
            switch practice.visualRole {
            case .foundationalTree:
                // Trees have high canopy crowns. Top landing zone.
                landingHeight = 0.56 + growthScale * 0.46
            case .plant:
                // Leafy plants
                landingHeight = 0.34 + growthScale * 0.38
            case .flower:
                // Flowers
                landingHeight = 0.32 + growthScale * 0.4
            }
            
            let landingPos = SIMD3<Float>(pos.x, landingHeight, pos.z)
            
            // Add a landing point at the top
            points.append(
                GardenLandingPoint(
                    position: landingPos,
                    normal: SIMD3<Float>(0, 1, 0),
                    type: practice.visualRole == .foundationalTree ? .tree : .flower,
                    associatedPracticeID: practice.id
                )
            )
        }
        
        // Static resting sites (Stepping stones)
        // Horizontal stepping stones: along z = 0.18, x from -2.7 to 2.7 by 0.45
        var currentX: Float = -2.7
        while currentX <= 2.7 {
            if abs(currentX - 0.25) > 0.1 { // Avoid intersection point
                points.append(
                    GardenLandingPoint(
                        position: SIMD3<Float>(currentX, 0.082, 0.18),
                        normal: SIMD3<Float>(0, 1, 0),
                        type: .stone,
                        associatedPracticeID: nil
                    )
                )
            }
            currentX += 0.45
        }
        
        // Cross path stepping stones along x = 0.25 (going front to back)
        var currentZ: Float = -1.8
        while currentZ <= 1.8 {
            points.append(
                GardenLandingPoint(
                    position: SIMD3<Float>(0.25, 0.082, currentZ),
                    normal: SIMD3<Float>(0, 1, 0),
                    type: .stone,
                    associatedPracticeID: nil
                )
            )
            currentZ += 0.45
        }
        
        self.landingPoints = points
    }
    
    /// Spawns procedural creatures into the scene based on active plant counts.
    public func reconcileCreatures(displayState: HasanaGardenDisplayState) {
        let tendedCount = displayState.tendedTodayCount
        
        // Dynamic counts based on total tended days
        let targetButterflies = min(6, 1 + tendedCount / 2)
        let targetBees = min(5, 1 + (tendedCount + 1) / 3)
        let targetBirds = min(3, tendedCount >= 3 ? 1 + (tendedCount - 3) / 2 : 0)
        
        reconcileType(.butterfly, targetCount: targetButterflies)
        reconcileType(.bee, targetCount: targetBees)
        reconcileType(.bird, targetCount: targetBirds)
    }
    
    private func reconcileType(_ type: GardenCreatureType, targetCount: Int) {
        let currentTyped = creatures.filter { $0.type == type }
        let difference = targetCount - currentTyped.count
        
        if difference > 0 {
            for _ in 0..<difference {
                // Spawn position near borders or top
                let spawnPos = SIMD3<Float>(
                    Float.random(in: -3.0...3.0),
                    Float.random(in: 1.5...2.2),
                    Float.random(in: -2.0...2.0)
                )
                let creature = GardenCreature(type: type, spawnPosition: spawnPos)
                creatures.append(creature)
                spawnVisualEntity(for: creature)
            }
        } else if difference < 0 {
            // Safely remove extra creatures, preferring those in flying/idle state
            let toRemoveCount = abs(difference)
            var removed = 0
            
            creatures.removeAll { creature in
                guard creature.type == type && removed < toRemoveCount else { return false }
                if creature.state == .flying || creature.state == .flocking {
                    creature.cleanUp()
                    removed += 1
                    return true
                }
                return false
            }
            
            if removed < toRemoveCount {
                creatures.removeAll { creature in
                    guard creature.type == type && removed < toRemoveCount else { return false }
                    creature.cleanUp()
                    removed += 1
                    return true
                }
            }
        }
    }
    
    // MARK: - Simulation Tick
    
    /// Main simulation cycle update loop driving calculations.
    /// - Parameters:
    ///   - deltaTime: Seconds elapsed since the last update frame.
    ///   - store: The primary garden store to fetch current progress states.
    public func update(deltaTime: TimeInterval, store: HasanaGardenStore) {
        let dt = Float(deltaTime)
        guard dt > 0.0001 else { return }
        
        let displayState = store.displayState
        updateLandingPoints(from: displayState)
        
        // Update wind forces
        updateWind(deltaTime: deltaTime)
        
        for creature in creatures {
            updateCreatureState(creature, deltaTime: dt, displayState: displayState)
            
            // If flying, apply kinematic force physics
            if creature.state == .flying || creature.state == .flocking || creature.state == .seekingTarget || creature.state == .takeoff {
                applyMovementPhysics(creature, deltaTime: dt)
            }
            
            // Animate RealityKit entities
            HasanaGardenCreatureVisualBuilder.animateCreature(creature: creature, deltaTime: dt)
        }
    }
    
    /// Triggers an interactive wind gust that temporarily alters flight dynamics.
    public func triggerWindGust() {
        isWindActive = true
        windStrength = 3.5
        windTimer = 4.0 // seconds duration
        
        windDirection = SIMD3<Float>(
            Float.random(in: -1...1),
            Float.random(in: -0.1...0.3),
            Float.random(in: -1...1)
        ).normalized
    }
    
    /// Disturb flying creatures, sending birds into a temporary panic state.
    public func scareCreatures() {
        for creature in creatures {
            if creature.state == .resting || creature.state == .pollinating {
                creature.state = .takeoff
                creature.targetRestDuration = 0
                
                // Jump velocity upwards
                creature.velocity = SIMD3<Float>(
                    Float.random(in: -1.0...1.0),
                    Float.random(in: 1.2...2.0),
                    Float.random(in: -1.0...1.0)
                ).normalized * creature.config.maxSpeed
            }
        }
    }
    
    // MARK: - Internal Movement Physics & Boids
    
    private func updateWind(deltaTime: TimeInterval) {
        if isWindActive {
            windTimer -= deltaTime
            if windTimer <= 0 {
                isWindActive = false
                windStrength = 0
            } else {
                // Decay wind strength over time
                windStrength = Float(windTimer) * 0.8
            }
        } else {
            // Ambient soft breeze utilizing perlin noise
            let timeVal = Float(Date().timeIntervalSince1970 * 0.2)
            windStrength = (HasanaGardenNoise.fBm(x: timeVal, y: 0, z: 0, octaves: 1) + 1.0) * 0.25
            windDirection = SIMD3<Float>(
                cos(timeVal),
                0.05,
                sin(timeVal * 0.5)
            ).normalized
        }
    }
    
    private func applyMovementPhysics(_ creature: GardenCreature, deltaTime: Float) {
        // Evaluate Aerodynamics: Lift & Drag Forces
        // Drag = 0.5 * airDensity * speed^2 * dragCoefficient
        let speed = creature.velocity.length
        if speed > 0.001 {
            let speedSq = speed * speed
            let dragMag = 0.5 * HasanaGardenEcosystemConstants.airDensity * speedSq * creature.config.dragCoefficient
            creature.dragForce = -creature.velocity.normalized * dragMag
            creature.acceleration += creature.dragForce / creature.config.mass
            
            // Lift = 0.5 * airDensity * speed^2 * liftCoefficient (acts perpendicular upwards)
            let liftMag = 0.5 * HasanaGardenEcosystemConstants.airDensity * speedSq * creature.config.liftCoefficient
            creature.liftForce = SIMD3<Float>(0, liftMag, 0)
            creature.acceleration += creature.liftForce / creature.config.mass
        }
        
        // Apply Gravitational force for birds
        if creature.type == .bird {
            creature.acceleration.y -= HasanaGardenEcosystemConstants.gravity
        }
        
        // Accelerate
        creature.velocity += creature.acceleration * deltaTime
        
        // Apply wind resistance and friction
        var currentMaxSpeed = creature.config.maxSpeed
        
        // If bird is gliding, decay velocity slower
        if creature.type == .bird && creature.isGliding {
            currentMaxSpeed *= creature.config.glideDecay
        }
        
        creature.velocity = creature.velocity.limit(to: currentMaxSpeed)
        creature.position += creature.velocity * deltaTime
        
        // Bind boundary checks
        if simulationBounds.isOutside(creature.position) {
            let boundaryForce = simulationBounds.steeringForce(
                for: creature.position,
                velocity: creature.velocity,
                maxSpeed: creature.config.maxSpeed
            )
            creature.velocity += boundaryForce * deltaTime * creature.config.boundaryWeight
            
            // Hard clamp coordinates to safety zone to prevent leaving garden entirely
            creature.position.x = Swift.max(simulationBounds.minX, Swift.min(simulationBounds.maxX, creature.position.x))
            creature.position.y = Swift.max(simulationBounds.minY, Swift.min(simulationBounds.maxY, creature.position.y))
            creature.position.z = Swift.max(simulationBounds.minZ, Swift.min(simulationBounds.maxZ, creature.position.z))
        }
        
        // Reset acceleration accumulation
        creature.acceleration = .zero
        
        // Sync coordinates with RealityKit Entity representation
        creature.visualEntity?.position = creature.position
    }
    
    // MARK: - State Transitions & Decision Trees
    
    private func updateCreatureState(_ creature: GardenCreature, deltaTime: Float, displayState: HasanaGardenDisplayState) {
        // Energy consumption updates
        if creature.state == .resting || creature.state == .pollinating {
            creature.energy = Swift.min(1.0, creature.energy + creature.config.energyRestorationRate * deltaTime)
        } else {
            creature.energy = Swift.max(0.0, creature.energy - creature.config.energyDepletionRate * deltaTime)
        }
        
        switch creature.state {
        case .spawning:
            // Elevate above spawn and transition to flying
            creature.state = .flying
            
        case .flying, .flocking:
            // High level state changes based on energy levels
            if creature.energy < 0.25 && creature.targetLandingPoint == nil {
                // Must rest! Find landing target.
                selectLandingPoint(for: creature, displayState: displayState)
            }
            
            // Standard search loops
            let searchProbability = creature.pollenSack == nil ? 0.015 : 0.008
            if Float.random(in: 0...1) < searchProbability && creature.targetLandingPoint == nil {
                selectLandingPoint(for: creature, displayState: displayState)
            }
            
            if creature.state == .flocking {
                computeFlockingForces(creature)
            } else {
                computeWanderForces(creature, deltaTime: deltaTime)
            }
            
        case .seekingTarget:
            guard let landingPoint = creature.targetLandingPoint else {
                creature.state = .flying
                return
            }
            
            if let path = creature.splinePath {
                // Fly along the pre-computed spline curve!
                creature.splineProgress += deltaTime * creature.splineSpeed
                if creature.splineProgress >= 1.0 {
                    creature.state = .landing
                } else {
                    let nextPos = path.evaluate(at: creature.splineProgress)
                    let nextTangent = path.evaluateTangent(at: creature.splineProgress)
                    
                    creature.velocity = nextTangent * creature.config.maxSpeed
                    creature.position = nextPos
                    creature.visualEntity?.position = creature.position
                }
            } else {
                // Linear steering attraction fallback
                let dist = creature.position.distance(to: landingPoint.position)
                
                if dist < creature.config.obstacleDetectionDistance {
                    creature.state = .landing
                } else {
                    let desired = (landingPoint.position - creature.position).normalized * creature.config.maxSpeed
                    let steering = (desired - creature.velocity) * creature.config.targetAttractionWeight
                    creature.acceleration += steering
                }
            }
            
        case .landing:
            guard let landingPoint = creature.targetLandingPoint else {
                creature.state = .flying
                return
            }
            
            let dist = creature.position.distance(to: landingPoint.position)
            
            if dist <= 0.025 {
                // Landed! Turn off physical kinematics, begin resting/pollinating actions
                creature.position = landingPoint.position
                creature.velocity = .zero
                creature.acceleration = .zero
                
                // Align orientation with landing normal
                let up = landingPoint.normal
                let forward = SIMD3<Float>(0, 0, 1)
                let alignRot = simd_quatf(from: forward, to: up)
                creature.orientation = alignRot
                if let visual = creature.visualEntity {
                    visual.position = creature.position
                    visual.orientation = creature.orientation
                }
                
                // Begin timer
                creature.restTimer = 0.0
                creature.targetRestDuration = Double.random(in: creature.config.minRestDuration...creature.config.maxRestDuration)
                creature.splinePath = nil
                creature.splineProgress = 0.0
                
                // If insect landing on a flower, trigger pollination sequence
                if (creature.type == .butterfly || creature.type == .bee) && landingPoint.associatedPracticeID != nil {
                    creature.state = .pollinating
                } else {
                    creature.state = .resting
                }
            } else {
                // Actively damp velocity for smooth touchdown
                let speedMult = Swift.max(0.12, dist / creature.config.obstacleDetectionDistance)
                let desired = (landingPoint.position - creature.position).normalized * (creature.config.maxSpeed * speedMult)
                let steering = desired - creature.velocity
                creature.acceleration += steering
            }
            
        case .resting:
            creature.restTimer += Double(deltaTime)
            creature.isGliding = true
            
            if creature.restTimer >= creature.targetRestDuration {
                creature.state = .takeoff
                creature.isGliding = false
            }
            
        case .pollinating:
            creature.restTimer += Double(deltaTime)
            creature.isGliding = true
            
            // Carry out pollination transfers halfway through rest
            if creature.restTimer >= creature.targetRestDuration * 0.5 && creature.state == .pollinating {
                handleFlowerInteraction(creature, displayState: displayState)
                creature.state = .resting // Complete remainder of rest as standard idle
            }
            
        case .takeoff:
            // Lift off directly upwards initially
            let liftForce = SIMD3<Float>(0, creature.config.maxSpeed * 0.6, 0)
            creature.velocity = liftForce
            creature.targetLandingPoint = nil
            creature.splinePath = nil
            creature.splineProgress = 0.0
            
            creature.state = .flying
        }
    }
    
    // MARK: - Flight Path Algorithms
    
    private func computeWanderForces(_ creature: GardenCreature, deltaTime: Float) {
        let timeVal = Float(Date().timeIntervalSince1970 * 0.4)
        
        // Evaluate noise maps based on creature offset seeds
        let nx = HasanaGardenNoise.fBm(x: creature.position.x + creature.noiseOffset.x, y: timeVal, z: creature.position.z, octaves: 2)
        let ny = HasanaGardenNoise.fBm(x: timeVal, y: creature.position.y + creature.noiseOffset.y, z: creature.position.z, octaves: 2)
        let nz = HasanaGardenNoise.fBm(x: creature.position.x, y: timeVal, z: creature.position.z + creature.noiseOffset.z, octaves: 2)
        
        var noiseForce = SIMD3<Float>(nx, ny * 0.6, nz).normalized * (creature.config.maxForce * 0.4)
        
        // Add flying type specifics
        switch creature.type {
        case .butterfly:
            // Butterflies are highly erratic, flitting up and down constantly (chaotic flight paths)
            let flutterFreq = Float(Date().timeIntervalSince1970 * 12.0)
            noiseForce.y += sin(flutterFreq) * 0.65
            noiseForce.x += cos(flutterFreq * 1.5) * 0.35
            noiseForce *= 1.95 // Boost wander forces
            
        case .bee:
            // Bees are direct but carry rapid micro-adjustments
            let vibration = SIMD3<Float>(
                sin(Float(Date().timeIntervalSince1970 * 25.0)) * 0.15,
                0,
                cos(Float(Date().timeIntervalSince1970 * 25.0)) * 0.15
            )
            creature.acceleration += vibration
            
        case .bird:
            // Birds glide when flying downwards or maintaining high velocities
            if creature.velocity.y < -0.1 && creature.velocity.length > creature.config.maxSpeed * 0.6 {
                creature.isGliding = true
            } else {
                creature.isGliding = false
            }
        }
        
        creature.acceleration += noiseForce
        
        // Apply global wind drifts
        let windDrift = windDirection * (windStrength * creature.config.windSensitivity)
        creature.acceleration += windDrift
    }
    
    private func computeFlockingForces(_ creature: GardenCreature) {
        var separation: SIMD3<Float> = .zero
        var cohesion: SIMD3<Float> = .zero
        var alignment: SIMD3<Float> = .zero
        
        var sepCount = 0
        var neighborCount = 0
        
        for other in creatures {
            guard other.id != creature.id && other.type == creature.type else { continue }
            
            let dist = creature.position.distance(to: other.position)
            
            if dist < creature.config.separationRadius {
                let diff = (creature.position - other.position).normalized / dist
                separation += diff
                sepCount += 1
            }
            
            if dist < creature.config.neighborRadius {
                cohesion += other.position
                alignment += other.velocity
                neighborCount += 1
            }
        }
        
        // Resolve steering forces
        if sepCount > 0 {
            separation = (separation / Float(sepCount)).normalized * creature.config.maxSpeed - creature.velocity
            separation = separation.limit(to: creature.config.maxForce)
        }
        
        if neighborCount > 0 {
            cohesion = cohesion / Float(neighborCount)
            let desiredCohesion = (cohesion - creature.position).normalized * creature.config.maxSpeed
            cohesion = (desiredCohesion - creature.velocity).limit(to: creature.config.maxForce)
            
            alignment = (alignment / Float(neighborCount)).normalized * creature.config.maxSpeed - creature.velocity
            alignment = alignment.limit(to: creature.config.maxForce)
        }
        
        // Combine forces
        let totalFlockForce = (separation * creature.config.separationWeight) +
                              (cohesion * creature.config.cohesionWeight) +
                              (alignment * creature.config.alignmentWeight)
        
        creature.acceleration += totalFlockForce
        
        // Apply wind drifts
        let windDrift = windDirection * (windStrength * creature.config.windSensitivity)
        creature.acceleration += windDrift
    }
    
    private func selectLandingPoint(for creature: GardenCreature, displayState: HasanaGardenDisplayState) {
        guard !landingPoints.isEmpty else { return }
        
        // Evaluate score for landing points based on creature type compatibility
        var scoredPoints: [(point: GardenLandingPoint, score: Float)] = []
        
        for point in landingPoints {
            // Birds don't land on small flowers
            if creature.type == .bird && point.type == .flower { continue }
            // Insects prefer flowers and plants over stones, birds prefer stones and trees
            var modifier: Float = 1.0
            
            if creature.type == .bird {
                if point.type == .tree { modifier = 1.8 }
                if point.type == .stone { modifier = 1.5 }
            } else {
                if point.type == .flower { modifier = 2.0 }
                if point.type == .tree { modifier = 0.5 }
                if point.type == .stone { modifier = 0.05 }
            }
            
            // Do not revisit same plant immediately
            if let pid = point.associatedPracticeID, creature.recentlyVisitedPracticeIDs.contains(pid) {
                modifier *= 0.1
            }
            
            let attractiveness = point.attractivenessScore(displayState: displayState)
            let finalScore = attractiveness * modifier
            
            if finalScore > 0.001 {
                scoredPoints.append((point, finalScore))
            }
        }
        
        guard !scoredPoints.isEmpty else { return }
        
        // Weighted random selection
        let totalWeight = scoredPoints.reduce(0.0) { $0 + $1.score }
        var roll = Float.random(in: 0...totalWeight)
        
        for entry in scoredPoints {
            roll -= entry.score
            if roll <= 0 {
                creature.targetLandingPoint = entry.point
                
                // Compute spline-based curves for birds and bees to look natural
                if creature.type == .bird || creature.type == .bee {
                    let startPos = creature.position
                    let endPos = entry.point.position
                    
                    // Generate 2 intermediate control points
                    let midVector = endPos - startPos
                    let distance = midVector.length
                    
                    // Bezier offsets
                    let control1 = startPos + midVector * 0.33 + SIMD3<Float>(0, distance * 0.3, 0)
                    let control2 = startPos + midVector * 0.66 + SIMD3<Float>(0, distance * 0.1, 0)
                    
                    creature.splinePath = HasanaGardenSplinePath(points: [startPos, control1, control2, endPos])
                    creature.splineProgress = 0.0
                    creature.splineSpeed = creature.config.maxSpeed / distance
                }
                
                creature.state = .seekingTarget
                break
            }
        }
    }
    
    // MARK: - Pollination Logic Tracking
    
    private func handleFlowerInteraction(_ creature: GardenCreature, displayState: HasanaGardenDisplayState) {
        guard let landingPoint = creature.targetLandingPoint,
              let currentPlantID = landingPoint.associatedPracticeID else {
            return
        }
        
        // Track visited history
        creature.recentlyVisitedPracticeIDs.append(currentPlantID)
        if creature.recentlyVisitedPracticeIDs.count > 3 {
            creature.recentlyVisitedPracticeIDs.removeFirst()
        }
        
        // 1. Fetch practice details
        guard let practiceState = displayState.practices.first(where: { $0.practice.id == currentPlantID }) else {
            return
        }
        
        let growth = practiceState.progress.growthStage
        let baseQuality: Float = {
            switch growth {
            case .sprout: return 0.2
            case .young: return 0.5
            case .mature: return 0.8
            case .flowering: return 1.0
            case .seed: return 0.0
            }
        }()
        
        // 2. Pollen Deposit Sequence
        if let carriedPollen = creature.pollenSack {
            // Cross-pollination check (deposited pollen is from a different flower)
            if carriedPollen.sourcePlantID != currentPlantID {
                let record = GardenPollinationRecord(
                    pollinatorID: creature.id,
                    pollinatorType: creature.type,
                    targetPlantID: currentPlantID,
                    sourcePlantID: carriedPollen.sourcePlantID,
                    pollenQuality: (carriedPollen.quality + baseQuality) * 0.5
                )
                
                pollinationRecords.append(record)
                totalPollinationCount += 1
                creature.totalPollinatedCount += 1
                
                // Recalculate metrics
                recalculateMetrics()
                
                // Visual feedback: Trigger a light particle burst at flower position
                triggerPollenParticleBurst(at: landingPoint.position, color: .systemYellow)
            }
            
            // Clear sack after deposit
            creature.pollenSack = nil
        }
        
        // 3. Pollen Collection Sequence (only if flower is mature/flowering)
        if growth == .mature || growth == .flowering {
            // Load up a new pollen payload
            let newPollen = GardenPollen(
                sourcePlantID: currentPlantID,
                timestamp: Date(),
                quality: baseQuality
            )
            creature.pollenSack = newPollen
            
            // Small collection flash
            triggerPollenParticleBurst(at: landingPoint.position, color: .white)
        }
    }
    
    private func recalculateMetrics() {
        guard !pollinationRecords.isEmpty else {
            crossPollinationEfficiency = 0.0
            return
        }
        
        // Compute ratio of cross-pollinations (different visual roles / practices)
        let crossCount = pollinationRecords.filter { $0.sourcePlantID != $0.targetPlantID }.count
        crossPollinationEfficiency = Float(crossCount) / Float(pollinationRecords.count)
    }
    
    private func triggerPollenParticleBurst(at position: SIMD3<Float>, color: UIColor) {
        guard let scene = sceneAnchor else { return }
        
        // Create a temporary particle burst entity using primitive spheres that disperse outwards
        let particleCount = 12
        let container = Entity()
        container.position = position
        scene.addChild(container)
        
        let pMesh = MeshResource.generateSphere(radius: 0.004)
        let pMat = SimpleMaterial(color: color.withAlphaComponent(0.9), roughness: 0.5, isMetallic: false)
        
        var particles: [ModelEntity] = []
        var velocities: [SIMD3<Float>] = []
        
        for _ in 0..<particleCount {
            let p = ModelEntity(mesh: pMesh, materials: [pMat])
            container.addChild(p)
            particles.append(p)
            
            // Random direction upwards
            let dir = SIMD3<Float>.randomInHemisphere(normal: SIMD3<Float>(0, 1, 0))
            let speed = Float.random(in: 0.15...0.45)
            velocities.append(dir * speed)
        }
        
        // Simple animation loop using Combine timer
        var age: Float = 0.0
        let maxAge: Float = 0.8
        
        var timerSub: AnyCancellable?
        timerSub = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak container] _ in
                guard let container = container else {
                    timerSub?.cancel()
                    return
                }
                
                let dt: Float = 1.0 / 60.0
                age += dt
                
                if age >= maxAge {
                    container.removeFromParent()
                    timerSub?.cancel()
                    return
                }
                
                let progress = age / maxAge
                let alpha = 1.0 - progress
                
                // Fade colors and update physics
                let fadedMat = SimpleMaterial(color: color.withAlphaComponent(CGFloat(alpha)), roughness: 0.5, isMetallic: false)
                
                for i in 0..<particles.count {
                    let p = particles[i]
                    var vel = velocities[i]
                    
                    // Apply gravity
                    vel.y -= 0.28 * dt
                    velocities[i] = vel
                    
                    p.position += vel * dt
                    p.model?.materials = [fadedMat]
                }
            }
        
        if let sub = timerSub {
            cancellables.insert(sub)
        }
    }
    
    // MARK: - RealityKit Spawner & Synchronizer
    
    private func spawnVisualEntity(for creature: GardenCreature) {
        guard let anchor = sceneAnchor else { return }
        
        let entity: Entity
        switch creature.type {
        case .butterfly:
            let colors: [UIColor] = [.systemPink, .systemPurple, .systemOrange, .systemBlue]
            entity = HasanaGardenCreatureVisualBuilder.buildButterfly(accentColor: colors.randomElement() ?? .systemPink)
        case .bee:
            entity = HasanaGardenCreatureVisualBuilder.buildBee()
        case .bird:
            entity = HasanaGardenCreatureVisualBuilder.buildBird()
        }
        
        entity.position = creature.position
        anchor.addChild(entity)
        creature.visualEntity = entity
    }
    
    private func rebuildVisuals() {
        guard let anchor = sceneAnchor else { return }
        
        // Remove existing visual representations
        for creature in creatures {
            creature.cleanUp()
        }
        
        // Re-spawn all active creatures in the scene
        for creature in creatures {
            spawnVisualEntity(for: creature)
        }
    }
}

// MARK: - SwiftUI Overlay Companion View
/// Renders visual telemetry statistics of the creature ecosystem.
public struct HasanaGardenCreatureTelemetryView: View {
    let system: HasanaGardenCreatureSystem
    
    public init(system: HasanaGardenCreatureSystem) {
        self.system = system
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Garden Ecosystem")
                .font(.headline)
                .foregroundStyle(Color(HasanaTheme.textPrimary))
            
            HStack(spacing: 16) {
                // Population Counter
                VStack(alignment: .leading) {
                    Text("Creatures")
                        .font(.caption)
                        .foregroundStyle(Color(HasanaTheme.textMuted))
                    Text("\(system.creatures.count)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color(HasanaTheme.accent))
                }
                
                // Pollination Count
                VStack(alignment: .leading) {
                    Text("Pollinations")
                        .font(.caption)
                        .foregroundStyle(Color(HasanaTheme.textMuted))
                    Text("\(system.totalPollinationCount)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color(HasanaTheme.gold))
                }
                
                // Cross Pollination Efficiency
                VStack(alignment: .leading) {
                    Text("Efficiency")
                        .font(.caption)
                        .foregroundStyle(Color(HasanaTheme.textMuted))
                    Text(String(format: "%.0f%%", system.crossPollinationEfficiency * 100))
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color(HasanaTheme.reflection))
                }
            }
            .padding(12)
            .background(Color(HasanaTheme.elevatedSurfaceSoft).opacity(0.6))
            .cornerRadius(12)
            
            if !system.pollinationRecords.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent Activity")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(Color(HasanaTheme.textMuted))
                    
                    ForEach(system.pollinationRecords.suffix(3).reversed()) { record in
                        HStack {
                            Image(systemName: record.pollinatorType == .bee ? "sparkles" : "leaf.fill")
                                .foregroundStyle(Color(HasanaTheme.accent))
                            Text("\(record.pollinatorType.rawValue.capitalized) pollinated \(record.targetPlantID.rawValue.capitalized)")
                                .font(.caption2)
                                .foregroundStyle(Color(HasanaTheme.textPrimary))
                            Spacer()
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
