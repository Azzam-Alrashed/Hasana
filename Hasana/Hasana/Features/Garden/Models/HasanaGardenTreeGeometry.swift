//
//  HasanaGardenTreeGeometry.swift
//  Hasana
//
//  Created on 2026-05-26.
//  Copyright © 2026 Azzam-Alrashed. All rights reserved.
//

import Foundation
import RealityKit
import UIKit
import simd
import CoreGraphics

// MARK: - Mathematical & Noise Utilities

/// A deterministic pseudo-random number generator used to ensure that procedural trees
/// grow stably and look identical across renders for a given seed (derived from tended days and practice status).
struct SeededRandom {
    private var state: UInt64
    
    /// Initializes the generator with a specific 64-bit seed.
    init(seed: UInt64) {
        // Avoid seed value 0 as it leads to degenerate state progression
        self.state = seed == 0 ? 0xDECAFBADDEADBEEF : seed
    }
    
    /// Returns a pseudo-random double precision float in the range [0.0, 1.0).
    mutating func nextDouble() -> Double {
        // LCG multiplier and increment constants from MMIX by Donald Knuth
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state) / Double(UInt64.max)
    }
    
    /// Returns a pseudo-random float in the range [min, max].
    mutating func nextFloat(min: Float, max: Float) -> Float {
        return min + Float(nextDouble()) * (max - min)
    }
    
    /// Returns a pseudo-random element from the given array, or nil if the array is empty.
    mutating func choice<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        let index = Int(nextDouble() * Double(array.count))
        return array[min(index, array.count - 1)]
    }
}

/// A mathematical utility to compute procedural noise displacements, simulating organic
/// surface variation, wood grain, and bark patterns.
struct FractalNoise {
    /// Generates a simple 3D sinusoidal noise value in the range [-1.0, 1.0].
    /// This is used because it is lightweight, fast, and does not require large lookup tables.
    static func noise(p: SIMD3<Float>) -> Float {
        let dotProduct = p.x * 12.9898 + p.y * 78.233 + p.z * 45.164
        let sinVal = sin(dotProduct) * 43758.5453123
        return (sinVal - floor(sinVal)) * 2.0 - 1.0
    }
    
    /// Generates Fractional Brownian Motion (fBm) noise by accumulating multiple octaves of noise.
    /// Used to simulate natural bark fissures and branch bumps.
    static func fbm(p: SIMD3<Float>, octaves: Int = 3, lacunarity: Float = 2.0, gain: Float = 0.5) -> Float {
        var total: Float = 0.0
        var amplitude: Float = 1.0
        var frequency: Float = 1.0
        var maxValue: Float = 0.0
        
        for _ in 0..<octaves {
            total += amplitude * noise(p: p * frequency)
            maxValue += amplitude
            frequency *= lacunarity
            amplitude *= gain
        }
        
        return total / maxValue
    }
}

// MARK: - L-System Engine

/// Represents an L-system rule that maps a predecessor character to a successor string.
struct LSystemRule: Equatable {
    let predecessor: Character
    let successor: String
    
    init(predecessor: Character, successor: String) {
        self.predecessor = predecessor
        self.successor = successor
    }
}

/// Grammar compiler that expands an initial axiom into an expanded command string based on production rules.
struct LSystemGrammar {
    let axiom: String
    let rules: [Character: String]
    
    init(axiom: String, rules: [LSystemRule]) {
        self.axiom = axiom
        
        var tempRules = [Character: String]()
        for rule in rules {
            tempRules[rule.predecessor] = rule.successor
        }
        self.rules = tempRules
    }
    
    /// Expands the axiom iteratively.
    /// - Parameter iterations: The recursion level.
    /// - Returns: The expanded command string containing turtle instructions.
    func expand(iterations: Int) -> String {
        var currentString = axiom
        
        for _ in 0..<iterations {
            var nextString = ""
            for char in currentString {
                if let replacement = rules[char] {
                    nextString += replacement
                } else {
                    nextString.append(char)
                }
            }
            currentString = nextString
            
            // Safety cap: prevent exponential explosion from breaking memory limits
            if currentString.count > 15000 {
                currentString = String(currentString.prefix(15000))
                break
            }
        }
        
        return currentString
    }
}

/// State data structure representing the turtle's location and direction in 3D space.
struct TurtleState {
    var position: SIMD3<Float>
    var orientation: simd_quatf
    var radius: Float
    var length: Float
    var depth: Int
    
    init(position: SIMD3<Float>, orientation: simd_quatf, radius: Float, length: Float, depth: Int) {
        self.position = position
        self.orientation = orientation
        self.radius = radius
        self.length = length
        self.depth = depth
    }
}

/// A line segment tracing a branch from a start position to an end position.
struct BranchSegment {
    let start: SIMD3<Float>
    let end: SIMD3<Float>
    let startRadius: Float
    let endRadius: Float
    let depth: Int
    let stepIndex: Int
}

/// Information describing a leaf node's placement and orientation in the tree canopy.
struct LeafPlacement {
    let position: SIMD3<Float>
    let orientation: simd_quatf
    let scale: SIMD3<Float>
    let depth: Int
}

/// Information describing a flower node's placement and orientation.
struct FlowerPlacement {
    let position: SIMD3<Float>
    let orientation: simd_quatf
    let scale: Float
}

/// Interprets the compiled L-system command string into a collection of 3D branch segments, leaves, and flowers.
class LSystemInterpreter {
    var branchAngle: Float = 25.0 * (.pi / 180.0) // default turn angle (radians)
    var lengthShrinkFactor: Float = 0.85
    var radiusShrinkFactor: Float = 0.78
    
    init() {}
    
    /// Interprets an L-system string into branches, leaves, and flowers.
    /// - Parameters:
    ///   - commands: The L-system string to execute.
    ///   - initialRadius: Starting radius of the trunk.
    ///   - initialLength: Starting length of the trunk.
    ///   - leafProbability: Chance of generating a leaf at attachment points.
    ///   - flowerProbability: Chance of generating a flower at tips.
    ///   - seed: Random seed for stochastic variations.
    /// - Returns: A tuple containing the procedural elements.
    func interpret(
        commands: String,
        initialRadius: Float,
        initialLength: Float,
        leafProbability: Float = 0.85,
        flowerProbability: Float = 0.4,
        seed: UInt64 = 42
    ) -> (branches: [BranchSegment], leaves: [LeafPlacement], flowers: [FlowerPlacement]) {
        var branches = [BranchSegment]()
        var leaves = [LeafPlacement]()
        var flowers = [FlowerPlacement]()
        
        var random = SeededRandom(seed: seed)
        var stack = [TurtleState]()
        
        // Initial state at the tree origin
        var currentState = TurtleState(
            position: SIMD3<Float>(0, 0, 0),
            orientation: simd_quatf(angle: 0, axis: [0, 1, 0]),
            radius: initialRadius,
            length: initialLength,
            depth: 0
        )
        
        var stepIndex = 0
        
        for char in commands {
            switch char {
            case "F", "G":
                // Draw branch forward: Calculate the endpoint
                let upDirection = SIMD3<Float>(0, 1, 0)
                let forwardVector = currentState.orientation.act(upDirection) * currentState.length
                let endPos = currentState.position + forwardVector
                
                // Radius tapers towards the branch tips
                let nextRadius = currentState.radius * radiusShrinkFactor
                
                let segment = BranchSegment(
                    start: currentState.position,
                    end: endPos,
                    startRadius: currentState.radius,
                    endRadius: nextRadius,
                    depth: currentState.depth,
                    stepIndex: stepIndex
                )
                branches.append(segment)
                
                // Update position for next step
                currentState.position = endPos
                currentState.radius = nextRadius
                currentState.length *= lengthShrinkFactor
                stepIndex += 1
                
            case "f":
                // Move forward without drawing a branch segment
                let upDirection = SIMD3<Float>(0, 1, 0)
                let forwardVector = currentState.orientation.act(upDirection) * currentState.length
                currentState.position += forwardVector
                currentState.length *= lengthShrinkFactor
                
            case "+":
                // Turn right (roll around Z axis)
                let jitter = random.nextFloat(min: -0.05, max: 0.05)
                let rot = simd_quatf(angle: branchAngle + jitter, axis: SIMD3<Float>(0, 0, 1))
                currentState.orientation = currentState.orientation * rot
                
            case "-":
                // Turn left (roll around Z axis)
                let jitter = random.nextFloat(min: -0.05, max: 0.05)
                let rot = simd_quatf(angle: -(branchAngle + jitter), axis: SIMD3<Float>(0, 0, 1))
                currentState.orientation = currentState.orientation * rot
                
            case "&":
                // Pitch up (pitch around X axis)
                let jitter = random.nextFloat(min: -0.05, max: 0.05)
                let rot = simd_quatf(angle: branchAngle + jitter, axis: SIMD3<Float>(1, 0, 0))
                currentState.orientation = currentState.orientation * rot
                
            case "^":
                // Pitch down (pitch around X axis)
                let jitter = random.nextFloat(min: -0.05, max: 0.05)
                let rot = simd_quatf(angle: -(branchAngle + jitter), axis: SIMD3<Float>(1, 0, 0))
                currentState.orientation = currentState.orientation * rot
                
            case "\\":
                // Yaw right (yaw around Y axis)
                let jitter = random.nextFloat(min: -0.05, max: 0.05)
                let rot = simd_quatf(angle: branchAngle + jitter, axis: SIMD3<Float>(0, 1, 0))
                currentState.orientation = currentState.orientation * rot
                
            case "/":
                // Yaw left (yaw around Y axis)
                let jitter = random.nextFloat(min: -0.05, max: 0.05)
                let rot = simd_quatf(angle: -(branchAngle + jitter), axis: SIMD3<Float>(0, 1, 0))
                currentState.orientation = currentState.orientation * rot
                
            case "|":
                // Reverse direction (turn 180 degrees)
                let rot = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
                currentState.orientation = currentState.orientation * rot
                
            case "[":
                // Push current state to stack
                let stateCopy = currentState
                stack.append(stateCopy)
                currentState.depth += 1
                
            case "]":
                // Pop state from stack, effectively retreating back down a fork
                if !stack.isEmpty {
                    currentState = stack.removeLast()
                }
                
            case "L":
                // Attach a leaf at the current branch joint
                if random.nextFloat(min: 0, max: 1) < leafProbability {
                    // Random rotation of the leaf blade around its stem axis
                    let leafPitch = random.nextFloat(min: -0.3, max: 0.1)
                    let leafRoll = random.nextFloat(min: -0.8, max: 0.8)
                    let leafYaw = random.nextFloat(min: 0, max: 2.0 * .pi)
                    
                    let localRot = simd_quatf(angle: leafPitch, axis: [1, 0, 0])
                                 * simd_quatf(angle: leafRoll, axis: [0, 0, 1])
                                 * simd_quatf(angle: leafYaw, axis: [0, 1, 0])
                    
                    let finalOrientation = currentState.orientation * localRot
                    let scaleX = random.nextFloat(min: 0.8, max: 1.2)
                    let scaleY = random.nextFloat(min: 0.9, max: 1.1)
                    let scaleZ = random.nextFloat(min: 0.8, max: 1.2)
                    
                    let leaf = LeafPlacement(
                        position: currentState.position,
                        orientation: finalOrientation,
                        scale: SIMD3<Float>(scaleX, scaleY, scaleZ),
                        depth: currentState.depth
                    )
                    leaves.append(leaf)
                }
                
            case "P":
                // Attach a flower node at branch tip
                if random.nextFloat(min: 0, max: 1) < flowerProbability {
                    let flowerScale = random.nextFloat(min: 0.75, max: 1.15)
                    let flower = FlowerPlacement(
                        position: currentState.position,
                        orientation: currentState.orientation,
                        scale: flowerScale
                    )
                    flowers.append(flower)
                }
                
            default:
                break
            }
        }
        
        return (branches, leaves, flowers)
    }
}

// MARK: - Fibonacci Distribution (Phyllotaxis)

/// Computes Fibonacci spirals to distribute elements like leaves, branches, or petals evenly
/// around surfaces without overlaps.
struct FibonacciDistributor {
    /// The Golden Angle in radians (~137.5 degrees)
    static let goldenAngle: Float = 137.50776 * (.pi / 180.0)
    
    /// Distributes points along a cylinder segment using the Golden Angle spiral.
    /// This mimics branch branching nodes and leaf stems growing around a trunk.
    /// - Parameters:
    ///   - count: Number of points to generate.
    ///   - radius: Cylinder radius.
    ///   - height: Cylinder height.
    /// - Returns: Array of local offsets and orientations.
    static func distributeOnCylinder(
        count: Int,
        radius: Float,
        height: Float
    ) -> [(position: SIMD3<Float>, orientation: simd_quatf)] {
        var points = [(position: SIMD3<Float>, orientation: simd_quatf)]()
        guard count > 0 else { return points }
        
        for i in 0..<count {
            let t = Float(i) / Float(count)
            let y = t * height
            let theta = Float(i) * goldenAngle
            
            let x = radius * cos(theta)
            let z = radius * sin(theta)
            
            let pos = SIMD3<Float>(x, y, z)
            
            // Orientation pointing outward from the cylinder center axis
            let outwardDir = simd_normalize(SIMD3<Float>(x, 0, z))
            let yawRot = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: outwardDir)
            
            // Add a slight upward tilt (pitch) of 15 degrees
            let pitchRot = simd_quatf(angle: -15.0 * (.pi / 180.0), axis: SIMD3<Float>(1, 0, 0))
            
            points.append((pos, yawRot * pitchRot))
        }
        
        return points
    }
    
    /// Distributes points over a hemisphere surface using Fibonacci mapping.
    /// Used to locate petal or flower placements in dense floral heads or dome canopies.
    static func distributeOnSphere(
        count: Int,
        radius: Float
    ) -> [SIMD3<Float>] {
        var points = [SIMD3<Float>]()
        guard count > 0 else { return points }
        
        for i in 0..<count {
            // Mapping index to [0.0, 1.0] spherical distribution
            let offset = 1.0 / Float(count)
            let y = ((Float(i) * offset) - 1.0) + (offset / 2.0)
            
            // Projecting to hemispherical cap only
            let r = sqrt(1.0 - y * y)
            let phi = Float(i) * goldenAngle
            
            let x = cos(phi) * r * radius
            let z = sin(phi) * r * radius
            let projectedY = abs(y) * radius // keep it in upper hemisphere
            
            points.append(SIMD3<Float>(x, projectedY, z))
        }
        
        return points
    }
}

// MARK: - Procedural Geometry Builders

/// Gathers vertex, normal, UV, and index data buffers to construct custom MeshResources.
struct ProceduralMeshBuilder {
    var positions = [SIMD3<Float>]()
    var normals = [SIMD3<Float>]()
    var uvs = [SIMD2<Float>]()
    var indices = [UInt32]()
    
    init() {}
    
    /// Adds a tapered cylinder segment with custom noise displacement, texturing coordinates, and closed caps.
    /// - Parameters:
    ///   - start: Starting position vector.
    ///   - end: Ending position vector.
    ///   - startRadius: Bottom radius.
    ///   - endRadius: Top radius.
    ///   - radialSegments: Resolution of circular cross section.
    ///   - heightSegments: Resolution along length.
    ///   - noiseScale: Strength of random radius distortions (organic bumpiness).
    ///   - noiseFreq: Frequency scale of noise.
    ///   - uvScaleX: Texture horizontal tiling.
    ///   - uvScaleY: Texture vertical tiling.
    mutating func addCylinder(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        startRadius: Float,
        endRadius: Float,
        radialSegments: Int = 12,
        heightSegments: Int = 4,
        noiseScale: Float = 0.015,
        noiseFreq: Float = 10.0,
        uvScaleX: Float = 1.0,
        uvScaleY: Float = 3.0
    ) {
        let baseIndex = UInt32(positions.count)
        let direction = end - start
        let length = simd_length(direction)
        guard length > 0.0001 else { return }
        
        let dir = simd_normalize(direction)
        
        // Compute orientation to align cylinder (which points along Y-axis natively) with the direction vector
        let rot = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: dir)
        
        // 1. Generate cylinder vertices along height segments
        for h in 0...heightSegments {
            let t = Float(h) / Float(heightSegments)
            let center = start + t * direction
            let radius = startRadius + t * (endRadius - startRadius)
            
            for rSeg in 0...radialSegments {
                let angleFraction = Float(rSeg) / Float(radialSegments)
                let angle = angleFraction * 2.0 * .pi
                
                let cosAngle = cos(angle)
                let sinAngle = sin(angle)
                
                // Add organic noise displacement
                let worldPosOnUnitCylinder = center + rot.act(SIMD3<Float>(cosAngle, 0, sinAngle))
                let noiseVal = FractalNoise.fbm(p: worldPosOnUnitCylinder * noiseFreq, octaves: 2) * noiseScale
                let adjustedRadius = max(0.002, radius + noiseVal)
                
                let localPos = SIMD3<Float>(adjustedRadius * cosAngle, 0, adjustedRadius * sinAngle)
                let worldPos = center + rot.act(localPos)
                
                // Normal direction perpendicular to the cylinder side surface
                let localNorm = SIMD3<Float>(cosAngle, 0, sinAngle)
                let worldNorm = simd_normalize(rot.act(localNorm))
                
                positions.append(worldPos)
                normals.append(worldNorm)
                uvs.append(SIMD2<Float>(angleFraction * uvScaleX, t * length * uvScaleY))
            }
        }
        
        // 2. Generate indices for cylinder side quads
        let rowVerticesCount = UInt32(radialSegments + 1)
        for h in 0..<heightSegments {
            for rSeg in 0..<radialSegments {
                let i0 = baseIndex + UInt32(h) * rowVerticesCount + UInt32(rSeg)
                let i1 = i0 + 1
                let i2 = i0 + rowVerticesCount
                let i3 = i2 + 1
                
                // Triangle 1
                indices.append(i0)
                indices.append(i2)
                indices.append(i1)
                
                // Triangle 2
                indices.append(i1)
                indices.append(i2)
                indices.append(i3)
            }
        }
        
        // 3. Bottom cap geometry
        if startRadius > 0.001 {
            let capCenterIdx = UInt32(positions.count)
            positions.append(start)
            normals.append(-dir)
            uvs.append(SIMD2<Float>(0.5, 0.5))
            
            let capRingStartIdx = UInt32(positions.count)
            for rSeg in 0...radialSegments {
                let angleFraction = Float(rSeg) / Float(radialSegments)
                let angle = angleFraction * 2.0 * .pi
                let localPos = SIMD3<Float>(startRadius * cos(angle), 0, startRadius * sin(angle))
                let worldPos = start + rot.act(localPos)
                
                positions.append(worldPos)
                normals.append(-dir)
                uvs.append(SIMD2<Float>(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))
            }
            
            for rSeg in 0..<radialSegments {
                indices.append(capCenterIdx)
                indices.append(capRingStartIdx + UInt32(rSeg) + 1)
                indices.append(capRingStartIdx + UInt32(rSeg))
            }
        }
        
        // 4. Top cap geometry
        if endRadius > 0.001 {
            let capCenterIdx = UInt32(positions.count)
            positions.append(end)
            normals.append(dir)
            uvs.append(SIMD2<Float>(0.5, 0.5))
            
            let capRingStartIdx = UInt32(positions.count)
            for rSeg in 0...radialSegments {
                let angleFraction = Float(rSeg) / Float(radialSegments)
                let angle = angleFraction * 2.0 * .pi
                let localPos = SIMD3<Float>(endRadius * cos(angle), 0, endRadius * sin(angle))
                let worldPos = end + rot.act(localPos)
                
                positions.append(worldPos)
                normals.append(dir)
                uvs.append(SIMD2<Float>(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))
            }
            
            for rSeg in 0..<radialSegments {
                indices.append(capCenterIdx)
                indices.append(capRingStartIdx + UInt32(rSeg))
                indices.append(capRingStartIdx + UInt32(rSeg) + 1)
            }
        }
    }
    
    /// Extrudes a flat leaf blade geometry with central veins and curves.
    /// - Parameters:
    ///   - length: Leaf size along Z.
    ///   - width: Maximum lateral width.
    ///   - curve: Curve droop.
    ///   - segmentsX: Horizontal grid segments.
    ///   - segmentsZ: Longitudinal grid segments.
    mutating func addLeaf(
        length: Float,
        width: Float,
        curve: Float = 0.15,
        segmentsX: Int = 4,
        segmentsZ: Int = 8
    ) {
        let baseIndex = UInt32(positions.count)
        
        for zSeg in 0...segmentsZ {
            let tz = Float(zSeg) / Float(segmentsZ)
            let z = tz * length
            
            // Curve the leaf downward towards its tip
            let yCurve = -curve * (tz * tz)
            
            // Envelope function mapping width: base(0.0) -> max(middle) -> tip(0.0)
            let currentMaxWidth = width * sin(tz * .pi)
            
            for xSeg in 0...segmentsX {
                let tx = Float(xSeg) / Float(segmentsX)
                let u = tx
                let x = (tx - 0.5) * currentMaxWidth
                
                // Add vein elevation at center
                let distToVein = abs(tx - 0.5) * 2.0
                let veinElevation = (1.0 - distToVein) * (width * 0.08)
                
                let pos = SIMD3<Float>(x, yCurve + veinElevation, z)
                positions.append(pos)
                
                // Calculate normal
                let normalSlope = -4.0 * (tx - 0.5) * (width / length)
                let norm = simd_normalize(SIMD3<Float>(normalSlope, 1.0, 0.0))
                normals.append(norm)
                
                uvs.append(SIMD2<Float>(u, tz))
            }
        }
        
        let rowVerticesCount = UInt32(segmentsX + 1)
        for zSeg in 0..<segmentsZ {
            for xSeg in 0..<segmentsX {
                let i0 = baseIndex + UInt32(zSeg) * rowVerticesCount + UInt32(xSeg)
                let i1 = i0 + 1
                let i2 = i0 + rowVerticesCount
                let i3 = i2 + 1
                
                indices.append(i0)
                indices.append(i2)
                indices.append(i1)
                
                indices.append(i1)
                indices.append(i2)
                indices.append(i3)
            }
        }
    }
    
    /// Compiles compiled vertices data into a RealityKit MeshResource.
    func buildMesh(name: String = "ProceduralMesh") -> MeshResource? {
        guard !positions.isEmpty else { return nil }
        
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.textureCoordinates = MeshBuffer(uvs)
        descriptor.primitives = .triangles(indices)
        
        return try? MeshResource.generate(from: [descriptor])
    }
}

// MARK: - Procedural Texture Renderer (In-Memory Canvas Synthesis)

/// Generates custom wood and bark texture images in memory using CoreGraphics canvas functions.
/// Avoids external bundle asset dependencies, making geometry completely portable and self-contained.
struct HasanaProceduralTextureGenerator {
    
    /// Renders a vertically repeating bark texture image with detailed color blending, noise fibers, and fissures.
    static func generateBarkImage(
        baseColor: UIColor,
        fissureColor: UIColor,
        width: Int = 256,
        height: Int = 256,
        seed: UInt64 = 77
    ) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // 1. Fill base bark tone
            baseColor.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            var random = SeededRandom(seed: seed)
            
            // 2. Draw vertical wood grain fibers
            for _ in 0..<120 {
                let x = CGFloat(random.nextFloat(min: 0, max: Float(width)))
                let y = CGFloat(random.nextFloat(min: 0, max: Float(height)))
                let fiberW = CGFloat(random.nextFloat(min: 1.0, max: 3.5))
                let fiberH = CGFloat(random.nextFloat(min: 30.0, max: 90.0))
                let opacity = CGFloat(random.nextFloat(min: 0.05, max: 0.22))
                
                let tint = fissureColor.withAlphaComponent(opacity)
                tint.setFill()
                
                cgContext.fill(CGRect(x: x, y: y, width: fiberW, height: fiberH))
                
                // Vertical wrap support
                if y + fiberH > CGFloat(height) {
                    cgContext.fill(CGRect(x: x, y: y - CGFloat(height), width: fiberW, height: fiberH))
                }
            }
            
            // 3. Draw vertical fissures/bark cracks
            for _ in 0..<15 {
                let startX = CGFloat(random.nextFloat(min: 0, max: Float(width)))
                let startY = CGFloat(random.nextFloat(min: 0, max: Float(height)))
                let crackLen = CGFloat(random.nextFloat(min: 40, max: 120))
                let crackW = CGFloat(random.nextFloat(min: 1.5, max: 4.0))
                
                cgContext.beginPath()
                cgContext.move(to: CGPoint(x: startX, y: startY))
                
                var currX = startX
                var currY = startY
                let segmentsCount = 6
                
                let segmentH = crackLen / CGFloat(segmentsCount)
                for _ in 0..<segmentsCount {
                    currY += segmentH
                    // Add minor horizontal wiggle to make crack look organic
                    currX += CGFloat(random.nextFloat(min: -3.0, max: 3.0))
                    cgContext.addLine(to: CGPoint(x: currX, y: currY))
                }
                
                cgContext.setLineWidth(crackW)
                fissureColor.withAlphaComponent(0.4).setStroke()
                cgContext.strokePath()
            }
        }
    }
    
    /// Renders a wood cross-section (rings) texture image, useful for caps on branches.
    static func generateWoodRingsImage(
        heartwoodColor: UIColor,
        sapwoodColor: UIColor,
        width: Int = 128,
        height: Int = 128,
        ringsCount: Int = 10,
        seed: UInt64 = 88
    ) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            let center = CGPoint(x: width / 2, y: height / 2)
            let maxRadius = CGFloat(width) * 0.48
            
            // Base sapwood fill
            sapwoodColor.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            var random = SeededRandom(seed: seed)
            
            // Render concentric growth rings
            for ringIndex in (0..<ringsCount).reversed() {
                let t = CGFloat(ringIndex) / CGFloat(ringsCount)
                let radius = maxRadius * t
                
                // Linear interpolation of wood color towards center
                let ringColor = UIColor.blend(from: sapwoodColor, to: heartwoodColor, ratio: 1.0 - t)
                
                cgContext.beginPath()
                
                // Trace circle with small organic radius perturbations
                let resolution = 72
                for i in 0...resolution {
                    let angle = CGFloat(i) * (2.0 * .pi / CGFloat(resolution))
                    let noise = CGFloat(sin(angle * 4.0 + CGFloat(seed)) * 1.5 + cos(angle * 8.0) * 0.8) * t
                    let adjustedRadius = radius + noise
                    
                    let x = center.x + adjustedRadius * cos(angle)
                    let y = center.y + adjustedRadius * sin(angle)
                    
                    if i == 0 {
                        cgContext.move(to: CGPoint(x: x, y: y))
                    } else {
                        cgContext.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                cgContext.closePath()
                ringColor.setFill()
                cgContext.fillPath()
                
                // Ring separator line (dark wood boundary)
                cgContext.beginPath()
                for i in 0...resolution {
                    let angle = CGFloat(i) * (2.0 * .pi / CGFloat(resolution))
                    let noise = CGFloat(sin(angle * 4.0 + CGFloat(seed)) * 1.5 + cos(angle * 8.0) * 0.8) * t
                    let adjustedRadius = radius + noise
                    
                    let x = center.x + adjustedRadius * cos(angle)
                    let y = center.y + adjustedRadius * sin(angle)
                    
                    if i == 0 {
                        cgContext.move(to: CGPoint(x: x, y: y))
                    } else {
                        cgContext.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                cgContext.closePath()
                
                let boundaryColor = heartwoodColor.withAlphaComponent(0.18)
                boundaryColor.setStroke()
                cgContext.setLineWidth(0.8)
                cgContext.strokePath()
            }
            
            // Draw radial cracks extending outward from the center core
            for _ in 0..<3 {
                let angle = CGFloat(random.nextFloat(min: 0, max: Float(2.0 * .pi)))
                let crackLen = maxRadius * CGFloat(random.nextFloat(min: 0.4, max: 0.85))
                
                cgContext.beginPath()
                cgContext.move(to: center)
                
                var currX = center.x
                var currY = center.y
                let steps = 4
                let stepLen = crackLen / CGFloat(steps)
                
                for s in 1...steps {
                    let currentDistance = CGFloat(s) * stepLen
                    // Add micro offsets orthogonal to path angle
                    let wiggle = CGFloat(random.nextFloat(min: -2.0, max: 2.0))
                    
                    currX = center.x + currentDistance * cos(angle) + wiggle * -sin(angle)
                    currY = center.y + currentDistance * sin(angle) + wiggle * cos(angle)
                    cgContext.addLine(to: CGPoint(x: currX, y: currY))
                }
                
                heartwoodColor.withAlphaComponent(0.35).setStroke()
                cgContext.setLineWidth(0.6)
                cgContext.strokePath()
            }
        }
    }
    
    /// Helper helper to compile a UI/CG Image into a RealityKit TextureResource.
    static func makeTextureResource(from image: UIImage, isColor: Bool = true) -> TextureResource? {
        guard let cgImage = image.cgImage else { return nil }
        let semantic: TextureResource.Semantic = isColor ? .color : .raw
        return try? TextureResource.generate(
            from: cgImage,
            options: TextureResource.CreateOptions(semantic: semantic)
        )
    }
}

// MARK: - Color Interpolation Helper

extension UIColor {
    /// Blends two colors together based on a ratio between 0.0 and 1.0.
    static func blend(from color1: UIColor, to color2: UIColor, ratio: CGFloat) -> UIColor {
        let clampedRatio = min(max(ratio, 0.0), 1.0)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 + (r2 - r1) * clampedRatio,
            green: g1 + (g2 - g1) * clampedRatio,
            blue: b1 + (b2 - b1) * clampedRatio,
            alpha: a1 + (a2 - a1) * clampedRatio
        )
    }
}

// MARK: - Botanical Specifications & Preset Configuration

/// Configuration model containing biological presets used to drive the L-system parser,
/// branch thickness, colors, and mesh parameters.
struct TreeBotanicalPreset {
    let name: String
    
    // L-System grammar parameters
    let lSystem: LSystemGrammar
    let branchAngle: Float
    let radiusShrink: Float
    let lengthShrink: Float
    
    // Geometry dimensions
    let baseLength: Float
    let baseRadius: Float
    
    // Leaf mesh parameters
    let leafLength: Float
    let leafWidth: Float
    let leafCurvature: Float
    let leafProbability: Float
    
    // Bark materials
    let barkColor: UIColor
    let barkFissureColor: UIColor
    
    // Foliage materials
    let leafColor: UIColor
    let leafTipColor: UIColor
    
    // Flower configuration
    let flowerProbability: Float
    let flowerColor: UIColor
}

extension TreeBotanicalPreset {
    /// Fetches the preset customized for the given practice ID.
    static func preset(for id: HasanaGardenPracticeID) -> TreeBotanicalPreset {
        switch id {
        case .fajr:
            // Fajr Cedar: Symmetrical, upright, evergreen look. High density needle clusters.
            return TreeBotanicalPreset(
                name: "Fajr Dawn Cedar",
                lSystem: LSystemGrammar(
                    axiom: "F",
                    rules: [
                        LSystemRule(predecessor: "F", successor: "F[&+FL][^-\\FL]\\FL")
                    ]
                ),
                branchAngle: 28.0 * (.pi / 180.0),
                radiusShrink: 0.72,
                lengthShrink: 0.78,
                baseLength: 0.38,
                baseRadius: 0.038,
                leafLength: 0.12,
                leafWidth: 0.03,
                leafCurvature: 0.04,
                leafProbability: 0.90,
                barkColor: UIColor(red: 0.38, green: 0.28, blue: 0.22, alpha: 1.0),
                barkFissureColor: UIColor(red: 0.22, green: 0.15, blue: 0.12, alpha: 1.0),
                leafColor: UIColor(red: 0.18, green: 0.48, blue: 0.28, alpha: 1.0),
                leafTipColor: UIColor(red: 0.28, green: 0.65, blue: 0.38, alpha: 1.0),
                flowerProbability: 0.20,
                flowerColor: UIColor(red: 0.95, green: 0.92, blue: 0.78, alpha: 1.0)
            )
            
        case .dhuhr:
            // Dhuhr Acacia: Wide, flat umbrella-like canopy to provide maximum shade in midday heat.
            return TreeBotanicalPreset(
                name: "Dhuhr Umbrella Acacia",
                lSystem: LSystemGrammar(
                    axiom: "F",
                    rules: [
                        LSystemRule(predecessor: "F", successor: "F[+FL]\\FL[-FL]")
                    ]
                ),
                branchAngle: 36.0 * (.pi / 180.0),
                radiusShrink: 0.75,
                lengthShrink: 0.72,
                baseLength: 0.35,
                baseRadius: 0.045,
                leafLength: 0.09,
                leafWidth: 0.045,
                leafCurvature: 0.08,
                leafProbability: 0.85,
                barkColor: UIColor(red: 0.44, green: 0.32, blue: 0.24, alpha: 1.0),
                barkFissureColor: UIColor(red: 0.26, green: 0.18, blue: 0.14, alpha: 1.0),
                leafColor: UIColor(red: 0.12, green: 0.42, blue: 0.18, alpha: 1.0),
                leafTipColor: UIColor(red: 0.32, green: 0.62, blue: 0.28, alpha: 1.0),
                flowerProbability: 0.50,
                flowerColor: UIColor(red: 0.98, green: 0.88, blue: 0.12, alpha: 1.0)
            )
            
        case .asr:
            // Asr Aspen: Slender, tall pyramidal tree showing beautiful golden-yellow autumn foliage.
            return TreeBotanicalPreset(
                name: "Asr Golden Aspen",
                lSystem: LSystemGrammar(
                    axiom: "F",
                    rules: [
                        LSystemRule(predecessor: "F", successor: "F[+&FL][-\\FL]F")
                    ]
                ),
                branchAngle: 22.0 * (.pi / 180.0),
                radiusShrink: 0.70,
                lengthShrink: 0.82,
                baseLength: 0.44,
                baseRadius: 0.032,
                leafLength: 0.07,
                leafWidth: 0.06,
                leafCurvature: 0.12,
                leafProbability: 0.88,
                barkColor: UIColor(red: 0.78, green: 0.76, blue: 0.72, alpha: 1.0), // silver birch style bark
                barkFissureColor: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0),
                leafColor: UIColor(red: 0.92, green: 0.62, blue: 0.12, alpha: 1.0), // Golden yellow
                leafTipColor: UIColor(red: 0.98, green: 0.76, blue: 0.22, alpha: 1.0),
                flowerProbability: 0.10,
                flowerColor: UIColor(red: 0.88, green: 0.45, blue: 0.08, alpha: 1.0)
            )
            
        case .maghrib:
            // Maghrib Willow: Elegant weeping branches drooping down, carrying crimson-tinted leaves.
            return TreeBotanicalPreset(
                name: "Maghrib Crimson Willow",
                lSystem: LSystemGrammar(
                    axiom: "F",
                    rules: [
                        LSystemRule(predecessor: "F", successor: "F[^&FL][+FL][-FL]")
                    ]
                ),
                branchAngle: 26.0 * (.pi / 180.0),
                radiusShrink: 0.78,
                lengthShrink: 0.85,
                baseLength: 0.42,
                baseRadius: 0.036,
                leafLength: 0.15,
                leafWidth: 0.024,
                leafCurvature: 0.20,
                leafProbability: 0.92,
                barkColor: UIColor(red: 0.32, green: 0.26, blue: 0.22, alpha: 1.0),
                barkFissureColor: UIColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1.0),
                leafColor: UIColor(red: 0.65, green: 0.12, blue: 0.18, alpha: 1.0), // Crimson/Sunset Red
                leafTipColor: UIColor(red: 0.82, green: 0.28, blue: 0.38, alpha: 1.0),
                flowerProbability: 0.40,
                flowerColor: UIColor(red: 0.92, green: 0.38, blue: 0.52, alpha: 1.0)
            )
            
        case .isha:
            // Isha Pine: Stately dark blue-green conifer with starry white blossoms.
            return TreeBotanicalPreset(
                name: "Isha Star Pine",
                lSystem: LSystemGrammar(
                    axiom: "F",
                    rules: [
                        LSystemRule(predecessor: "F", successor: "F[+FL][-FL][&FL]")
                    ]
                ),
                branchAngle: 32.0 * (.pi / 180.0),
                radiusShrink: 0.74,
                lengthShrink: 0.76,
                baseLength: 0.40,
                baseRadius: 0.040,
                leafLength: 0.10,
                leafWidth: 0.035,
                leafCurvature: 0.06,
                leafProbability: 0.88,
                barkColor: UIColor(red: 0.28, green: 0.22, blue: 0.20, alpha: 1.0),
                barkFissureColor: UIColor(red: 0.12, green: 0.08, blue: 0.06, alpha: 1.0),
                leafColor: UIColor(red: 0.10, green: 0.24, blue: 0.36, alpha: 1.0), // Deep blue-green
                leafTipColor: UIColor(red: 0.18, green: 0.38, blue: 0.54, alpha: 1.0),
                flowerProbability: 0.70,
                flowerColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // Star-like white
            )
            
        case .quran, .adhkar, .witr:
            // Non-tree plants also get specialized fallback configurations if processed by the tree engine.
            return TreeBotanicalPreset(
                name: "Garden Herbaceous Shrub",
                lSystem: LSystemGrammar(
                    axiom: "F",
                    rules: [
                        LSystemRule(predecessor: "F", successor: "F[+L][-L]")
                    ]
                ),
                branchAngle: 30.0 * (.pi / 180.0),
                radiusShrink: 0.70,
                lengthShrink: 0.75,
                baseLength: 0.24,
                baseRadius: 0.016,
                leafLength: 0.08,
                leafWidth: 0.05,
                leafCurvature: 0.10,
                leafProbability: 0.95,
                barkColor: UIColor(red: 0.32, green: 0.52, blue: 0.28, alpha: 1.0),
                barkFissureColor: UIColor(red: 0.20, green: 0.38, blue: 0.18, alpha: 1.0),
                leafColor: UIColor(red: 0.18, green: 0.58, blue: 0.28, alpha: 1.0),
                leafTipColor: UIColor(red: 0.32, green: 0.76, blue: 0.42, alpha: 1.0),
                flowerProbability: 0.80,
                flowerColor: UIColor(red: 0.96, green: 0.48, blue: 0.64, alpha: 1.0)
            )
        }
    }
}

// MARK: - Hasana Garden Tree Factory

/// The master geometry builder that integrates all the procedural sub-components.
/// Evaluates L-systems, runs Fibonacci distribution math, constructs custom meshes and materials,
/// and returns a final 3D RealityKit Entity ready for the ARView garden rendering pipeline.
struct HasanaGardenTreeGeometry {
    
    /// Generates the complete 3D Entity representation of a practice tree/plant based on its state.
    /// - Parameters:
    ///   - state: The current practice state containing progress, growth stage, and status.
    /// - Returns: A fully configured Entity representing the tree.
    static func generateEntity(for state: HasanaGardenPracticeState) -> Entity {
        let root = Entity()
        
        let growthStage = state.progress.growthStage
        let practiceID = state.practice.id
        
        // Let seed stages render as a simple emerging bud/seed to avoid complex calculation
        if growthStage == .seed {
            buildSeedModel(for: state, in: root)
            return root
        }
        
        // Fetch botanical parameters
        let preset = TreeBotanicalPreset.preset(for: practiceID)
        
        // Determine L-system depth and scaling based on growth stage
        let iterations: Int
        let sizeMultiplier: Float
        switch growthStage {
        case .seed:
            iterations = 0
            sizeMultiplier = 0.2
        case .sprout:
            iterations = 1
            sizeMultiplier = 0.45
        case .young:
            iterations = 2
            sizeMultiplier = 0.70
        case .mature:
            iterations = 3
            sizeMultiplier = 0.92
        case .flowering:
            iterations = 3
            sizeMultiplier = 1.0
        }
        
        // Deterministic organic variation seed
        let totalTendedDays = state.progress.totalTendedDays
        let isTended = state.isTendedToday
        let isDormant = state.isDormant
        let seed = UInt64(abs(practiceID.hashValue) &+ totalTendedDays &+ (isTended ? 1 : 0))
        
        // 1. Expand the L-system grammar and interpret segments
        let expandedString = preset.lSystem.expand(iterations: iterations)
        
        let interpreter = LSystemInterpreter()
        interpreter.branchAngle = preset.branchAngle
        interpreter.radiusShrinkFactor = preset.radiusShrink
        interpreter.lengthShrinkFactor = preset.lengthShrink
        
        let lengthVal = preset.baseLength * sizeMultiplier
        let radiusVal = preset.baseRadius * sizeMultiplier
        
        // Evaluate the L-system string to extract coordinates
        let leafProb = preset.leafProbability
        let flowerProb = growthStage == .flowering ? preset.flowerProbability : 0.0
        
        let parsed = interpreter.interpret(
            commands: expandedString,
            initialRadius: radiusVal,
            initialLength: lengthVal,
            leafProbability: leafProb,
            flowerProbability: flowerProb,
            seed: seed
        )
        
        // Apply dormant wilt: bend branch vectors slightly downward and droop leaves
        var processedBranches = parsed.branches
        if isDormant && !isTended {
            // Apply a slight gravity bend (droop) to branches far from the trunk base
            processedBranches = parsed.branches.map { seg in
                let gravityOffset = SIMD3<Float>(0, -0.04 * (Float(seg.depth) * 0.5 + 0.5), 0)
                let adjustedEnd = seg.end + gravityOffset
                return BranchSegment(
                    start: seg.start,
                    end: adjustedEnd,
                    startRadius: seg.startRadius * 0.9,
                    endRadius: seg.endRadius * 0.9,
                    depth: seg.depth,
                    stepIndex: seg.stepIndex
                )
            }
        }
        
        // 2. Generate Bark mesh for all branches
        var barkBuilder = ProceduralMeshBuilder()
        for branch in processedBranches {
            barkBuilder.addCylinder(
                from: branch.start,
                to: branch.end,
                startRadius: branch.startRadius,
                endRadius: branch.endRadius,
                radialSegments: 10,
                heightSegments: 3,
                noiseScale: radiusVal * 0.12,
                noiseFreq: 12.0
            )
        }
        
        // 3. Create Bark texture & material
        let (barkMat, leafMat) = createMaterials(
            preset: preset,
            seed: seed,
            isTended: isTended,
            isDormant: isDormant
        )
        
        // Build the combined branch ModelEntity
        if let barkMesh = barkBuilder.buildMesh(name: "TreeTrunkAndBranches") {
            let trunkEntity = ModelEntity(mesh: barkMesh, materials: [barkMat])
            trunkEntity.name = "practice:\(practiceID.rawValue)"
            root.addChild(trunkEntity)
        }
        
        // 4. Generate & attach Leaf models
        if !parsed.leaves.isEmpty {
            // Build a single combined leaf mesh for optimal performance
            var leafBuilder = ProceduralMeshBuilder()
            
            for leaf in parsed.leaves {
                let leafGroup = Entity()
                leafGroup.position = leaf.position
                leafGroup.orientation = leaf.orientation
                
                // Add leaf to a localized builder
                var localLeafBuilder = ProceduralMeshBuilder()
                let length = preset.leafLength * leaf.scale.z * sizeMultiplier
                let width = preset.leafWidth * leaf.scale.x * sizeMultiplier
                
                // Dormant leaves droop further downwards
                let curvature = (isDormant && !isTended) ? preset.leafCurvature * 2.2 : preset.leafCurvature
                
                localLeafBuilder.addLeaf(
                    length: length,
                    width: width,
                    curve: curvature
                )
                
                if let leafMesh = localLeafBuilder.buildMesh(name: "LeafMesh") {
                    let leafModel = ModelEntity(mesh: leafMesh, materials: [leafMat])
                    leafModel.name = "practice:\(practiceID.rawValue)"
                    leafModel.position = leaf.position
                    leafModel.orientation = leaf.orientation
                    
                    // Attach individual leaf model directly to aggregate node
                    root.addChild(leafModel)
                }
            }
        }
        
        // 5. Generate & attach flower models at branch endpoints (if in flowering stage)
        if growthStage == .flowering && !parsed.flowers.isEmpty {
            let flowerCount = min(parsed.flowers.count, 6) // limit flower count to keep visual clean
            for i in 0..<flowerCount {
                let flower = parsed.flowers[i]
                
                let flowerGroup = Entity()
                flowerGroup.position = flower.position
                flowerGroup.orientation = flower.orientation
                
                buildFlowerModel(
                    preset: preset,
                    scale: flower.scale * sizeMultiplier,
                    isDormant: isDormant && !isTended,
                    in: flowerGroup,
                    practiceID: practiceID
                )
                
                root.addChild(flowerGroup)
            }
        }
        
        return root
    }
    
    // MARK: - Specialized Sub-Model Builders
    
    /// Constructs a simple seedling model for the initial sprout stages.
    private static func buildSeedModel(for state: HasanaGardenPracticeState, in root: Entity) {
        let practiceID = state.practice.id
        let color = TreeBotanicalPreset.preset(for: practiceID).leafColor
        let isDormant = state.isDormant && !state.isTendedToday
        
        // Mute seed color when dormant
        let adjustedColor = isDormant ? UIColor.blend(from: color, to: UIColor.lightGray, ratio: 0.6) : color
        let material = SimpleMaterial(color: adjustedColor, roughness: 0.8, isMetallic: false)
        
        // Draw a tiny seedling soil mound
        let soilMound = ModelEntity(
            mesh: .generateSphere(radius: 0.05),
            materials: [SimpleMaterial(color: UIColor(red: 0.30, green: 0.22, blue: 0.16, alpha: 1.0), roughness: 0.9, isMetallic: false)]
        )
        soilMound.name = "practice:\(practiceID.rawValue)"
        soilMound.scale = SIMD3<Float>(1.2, 0.4, 1.2)
        root.addChild(soilMound)
        
        // Tiny emerging seedling leaf tip
        let sprout = ModelEntity(
            mesh: .generateSphere(radius: 0.024),
            materials: [material]
        )
        sprout.name = "practice:\(practiceID.rawValue)"
        sprout.position = SIMD3<Float>(0, 0.025, 0)
        sprout.scale = SIMD3<Float>(1.0, 1.6, 0.5)
        // Angle tip outward
        sprout.orientation = simd_quatf(angle: 0.22, axis: [0, 0, 1])
        root.addChild(sprout)
    }
    
    /// Assembles a procedurally generated flower with a center disc and radiating petals.
    private static func buildFlowerModel(
        preset: TreeBotanicalPreset,
        scale: Float,
        isDormant: Bool,
        in root: Entity,
        practiceID: HasanaGardenPracticeID
    ) {
        // 1. Flower center (disc/receptacle)
        let centerColor = isDormant ? UIColor.lightGray : UIColor(red: 0.98, green: 0.85, blue: 0.12, alpha: 1.0)
        let centerMaterial = SimpleMaterial(color: centerColor, roughness: 0.75, isMetallic: false)
        
        let centerMesh = MeshResource.generateSphere(radius: 0.038 * scale)
        let centerModel = ModelEntity(mesh: centerMesh, materials: [centerMaterial])
        centerModel.name = "practice:\(practiceID.rawValue)"
        centerModel.scale = SIMD3<Float>(1.0, 0.5, 1.0) // squashed dome
        root.addChild(centerModel)
        
        // 2. Petals radiating around center using Fibonacci spiral phyllotaxis
        let petalsCount = 8
        let petalColor = isDormant ? UIColor.blend(from: preset.flowerColor, to: UIColor.lightGray, ratio: 0.5) : preset.flowerColor
        let petalMaterial = SimpleMaterial(color: petalColor.withAlphaComponent(0.9), roughness: 0.6, isMetallic: false)
        
        let petalLength = 0.065 * scale
        let petalWidth = 0.032 * scale
        
        for i in 0..<petalsCount {
            let angle = (Float(i) / Float(petalsCount)) * 2.0 * .pi
            
            // Generate leaf-like petal mesh
            var petalBuilder = ProceduralMeshBuilder()
            petalBuilder.addLeaf(
                length: petalLength,
                width: petalWidth,
                curve: isDormant ? 0.35 : 0.08
            )
            
            if let petalMesh = petalBuilder.buildMesh(name: "PetalMesh") {
                let petalModel = ModelEntity(mesh: petalMesh, materials: [petalMaterial])
                petalModel.name = "practice:\(practiceID.rawValue)"
                
                // Position offset outwards from center
                let rad: Float = 0.024 * scale
                let offset = SIMD3<Float>(rad * cos(angle), 0, rad * sin(angle))
                petalModel.position = offset
                
                // Rotations: point petal outward and tilt up/down
                let yawRot = simd_quatf(angle: angle - .pi / 2.0, axis: [0, 1, 0])
                let pitchAngle: Float = isDormant ? -0.45 : 0.12 // wilt down if dormant
                let pitchRot = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
                
                petalModel.orientation = yawRot * pitchRot
                root.addChild(petalModel)
            }
        }
    }
    
    /// Compiles the procedural materials for bark and foliage with appropriate textures and color states.
    private static func createMaterials(
        preset: TreeBotanicalPreset,
        seed: UInt64,
        isTended: Bool,
        isDormant: Bool
    ) -> (barkMat: SimpleMaterial, leafMat: SimpleMaterial) {
        
        // Define color states
        let targetBarkColor: UIColor
        let targetFissureColor: UIColor
        let targetLeafColor: UIColor
        let targetLeafTipColor: UIColor
        
        if isDormant && !isTended {
            // Dormant plants get desaturated, greyed tones (gentle resting state)
            targetBarkColor = UIColor.blend(from: preset.barkColor, to: UIColor(red: 0.52, green: 0.52, blue: 0.56, alpha: 1.0), ratio: 0.58)
            targetFissureColor = UIColor.blend(from: preset.barkFissureColor, to: UIColor(red: 0.38, green: 0.38, blue: 0.40, alpha: 1.0), ratio: 0.58)
            
            let dormantGreyGreen = UIColor(red: 0.42, green: 0.46, blue: 0.44, alpha: 0.52)
            targetLeafColor = UIColor.blend(from: preset.leafColor, to: dormantGreyGreen, ratio: 0.72)
            targetLeafTipColor = UIColor.blend(from: preset.leafTipColor, to: dormantGreyGreen, ratio: 0.72)
        } else {
            // Active plants get bright vibrant colors
            targetBarkColor = preset.barkColor
            targetFissureColor = preset.barkFissureColor
            targetLeafColor = preset.leafColor
            targetLeafTipColor = preset.leafTipColor
        }
        
        // 1. Generate procedural Bark texture
        let barkImage = HasanaProceduralTextureGenerator.generateBarkImage(
            baseColor: targetBarkColor,
            fissureColor: targetFissureColor,
            width: 256,
            height: 256,
            seed: seed
        )
        
        var barkMat = SimpleMaterial(color: targetBarkColor, roughness: 0.88, isMetallic: false)
        if let barkTex = HasanaProceduralTextureGenerator.makeTextureResource(from: barkImage, isColor: true) {
            barkMat.color = SimpleMaterial.BaseColor(tint: .white, texture: .init(barkTex))
        }
        
        // 2. Generate procedural Leaf texture (gradient from base to tip)
        let leafImage = generateLeafGradientImage(
            baseColor: targetLeafColor,
            tipColor: targetLeafTipColor,
            width: 64,
            height: 128
        )
        
        var leafMat = SimpleMaterial(color: targetLeafColor, roughness: 0.65, isMetallic: false)
        if let leafTex = HasanaProceduralTextureGenerator.makeTextureResource(from: leafImage, isColor: true) {
            leafMat.color = SimpleMaterial.BaseColor(tint: .white, texture: .init(leafTex))
        }
        
        return (barkMat, leafMat)
    }
    
    /// Generates a simple gradient image representing a leaf's coloring from base stem to leaf tip.
    private static func generateLeafGradientImage(
        baseColor: UIColor,
        tipColor: UIColor,
        width: Int,
        height: Int
    ) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [baseColor.cgColor, tipColor.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                let startPoint = CGPoint(x: width / 2, y: height) // base
                let endPoint = CGPoint(x: width / 2, y: 0)      // tip
                
                cgContext.drawLinearGradient(
                    gradient,
                    start: startPoint,
                    end: endPoint,
                    options: []
                )
            }
        }
    }
}
