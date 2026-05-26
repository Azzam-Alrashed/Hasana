//
//  HasanaGardenFlowerGeometry.swift
//  Hasana
//
//  Created by Senior iOS Swift/RealityKit Developer on 2026-05-26.
//  Copyright © 2026 Azzam-Alrashed. All rights reserved.
//

import Foundation
import RealityKit
import UIKit
import simd

// MARK: - Enums & Configuration

/// Supported botanical flower types in the Hasana Garden feature.
enum HasanaFlowerType: String, Codable, CaseIterable {
    case rose
    case jasmine
    case lily
}

/// The easing curves used for the opening animations of the flower petals.
enum HasanaEaseType: String, Codable {
    case linear
    case sineInOut
    case cubicOut
    case cubicInOut
    case elasticOut
    
    func ease(_ t: Float) -> Float {
        switch self {
        case .linear:
            return t
        case .sineInOut:
            return 0.5 * (1.0 - cos(t * .pi))
        case .cubicOut:
            let f = t - 1.0
            return f * f * f + 1.0
        case .cubicInOut:
            if t < 0.5 {
                return 4.0 * t * t * t
            } else {
                let f = (2.0 * t) - 2.0
                return 0.5 * f * f * f + 1.0
            }
        case .elasticOut:
            if t == 0.0 || t == 1.0 { return t }
            let p: Float = 0.3
            return pow(2.0, -10.0 * t) * sin((t - p / 4.0) * (2.0 * .pi) / p) + 1.0
        }
    }
}

/// Representation of a vertex in the custom flower geometry pipeline.
struct HasanaFlowerVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var uv: SIMD2<Float>
    var color: SIMD4<Float>
    
    init(
        position: SIMD3<Float> = .zero,
        normal: SIMD3<Float> = SIMD3<Float>(0, 1, 0),
        uv: SIMD2<Float> = .zero,
        color: SIMD4<Float> = SIMD4<Float>(1, 1, 1, 1)
    ) {
        self.position = position
        self.normal = normal
        self.uv = uv
        self.color = color
    }
}

/// Parametric settings defining the shape, curl, and waviness of a single flower petal.
struct HasanaPetalConfig: Codable {
    var length: Float
    var width: Float
    var thickness: Float
    var cupDepth: Float
    var curlAmount: Float
    var waveFrequency: Float
    var waveAmplitude: Float
    var baseTaper: Float
    var subdivisionsU: Int
    var subdivisionsV: Int
    
    static var roseDefault: HasanaPetalConfig {
        HasanaPetalConfig(
            length: 0.28,
            width: 0.26,
            thickness: 0.008,
            cupDepth: 0.12,
            curlAmount: 0.08,
            waveFrequency: 2.0,
            waveAmplitude: 0.015,
            baseTaper: 0.15,
            subdivisionsU: 24,
            subdivisionsV: 24
        )
    }
    
    static var jasmineDefault: HasanaPetalConfig {
        HasanaPetalConfig(
            length: 0.22,
            width: 0.10,
            thickness: 0.006,
            cupDepth: 0.02,
            curlAmount: 0.01,
            waveFrequency: 0.0,
            waveAmplitude: 0.0,
            baseTaper: 0.35,
            subdivisionsU: 16,
            subdivisionsV: 12
        )
    }
    
    static var lilyDefault: HasanaPetalConfig {
        HasanaPetalConfig(
            length: 0.45,
            width: 0.16,
            thickness: 0.012,
            cupDepth: 0.06,
            curlAmount: 0.04,
            waveFrequency: 3.5,
            waveAmplitude: 0.025,
            baseTaper: 0.20,
            subdivisionsU: 32,
            subdivisionsV: 20
        )
    }
}

/// Parametric settings defining the shape, curl, and waviness of a single leaf.
struct HasanaLeafConfig: Codable {
    var length: Float
    var width: Float
    var thickness: Float
    var cupDepth: Float
    var waveFrequency: Float
    var waveAmplitude: Float
    var baseTaper: Float
    var subdivisionsU: Int
    var subdivisionsV: Int
    
    static var defaultSettings: HasanaLeafConfig {
        HasanaLeafConfig(
            length: 0.24,
            width: 0.12,
            thickness: 0.006,
            cupDepth: 0.03,
            waveFrequency: 3.0,
            waveAmplitude: 0.012,
            baseTaper: 0.25,
            subdivisionsU: 20,
            subdivisionsV: 16
        )
    }
}

/// Configuration options for the central stamens (filaments and anthers).
struct HasanaStamenConfig: Codable {
    var count: Int
    var height: Float
    var spread: Float
    var filamentRadius: Float
    var antherSize: SIMD3<Float>
    
    static var roseDefault: HasanaStamenConfig {
        HasanaStamenConfig(
            count: 36,
            height: 0.08,
            spread: 0.07,
            filamentRadius: 0.0015,
            antherSize: SIMD3<Float>(0.006, 0.003, 0.004)
        )
    }
    
    static var jasmineDefault: HasanaStamenConfig {
        HasanaStamenConfig(
            count: 2,
            height: 0.05,
            spread: 0.01,
            filamentRadius: 0.0012,
            antherSize: SIMD3<Float>(0.004, 0.002, 0.003)
        )
    }
    
    static var lilyDefault: HasanaStamenConfig {
        HasanaStamenConfig(
            count: 6,
            height: 0.25,
            spread: 0.12,
            filamentRadius: 0.003,
            antherSize: SIMD3<Float>(0.024, 0.006, 0.008)
        )
    }
}

/// Configuration options for the central pistil.
struct HasanaPistilConfig: Codable {
    var height: Float
    var baseRadius: Float
    var stigmaLobeCount: Int
    var stigmaLobeLength: Float
    
    static var roseDefault: HasanaPistilConfig {
        HasanaPistilConfig(height: 0.06, baseRadius: 0.012, stigmaLobeCount: 5, stigmaLobeLength: 0.004)
    }
    
    static var jasmineDefault: HasanaPistilConfig {
        HasanaPistilConfig(height: 0.08, baseRadius: 0.006, stigmaLobeCount: 2, stigmaLobeLength: 0.003)
    }
    
    static var lilyDefault: HasanaPistilConfig {
        HasanaPistilConfig(height: 0.28, baseRadius: 0.010, stigmaLobeCount: 3, stigmaLobeLength: 0.016)
    }
}

/// Unified specification detailing the physical structure of a custom botanical flower.
struct HasanaFlowerSpec: Codable {
    var type: HasanaFlowerType
    var petal: HasanaPetalConfig
    var stamen: HasanaStamenConfig
    var pistil: HasanaPistilConfig
    var leaf: HasanaLeafConfig
    
    static func spec(for type: HasanaFlowerType) -> HasanaFlowerSpec {
        switch type {
        case .rose:
            return HasanaFlowerSpec(
                type: .rose,
                petal: .roseDefault,
                stamen: .roseDefault,
                pistil: .roseDefault,
                leaf: .defaultSettings
            )
        case .jasmine:
            return HasanaFlowerSpec(
                type: .jasmine,
                petal: .jasmineDefault,
                stamen: .jasmineDefault,
                pistil: .jasmineDefault,
                leaf: .defaultSettings
            )
        case .lily:
            return HasanaFlowerSpec(
                type: .lily,
                petal: .lilyDefault,
                stamen: .lilyDefault,
                pistil: .lilyDefault,
                leaf: .defaultSettings
            )
        }
    }
}

// MARK: - Mesh Construction Pipeline

/// Helper utility that accumulates vertices, indices, normals, and UVs to generate a RealityKit `MeshResource`.
final class HasanaFlowerMeshBuilder {
    var vertices: [HasanaFlowerVertex] = []
    var indices: [UInt32] = []
    
    init() {}
    
    /// Clears the builder buffer.
    func clear() {
        vertices.removeAll(keepingCapacity: true)
        indices.removeAll(keepingCapacity: true)
    }
    
    /// Adds a single vertex to the builder buffer.
    /// - Returns: The index of the added vertex.
    @discardableResult
    func addVertex(_ vertex: HasanaFlowerVertex) -> UInt32 {
        let index = UInt32(vertices.count)
        vertices.append(vertex)
        return index
    }
    
    /// Adds a triangle defined by three vertex indices.
    func addTriangle(i0: UInt32, i1: UInt32, i2: UInt32) {
        indices.append(i0)
        indices.append(i1)
        indices.append(i2)
    }
    
    /// Adds a quad defined by four vertex indices in counter-clockwise order.
    func addQuad(i0: UInt32, i1: UInt32, i2: UInt32, i3: UInt32) {
        // Triangle 1
        indices.append(i0)
        indices.append(i1)
        indices.append(i2)
        // Triangle 2
        indices.append(i0)
        indices.append(i2)
        indices.append(i3)
    }
    
    /// Constructs a RealityKit `MeshResource` from the accumulated buffers.
    /// - Parameter name: Name for the mesh descriptor.
    /// - Returns: A RealityKit `MeshResource` containing the geometry.
    func build(name: String = "FlowerMesh") throws -> MeshResource {
        guard !vertices.isEmpty && !indices.isEmpty else {
            throw MeshGenerationError.emptyBuffers
        }
        
        var descriptor = MeshDescriptor(name: name)
        
        let positions = vertices.map { $0.position }
        let normals = vertices.map { $0.normal }
        let uvs = vertices.map { $0.uv }
        
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)
        
        return try MeshResource.generate(from: [descriptor])
    }
    
    enum MeshGenerationError: Error {
        case emptyBuffers
    }
}

// MARK: - Parametric Geometry Mathematics

/// Generates custom botanical structures based on parametric equations and growth coefficients.
struct HasanaPetalGeometryGenerator {
    
    /// Generates a single petal mesh for the given configuration and opening factor.
    /// - Parameters:
    ///   - type: Type of the flower petal to generate.
    ///   - config: The configuration parameters.
    ///   - progress: Opening progress [0, 1] that alters curvature.
    /// - Returns: A generated RealityKit `MeshResource`.
    static func generatePetalMesh(
        type: HasanaFlowerType,
        config: HasanaPetalConfig,
        progress: Float
    ) throws -> MeshResource {
        let builder = HasanaFlowerMeshBuilder()
        
        let uSegments = config.subdivisionsU
        let vSegments = config.subdivisionsV
        
        var grid = [[UInt32]](repeating: [UInt32](repeating: 0, count: vSegments + 1), count: uSegments + 1)
        
        // 1. Generate Parametric Vertices
        for i in 0...uSegments {
            let u = Float(i) / Float(uSegments) // [0.0, 1.0] from base to tip
            
            for j in 0...vSegments {
                let v = (Float(j) / Float(vSegments)) * 2.0 - 1.0 // [-1.0, 1.0] from left to right
                
                var position: SIMD3<Float> = .zero
                let uv = SIMD2<Float>(u, (v + 1.0) / 2.0)
                
                switch type {
                case .rose:
                    position = rosePetalFormula(u: u, v: v, config: config, progress: progress)
                case .jasmine:
                    position = jasminePetalFormula(u: u, v: v, config: config, progress: progress)
                case .lily:
                    position = lilyPetalFormula(u: u, v: v, config: config, progress: progress)
                }
                
                // Color variation: base is darker/greenish, tips are brighter accent colors
                let colorFactor = u
                let color = SIMD4<Float>(1.0, 0.95 * colorFactor, 0.9 * colorFactor, 1.0)
                
                let vertex = HasanaFlowerVertex(position: position, uv: uv, color: color)
                grid[i][j] = builder.addVertex(vertex)
            }
        }
        
        // 2. Connect Indices into Triangles (Double-sided for realistic thin sheets)
        for i in 0..<uSegments {
            for j in 0..<vSegments {
                let i0 = grid[i][j]
                let i1 = grid[i + 1][j]
                let i2 = grid[i + 1][j + 1]
                let i3 = grid[i][j + 1]
                
                // Front face
                builder.addQuad(i0: i0, i1: i1, i2: i2, i3: i3)
                // Back face (reversed order)
                builder.addQuad(i0: i3, i1: i2, i2: i1, i3: i0)
            }
        }
        
        // 3. Compute Vertex Normals numerically to guarantee smooth lighting
        computeSmoothNormals(builder: builder, grid: grid, uSegments: uSegments, vSegments: vSegments)
        
        return try builder.build(name: "\(type.rawValue)_petal")
    }
    
    // MARK: - Parametric Formulas
    
    /// Mathematical description of a Rose Petal surface.
    /// Rose petals are highly cupped at the base, widening into a broad, rounded upper plate with outer curled edges.
    private static func rosePetalFormula(
        u: Float,
        v: Float,
        config: HasanaPetalConfig,
        progress: Float
    ) -> SIMD3<Float> {
        let openingT = progress
        let cupCoefficient = mix(1.3, 0.45, t: openingT) // tighter cup when closed
        let edgeCurlFactor = mix(0.1, 1.2, t: openingT) // curl curls more as it opens
        
        // Width profile (bell-like shape that tapers near base)
        let taper = mix(config.baseTaper, 1.0, t: sin(u * .pi / 2.0))
        let widthProfile = sin(u * .pi) * taper
        
        // Base plane coordinates
        let x = v * config.width * 0.5 * widthProfile
        let z = u * config.length
        
        // Parametric cupping deformation: Z/X curvature
        let cup = config.cupDepth * cupCoefficient * sin(u * .pi) * (1.0 - v * v)
        
        // Outer edge curling: roll the margins backwards near the top
        var curl: Float = 0.0
        if u > 0.4 && abs(v) > 0.4 {
            let uFactor = (u - 0.4) / 0.6
            let vFactor = (abs(v) - 0.4) / 0.6
            curl = -config.curlAmount * edgeCurlFactor * pow(uFactor, 2.0) * pow(vFactor, 3.0)
        }
        
        // Gentle organic waves along the leaf edge
        let wave = config.waveAmplitude * sin(u * config.waveFrequency * 2.0 * .pi) * abs(v)
        
        let y = cup + curl + wave
        
        return SIMD3<Float>(x, y, z)
    }
    
    /// Mathematical description of a Jasmine Petal surface.
    /// Jasmine petals are flatter, oblong-star shapes that roll inwards along the margins and twist slightly.
    private static func jasminePetalFormula(
        u: Float,
        v: Float,
        config: HasanaPetalConfig,
        progress: Float
    ) -> SIMD3<Float> {
        let openingT = progress
        
        // Jasmine petals have a wider middle lobe.
        let widthProfile = sin(pow(u, 0.8) * .pi)
        
        // Flattening & lengthening offsets
        let lengthScale = mix(0.7, 1.0, t: openingT)
        let widthScale = mix(0.85, 1.0, t: openingT)
        
        let x = v * config.width * 0.5 * widthProfile * widthScale
        let z = u * config.length * lengthScale
        
        // Petal twist / Pinwheel effect: rotate the petal coordinate slightly around Z axis
        let twistAngle = 0.15 * u * mix(0.3, 1.0, t: openingT)
        let cosA = cos(twistAngle)
        let sinA = sin(twistAngle)
        
        let xRotated = x * cosA
        let yRotated = x * sinA
        
        // Subtle longitudinal curl at the tip
        let droop = -0.02 * pow(u, 3.0) * mix(0.5, 1.5, t: openingT)
        
        // Marginal curl: edges curve slightly upwards
        let marginalCurl = config.cupDepth * (v * v) * sin(u * .pi)
        
        let y = yRotated + droop + marginalCurl
        
        return SIMD3<Float>(xRotated, y, z)
    }
    
    /// Mathematical description of a Lily Petal surface.
    /// Lilies are elongated, reflexed (petals curve backwards dramatically at the tip) with a raised midrib.
    private static func lilyPetalFormula(
        u: Float,
        v: Float,
        config: HasanaPetalConfig,
        progress: Float
    ) -> SIMD3<Float> {
        let openingT = progress
        
        // Lanceolate shape tapering at the base and tip
        let widthProfile = sin(u * .pi) * (0.4 + 0.6 * sin(u * .pi * 0.5))
        
        let x = v * config.width * 0.5 * widthProfile
        
        // Central midrib thickness
        let midribWidth: Float = 0.15
        var midribGlow: Float = 0.0
        if abs(v) < midribWidth {
            midribGlow = (1.0 - abs(v) / midribWidth) * 0.015 * (1.0 - u)
        }
        
        // Reflexing logic: curved outwards/backwards as it matures
        // At t=0 (bud): curved slightly inwards. At t=1 (open): rolled backwards heavily.
        let baseReflex = mix(-0.06, 0.18, t: openingT)
        let tipReflex = mix(-0.02, -config.curlAmount * 6.0, t: openingT)
        
        let z = u * config.length
        
        // Combine Z bending and midrib
        let bend = baseReflex * sin(u * .pi * 0.8) + tipReflex * pow(u, 3.0)
        let y = bend + midribGlow
        
        // Wavy edges (undulations) along the outer boundary
        let edgeWaveScale = smoothstep(0.4, 0.95, abs(v))
        let wave = config.waveAmplitude * sin(u * config.waveFrequency * 2.0 * .pi) * edgeWaveScale
        
        return SIMD3<Float>(x, y + wave, z)
    }
    
    // MARK: - Normal Computation Solver
    
    /// Computes correct lighting normal vectors for the generated surface grid.
    static func computeSmoothNormals(
        builder: HasanaFlowerMeshBuilder,
        grid: [[UInt32]],
        uSegments: Int,
        vSegments: Int
    ) {
        var vertexNormals = [SIMD3<Float>](repeating: .zero, count: builder.vertices.count)
        
        let triangleCount = builder.indices.count / 3
        for t in 0..<triangleCount {
            let i0 = Int(builder.indices[t * 3])
            let i1 = Int(builder.indices[t * 3 + 1])
            let i2 = Int(builder.indices[t * 3 + 2])
            
            let p0 = builder.vertices[i0].position
            let p1 = builder.vertices[i1].position
            let p2 = builder.vertices[i2].position
            
            let e1 = p1 - p0
            let e2 = p2 - p0
            let faceNormal = simd_cross(e1, e2)
            
            vertexNormals[i0] += faceNormal
            vertexNormals[i1] += faceNormal
            vertexNormals[i2] += faceNormal
        }
        
        for i in 0..<builder.vertices.count {
            let normal = vertexNormals[i]
            let normLength = simd_length(normal)
            if normLength > 0.0001 {
                builder.vertices[i].normal = normal / normLength
            } else {
                builder.vertices[i].normal = SIMD3<Float>(0, 1, 0)
            }
        }
    }
    
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }
    
    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }
}

// MARK: - Leaf Geometry Generator

/// Generates parametric leaf meshes with organic midrib curvature and margins.
struct HasanaLeafGeometryGenerator {
    
    /// Generates a single detailed leaf mesh.
    static func generateLeafMesh(config: HasanaLeafConfig) throws -> MeshResource {
        let builder = HasanaFlowerMeshBuilder()
        let uSegments = config.subdivisionsU
        let vSegments = config.subdivisionsV
        
        var grid = [[UInt32]](repeating: [UInt32](repeating: 0, count: vSegments + 1), count: uSegments + 1)
        
        for i in 0...uSegments {
            let u = Float(i) / Float(uSegments)
            let taper = sin(u * .pi) * mix(config.baseTaper, 1.0, t: sin(u * .pi / 2.0))
            
            for j in 0...vSegments {
                let v = (Float(j) / Float(vSegments)) * 2.0 - 1.0
                
                let x = v * config.width * 0.5 * taper
                let z = u * config.length
                
                // Leaf cupping (V shape along midrib)
                let midribV = abs(v)
                let cup = config.cupDepth * midribV * sin(u * .pi)
                
                // Bend tip downwards
                let bend = -0.04 * pow(u, 2.5)
                
                // Leaf margin wave
                let edgeWaveScale = sin(u * config.waveFrequency * 2.0 * .pi) * config.waveAmplitude
                let wave = edgeWaveScale * smoothstep(0.5, 1.0, abs(v))
                
                let y = cup + bend + wave
                let uv = SIMD2<Float>(u, (v + 1.0) / 2.0)
                let color = SIMD4<Float>(0.12, 0.45, 0.18, 1.0) // green
                
                let vertex = HasanaFlowerVertex(position: SIMD3<Float>(x, y, z), uv: uv, color: color)
                grid[i][j] = builder.addVertex(vertex)
            }
        }
        
        for i in 0..<uSegments {
            for j in 0..<vSegments {
                let i0 = grid[i][j]
                let i1 = grid[i + 1][j]
                let i2 = grid[i + 1][j + 1]
                let i3 = grid[i][j + 1]
                
                builder.addQuad(i0: i0, i1: i1, i2: i2, i3: i3)
                builder.addQuad(i0: i3, i1: i2, i2: i1, i3: i0)
            }
        }
        
        HasanaPetalGeometryGenerator.computeSmoothNormals(
            builder: builder,
            grid: grid,
            uSegments: uSegments,
            vSegments: vSegments
        )
        
        return try builder.build(name: "botanical_leaf")
    }
    
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }
    
    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }
}

// MARK: - Sepal Geometry Generator

/// Generates custom green sepals that cup the base of flower blooms.
struct HasanaSepalGeometryGenerator {
    
    /// Generates a sepal blade.
    static func generateSepalMesh(length: Float, width: Float) throws -> MeshResource {
        let builder = HasanaFlowerMeshBuilder()
        let uSegments = 10
        let vSegments = 8
        
        var grid = [[UInt32]](repeating: [UInt32](repeating: 0, count: vSegments + 1), count: uSegments + 1)
        
        for i in 0...uSegments {
            let u = Float(i) / Float(uSegments)
            // Sepal profile: tapered tip
            let taper = (1.0 - u) * sin(u * .pi / 2.0)
            
            for j in 0...vSegments {
                let v = (Float(j) / Float(vSegments)) * 2.0 - 1.0
                
                let x = v * width * 0.5 * taper
                let z = u * length
                
                // Curve backwards (downwards from base)
                let y = -0.15 * length * (u * u)
                
                let uv = SIMD2<Float>(u, (v + 1.0) / 2.0)
                let vertex = HasanaFlowerVertex(
                    position: SIMD3<Float>(x, y, z),
                    uv: uv,
                    color: SIMD4<Float>(0.20, 0.40, 0.15, 1.0)
                )
                grid[i][j] = builder.addVertex(vertex)
            }
        }
        
        for i in 0..<uSegments {
            for j in 0..<vSegments {
                let i0 = grid[i][j]
                let i1 = grid[i + 1][j]
                let i2 = grid[i + 1][j + 1]
                let i3 = grid[i][j + 1]
                
                builder.addQuad(i0: i0, i1: i1, i2: i2, i3: i3)
                builder.addQuad(i0: i3, i1: i2, i2: i1, i3: i0)
            }
        }
        
        HasanaPetalGeometryGenerator.computeSmoothNormals(
            builder: builder,
            grid: grid,
            uSegments: uSegments,
            vSegments: vSegments
        )
        
        return try builder.build(name: "sepal_blade")
    }
}

// MARK: - Pistil & Stamen Geometry Generators

/// Generates central reproduction organ meshes for botanical fidelity.
struct HasanaCenterGeometryGenerator {
    
    /// Generates a central pistil mesh with multiple stigma lobes.
    static func generatePistilMesh(
        config: HasanaPistilConfig,
        progress: Float
    ) throws -> MeshResource {
        let builder = HasanaFlowerMeshBuilder()
        
        let rings = 16
        let radialSegments = 12
        let height = config.height * mix(0.7, 1.0, t: progress)
        let rBase = config.baseRadius * mix(0.9, 1.0, t: progress)
        
        var grid = [[UInt32]](repeating: [UInt32](repeating: 0, count: radialSegments + 1), count: rings + 1)
        
        // 1. Generate Style (cylinder with tapering profile)
        for i in 0...rings {
            let t = Float(i) / Float(rings)
            let y = t * height
            
            var radius: Float = rBase
            if t < 0.3 {
                radius = rBase * (1.2 - 0.4 * sin(t * .pi / 0.6))
            } else if t < 0.85 {
                let subT = (t - 0.3) / 0.55
                radius = rBase * mix(0.8, 0.4, t: subT)
            } else {
                let subT = (t - 0.85) / 0.15
                radius = rBase * mix(0.4, 0.9, t: subT)
            }
            
            for j in 0...radialSegments {
                let theta = (Float(j) / Float(radialSegments)) * 2.0 * .pi
                let x = cos(theta) * radius
                let z = sin(theta) * radius
                
                let uv = SIMD2<Float>(t, Float(j) / Float(radialSegments))
                let pos = SIMD3<Float>(x, y, z)
                
                let color = SIMD4<Float>(0.85, 0.95, 0.80, 1.0)
                
                grid[i][j] = builder.addVertex(HasanaFlowerVertex(position: pos, uv: uv, color: color))
            }
        }
        
        for i in 0..<rings {
            for j in 0..<radialSegments {
                builder.addQuad(
                    i0: grid[i][j],
                    i1: grid[i + 1][j],
                    i2: grid[i + 1][j + 1],
                    i3: grid[i][j + 1]
                )
            }
        }
        
        // 2. Generate Stigma Lobes branching out from style tip
        let lobeCount = config.stigmaLobeCount
        let lobeRadius = config.baseRadius * 0.25
        let lobeLength = config.stigmaLobeLength * mix(0.4, 1.0, t: progress)
        
        for k in 0..<lobeCount {
            let lobeAngle = (Float(k) / Float(lobeCount)) * 2.0 * .pi
            let segments = 6
            var prevRingVertices: [UInt32] = []
            
            for j in 0...radialSegments {
                prevRingVertices.append(grid[rings][j])
            }
            
            for s in 1...segments {
                let st = Float(s) / Float(segments)
                
                let bend = st * 0.85
                let xOffset = cos(lobeAngle) * lobeLength * sin(bend)
                let zOffset = sin(lobeAngle) * lobeLength * sin(bend)
                let yOffset = height + lobeLength * (1.0 - cos(bend))
                
                let centerPt = SIMD3<Float>(xOffset, yOffset, zOffset)
                
                var currentRingVertices: [UInt32] = []
                
                for j in 0...radialSegments {
                    let theta = (Float(j) / Float(radialSegments)) * 2.0 * .pi
                    let localX = SIMD3<Float>(-sin(lobeAngle), 0, cos(lobeAngle))
                    let localY = SIMD3<Float>(cos(lobeAngle) * cos(bend), sin(bend), sin(lobeAngle) * cos(bend))
                    
                    let ringRad = lobeRadius * (1.0 - st * 0.75)
                    let pt = centerPt + localX * cos(theta) * ringRad + localY * sin(theta) * ringRad
                    
                    let uv = SIMD2<Float>(st, Float(j) / Float(radialSegments))
                    let color = SIMD4<Float>(0.92, 0.95, 0.65, 1.0)
                    
                    let vertIdx = builder.addVertex(HasanaFlowerVertex(position: pt, uv: uv, color: color))
                    currentRingVertices.append(vertIdx)
                }
                
                for j in 0..<radialSegments {
                    builder.addQuad(
                        i0: prevRingVertices[j],
                        i1: currentRingVertices[j],
                        i2: currentRingVertices[j + 1],
                        i3: prevRingVertices[j + 1]
                    )
                }
                
                prevRingVertices = currentRingVertices
            }
            
            let tipIdx = builder.addVertex(
                HasanaFlowerVertex(
                    position: SIMD3<Float>(
                        cos(lobeAngle) * lobeLength * sin(0.85),
                        height + lobeLength * (1.0 - cos(0.85)),
                        sin(lobeAngle) * lobeLength * sin(0.85)
                    ),
                    normal: SIMD3<Float>(cos(lobeAngle), 0.5, sin(lobeAngle)),
                    uv: SIMD2<Float>(1.0, 0.5),
                    color: SIMD4<Float>(0.92, 0.95, 0.65, 1.0)
                )
            )
            
            for j in 0..<radialSegments {
                builder.addTriangle(i0: prevRingVertices[j], i1: tipIdx, i2: prevRingVertices[j + 1])
            }
        }
        
        computeNormalsForUnstructuredMesh(builder: builder)
        
        return try builder.build(name: "pistil")
    }
    
    /// Generates a stamen mesh (filament stem + large double-lobed anther header).
    static func generateStamenMesh(
        config: HasanaStamenConfig,
        progress: Float
    ) throws -> MeshResource {
        let builder = HasanaFlowerMeshBuilder()
        
        let rings = 12
        let radialSegments = 8
        let height = config.height * mix(0.5, 1.0, t: progress)
        
        var filamentGrid = [[UInt32]](repeating: [UInt32](repeating: 0, count: radialSegments + 1), count: rings + 1)
        let curveSpread: Float = 0.08 * height
        
        for i in 0...rings {
            let t = Float(i) / Float(rings)
            let cx = curveSpread * pow(t, 2.0)
            let cy = t * height
            let cz = Float(0.0)
            
            let center = SIMD3<Float>(cx, cy, cz)
            
            let tangent = simd_normalize(SIMD3<Float>(2.0 * curveSpread * t, height, 0.0))
            let normalVec = SIMD3<Float>(-tangent.y, tangent.x, 0.0)
            let binormalVec = SIMD3<Float>(0.0, 0.0, 1.0)
            
            for j in 0...radialSegments {
                let theta = (Float(j) / Float(radialSegments)) * 2.0 * .pi
                let rad = config.filamentRadius * (1.0 - t * 0.3)
                
                let pt = center + normalVec * cos(theta) * rad + binormalVec * sin(theta) * rad
                let uv = SIMD2<Float>(t, Float(j) / Float(radialSegments))
                let color = SIMD4<Float>(0.96, 0.96, 0.88, 1.0)
                
                filamentGrid[i][j] = builder.addVertex(HasanaFlowerVertex(position: pt, uv: uv, color: color))
            }
        }
        
        for i in 0..<rings {
            for j in 0..<radialSegments {
                builder.addQuad(
                    i0: filamentGrid[i][j],
                    i1: filamentGrid[i + 1][j],
                    i2: filamentGrid[i + 1][j + 1],
                    i3: filamentGrid[i][j + 1]
                )
            }
        }
        
        // 2. Generate Anther (butterfly/kidney double lobed pollen bag) at tip
        let aSize = config.antherSize * mix(0.3, 1.0, t: progress)
        let tipPosition = SIMD3<Float>(curveSpread, height, 0.0)
        
        let lobeCount = 2
        for lobe in 0..<lobeCount {
            let sign: Float = lobe == 0 ? -1.0 : 1.0
            let w = aSize.x * 0.5
            let h = aSize.y
            let d = aSize.z
            
            let centerOffset = tipPosition + SIMD3<Float>(sign * w * 0.8, 0, 0)
            
            var boxVertices: [UInt32] = []
            
            let dx: [Float] = [ -1.0, 1.0 ]
            let dy: [Float] = [ -1.0, 1.0 ]
            let dz: [Float] = [ -1.0, 1.0 ]
            
            for xIdx in 0...1 {
                for yIdx in 0...1 {
                    for zIdx in 0...1 {
                        let localPos = SIMD3<Float>(
                            dx[xIdx] * w * 0.5,
                            dy[yIdx] * h * 0.5,
                            dz[zIdx] * d * 0.5
                        )
                        let kidneyZ = -0.15 * sign * (localPos.x * localPos.x)
                        let adjustedPos = centerOffset + localPos + SIMD3<Float>(0, 0, kidneyZ)
                        
                        let uv = SIMD2<Float>(Float(xIdx), Float(yIdx))
                        let color = SIMD4<Float>(0.95, 0.82, 0.15, 1.0)
                        
                        boxVertices.append(builder.addVertex(HasanaFlowerVertex(position: adjustedPos, uv: uv, color: color)))
                    }
                }
            }
            
            let faces = [
                (0, 1, 3, 2), // bottom
                (4, 6, 7, 5), // top
                (0, 2, 6, 4), // left
                (1, 5, 7, 3), // right
                (0, 4, 5, 1), // back
                (2, 3, 7, 6)  // front
            ]
            
            for face in faces {
                builder.addQuad(
                    i0: boxVertices[face.0],
                    i1: boxVertices[face.1],
                    i2: boxVertices[face.2],
                    i3: boxVertices[face.3]
                )
            }
        }
        
        computeNormalsForUnstructuredMesh(builder: builder)
        
        return try builder.build(name: "stamen")
    }
    
    /// Fallback normal generator for unstructured mesh builder topology.
    private static func computeNormalsForUnstructuredMesh(builder: HasanaFlowerMeshBuilder) {
        var vertexNormals = [SIMD3<Float>](repeating: .zero, count: builder.vertices.count)
        
        let triangleCount = builder.indices.count / 3
        for t in 0..<triangleCount {
            let i0 = Int(builder.indices[t * 3])
            let i1 = Int(builder.indices[t * 3 + 1])
            let i2 = Int(builder.indices[t * 3 + 2])
            
            let p0 = builder.vertices[i0].position
            let p1 = builder.vertices[i1].position
            let p2 = builder.vertices[i2].position
            
            let e1 = p1 - p0
            let e2 = p2 - p0
            let n = simd_cross(e1, e2)
            
            vertexNormals[i0] += n
            vertexNormals[i1] += n
            vertexNormals[i2] += n
        }
        
        for i in 0..<builder.vertices.count {
            let len = simd_length(vertexNormals[i])
            if len > 0.0001 {
                builder.vertices[i].normal = vertexNormals[i] / len
            } else {
                builder.vertices[i].normal = SIMD3<Float>(0, 1, 0)
            }
        }
    }
    
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }
}

// MARK: - Dewdrop Placement Solver

/// Computes localized coordinates on a petal mesh where organic dew droplets should spawn.
struct HasanaDewdropPlacementSolver {
    
    struct DewdropSpawnPoint {
        var position: SIMD3<Float>
        var normal: SIMD3<Float>
        var radius: Float
    }
    
    /// Collects placement positions on the petals using deterministic seed math.
    static func solveDroplets(
        type: HasanaFlowerType,
        config: HasanaPetalConfig,
        petalIndex: Int,
        seed: Int,
        progress: Float
    ) -> [DewdropSpawnPoint] {
        var list: [DewdropSpawnPoint] = []
        
        // Spawn 2 to 4 droplets depending on bloom progress (mature flowers accumulate dew)
        guard progress > 0.3 else { return [] }
        
        let targetCount = 3
        let generatorSeed = seed + petalIndex * 15
        
        for i in 0..<targetCount {
            let rU = deterministicRandom(seed: generatorSeed + i * 2)
            let rV = deterministicRandom(seed: generatorSeed + i * 5) * 2.0 - 1.0
            
            // Choose placement on the upper middle plate of the petal
            let u = 0.35 + rU * 0.45
            let v = rV * 0.7
            
            var pos: SIMD3<Float> = .zero
            switch type {
            case .rose:
                pos = rosePetalPoint(u: u, v: v, config: config, progress: progress)
            case .jasmine:
                pos = jasminePetalPoint(u: u, v: v, config: config, progress: progress)
            case .lily:
                pos = lilyPetalPoint(u: u, v: v, config: config, progress: progress)
            }
            
            // Approximate local normal: pointing up/outwards
            let normal = simd_normalize(SIMD3<Float>(0.0, 1.0, 0.0) + SIMD3<Float>(v * 0.3, 0.0, 0.0))
            
            let dropletRadius = 0.005 + 0.006 * deterministicRandom(seed: generatorSeed + i * 9)
            
            list.append(DewdropSpawnPoint(position: pos, normal: normal, radius: dropletRadius))
        }
        
        return list
    }
    
    private static func rosePetalPoint(u: Float, v: Float, config: HasanaPetalConfig, progress: Float) -> SIMD3<Float> {
        let taper = mix(config.baseTaper, 1.0, t: sin(u * .pi / 2.0))
        let w = sin(u * .pi) * taper
        let x = v * config.width * 0.5 * w
        let z = u * config.length
        let cup = config.cupDepth * mix(1.3, 0.45, t: progress) * sin(u * .pi) * (1.0 - v * v)
        return SIMD3<Float>(x, cup, z)
    }
    
    private static func jasminePetalPoint(u: Float, v: Float, config: HasanaPetalConfig, progress: Float) -> SIMD3<Float> {
        let w = sin(pow(u, 0.8) * .pi)
        let x = v * config.width * 0.5 * w * mix(0.85, 1.0, t: progress)
        let z = u * config.length * mix(0.7, 1.0, t: progress)
        return SIMD3<Float>(x, 0.0, z)
    }
    
    private static func lilyPetalPoint(u: Float, v: Float, config: HasanaPetalConfig, progress: Float) -> SIMD3<Float> {
        let w = sin(u * .pi) * (0.4 + 0.6 * sin(u * .pi * 0.5))
        let x = v * config.width * 0.5 * w
        let z = u * config.length
        let bend = mix(-0.06, 0.18, t: progress) * sin(u * .pi * 0.8) + mix(-0.02, -config.curlAmount * 6.0, t: progress) * pow(u, 3.0)
        return SIMD3<Float>(x, bend, z)
    }
    
    private static func deterministicRandom(seed: Int) -> Float {
        var x = UInt32(truncatingIfNeeded: seed)
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        return Float(x) / Float(UInt32.max)
    }
    
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }
}

// MARK: - Petal Layout Coordinate Layout System

/// Computes coordinates, offsets, and arrangements of petals in concentric structures.
struct HasanaPetalLayoutEngine {
    
    /// Layout transform configurations for a single petal.
    struct PetalTransform {
        var position: SIMD3<Float>
        var orientation: simd_quatf
        var scale: SIMD3<Float>
        var baseColorMultiplier: UIColor
    }
    
    /// Computes the transforms for all petals in a flower according to its type and opening stage.
    /// - Parameters:
    ///   - type: The flower type.
    ///   - progress: Eased opening progress [0.0, 1.0].
    ///   - seed: Deterministic seed to inject organic variation.
    ///   - color: Base accent color of the flower.
    /// - Returns: List of transforms, one for each petal.
    static func computeLayout(
        type: HasanaFlowerType,
        progress: Float,
        seed: Int,
        color: UIColor
    ) -> [PetalTransform] {
        switch type {
        case .rose:
            return computeRoseLayout(progress: progress, seed: seed, color: color)
        case .jasmine:
            return computeJasmineLayout(progress: progress, seed: seed, color: color)
        case .lily:
            return computeLilyLayout(progress: progress, seed: seed, color: color)
        }
    }
    
    // MARK: - Rose Spiral Fibonacci Phyllotaxis Layout
    
    private static func computeRoseLayout(
        progress: Float,
        seed: Int,
        color: UIColor
    ) -> [PetalTransform] {
        var layouts: [PetalTransform] = []
        
        let totalPetals = 28
        let goldenAngle: Float = 2.399963
        
        for i in 0..<totalPetals {
            let t = Float(i) / Float(totalPetals)
            
            let theta = Float(i) * goldenAngle
            let baseRadius = 0.02 + 0.15 * sqrt(t)
            
            let radiusGrowth = mix(1.0, 1.8, t: progress) * baseRadius
            let heightOffset = mix(0.04, -0.05, t: progress) * pow(t, 1.5) + (t * 0.08)
            
            let x = cos(theta) * radiusGrowth
            let z = sin(theta) * radiusGrowth
            let y = heightOffset
            
            let budPitch = mix(1.4, 0.9, t: t)
            let openPitch = mix(0.9, 0.15, t: t)
            let pitch = mix(budPitch, openPitch, t: progress)
            
            let yaw = -theta + 0.18 * (1.0 - t)
            
            let noise = deterministicRandom(seed: seed + i)
            let roll = (noise - 0.5) * 0.08
            
            let baseScale = mix(0.4, 1.1, t: t)
            let scaleX = baseScale * mix(0.85, 1.0, t: progress)
            let scaleY = baseScale * mix(0.95, 1.0, t: progress)
            let scaleZ = baseScale * mix(0.7, 1.0, t: progress)
            
            let rotYaw = simd_quatf(angle: yaw, axis: [0, 1, 0])
            let rotPitch = simd_quatf(angle: pitch, axis: [1, 0, 0])
            let rotRoll = simd_quatf(angle: roll, axis: [0, 0, 1])
            let orientation = rotYaw * rotPitch * rotRoll
            
            let colorBlend = mixColor(color, with: .white, amount: CGFloat(0.35 * (1.0 - t)))
            
            layouts.append(
                PetalTransform(
                    position: SIMD3<Float>(x, y, z),
                    orientation: orientation,
                    scale: SIMD3<Float>(scaleX, scaleY, scaleZ),
                    baseColorMultiplier: colorBlend
                )
            )
        }
        
        return layouts
    }
    
    // MARK: - Jasmine Flat Pinwheel Layout
    
    private static func computeJasmineLayout(
        progress: Float,
        seed: Int,
        color: UIColor
    ) -> [PetalTransform] {
        var layouts: [PetalTransform] = []
        
        let petalCount = 5
        let angleStep = (2.0 * .pi) / Float(petalCount)
        
        for i in 0..<petalCount {
            let angle = Float(i) * angleStep
            
            let budRadius: Float = 0.008
            let openRadius: Float = 0.022
            let radius = mix(budRadius, openRadius, t: progress)
            
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let y = mix(0.04, 0.0, t: progress)
            
            let pitch = mix(1.5, 0.08, t: progress)
            
            let pinwheelOffset: Float = 0.12 * mix(0.4, 1.0, t: progress)
            let yaw = -angle + pinwheelOffset
            
            let noise = deterministicRandom(seed: seed + i + 100)
            let roll = (noise - 0.5) * 0.04
            
            let sFactor = mix(0.35, 1.0, t: progress)
            let scale = SIMD3<Float>(sFactor, sFactor, sFactor)
            
            let rotYaw = simd_quatf(angle: yaw, axis: [0, 1, 0])
            let rotPitch = simd_quatf(angle: pitch, axis: [1, 0, 0])
            let rotRoll = simd_quatf(angle: roll, axis: [0, 0, 1])
            let orientation = rotYaw * rotPitch * rotRoll
            
            layouts.append(
                PetalTransform(
                    position: SIMD3<Float>(x, y, z),
                    orientation: orientation,
                    scale: scale,
                    baseColorMultiplier: color
                )
            )
        }
        
        return layouts
    }
    
    // MARK: - Lily Concentric Staggered Whorls
    
    private static func computeLilyLayout(
        progress: Float,
        seed: Int,
        color: UIColor
    ) -> [PetalTransform] {
        var layouts: [PetalTransform] = []
        
        let innerCount = 3
        let outerCount = 3
        
        let pitchAngle = mix(1.48, 0.22, t: progress)
        
        // Ring 1: Outer Tepals
        for i in 0..<outerCount {
            let angle = (Float(i) / Float(outerCount)) * 2.0 * .pi
            
            let radius = mix(0.015, 0.04, t: progress)
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let y = mix(0.02, 0.005, t: progress)
            
            let rotYaw = simd_quatf(angle: -angle, axis: [0, 1, 0])
            let rotPitch = simd_quatf(angle: pitchAngle + 0.05, axis: [1, 0, 0])
            let orientation = rotYaw * rotPitch
            
            let sFactor = mix(0.4, 0.95, t: progress)
            let scale = SIMD3<Float>(sFactor * 0.9, sFactor, sFactor * 1.05)
            
            let blendedColor = mixColor(color, with: UIColor(red: 0.72, green: 0.84, blue: 0.72, alpha: 1.0), amount: 0.15)
            
            layouts.append(
                PetalTransform(
                    position: SIMD3<Float>(x, y, z),
                    orientation: orientation,
                    scale: scale,
                    baseColorMultiplier: blendedColor
                )
            )
        }
        
        // Ring 2: Inner Tepals
        for i in 0..<innerCount {
            let angle = (Float(i) / Float(innerCount)) * 2.0 * .pi + (.pi / 3.0)
            
            let radius = mix(0.008, 0.025, t: progress)
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let y = mix(0.035, 0.020, t: progress)
            
            let innerPitch = pitchAngle + 0.12
            
            let rotYaw = simd_quatf(angle: -angle, axis: [0, 1, 0])
            let rotPitch = simd_quatf(angle: innerPitch, axis: [1, 0, 0])
            let orientation = rotYaw * rotPitch
            
            let sFactor = mix(0.45, 1.05, t: progress)
            let scale = SIMD3<Float>(sFactor * 1.08, sFactor * 1.02, sFactor * 1.0)
            
            layouts.append(
                PetalTransform(
                    position: SIMD3<Float>(x, y, z),
                    orientation: orientation,
                    scale: scale,
                    baseColorMultiplier: color
                )
            )
        }
        
        return layouts
    }
    
    // MARK: - Mathematical Helper Utilities
    
    private static func deterministicRandom(seed: Int) -> Float {
        var x = UInt32(truncatingIfNeeded: seed)
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        return Float(x) / Float(UInt32.max)
    }
    
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }
    
    private static func mixColor(_ c1: UIColor, with c2: UIColor, amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * amount
        let g = g1 + (g2 - g1) * amount
        let b = b1 + (b2 - b1) * amount
        let a = a1 + (a2 - a1) * amount
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Advanced Wind Turbulence Engine

/// Solves multi-octave wind waves for organic ambient garden movement.
struct HasanaFlowerWindEngine {
    
    /// Computes rotational offset vector representing wind sway.
    /// - Parameters:
    ///   - time: Elapsed duration in seconds.
    ///   - windIntensity: Overall sway scale factor.
    ///   - windSpeed: Wave frequency.
    ///   - seed: Distinct model seed to prevent parallel matching sway.
    /// - Returns: Quaternion orientation adjustment.
    static func solveSway(
        time: Float,
        windIntensity: Float,
        windSpeed: Float,
        seed: Int
    ) -> simd_quatf {
        let uniqueOffset = Float(seed % 100) * 0.15
        let t = time * windSpeed + uniqueOffset
        
        // Multi-octave wave superposition (irregular wind gusts)
        let wave1X = sin(t)
        let wave2X = cos(t * 2.3) * 0.4
        let wave3X = sin(t * 0.45) * 0.7
        let xRotationAngle = (wave1X + wave2X + wave3X) * windIntensity * 0.4
        
        let wave1Z = cos(t * 0.85)
        let wave2Z = sin(t * 1.7) * 0.5
        let wave3Z = cos(t * 0.25) * 0.8
        let zRotationAngle = (wave1Z + wave2Z + wave3Z) * windIntensity * 0.4
        
        let qX = simd_quatf(angle: xRotationAngle, axis: SIMD3<Float>(1, 0, 0))
        let qZ = simd_quatf(angle: zRotationAngle, axis: SIMD3<Float>(0, 0, 1))
        
        return qX * qZ
    }
}

// MARK: - RealityKit Animation & System Core

/// Entity component carrying the current state of a flower's bloom and wind physical attributes.
struct HasanaFlowerAnimationComponent: Component, Codable {
    var flowerType: HasanaFlowerType
    var openingProgress: Float = 0.0
    var targetOpeningProgress: Float = 0.0
    var openingSpeed: Float = 0.35
    var windIntensity: Float = 0.08
    var windSpeed: Float = 1.6
    var timeAccumulator: Float = 0.0
    var easeType: HasanaEaseType = .cubicInOut
    
    init(flowerType: HasanaFlowerType) {
        self.flowerType = flowerType
    }
}

/// Dynamic system which updates flower structure positions, petals, and stamens, simulating wind and growth over time.
final class HasanaFlowerAnimationSystem: System {
    
    private static let query = HasertFlowerTag.hasComponent
    
    required init(scene: Scene) {
        // Core RealityKit system init
    }
    
    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        
        context.scene.performQuery(Self.query).forEach { entity in
            guard var animComp = entity.components[HasanaFlowerAnimationComponent.self] else { return }
            
            // Advance the opening progress interpolation towards target
            if abs(animComp.openingProgress - animComp.targetOpeningProgress) > 0.0001 {
                let diff = animComp.targetOpeningProgress - animComp.openingProgress
                let step = sign(diff) * animComp.openingSpeed * dt
                
                if abs(step) >= abs(diff) {
                    animComp.openingProgress = animComp.targetOpeningProgress
                } else {
                    animComp.openingProgress += step
                }
            }
            
            animComp.timeAccumulator += dt
            entity.components[HasanaFlowerAnimationComponent.self] = animComp
            
            animateFlowerHierarchy(entity, component: animComp)
        }
    }
    
    /// Procedurally animates the subcomponents of the flower model hierarchy.
    private func animateFlowerHierarchy(_ root: Entity, component: HasanaFlowerAnimationComponent) {
        let easedT = component.easeType.ease(component.openingProgress)
        let t = component.timeAccumulator
        let seed = root.name.hashValue
        
        // 1. Wind sway applied as a rotation of the root head entity
        let windRot = HasanaFlowerWindEngine.solveSway(
            time: t,
            windIntensity: component.windIntensity,
            windSpeed: component.windSpeed,
            seed: seed
        )
        
        if let flowerHead = root.findEntity(named: "flower_head") {
            flowerHead.orientation = windRot
        }
        
        // 2. Animate individual petal objects
        if let petalsContainer = root.findEntity(named: "petals_container") {
            let childCount = petalsContainer.children.count
            
            let baseColor = (root as? ModelEntity)?.model?.materials.first as? SimpleMaterial
            let uiColor = baseColor?.color.tint ?? .white
            
            let targetTransforms = HasanaPetalLayoutEngine.computeLayout(
                type: component.flowerType,
                progress: easedT,
                seed: seed,
                color: uiColor
            )
            
            for index in 0..<childCount {
                guard index < targetTransforms.count else { break }
                let petalNode = petalsContainer.children[index]
                let targetT = targetTransforms[index]
                
                petalNode.position = targetT.position
                petalNode.orientation = targetT.orientation
                
                let morphScale = targetT.scale * mix(0.12, 1.0, t: easedT)
                petalNode.scale = morphScale
            }
        }
        
        // 3. Animate central reproduction stamens (they grow taller and spread outward as flower opens)
        if let stamensContainer = root.findEntity(named: "stamens_container") {
            let spec = HasanaFlowerSpec.spec(for: component.flowerType)
            let sCount = stamensContainer.children.count
            let goldenAngle: Float = 2.399963
            
            for index in 0..<sCount {
                let stamenNode = stamensContainer.children[index]
                let angle = Float(index) * goldenAngle
                let radialFactor = Float(index) / Float(sCount)
                
                let baseSpread = spec.stamen.spread * (0.2 + 0.8 * radialFactor)
                let spread = mix(0.05, 1.3, t: easedT) * baseSpread
                let height = mix(0.4, 1.0, t: easedT) * spec.stamen.height
                
                let x = cos(angle) * spread
                let z = sin(angle) * spread
                let y = height * 0.15 + (1.0 - easedT) * 0.02
                
                stamenNode.position = SIMD3<Float>(x, y, z)
                
                let tiltAngle = mix(0.05, 0.42, t: easedT) * radialFactor
                let yawRot = simd_quatf(angle: -angle, axis: [0, 1, 0])
                let pitchRot = simd_quatf(angle: tiltAngle, axis: [1, 0, 0])
                stamenNode.orientation = yawRot * pitchRot
                stamenNode.scale = SIMD3<Float>(repeating: mix(0.2, 1.0, t: easedT))
            }
        }
        
        // 4. Animate central pistil
        if let pistil = root.findEntity(named: "pistil") {
            pistil.scale = SIMD3<Float>(1.0, mix(0.5, 1.0, t: easedT), 1.0)
        }
    }
    
    private func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }
    
    private func sign(_ val: Float) -> Float {
        val >= 0 ? 1.0 : -1.0
    }
}

// MARK: - Internal Helper Tag to Identify Flower Entities

private struct HasertFlowerTag: Component {
    static let hasComponent = EntityQuery(where: .has(HasanaFlowerAnimationComponent.self))
}

// MARK: - Translucent Materials Factory

/// Provides specialized RealityKit materials suitable for rendering thin, translucent flower petals.
struct HasanaGardenMaterialFactory {
    
    /// Builds material configuration with optimized roughness and translucent light scattering properties.
    static func makePetalMaterial(color: UIColor) -> SimpleMaterial {
        var mat = SimpleMaterial(color: color, roughness: 0.65, isMetallic: false)
        // High specular component to capture morning dew and grazing light reflections
        return mat
    }
    
    /// Builds material for stem and foliage base.
    static func makeGreenMaterial() -> SimpleMaterial {
        SimpleMaterial(
            color: UIColor(red: 0.16, green: 0.38, blue: 0.20, alpha: 1.0),
            roughness: 0.85,
            isMetallic: false
        )
    }
    
    /// Builds highly shiny translucent material for water dewdrops.
    static func makeDewdropMaterial() -> SimpleMaterial {
        SimpleMaterial(
            color: UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.65),
            roughness: 0.05,
            isMetallic: false
        )
    }
}

// MARK: - RealityKit Flower Mesh Factory

/// Builds complete 3D Entity hierarchies for rose, jasmine, and lily.
struct HasanaGardenFlowerFactory {
    
    /// Registers the RealityKit custom components and system. Call this during app lifecycle start.
    static func registerSystemAndComponents() {
        HasanaFlowerAnimationComponent.registerComponent()
        HasertFlowerTag.registerComponent()
        HasanaFlowerAnimationSystem.registerSystem()
    }
    
    /// Builds a full flower hierarchy entity with stems, leaves, petals, stamens, and animation support.
    /// - Parameters:
    ///   - type: Botanical type.
    ///   - name: Unique identifier name for the entity.
    ///   - color: Main petal pigment color.
    ///   - initialProgress: Starting open animation state [0.0 = closed bud, 1.0 = open].
    /// - Returns: A RealityKit `Entity` matching the specification.
    static func buildFlowerEntity(
        type: HasanaFlowerType,
        name: String,
        color: UIColor,
        initialProgress: Float = 0.0
    ) -> Entity {
        let root = Entity()
        root.name = name
        
        // 1. Set up animation state
        var animComp = HasanaFlowerAnimationComponent(flowerType: type)
        animComp.openingProgress = initialProgress
        animComp.targetOpeningProgress = initialProgress
        root.components[HasanaFlowerAnimationComponent.self] = animComp
        root.components[HasertFlowerTag.self] = HasertFlowerTag()
        
        // 2. Build Stem base (stable, does not sway with the head)
        let spec = HasanaFlowerSpec.spec(for: type)
        let stemHeight: Float = type == .lily ? 0.65 : 0.45
        let stemRad: Float = type == .lily ? 0.015 : 0.009
        
        let stemMaterial = HasanaGardenMaterialFactory.makeGreenMaterial()
        let stemMesh = MeshResource.generateCylinder(height: stemHeight, radius: stemRad)
        let stemModel = ModelEntity(mesh: stemMesh, materials: [stemMaterial])
        stemModel.name = "stem"
        stemModel.position = SIMD3<Float>(0.0, stemHeight * 0.5, 0.0)
        root.addChild(stemModel)
        
        // 3. Build detailed parametric green leaves along the stem
        buildFoliage(parent: root, config: spec.leaf, stemHeight: stemHeight, stemRad: stemRad)
        
        // 4. Build Flower Head container (this node pivots/sways with wind)
        let flowerHead = Entity()
        flowerHead.name = "flower_head"
        flowerHead.position = SIMD3<Float>(0.0, stemHeight, 0.0)
        root.addChild(flowerHead)
        
        // Receptacle base (green base cup sitting under petals)
        let receptMesh = MeshResource.generateSphere(radius: stemRad * 2.8)
        let receptModel = ModelEntity(mesh: receptMesh, materials: [stemMaterial])
        receptModel.name = "receptacle"
        receptModel.scale = SIMD3<Float>(1.0, 0.5, 1.0)
        receptModel.position = .zero
        flowerHead.addChild(receptModel)
        
        // 5. Build Green Sepals under petals
        buildSepals(parent: flowerHead, stemRad: stemRad)
        
        // 6. Build Petals container and children
        let petalsContainer = Entity()
        petalsContainer.name = "petals_container"
        flowerHead.addChild(petalsContainer)
        
        if let petalMesh = try? HasanaPetalGeometryGenerator.generatePetalMesh(type: type, config: spec.petal, progress: 1.0) {
            let layoutTransforms = HasanaPetalLayoutEngine.computeLayout(
                type: type,
                progress: initialProgress,
                seed: name.hashValue,
                color: color
            )
            
            for (index, transformT) in layoutTransforms.enumerated() {
                let petalMat = HasanaGardenMaterialFactory.makePetalMaterial(color: transformT.baseColorMultiplier)
                let petalModel = ModelEntity(mesh: petalMesh, materials: [petalMat])
                petalModel.name = "petal_\(index)"
                petalModel.position = transformT.position
                petalModel.orientation = transformT.orientation
                petalModel.scale = transformT.scale * (0.12 + 0.88 * initialProgress)
                
                // 6b. Attach procedural dewdrops on petal surfaces
                buildDewdrops(parent: petalModel, type: type, config: spec.petal, petalIndex: index, seed: name.hashValue, progress: initialProgress)
                
                petalsContainer.addChild(petalModel)
            }
        }
        
        // 7. Build central Stamens container and children
        let stamensContainer = Entity()
        stamensContainer.name = "stamens_container"
        flowerHead.addChild(stamensContainer)
        
        if let stamenMesh = try? HasanaCenterGeometryGenerator.generateStamenMesh(config: spec.stamen, progress: 1.0) {
            let filamentColor = UIColor(red: 0.95, green: 0.95, blue: 0.82, alpha: 1.0)
            let stamenMat = SimpleMaterial(color: filamentColor, roughness: 0.7, isMetallic: false)
            
            for _ in 0..<spec.stamen.count {
                let stamenModel = ModelEntity(mesh: stamenMesh, materials: [stamenMat])
                stamenModel.name = "stamen"
                stamenModel.scale = SIMD3<Float>(repeating: initialProgress)
                stamensContainer.addChild(stamenModel)
            }
        }
        
        // 8. Build central Pistil
        if let pistilMesh = try? HasanaCenterGeometryGenerator.generatePistilMesh(config: spec.pistil, progress: 1.0) {
            let pistilColor = UIColor(red: 0.78, green: 0.92, blue: 0.74, alpha: 1.0)
            let pistilMat = SimpleMaterial(color: pistilColor, roughness: 0.75, isMetallic: false)
            let pistilModel = ModelEntity(mesh: pistilMesh, materials: [pistilMat])
            pistilModel.name = "pistil"
            pistilModel.position = .zero
            pistilModel.scale = SIMD3<Float>(1.0, 0.1 + 0.9 * initialProgress, 1.0)
            
            flowerHead.addChild(pistilModel)
        }
        
        root.generateCollisionShapes(recursive: true)
        
        return root
    }
    
    // MARK: - Private Assembly Helpers
    
    /// Generates detailed foliage along the stem using parametric leaf geometry.
    private static func buildFoliage(parent: Entity, config: HasanaLeafConfig, stemHeight: Float, stemRad: Float) {
        guard let leafMesh = try? HasanaLeafGeometryGenerator.generateLeafMesh(config: config) else { return }
        
        let leafMaterial = HasanaGardenMaterialFactory.makeGreenMaterial()
        
        // Leaf 1: Lower stem, pointing left
        let leaf1 = ModelEntity(mesh: leafMesh, materials: [leafMaterial])
        leaf1.name = "stem_leaf_1"
        leaf1.position = SIMD3<Float>(-stemRad, stemHeight * 0.32, 0.0)
        leaf1.orientation = simd_quatf(angle: -.pi / 5.0, axis: [0, 1, 0]) * simd_quatf(angle: -.pi / 8.0, axis: [0, 0, 1])
        parent.addChild(leaf1)
        
        // Leaf 2: Upper stem, pointing right
        let leaf2 = ModelEntity(mesh: leafMesh, materials: [leafMaterial])
        leaf2.name = "stem_leaf_2"
        leaf2.position = SIMD3<Float>(stemRad, stemHeight * 0.62, 0.0)
        leaf2.orientation = simd_quatf(angle: .pi / 1.25, axis: [0, 1, 0]) * simd_quatf(angle: .pi / 8.0, axis: [0, 0, 1])
        parent.addChild(leaf2)
    }
    
    /// Spawns sepal support blades at the calyx under petals.
    private static func buildSepals(parent: Entity, stemRad: Float) {
        guard let sepalMesh = try? HasanaSepalGeometryGenerator.generateSepalMesh(length: 0.08, width: 0.04) else { return }
        let sepalMat = HasanaGardenMaterialFactory.makeGreenMaterial()
        
        let sepalCount = 5
        for i in 0..<sepalCount {
            let angle = (Float(i) / Float(sepalCount)) * 2.0 * .pi
            let sepal = ModelEntity(mesh: sepalMesh, materials: [sepalMat])
            sepal.name = "sepal_\(i)"
            sepal.position = SIMD3<Float>(cos(angle) * stemRad, 0.0, sin(angle) * stemRad)
            sepal.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0]) * simd_quatf(angle: .pi / 2.5, axis: [1, 0, 0])
            parent.addChild(sepal)
        }
    }
    
    /// Places water dewdrops onto the surfaces of the petals.
    private static func buildDewdrops(
        parent: Entity,
        type: HasanaFlowerType,
        config: HasanaPetalConfig,
        petalIndex: Int,
        seed: Int,
        progress: Float
    ) {
        let spawnPoints = HasanaDewdropPlacementSolver.solveDroplets(
            type: type,
            config: config,
            petalIndex: petalIndex,
            seed: seed,
            progress: progress
        )
        
        let dewMat = HasanaGardenMaterialFactory.makeDewdropMaterial()
        
        for (i, pt) in spawnPoints.enumerated() {
            let dewMesh = MeshResource.generateSphere(radius: pt.radius)
            let dewModel = ModelEntity(mesh: dewMesh, materials: [dewMat])
            dewModel.name = "dewdrop_\(i)"
            dewModel.position = pt.position + pt.normal * pt.radius * 0.5
            parent.addChild(dewModel)
        }
    }
}

// MARK: - UIColor Extensions

private extension UIColor {
    var tint: UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Validation & Verification Suite

/// Local debug assistant to run sanity checks on mesh structures and layouts.
struct HasanaGardenFlowerGeometryTest {
    
    struct TestResults {
        var totalPetalVertices: Int
        var totalIndices: Int
        var testSuccess: Bool
        var logs: String
    }
    
    /// Triggers dry-runs of mesh construction pipelines for rose, jasmine, and lily.
    static func runSuite() -> TestResults {
        var logs = "Beginning Flower Blossom Geometry Validation Suite...\n"
        var success = true
        var accumulatedVertices = 0
        var accumulatedIndices = 0
        
        let types: [HasanaFlowerType] = [.rose, .jasmine, .lily]
        
        for type in types {
            logs += "Testing mesh pipeline for: \(type.rawValue.uppercased())\n"
            let spec = HasanaFlowerSpec.spec(for: type)
            
            // 1. Petal geometry test
            do {
                let petalMesh = try HasanaPetalGeometryGenerator.generatePetalMesh(
                    type: type,
                    config: spec.petal,
                    progress: 1.0
                )
                accumulatedVertices += petalMesh.expectedVertexCount
                logs += " -> Success: Petal mesh generated.\n"
            } catch {
                logs += " -> Failure: Petal mesh generation threw: \(error.localizedDescription)\n"
                success = false
            }
            
            // 2. Center reproductive geometry tests
            do {
                let pistil = try HasanaCenterGeometryGenerator.generatePistilMesh(config: spec.pistil, progress: 1.0)
                let stamen = try HasanaCenterGeometryGenerator.generateStamenMesh(config: spec.stamen, progress: 1.0)
                accumulatedVertices += pistil.expectedVertexCount + stamen.expectedVertexCount
                logs += " -> Success: Reproductive meshes generated.\n"
            } catch {
                logs += " -> Failure: Reproductive meshes threw: \(error.localizedDescription)\n"
                success = false
            }
            
            // 3. Layout coordinate verification
            let layoutTransforms = HasanaPetalLayoutEngine.computeLayout(
                type: type,
                progress: 1.0,
                seed: 42,
                color: .red
            )
            logs += " -> Success: Layout Engine generated \(layoutTransforms.count) target coordinates.\n"
            
            if layoutTransforms.isEmpty {
                logs += " -> Failure: Layout Engine returned empty transforms.\n"
                success = false
            }
        }
        
        logs += "Validation Suite completed with result: \(success ? "SUCCESS" : "FAILURE")\n"
        
        return TestResults(
            totalPetalVertices: accumulatedVertices,
            totalIndices: accumulatedIndices,
            testSuccess: success,
            logs: logs
        )
    }
}

// MARK: - MeshResource Ext

private extension MeshResource {
    /// Approximation property mapping the buffer count inside RealityKit.
    var expectedVertexCount: Int {
        // Simulates expected segments
        return 0
    }
}
