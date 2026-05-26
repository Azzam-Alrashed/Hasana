//
//  HasanaThemePaletteEngine.swift
//  Hasana
//
//  Created by Azzam Alrashed on 2026-05-26.
//  Copyright © 2026 Azzam Alrashed. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import RealityKit
import Combine
import Observation

// MARK: - WCAG Contrast & Luminance Definitions
/// Audit result indicating contrast compliance levels.
struct ContrastAuditResult: Codable, Hashable {
    let ratio: CGFloat
    let passAANormal: Bool
    let passAAALarge: Bool
    let passAAALormal: Bool // 7.0:1
    let passAALarge: Bool   // 3.0:1
    
    var overallStatus: String {
        if passAAALormal && passAAALarge {
            return "AAA Compliant"
        } else if passAANormal && passAALarge {
            return "AA Compliant"
        } else if passAALarge {
            return "Large Text Only"
        } else {
            return "Fail Compliance"
        }
    }
}

/// Utility for assessing contrast ratios between foreground and background colors according to WCAG 2.1 guidelines.
enum WCAGContrastAnalyzer {
    
    /// Computes relative luminance of a color.
    static func relativeLuminance(for color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        func convert(_ channel: CGFloat) -> CGFloat {
            return channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        
        let R = convert(red)
        let G = convert(green)
        let B = convert(blue)
        
        return 0.2126 * R + 0.7152 * G + 0.0722 * B
    }
    
    /// Computes contrast ratio between two colors. Formula: (L1 + 0.05) / (L2 + 0.05)
    static func contrastRatio(between color1: UIColor, and color2: UIColor) -> CGFloat {
        let l1 = relativeLuminance(for: color1)
        let l2 = relativeLuminance(for: color2)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }
    
    /// Evaluates if foreground on background passes WCAG requirements.
    static func audit(foreground: UIColor, background: UIColor) -> ContrastAuditResult {
        let ratio = contrastRatio(between: foreground, and: background)
        return ContrastAuditResult(
            ratio: ratio,
            passAANormal: ratio >= 4.5,
            passAAALarge: ratio >= 4.5,
            passAAALormal: ratio >= 7.0,
            passAALarge: ratio >= 3.0
        )
    }
}

// MARK: - Color Hex Encoder / Decoder
enum ThemeColorCoder {
    
    /// Formats a UIColor to a 6-character hex string (e.g. "#FF55AA").
    static func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ri = Int(max(0, min(255, round(r * 255.0))))
        let gi = Int(max(0, min(255, round(g * 255.0))))
        let bi = Int(max(0, min(255, round(b * 255.0))))
        
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
    
    /// Decodes a hex string to a UIColor. Supports fallback to clear color.
    static func color(from hex: String) -> UIColor {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        
        switch value.count {
        case 6:
            red = (int >> 16) & 0xFF
            green = (int >> 8) & 0xFF
            blue = int & 0xFF
        default:
            return .clear
        }
        
        return UIColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: 1.0
        )
    }
}

extension UIColor {
    convenience init(themeHex hex: String) {
        self.init(cgColor: ThemeColorCoder.color(from: hex).cgColor)
    }
    
    var themeHex: String {
        return ThemeColorCoder.hexString(from: self)
    }
}

extension Color {
    init(themeHex hex: String) {
        self.init(uiColor: ThemeColorCoder.color(from: hex))
    }
}

// MARK: - HSL Color & Interpolation Engine
struct HSLColor: Codable, Hashable {
    var h: CGFloat // Hue (0...360)
    var s: CGFloat // Saturation (0...1)
    var l: CGFloat // Lightness (0...1)
    var a: CGFloat // Alpha (0...1)
    
    init(h: CGFloat, s: CGFloat, l: CGFloat, a: CGFloat = 1.0) {
        self.h = h
        self.s = s
        self.l = l
        self.a = a
    }
    
    init(uiColor: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &alpha)
        
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        var hVal: CGFloat = 0
        var sVal: CGFloat = 0
        let lVal = (maxVal + minVal) / 2.0
        
        if maxVal != minVal {
            let d = maxVal - minVal
            sVal = lVal > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal)
            
            if maxVal == r {
                hVal = (g - b) / d + (g < b ? 6.0 : 0.0)
            } else if maxVal == g {
                hVal = (b - r) / d + 2.0
            } else if maxVal == b {
                hVal = (r - g) / d + 4.0
            }
            hVal /= 6.0
        }
        
        self.h = hVal * 360.0
        self.s = sVal
        self.l = lVal
        self.a = alpha
    }
    
    func toUIColor() -> UIColor {
        let hNorm = h / 360.0
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        if s == 0 {
            r = l
            g = l
            b = l
        } else {
            func hue2rgb(p: CGFloat, q: CGFloat, t: CGFloat) -> CGFloat {
                var tVal = t
                if tVal < 0 { tVal += 1 }
                if tVal > 1 { tVal -= 1 }
                if tVal < 1.0/6.0 { return p + (q - p) * 6.0 * tVal }
                if tVal < 1.0/2.0 { return q }
                if tVal < 2.0/3.0 { return p + (q - p) * (2.0/3.0 - tVal) * 6.0 }
                return p
            }
            
            let q = l < 0.5 ? l * (1.0 + s) : l + s - l * s
            let p = 2.0 * l - q
            
            r = hue2rgb(p: p, q: q, t: hNorm + 1.0/3.0)
            g = hue2rgb(p: p, q: q, t: hNorm)
            b = hue2rgb(p: p, q: q, t: hNorm - 1.0/3.0)
        }
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Interpolates smoothly between this color and another HSL color. Useful for transitions like sunset/sunrise.
    func lerp(to target: HSLColor, fraction: CGFloat) -> HSLColor {
        let f = max(0, min(1, fraction))
        
        // Handle hue wrapping correctly
        var hStart = self.h
        var hEnd = target.h
        let diff = hEnd - hStart
        
        if diff > 180 {
            hStart += 360
        } else if diff < -180 {
            hEnd += 360
        }
        
        var interpolatedH = hStart + (hEnd - hStart) * f
        if interpolatedH >= 360 {
            interpolatedH -= 360
        } else if interpolatedH < 0 {
            interpolatedH += 360
        }
        
        let interpolatedS = self.s + (target.s - self.s) * f
        let interpolatedL = self.l + (target.l - self.l) * f
        let interpolatedA = self.a + (target.a - self.a) * f
        
        return HSLColor(h: interpolatedH, s: interpolatedS, l: interpolatedL, a: interpolatedA)
    }
    
    /// Generates a darker mode variant of this HSL color.
    func darkVariant() -> HSLColor {
        var targetL = 1.0 - l
        if targetL > 0.4 {
            targetL = 0.12 + (targetL * 0.15)
        } else {
            targetL = max(0.06, targetL * 0.7)
        }
        
        // Desaturate slightly to keep text and backgrounds readable in low light
        let targetS = s * 0.85
        return HSLColor(h: h, s: targetS, l: targetL, a: a)
    }
}

// MARK: - Customizable Theme Palette Definition
struct CustomThemePalette: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var isSystem: Bool
    
    // UI Palette Hex Colors (Light Mode)
    var backgroundLight: String
    var backgroundSecondaryLight: String
    var elevatedSurfaceLight: String
    var elevatedSurfaceSoftLight: String
    var accentLight: String
    var accentSoftLight: String
    var borderLight: String
    var borderStrongLight: String
    var textPrimaryLight: String
    var textMutedLight: String
    var shadowLight: String
    
    // UI Palette Hex Colors (Dark Mode)
    var backgroundDark: String
    var backgroundSecondaryDark: String
    var elevatedSurfaceDark: String
    var elevatedSurfaceSoftDark: String
    var accentDark: String
    var accentSoftDark: String
    var borderDark: String
    var borderStrongDark: String
    var textPrimaryDark: String
    var textMutedDark: String
    var shadowDark: String
    
    // 3D Garden Specific Light Mode Colors
    var foliageColorLight: String
    var blossomColorLight: String
    var trunkColorLight: String
    var soilColorLight: String
    var waterColorLight: String
    var skyColorLight: String
    
    // 3D Garden Specific Dark Mode Colors
    var foliageColorDark: String
    var blossomColorDark: String
    var trunkColorDark: String
    var soilColorDark: String
    var waterColorDark: String
    var skyColorDark: String
    
    // 3D Physically-Based Material Parameters
    var foliageMetallic: Float
    var foliageRoughness: Float
    var blossomMetallic: Float
    var blossomRoughness: Float
    var trunkMetallic: Float
    var trunkRoughness: Float
    var soilMetallic: Float
    var soilRoughness: Float
    var waterMetallic: Float
    var waterRoughness: Float
    var waterSpecular: Float
    var waterOpacity: Float
    
    // Core Layout Options & Presets
    var cornerRadiusSmall: CGFloat
    var cornerRadiusMedium: CGFloat
    var cornerRadiusLarge: CGFloat
    var spacingSmall: CGFloat
    var spacingMedium: CGFloat
    var spacingLarge: CGFloat
    
    init(
        id: UUID = UUID(),
        name: String,
        isSystem: Bool = false,
        backgroundLight: String,
        backgroundSecondaryLight: String,
        elevatedSurfaceLight: String,
        elevatedSurfaceSoftLight: String,
        accentLight: String,
        accentSoftLight: String,
        borderLight: String,
        borderStrongLight: String,
        textPrimaryLight: String,
        textMutedLight: String,
        shadowLight: String,
        backgroundDark: String,
        backgroundSecondaryDark: String,
        elevatedSurfaceDark: String,
        elevatedSurfaceSoftDark: String,
        accentDark: String,
        accentSoftDark: String,
        borderDark: String,
        borderStrongDark: String,
        textPrimaryDark: String,
        textMutedDark: String,
        shadowDark: String,
        foliageColorLight: String,
        blossomColorLight: String,
        trunkColorLight: String,
        soilColorLight: String,
        waterColorLight: String,
        skyColorLight: String,
        foliageColorDark: String,
        blossomColorDark: String,
        trunkColorDark: String,
        soilColorDark: String,
        waterColorDark: String,
        skyColorDark: String,
        foliageMetallic: Float = 0.1,
        foliageRoughness: Float = 0.6,
        blossomMetallic: Float = 0.0,
        blossomRoughness: Float = 0.5,
        trunkMetallic: Float = 0.0,
        trunkRoughness: Float = 0.85,
        soilMetallic: Float = 0.0,
        soilRoughness: Float = 0.95,
        waterMetallic: Float = 0.9,
        waterRoughness: Float = 0.05,
        waterSpecular: Float = 1.0,
        waterOpacity: Float = 0.75,
        cornerRadiusSmall: CGFloat = 8,
        cornerRadiusMedium: CGFloat = 16,
        cornerRadiusLarge: CGFloat = 24,
        spacingSmall: CGFloat = 8,
        spacingMedium: CGFloat = 16,
        spacingLarge: CGFloat = 24
    ) {
        self.id = id
        self.name = name
        self.isSystem = isSystem
        self.backgroundLight = backgroundLight
        self.backgroundSecondaryLight = backgroundSecondaryLight
        self.elevatedSurfaceLight = elevatedSurfaceLight
        self.elevatedSurfaceSoftLight = elevatedSurfaceSoftLight
        self.accentLight = accentLight
        self.accentSoftLight = accentSoftLight
        self.borderLight = borderLight
        self.borderStrongLight = borderStrongLight
        self.textPrimaryLight = textPrimaryLight
        self.textMutedLight = textMutedLight
        self.shadowLight = shadowLight
        self.backgroundDark = backgroundDark
        self.backgroundSecondaryDark = backgroundSecondaryDark
        self.elevatedSurfaceDark = elevatedSurfaceDark
        self.elevatedSurfaceSoftDark = elevatedSurfaceSoftDark
        self.accentDark = accentDark
        self.accentSoftDark = accentSoftDark
        self.borderDark = borderDark
        self.borderStrongDark = borderStrongDark
        self.textPrimaryDark = textPrimaryDark
        self.textMutedDark = textMutedDark
        self.shadowDark = shadowDark
        self.foliageColorLight = foliageColorLight
        self.blossomColorLight = blossomColorLight
        self.trunkColorLight = trunkColorLight
        self.soilColorLight = soilColorLight
        self.waterColorLight = waterColorLight
        self.skyColorLight = skyColorLight
        self.foliageColorDark = foliageColorDark
        self.blossomColorDark = blossomColorDark
        self.trunkColorDark = trunkColorDark
        self.soilColorDark = soilColorDark
        self.waterColorDark = waterColorDark
        self.skyColorDark = skyColorDark
        self.foliageMetallic = foliageMetallic
        self.foliageRoughness = foliageRoughness
        self.blossomMetallic = blossomMetallic
        self.blossomRoughness = blossomRoughness
        self.trunkMetallic = trunkMetallic
        self.trunkRoughness = trunkRoughness
        self.soilMetallic = soilMetallic
        self.soilRoughness = soilRoughness
        self.waterMetallic = waterMetallic
        self.waterRoughness = waterRoughness
        self.waterSpecular = waterSpecular
        self.waterOpacity = waterOpacity
        self.cornerRadiusSmall = cornerRadiusSmall
        self.cornerRadiusMedium = cornerRadiusMedium
        self.cornerRadiusLarge = cornerRadiusLarge
        self.spacingSmall = spacingSmall
        self.spacingMedium = spacingMedium
        self.spacingLarge = spacingLarge
    }
}

// MARK: - RealityKit 3D Material Helpers
#if canImport(RealityKit)
enum HasanaRealityKitMaterialBuilder {
    
    /// Creates a transparent or solid PhysicallyBasedMaterial.
    @available(iOS 15.0, *)
    static func createPBRMaterial(
        color: UIColor,
        metallic: Float,
        roughness: Float,
        specular: Float = 1.0,
        opacity: Float = 1.0
    ) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = PhysicallyBasedMaterial.BaseColor(tint: color.withAlphaComponent(CGFloat(opacity)))
        mat.metallic = PhysicallyBasedMaterial.Metallic(scale: metallic)
        mat.roughness = PhysicallyBasedMaterial.Roughness(scale: roughness)
        mat.specular = PhysicallyBasedMaterial.Specular(scale: specular)
        
        if opacity < 1.0 {
            mat.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: opacity))
        } else {
            mat.blending = .opaque
        }
        return mat
    }
}

extension CustomThemePalette {
    
    /// Creates the foliage material for 3D plants.
    func foliageMaterial(for scheme: ColorScheme) -> RealityKit.Material {
        let hex = scheme == .dark ? foliageColorDark : foliageColorLight
        let col = UIColor(themeHex: hex)
        if #available(iOS 15.0, *) {
            return HasanaRealityKitMaterialBuilder.createPBRMaterial(
                color: col,
                metallic: foliageMetallic,
                roughness: foliageRoughness
            )
        } else {
            return SimpleMaterial(color: col, isMetallic: foliageMetallic > 0.4)
        }
    }
    
    /// Creates the flower blossom material for 3D plants.
    func blossomMaterial(for scheme: ColorScheme) -> RealityKit.Material {
        let hex = scheme == .dark ? blossomColorDark : blossomColorLight
        let col = UIColor(themeHex: hex)
        if #available(iOS 15.0, *) {
            return HasanaRealityKitMaterialBuilder.createPBRMaterial(
                color: col,
                metallic: blossomMetallic,
                roughness: blossomRoughness
            )
        } else {
            return SimpleMaterial(color: col, isMetallic: blossomMetallic > 0.4)
        }
    }
    
    /// Creates the wood stem/trunk material.
    func trunkMaterial(for scheme: ColorScheme) -> RealityKit.Material {
        let hex = scheme == .dark ? trunkColorDark : trunkColorLight
        let col = UIColor(themeHex: hex)
        if #available(iOS 15.0, *) {
            return HasanaRealityKitMaterialBuilder.createPBRMaterial(
                color: col,
                metallic: trunkMetallic,
                roughness: trunkRoughness
            )
        } else {
            return SimpleMaterial(color: col, isMetallic: trunkMetallic > 0.4)
        }
    }
    
    /// Creates the organic ground/soil material.
    func soilMaterial(for scheme: ColorScheme) -> RealityKit.Material {
        let hex = scheme == .dark ? soilColorDark : soilColorLight
        let col = UIColor(themeHex: hex)
        if #available(iOS 15.0, *) {
            return HasanaRealityKitMaterialBuilder.createPBRMaterial(
                color: col,
                metallic: soilMetallic,
                roughness: soilRoughness
            )
        } else {
            return SimpleMaterial(color: col, isMetallic: soilMetallic > 0.4)
        }
    }
    
    /// Creates the fluid water material.
    func waterMaterial(for scheme: ColorScheme) -> RealityKit.Material {
        let hex = scheme == .dark ? waterColorDark : waterColorLight
        let col = UIColor(themeHex: hex)
        if #available(iOS 15.0, *) {
            return HasanaRealityKitMaterialBuilder.createPBRMaterial(
                color: col,
                metallic: waterMetallic,
                roughness: waterRoughness,
                specular: waterSpecular,
                opacity: waterOpacity
            )
        } else {
            return SimpleMaterial(color: col.withAlphaComponent(CGFloat(waterOpacity)), isMetallic: waterMetallic > 0.4)
        }
    }
}
#endif

// MARK: - Typography & Fonts Customization Settings
enum HasanaFontWeight: String, Codable, CaseIterable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
    
    var swiftUIWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
    
    var uiKitWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

struct HasanaFontDefinition: Codable, Hashable {
    var size: CGFloat
    var weight: HasanaFontWeight
    var tracking: CGFloat
    var leading: CGFloat
    
    init(size: CGFloat, weight: HasanaFontWeight, tracking: CGFloat, leading: CGFloat) {
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.leading = leading
    }
    
    /// Dynamic font scaling factor. Computes adjusted size based on UI Layout preferences.
    func font(name: String?, language: HasanaLanguage) -> Font {
        let appliedScale: CGFloat = (language == .arabic) ? 1.08 : 1.0 // Arabic text usually needs slightly larger text at lower sizes
        let scaledSize = size * appliedScale
        
        if let fontName = name, !fontName.isEmpty, fontName != "System" {
            return Font.custom(fontName, size: scaledSize).weight(weight.swiftUIWeight)
        }
        return Font.system(size: scaledSize, weight: weight.swiftUIWeight)
    }
    
    func uiFont(name: String?, language: HasanaLanguage) -> UIFont {
        let appliedScale: CGFloat = (language == .arabic) ? 1.08 : 1.0
        let scaledSize = size * appliedScale
        
        if let fontName = name, !fontName.isEmpty, fontName != "System" {
            return UIFont(name: fontName, size: scaledSize) ?? UIFont.systemFont(ofSize: scaledSize, weight: weight.uiKitWeight)
        }
        return UIFont.systemFont(ofSize: scaledSize, weight: weight.uiKitWeight)
    }
}

struct HasanaFontChoice: Codable, Hashable, Identifiable {
    var id: String
    var displayName: String
    var latinFontName: String?
    var arabicFontName: String?
    
    init(id: String, displayName: String, latinFontName: String? = nil, arabicFontName: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.latinFontName = latinFontName
        self.arabicFontName = arabicFontName
    }
    
    func fontName(for direction: LayoutDirection) -> String? {
        return direction == .rightToLeft ? arabicFontName : latinFontName
    }
    
    // Default system pairings
    static let system = HasanaFontChoice(id: "system", displayName: "System Default")
    static let rounded = HasanaFontChoice(id: "rounded", displayName: "System Rounded", latinFontName: "SF Pro Rounded", arabicFontName: "Geeza Pro Bold")
    static let traditional = HasanaFontChoice(id: "traditional", displayName: "Traditional Quranic", latinFontName: "Georgia", arabicFontName: "Diwan Mishafi")
    static let modern = HasanaFontChoice(id: "modern", displayName: "Cairo Modern", latinFontName: "Avenir Next", arabicFontName: "Damascus")
    
    static let allFontChoices: [HasanaFontChoice] = [.system, .rounded, .traditional, .modern]
}

struct HasanaFontPalette: Codable, Hashable {
    var titleLarge: HasanaFontDefinition
    var titleMedium: HasanaFontDefinition
    var bodyLarge: HasanaFontDefinition
    var bodyMedium: HasanaFontDefinition
    var caption: HasanaFontDefinition
    var arabicCalligraphy: HasanaFontDefinition
    
    static var `default`: HasanaFontPalette {
        HasanaFontPalette(
            titleLarge: HasanaFontDefinition(size: 28, weight: .bold, tracking: 0.2, leading: 34),
            titleMedium: HasanaFontDefinition(size: 20, weight: .semibold, tracking: 0.1, leading: 26),
            bodyLarge: HasanaFontDefinition(size: 16, weight: .regular, tracking: 0.0, leading: 22),
            bodyMedium: HasanaFontDefinition(size: 14, weight: .regular, tracking: 0.0, leading: 20),
            caption: HasanaFontDefinition(size: 12, weight: .light, tracking: 0.1, leading: 16),
            arabicCalligraphy: HasanaFontDefinition(size: 32, weight: .medium, tracking: 0.0, leading: 42)
        )
    }
}

// MARK: - Customizable Themes Presets
extension CustomThemePalette {
    
    static var gardenPreset: CustomThemePalette {
        CustomThemePalette(
            id: UUID(uuidString: "7a2b918f-ca96-41e9-847e-8580556a3195")!,
            name: "Garden",
            isSystem: true,
            backgroundLight: "#F3F7FC",
            backgroundSecondaryLight: "#E6EEF7",
            elevatedSurfaceLight: "#FBFDFF",
            elevatedSurfaceSoftLight: "#F5F9FD",
            accentLight: "#4C99E9",
            accentSoftLight: "#EBF3FC",
            borderLight: "#D2E2F5",
            borderStrongLight: "#ADCBEF",
            textPrimaryLight: "#0E1724",
            textMutedLight: "#5F7085",
            shadowLight: "#182E4B",
            backgroundDark: "#0B131E",
            backgroundSecondaryDark: "#111E30",
            elevatedSurfaceDark: "#15243B",
            elevatedSurfaceSoftDark: "#192A44",
            accentDark: "#7FB5F5",
            accentSoftDark: "#182E4B",
            borderDark: "#223550",
            borderStrongDark: "#3D5C85",
            textPrimaryDark: "#F0F5FA",
            textMutedDark: "#A3B5C9",
            shadowDark: "#000000",
            foliageColorLight: "#3B7A57",
            blossomColorLight: "#E2583E",
            trunkColorLight: "#8B5A2B",
            soilColorLight: "#6E473B",
            waterColorLight: "#3399FF",
            skyColorLight: "#87CEEB",
            foliageColorDark: "#50C878",
            blossomColorDark: "#FF6F59",
            trunkColorDark: "#CD853F",
            soilColorDark: "#8B7355",
            waterColorDark: "#00CCCC",
            skyColorDark: "#191970",
            foliageMetallic: 0.1,
            foliageRoughness: 0.65,
            blossomMetallic: 0.0,
            blossomRoughness: 0.5,
            trunkMetallic: 0.0,
            trunkRoughness: 0.85,
            soilMetallic: 0.0,
            soilRoughness: 0.95,
            waterMetallic: 0.9,
            waterRoughness: 0.05,
            waterSpecular: 1.0,
            waterOpacity: 0.7,
            cornerRadiusSmall: 8,
            cornerRadiusMedium: 16,
            cornerRadiusLarge: 24,
            spacingSmall: 8,
            spacingMedium: 16,
            spacingLarge: 24
        )
    }
    
    static var sunrisePreset: CustomThemePalette {
        CustomThemePalette(
            id: UUID(uuidString: "8b3c0290-db07-42fa-958f-9691667b42a6")!,
            name: "Sunrise",
            isSystem: true,
            backgroundLight: "#FFF7EE",
            backgroundSecondaryLight: "#F3E7D9",
            elevatedSurfaceLight: "#FFFCF7",
            elevatedSurfaceSoftLight: "#FAF0E4",
            accentLight: "#C6723A",
            accentSoftLight: "#F8E5D3",
            borderLight: "#E5CDB7",
            borderStrongLight: "#D6A77E",
            textPrimaryLight: "#2C1A0C",
            textMutedLight: "#7D6652",
            shadowLight: "#4A2B18",
            backgroundDark: "#17120D",
            backgroundSecondaryDark: "#241B13",
            elevatedSurfaceDark: "#30251A",
            elevatedSurfaceSoftDark: "#3A2A1D",
            accentDark: "#F1B26F",
            accentSoftDark: "#4A2B18",
            borderDark: "#513B2A",
            borderStrongDark: "#79593D",
            textPrimaryDark: "#FDF5EE",
            textMutedDark: "#C1AFA1",
            shadowDark: "#000000",
            foliageColorLight: "#808000",
            blossomColorLight: "#FF4500",
            trunkColorLight: "#A0522D",
            soilColorLight: "#8B4513",
            waterColorLight: "#FF8C00",
            skyColorLight: "#FFD700",
            foliageColorDark: "#9ACD32",
            blossomColorDark: "#FF6347",
            trunkColorDark: "#D2691E",
            soilColorDark: "#CD853F",
            waterColorDark: "#FFA500",
            skyColorDark: "#8B0000",
            foliageMetallic: 0.15,
            foliageRoughness: 0.55,
            blossomMetallic: 0.1,
            blossomRoughness: 0.4,
            trunkMetallic: 0.05,
            trunkRoughness: 0.8,
            soilMetallic: 0.0,
            soilRoughness: 0.9,
            waterMetallic: 0.85,
            waterRoughness: 0.08,
            waterSpecular: 0.9,
            waterOpacity: 0.8,
            cornerRadiusSmall: 8,
            cornerRadiusMedium: 16,
            cornerRadiusLarge: 24,
            spacingSmall: 8,
            spacingMedium: 16,
            spacingLarge: 24
        )
    }
    
    static var oceanPreset: CustomThemePalette {
        CustomThemePalette(
            id: UUID(uuidString: "9c4d1301-ec18-43fa-a69f-0702778c53b7")!,
            name: "Ocean",
            isSystem: true,
            backgroundLight: "#EFF8F7",
            backgroundSecondaryLight: "#DCEDEB",
            elevatedSurfaceLight: "#FAFFFE",
            elevatedSurfaceSoftLight: "#EEF9F7",
            accentLight: "#248D83",
            accentSoftLight: "#DDF3F0",
            borderLight: "#BDE0DC",
            borderStrongLight: "#77BEB6",
            textPrimaryLight: "#051A18",
            textMutedLight: "#4B6E6A",
            shadowLight: "#163C38",
            backgroundDark: "#071716",
            backgroundSecondaryDark: "#102523",
            elevatedSurfaceDark: "#173431",
            elevatedSurfaceSoftDark: "#1E403C",
            accentDark: "#63D0C5",
            accentSoftDark: "#163C38",
            borderDark: "#28524D",
            borderStrongDark: "#3D7C75",
            textPrimaryDark: "#F0FAF9",
            textMutedDark: "#8DBAB5",
            shadowDark: "#000000",
            foliageColorLight: "#008080",
            blossomColorLight: "#FF1493",
            trunkColorLight: "#5F9EA0",
            soilColorLight: "#2F4F4F",
            waterColorLight: "#00FFFF",
            skyColorLight: "#B0E0E6",
            foliageColorDark: "#20B2AA",
            blossomColorDark: "#FF69B4",
            trunkColorDark: "#4682B4",
            soilColorDark: "#3A5F5F",
            waterColorDark: "#008B8B",
            skyColorDark: "#191970",
            foliageMetallic: 0.2,
            foliageRoughness: 0.6,
            blossomMetallic: 0.15,
            blossomRoughness: 0.45,
            trunkMetallic: 0.05,
            trunkRoughness: 0.8,
            soilMetallic: 0.0,
            soilRoughness: 0.9,
            waterMetallic: 0.95,
            waterRoughness: 0.02,
            waterSpecular: 1.0,
            waterOpacity: 0.65,
            cornerRadiusSmall: 8,
            cornerRadiusMedium: 16,
            cornerRadiusLarge: 24,
            spacingSmall: 8,
            spacingMedium: 16,
            spacingLarge: 24
        )
    }
    
    static var lavenderPreset: CustomThemePalette {
        CustomThemePalette(
            id: UUID(uuidString: "ad5e2412-fd29-44fb-b7af-1813889d64c8")!,
            name: "Lavender",
            isSystem: true,
            backgroundLight: "#F7F4FB",
            backgroundSecondaryLight: "#EDE7F4",
            elevatedSurfaceLight: "#FEFBFF",
            elevatedSurfaceSoftLight: "#F5EFFA",
            accentLight: "#7B65B5",
            accentSoftLight: "#ECE5F8",
            borderLight: "#D7CAE9",
            borderStrongLight: "#B6A0D9",
            textPrimaryLight: "#1F1235",
            textMutedLight: "#67597F",
            shadowLight: "#372A54",
            backgroundDark: "#12101A",
            backgroundSecondaryDark: "#1F1A2D",
            elevatedSurfaceDark: "#2A243A",
            elevatedSurfaceSoftDark: "#342C47",
            accentDark: "#BEA8F2",
            accentSoftDark: "#372A54",
            borderDark: "#4A4062",
            borderStrongDark: "#75639B",
            textPrimaryDark: "#F9F6FC",
            textMutedDark: "#AE9FCA",
            shadowDark: "#000000",
            foliageColorLight: "#4B0082",
            blossomColorLight: "#DA70D6",
            trunkColorLight: "#8A2BE2",
            soilColorLight: "#483D8B",
            waterColorLight: "#E6E6FA",
            skyColorLight: "#D8BFD8",
            foliageColorDark: "#9370DB",
            blossomColorDark: "#EE82EE",
            trunkColorDark: "#BA55D3",
            soilColorDark: "#524785",
            waterColorDark: "#8A2BE2",
            skyColorDark: "#311432",
            foliageMetallic: 0.1,
            foliageRoughness: 0.7,
            blossomMetallic: 0.05,
            blossomRoughness: 0.5,
            trunkMetallic: 0.0,
            trunkRoughness: 0.88,
            soilMetallic: 0.0,
            soilRoughness: 0.93,
            waterMetallic: 0.9,
            waterRoughness: 0.04,
            waterSpecular: 0.95,
            waterOpacity: 0.7,
            cornerRadiusSmall: 8,
            cornerRadiusMedium: 16,
            cornerRadiusLarge: 24,
            spacingSmall: 8,
            spacingMedium: 16,
            spacingLarge: 24
        )
    }
    
    static let systemPalettes: [CustomThemePalette] = [
        .gardenPreset,
        .sunrisePreset,
        .oceanPreset,
        .lavenderPreset
    ]
}

// MARK: - Customizable Theme Palette Engine
@Observable
@MainActor
final class HasanaThemePaletteEngine {
    
    static let shared = HasanaThemePaletteEngine()
    
    // Active states
    var palettes: [CustomThemePalette] = []
    var activePaletteId: UUID = UUID()
    var activeFontChoice: HasanaFontChoice = .system
    var activeFontPalette: HasanaFontPalette = .default
    
    // Dynamic settings mapped from global settings
    var activeLanguage: HasanaLanguage = .arabic
    var appearanceOverride: HasanaAppearance = .system
    
    // Contrast Warning Tracker
    var contrastWarningInfo: String? = nil
    
    // Caching colors to optimize rendering loops
    private var colorCache: [String: Color] = [:]
    private var uiColorCache: [String: UIColor] = [:]
    
    private init() {
        loadData()
    }
    
    /// Resolves the currently active palette, falling back to Garden if missing.
    var activePalette: CustomThemePalette {
        if let selected = palettes.first(where: { $0.id == activePaletteId }) {
            return selected
        }
        return .gardenPreset
    }
    
    // MARK: - Disk Persistence
    private func loadData() {
        let defaults = UserDefaults.standard
        
        // Load custom palettes
        if let customData = defaults.data(forKey: "hasana.theme.custom_palettes"),
           let decoded = try? JSONDecoder().decode([CustomThemePalette].self, from: customData) {
            self.palettes = CustomThemePalette.systemPalettes + decoded
        } else {
            self.palettes = CustomThemePalette.systemPalettes
        }
        
        // Load active palette ID
        if let idString = defaults.string(forKey: "hasana.theme.active_id"),
           let uuid = UUID(uuidString: idString) {
            self.activePaletteId = uuid
        } else {
            self.activePaletteId = CustomThemePalette.gardenPreset.id
        }
        
        // Load active font choice
        if let fontData = defaults.data(forKey: "hasana.theme.active_font"),
           let decodedFont = try? JSONDecoder().decode(HasanaFontChoice.self, from: fontData) {
            self.activeFontChoice = decodedFont
        } else {
            self.activeFontChoice = .system
        }
        
        // Load Custom font definitions
        if let fontPalData = defaults.data(forKey: "hasana.theme.font_palette"),
           let decodedFontPal = try? JSONDecoder().decode(HasanaFontPalette.self, from: fontPalData) {
            self.activeFontPalette = decodedFontPal
        } else {
            self.activeFontPalette = .default
        }
        
        // Sync application settings overrides if present
        if let appStateString = defaults.string(forKey: "hasana.settings.appearance"),
           let appAppearance = HasanaAppearance(rawValue: appStateString) {
            self.appearanceOverride = appAppearance
        }
        
        if let langString = defaults.string(forKey: "hasana.settings.language"),
           let lang = HasanaLanguage(rawValue: langString) {
            self.activeLanguage = lang
        }
    }
    
    func saveToDisk() {
        let defaults = UserDefaults.standard
        
        // Filter out system palettes so we only save user-made ones
        let customPalettes = palettes.filter { !$0.isSystem }
        if let encoded = try? JSONEncoder().encode(customPalettes) {
            defaults.set(encoded, forKey: "hasana.theme.custom_palettes")
        }
        
        defaults.set(activePaletteId.uuidString, forKey: "hasana.theme.active_id")
        
        if let encodedFont = try? JSONEncoder().encode(activeFontChoice) {
            defaults.set(encodedFont, forKey: "hasana.theme.active_font")
        }
        
        if let encodedFontPal = try? JSONEncoder().encode(activeFontPalette) {
            defaults.set(encodedFontPal, forKey: "hasana.theme.font_palette")
        }
        
        // Clear caches so changes take place immediately
        colorCache.removeAll()
        uiColorCache.removeAll()
    }
    
    // MARK: - Core API
    
    /// Switch active palette.
    func selectPalette(_ id: UUID) {
        self.activePaletteId = id
        saveToDisk()
    }
    
    /// Create new or update existing user palette.
    func saveCustomPalette(_ palette: CustomThemePalette) {
        var updated = palette
        updated.isSystem = false
        
        if let idx = palettes.firstIndex(where: { $0.id == palette.id }) {
            palettes[idx] = updated
        } else {
            palettes.append(updated)
        }
        
        saveToDisk()
    }
    
    /// Delete user palette.
    func deleteCustomPalette(_ id: UUID) {
        guard let item = palettes.first(where: { $0.id == id }), !item.isSystem else {
            return
        }
        palettes.removeAll(where: { $0.id == id })
        if activePaletteId == id {
            activePaletteId = CustomThemePalette.gardenPreset.id
        }
        saveToDisk()
    }
    
    /// Updates font selections.
    func selectFontChoice(_ choice: HasanaFontChoice) {
        self.activeFontChoice = choice
        saveToDisk()
    }
    
    /// Updates dynamic Arabic/English sizing palette.
    func updateFontPalette(_ palette: HasanaFontPalette) {
        self.activeFontPalette = palette
        saveToDisk()
    }
    
    // MARK: - Base64 Export / Import Engine
    
    /// Encodes a palette into a base64 configuration string for easy sharing.
    func exportPalette(id: UUID) -> String? {
        guard let p = palettes.first(where: { $0.id == id }) else { return nil }
        guard let data = try? JSONEncoder().encode(p) else { return nil }
        return data.base64EncodedString()
    }
    
    /// Decodes and imports a palette string.
    func importPalette(from base64String: String) -> Bool {
        guard let data = Data(base64Encoded: base64String),
              var p = try? JSONDecoder().decode(CustomThemePalette.self, from: data) else {
            return false
        }
        
        p.id = UUID()
        p.isSystem = false
        p.name = "\(p.name) (Imported)"
        
        palettes.append(p)
        activePaletteId = p.id
        saveToDisk()
        return true
    }
    
    // MARK: - Dark Mode Color Auto-Generator
    
    /// Creates a beautifully harmonized Dark mode variant from a Light mode palette by shifting HSL curves.
    func generateDarkModePalette(fromLight light: CustomThemePalette, name: String) -> CustomThemePalette {
        func darkHex(_ hex: String) -> String {
            let col = ThemeColorCoder.color(from: hex)
            let hsl = HSLColor(uiColor: col)
            return ThemeColorCoder.hexString(from: hsl.darkVariant().toUIColor())
        }
        
        return CustomThemePalette(
            id: UUID(),
            name: name,
            isSystem: false,
            // Keep Light colors
            backgroundLight: light.backgroundLight,
            backgroundSecondaryLight: light.backgroundSecondaryLight,
            elevatedSurfaceLight: light.elevatedSurfaceLight,
            elevatedSurfaceSoftLight: light.elevatedSurfaceSoftLight,
            accentLight: light.accentLight,
            accentSoftLight: light.accentSoftLight,
            borderLight: light.borderLight,
            borderStrongLight: light.borderStrongLight,
            textPrimaryLight: light.textPrimaryLight,
            textMutedLight: light.textMutedLight,
            shadowLight: light.shadowLight,
            
            // Map dark variant automatically
            backgroundDark: darkHex(light.backgroundLight),
            backgroundSecondaryDark: darkHex(light.backgroundSecondaryLight),
            elevatedSurfaceDark: darkHex(light.elevatedSurfaceLight),
            elevatedSurfaceSoftDark: darkHex(light.elevatedSurfaceSoftLight),
            accentDark: light.accentDark != light.accentLight ? light.accentDark : darkHex(light.accentLight),
            accentSoftDark: darkHex(light.accentSoftLight),
            borderDark: darkHex(light.borderLight),
            borderStrongDark: darkHex(light.borderStrongLight),
            textPrimaryDark: "#F0F5FA",
            textMutedDark: "#A3B5C9",
            shadowDark: "#000000",
            
            // 3D Garden - Shift values
            foliageColorLight: light.foliageColorLight,
            blossomColorLight: light.blossomColorLight,
            trunkColorLight: light.trunkColorLight,
            soilColorLight: light.soilColorLight,
            waterColorLight: light.waterColorLight,
            skyColorLight: light.skyColorLight,
            
            foliageColorDark: darkHex(light.foliageColorLight),
            blossomColorDark: darkHex(light.blossomColorLight),
            trunkColorDark: darkHex(light.trunkColorLight),
            soilColorDark: darkHex(light.soilColorLight),
            waterColorDark: darkHex(light.waterColorLight),
            skyColorDark: darkHex(light.skyColorLight),
            
            foliageMetallic: light.foliageMetallic,
            foliageRoughness: light.foliageRoughness,
            blossomMetallic: light.blossomMetallic,
            blossomRoughness: light.blossomRoughness,
            trunkMetallic: light.trunkMetallic,
            trunkRoughness: light.trunkRoughness,
            soilMetallic: light.soilMetallic,
            soilRoughness: light.soilRoughness,
            waterMetallic: light.waterMetallic,
            waterRoughness: light.waterRoughness,
            waterSpecular: light.waterSpecular,
            waterOpacity: light.waterOpacity,
            
            cornerRadiusSmall: light.cornerRadiusSmall,
            cornerRadiusMedium: light.cornerRadiusMedium,
            cornerRadiusLarge: light.cornerRadiusLarge,
            spacingSmall: light.spacingSmall,
            spacingMedium: light.spacingMedium,
            spacingLarge: light.spacingLarge
        )
    }
    
    // MARK: - Dynamic Color Resolution
    
    /// Resolves color based on the current system or custom appearance override settings.
    func resolveColor(_ keyPathLight: KeyPath<CustomThemePalette, String>, _ keyPathDark: KeyPath<CustomThemePalette, String>, for scheme: ColorScheme) -> Color {
        let isDark = (appearanceOverride == .dark) || (appearanceOverride == .system && scheme == .dark)
        let hex = isDark ? activePalette[keyPath: keyPathDark] : activePalette[keyPath: keyPathLight]
        
        if let cached = colorCache[hex] {
            return cached
        }
        
        let col = Color(themeHex: hex)
        colorCache[hex] = col
        return col
    }
    
    func resolveUIColor(_ keyPathLight: KeyPath<CustomThemePalette, String>, _ keyPathDark: KeyPath<CustomThemePalette, String>, for style: UIUserInterfaceStyle) -> UIColor {
        let isDark = (appearanceOverride == .dark) || (appearanceOverride == .system && style == .dark)
        let hex = isDark ? activePalette[keyPath: keyPathDark] : activePalette[keyPath: keyPathLight]
        
        if let cached = uiColorCache[hex] {
            return cached
        }
        
        let col = UIColor(themeHex: hex)
        uiColorCache[hex] = col
        return col
    }
    
    // Direct Access Helpers
    func background(for scheme: ColorScheme) -> Color {
        resolveColor(\.backgroundLight, \.backgroundDark, for: scheme)
    }
    func backgroundSecondary(for scheme: ColorScheme) -> Color {
        resolveColor(\.backgroundSecondaryLight, \.backgroundSecondaryDark, for: scheme)
    }
    func elevatedSurface(for scheme: ColorScheme) -> Color {
        resolveColor(\.elevatedSurfaceLight, \.elevatedSurfaceDark, for: scheme)
    }
    func elevatedSurfaceSoft(for scheme: ColorScheme) -> Color {
        resolveColor(\.elevatedSurfaceSoftLight, \.elevatedSurfaceSoftDark, for: scheme)
    }
    func accent(for scheme: ColorScheme) -> Color {
        resolveColor(\.accentLight, \.accentDark, for: scheme)
    }
    func accentSoft(for scheme: ColorScheme) -> Color {
        resolveColor(\.accentSoftLight, \.accentSoftDark, for: scheme)
    }
    func border(for scheme: ColorScheme) -> Color {
        resolveColor(\.borderLight, \.borderDark, for: scheme)
    }
    func borderStrong(for scheme: ColorScheme) -> Color {
        resolveColor(\.borderStrongLight, \.borderStrongDark, for: scheme)
    }
    func textPrimary(for scheme: ColorScheme) -> Color {
        resolveColor(\.textPrimaryLight, \.textPrimaryDark, for: scheme)
    }
    func textMuted(for scheme: ColorScheme) -> Color {
        resolveColor(\.textMutedLight, \.textMutedDark, for: scheme)
    }
    func shadow(for scheme: ColorScheme) -> Color {
        resolveColor(\.shadowLight, \.shadowDark, for: scheme)
    }
    
    // MARK: - Dynamic Font Mapping
    
    /// Resolves font definition based on the selected typography configurations.
    func fontDefinition(for style: HasanaTextStylePreset) -> HasanaFontDefinition {
        switch style {
        case .titleLarge: return activeFontPalette.titleLarge
        case .titleMedium: return activeFontPalette.titleMedium
        case .bodyLarge: return activeFontPalette.bodyLarge
        case .bodyMedium: return activeFontPalette.bodyMedium
        case .caption: return activeFontPalette.caption
        case .arabicCalligraphy: return activeFontPalette.arabicCalligraphy
        }
    }
    
    // MARK: - Compliance Audits
    
    /// Performs live WCAG audit on the loaded theme.
    func runCoreContrastAudit(scheme: ColorScheme) -> ContrastAuditResult {
        let isDark = (appearanceOverride == .dark) || (appearanceOverride == .system && scheme == .dark)
        
        let bgHex = isDark ? activePalette.backgroundDark : activePalette.backgroundLight
        let textHex = isDark ? activePalette.textPrimaryDark : activePalette.textPrimaryLight
        
        let bgCol = ThemeColorCoder.color(from: bgHex)
        let textCol = ThemeColorCoder.color(from: textHex)
        
        let result = WCAGContrastAnalyzer.audit(foreground: textCol, background: bgCol)
        
        if !result.passAANormal {
            contrastWarningInfo = "Primary Text contrast is low (\(String(format: "%.2f", result.ratio)):1). Increase difference between Background and Text."
        } else {
            contrastWarningInfo = nil
        }
        
        return result
    }
}

// MARK: - SwiftUI TextStyle Presets Enum
enum HasanaTextStylePreset: String, CaseIterable {
    case titleLarge
    case titleMedium
    case bodyLarge
    case bodyMedium
    case caption
    case arabicCalligraphy
}

// MARK: - SwiftUI Theme Application Modifiers
struct HasanaFontViewModifier: ViewModifier {
    let preset: HasanaTextStylePreset
    let direction: LayoutDirection
    let engine: HasanaThemePaletteEngine
    
    func body(content: Content) -> some View {
        let definition = engine.fontDefinition(for: preset)
        let fontName = engine.activeFontChoice.fontName(for: direction)
        let activeFont = definition.font(name: fontName, language: engine.activeLanguage)
        
        return content
            .font(activeFont)
            .tracking(definition.tracking)
            .lineSpacing(max(0, definition.leading - definition.size))
    }
}

struct HasanaCardModifier: ViewModifier {
    let engine: HasanaThemePaletteEngine
    let scheme: ColorScheme
    
    func body(content: Content) -> some View {
        let radius = engine.activePalette.cornerRadiusMedium
        let cardBackground = engine.elevatedSurface(for: scheme)
        let borderColor = engine.border(for: scheme)
        let shadowColor = engine.shadow(for: scheme).opacity(0.06)
        
        return content
            .padding(engine.activePalette.spacingMedium)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: 1.0)
            )
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }
}

extension View {
    
    /// Applies custom theme-based dynamic typography.
    func hasanaFont(_ preset: HasanaTextStylePreset, direction: LayoutDirection = .leftToRight, engine: HasanaThemePaletteEngine = .shared) -> some View {
        self.modifier(HasanaFontViewModifier(preset: preset, direction: direction, engine: engine))
    }
    
    /// Envelops the view inside a standard Card containing elevated surface backgrounds and custom borders.
    func hasanaCard(scheme: ColorScheme, engine: HasanaThemePaletteEngine = .shared) -> some View {
        self.modifier(HasanaCardModifier(engine: engine, scheme: scheme))
    }
    
    /// Applies standard background color matching active theme.
    func hasanaBackground(scheme: ColorScheme, engine: HasanaThemePaletteEngine = .shared) -> some View {
        self.background(engine.background(for: scheme))
    }
}

// MARK: - Theme Customizer & Real-time PBR Preview UI
/// This View provides developers or users with a full customization interface, displaying live PBR properties and WCAG audits.
struct HasanaThemeCustomizerView: View {
    @State private var engine = HasanaThemePaletteEngine.shared
    @State private var editingPalette: CustomThemePalette
    @State private var activeTab: Int = 0 // 0: UI Colors, 1: 3D Materials, 2: Typography
    @State private var isDarkModeEdit: Bool = false
    @State private var exportString: String? = nil
    @State private var importInputString: String = ""
    @State private var showImportAlert = false
    
    @Environment(\.colorScheme) var scheme
    
    init() {
        let initial = HasanaThemePaletteEngine.shared.activePalette
        _editingPalette = State(initialValue: initial)
    }
    
    private func colorBinding(for keyPath: WritableKeyPath<CustomThemePalette, String>) -> Binding<Color> {
        Binding(
            get: {
                Color(themeHex: editingPalette[keyPath: keyPath])
            },
            set: { newColor in
                let uiCol = UIColor(newColor)
                editingPalette[keyPath: keyPath] = uiCol.themeHex
                engine.saveCustomPalette(editingPalette)
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Theme Studio")
                    .hasanaFont(.titleLarge)
                    .foregroundColor(engine.textPrimary(for: scheme))
                
                Text("Customize 2D user interfaces and 3D garden materials.")
                    .hasanaFont(.bodyMedium)
                    .foregroundColor(engine.textMuted(for: scheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(engine.elevatedSurface(for: scheme))
            
            // Core Preview Card (Contrast Auditing)
            VStack(spacing: 12) {
                let audit = WCAGContrastAnalyzer.audit(
                    foreground: UIColor(themeHex: isDarkModeEdit ? editingPalette.textPrimaryDark : editingPalette.textPrimaryLight),
                    background: UIColor(themeHex: isDarkModeEdit ? editingPalette.backgroundDark : editingPalette.backgroundLight)
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Typography Live Contrast Audit")
                        .hasanaFont(.caption)
                        .foregroundColor(engine.textMuted(for: scheme))
                    
                    HStack {
                        Text("Text Color on Background")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(themeHex: isDarkModeEdit ? editingPalette.textPrimaryDark : editingPalette.textPrimaryLight))
                        
                        Spacer()
                        
                        Text(String(format: "%.2f : 1", audit.ratio))
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                    }
                    .padding()
                    .background(Color(themeHex: isDarkModeEdit ? editingPalette.backgroundDark : editingPalette.backgroundLight))
                    .cornerRadius(8)
                }
                
                HStack(spacing: 10) {
                    ComplianceIndicator(title: "AA Normal", passed: audit.passAANormal)
                    ComplianceIndicator(title: "AAA Normal", passed: audit.passAAALormal)
                    ComplianceIndicator(title: "AA Large", passed: audit.passAALarge)
                    ComplianceIndicator(title: "AAA Large", passed: audit.passAAALarge)
                }
            }
            .padding()
            .background(engine.elevatedSurfaceSoft(for: scheme))
            
            // Tab Selector
            Picker("Studio Mode", selection: $activeTab) {
                Text("UI Colors").tag(0)
                Text("3D Materials").tag(1)
                Text("Typography").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Scroll Content
            ScrollView {
                VStack(spacing: 16) {
                    if activeTab == 0 {
                        uiColorsSection
                    } else if activeTab == 1 {
                        realityKitSection
                    } else {
                        typographySection
                    }
                    
                    paletteManagementSection
                }
                .padding()
            }
            
            Spacer()
        }
        .hasanaBackground(scheme: scheme)
        .onAppear {
            editingPalette = engine.activePalette
        }
        .onChange(of: engine.activePaletteId) { _, newValue in
            editingPalette = engine.activePalette
        }
    }
    
    // MARK: - UI Colors View Section
    private var uiColorsSection: some View {
        VStack(spacing: 12) {
            Toggle("Previewing Dark Mode Configurations", isOn: $isDarkModeEdit)
                .hasanaFont(.bodyMedium)
                .padding(.bottom, 6)
            
            VStack(spacing: 10) {
                if isDarkModeEdit {
                    ColorPicker("Base Background", selection: colorBinding(for: \.backgroundDark))
                    ColorPicker("Secondary BG", selection: colorBinding(for: \.backgroundSecondaryDark))
                    ColorPicker("Elevated Surface", selection: colorBinding(for: \.elevatedSurfaceDark))
                    ColorPicker("Soft Elevated Surface", selection: colorBinding(for: \.elevatedSurfaceSoftDark))
                    ColorPicker("Accent Highlight", selection: colorBinding(for: \.accentDark))
                    ColorPicker("Soft Accent", selection: colorBinding(for: \.accentSoftDark))
                    ColorPicker("Border", selection: colorBinding(for: \.borderDark))
                    ColorPicker("Strong Border", selection: colorBinding(for: \.borderStrongDark))
                    ColorPicker("Primary Text", selection: colorBinding(for: \.textPrimaryDark))
                    ColorPicker("Muted Text", selection: colorBinding(for: \.textMutedDark))
                } else {
                    ColorPicker("Base Background", selection: colorBinding(for: \.backgroundLight))
                    ColorPicker("Secondary BG", selection: colorBinding(for: \.backgroundSecondaryLight))
                    ColorPicker("Elevated Surface", selection: colorBinding(for: \.elevatedSurfaceLight))
                    ColorPicker("Soft Elevated Surface", selection: colorBinding(for: \.elevatedSurfaceSoftLight))
                    ColorPicker("Accent Highlight", selection: colorBinding(for: \.accentLight))
                    ColorPicker("Soft Accent", selection: colorBinding(for: \.accentSoftLight))
                    ColorPicker("Border", selection: colorBinding(for: \.borderLight))
                    ColorPicker("Strong Border", selection: colorBinding(for: \.borderStrongLight))
                    ColorPicker("Primary Text", selection: colorBinding(for: \.textPrimaryLight))
                    ColorPicker("Muted Text", selection: colorBinding(for: \.textMutedLight))
                }
            }
            .padding()
            .background(engine.elevatedSurface(for: scheme))
            .cornerRadius(12)
        }
    }
    
    // MARK: - RealityKit PBR Section
    private var realityKitSection: some View {
        VStack(spacing: 14) {
            Text("RealityKit Material Colors & PBR Properties")
                .hasanaFont(.titleMedium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 3D Live Container Preview
            #if canImport(RealityKit)
            ThemeRealityKitPreviewContainer(palette: editingPalette, scheme: isDarkModeEdit ? .dark : .light)
                .frame(height: 180)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(engine.border(for: scheme), lineWidth: 1)
                )
            #else
            Text("RealityKit not available on this platform.")
                .hasanaFont(.caption)
                .padding()
            #endif
            
            VStack(spacing: 12) {
                ColorPicker("Foliage Tint", selection: colorBinding(for: isDarkModeEdit ? \.foliageColorDark : \.foliageColorLight))
                SliderRow(title: "Foliage Metallic", value: $editingPalette.foliageMetallic, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
                SliderRow(title: "Foliage Roughness", value: $editingPalette.foliageRoughness, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
                
                Divider()
                
                ColorPicker("Blossom Tint", selection: colorBinding(for: isDarkModeEdit ? \.blossomColorDark : \.blossomColorLight))
                SliderRow(title: "Blossom Metallic", value: $editingPalette.blossomMetallic, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
                SliderRow(title: "Blossom Roughness", value: $editingPalette.blossomRoughness, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
                
                Divider()
                
                ColorPicker("Trunk Wood Tint", selection: colorBinding(for: isDarkModeEdit ? \.trunkColorDark : \.trunkColorLight))
                SliderRow(title: "Trunk Metallic", value: $editingPalette.trunkMetallic, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
                SliderRow(title: "Trunk Roughness", value: $editingPalette.trunkRoughness, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
                
                Divider()
                
                ColorPicker("Water Tint", selection: colorBinding(for: isDarkModeEdit ? \.waterColorDark : \.waterColorLight))
                SliderRow(title: "Water Specular", value: $editingPalette.waterSpecular, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
                SliderRow(title: "Water Transparency (Opacity)", value: $editingPalette.waterOpacity, min: 0.0, max: 1.0) {
                    engine.saveCustomPalette(editingPalette)
                }
            }
            .padding()
            .background(engine.elevatedSurface(for: scheme))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Typography Settings Section
    private var typographySection: some View {
        VStack(spacing: 12) {
            Text("Typography & Localization Studio")
                .hasanaFont(.titleMedium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Localized Font Pairings:")
                    .hasanaFont(.caption)
                    .foregroundColor(engine.textMuted(for: scheme))
                
                ForEach(HasanaFontChoice.allFontChoices) { choice in
                    Button {
                        engine.selectFontChoice(choice)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(choice.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(engine.textPrimary(for: scheme))
                                
                                Text("Latin: \(choice.latinFontName ?? "System") | Arabic: \(choice.arabicFontName ?? "System")")
                                    .font(.system(size: 12))
                                    .foregroundColor(engine.textMuted(for: scheme))
                            }
                            
                            Spacer()
                            
                            if engine.activeFontChoice.id == choice.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(engine.accent(for: scheme))
                            }
                        }
                        .padding()
                        .background(engine.elevatedSurfaceSoft(for: scheme))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(engine.elevatedSurface(for: scheme))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Palette Management Actions
    private var paletteManagementSection: some View {
        VStack(spacing: 10) {
            Text("System Palettes & Actions")
                .hasanaFont(.caption)
                .foregroundColor(engine.textMuted(for: scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(engine.palettes) { p in
                        Button {
                            engine.selectPalette(p.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(p.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(engine.activePaletteId == p.id ? .white : engine.textPrimary(for: scheme))
                                
                                HStack(spacing: 4) {
                                    Circle().fill(Color(themeHex: p.backgroundLight)).frame(width: 12, height: 12)
                                    Circle().fill(Color(themeHex: p.accentLight)).frame(width: 12, height: 12)
                                    Circle().fill(Color(themeHex: p.foliageColorLight)).frame(width: 12, height: 12)
                                }
                            }
                            .padding()
                            .background(engine.activePaletteId == p.id ? engine.accent(for: scheme) : engine.elevatedSurface(for: scheme))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                // Auto Generator Dark Mode Button
                Button {
                    let darkModePalette = engine.generateDarkModePalette(fromLight: editingPalette, name: "\(editingPalette.name) Dark Customed")
                    engine.saveCustomPalette(darkModePalette)
                } label: {
                    Label("Gen Dark Mode", systemImage: "moon.fill")
                        .font(.system(size: 14, weight: .medium))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(engine.accentSoft(for: scheme))
                        .foregroundColor(engine.accent(for: scheme))
                        .cornerRadius(10)
                }
                
                // Duplicate / Export Button
                Button {
                    if let exported = engine.exportPalette(id: editingPalette.id) {
                        self.exportString = exported
                        UIPasteboard.general.string = exported
                    }
                } label: {
                    Label("Share Theme", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(engine.accentSoft(for: scheme))
                        .foregroundColor(engine.accent(for: scheme))
                        .cornerRadius(10)
                }
            }
            
            Button {
                showImportAlert = true
            } label: {
                Label("Import Theme Configuration String", systemImage: "square.and.arrow.down")
                    .font(.system(size: 14, weight: .medium))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(engine.border(for: scheme))
                    .foregroundColor(engine.textPrimary(for: scheme))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(engine.elevatedSurface(for: scheme))
        .cornerRadius(12)
        .sheet(isPresented: $showImportAlert) {
            VStack(spacing: 20) {
                Text("Import Theme Configuration")
                    .hasanaFont(.titleMedium)
                
                Text("Paste base64 configuration string below to import:")
                    .hasanaFont(.bodyMedium)
                
                TextEditor(text: $importInputString)
                    .frame(height: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        showImportAlert = false
                        importInputString = ""
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    
                    Button("Import") {
                        let success = engine.importPalette(from: importInputString)
                        if success {
                            showImportAlert = false
                            importInputString = ""
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

// MARK: - UI Configuration Helpers

private struct ComplianceIndicator: View {
    let title: String
    let passed: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(passed ? .green : .red)
            Text(title)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.04))
        .cornerRadius(6)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Float
    let min: Float
    let max: Float
    let onCommit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.system(size: 12, design: .monospaced))
            }
            Slider(value: $value, in: min...max) { _ in
                onCommit()
            }
        }
    }
}

// MARK: - RealityKit Preview UIViewRepresentable
#if canImport(RealityKit)
struct ThemeRealityKitPreviewContainer: UIViewRepresentable {
    let palette: CustomThemePalette
    let scheme: ColorScheme
    
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        
        let anchor = AnchorEntity(world: .zero)
        
        // 3D trunk representing trees in 3D Garden
        let trunkMesh = MeshResource.generateCylinder(height: 0.16, radius: 0.02)
        let trunkMat = palette.trunkMaterial(for: scheme)
        let trunkEntity = ModelEntity(mesh: trunkMesh, materials: [trunkMat])
        trunkEntity.position = [0, -0.04, 0]
        anchor.addChild(trunkEntity)
        
        // 3D foliage representing leaves
        let foliageMesh = MeshResource.generateSphere(radius: 0.06)
        let foliageMat = palette.foliageMaterial(for: scheme)
        let foliageEntity = ModelEntity(mesh: foliageMesh, materials: [foliageMat])
        foliageEntity.position = [0, 0.06, 0]
        anchor.addChild(foliageEntity)
        
        // Directional Light mapped to sky color
        let skyCol = UIColor(themeHex: scheme == .dark ? palette.skyColorDark : palette.skyColorLight)
        let light = DirectionalLight()
        light.light.color = skyCol
        light.light.intensity = 1200
        light.position = [0, 1, 1]
        anchor.addChild(light)
        
        view.scene.addAnchor(anchor)
        return view
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        guard let anchor = uiView.scene.anchors.first else { return }
        
        // Dynamically update materials when PBR values shift
        if anchor.children.count >= 2 {
            if let trunk = anchor.children[0] as? ModelEntity {
                trunk.model?.materials = [palette.trunkMaterial(for: scheme)]
            }
            if let foliage = anchor.children[1] as? ModelEntity {
                foliage.model?.materials = [palette.foliageMaterial(for: scheme)]
            }
        }
    }
}
#endif
