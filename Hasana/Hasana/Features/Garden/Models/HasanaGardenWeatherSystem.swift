//
//  HasanaGardenWeatherSystem.swift
//  Hasana
//
//  Created by Hasana Developer on 2026-05-26.
//

import Combine
import CoreGraphics
import Foundation
import RealityKit
import SwiftUI
import UIKit
import simd

// MARK: - Core Mathematical Utilities

/// A namespace for mathematical operations used throughout the weather and astronomical simulation.
enum WeatherMath {
    /// Linearly interpolates between two Floats.
    @inlinable
    static func lerp(from start: Float, to end: Float, progress: Float) -> Float {
        start + (end - start) * min(max(progress, 0.0), 1.0)
    }
    
    /// Linearly interpolates between two CGFloats.
    @inlinable
    static func lerp(from start: CGFloat, to end: CGFloat, progress: CGFloat) -> CGFloat {
        start + (end - start) * min(max(progress, 0.0), 1.0)
    }

    /// Linearly interpolates between two SIMD3<Float> vectors.
    @inlinable
    static func lerp(from start: SIMD3<Float>, to end: SIMD3<Float>, progress: Float) -> SIMD3<Float> {
        start + (end - start) * min(max(progress, 0.0), 1.0)
    }
    
    /// Linearly interpolates between two SIMD4<Float> vectors.
    @inlinable
    static func lerp(from start: SIMD4<Float>, to end: SIMD4<Float>, progress: Float) -> SIMD4<Float> {
        start + (end - start) * min(max(progress, 0.0), 1.0)
    }

    /// Linearly interpolates between two UIColors.
    static func lerp(from start: UIColor, to end: UIColor, progress: Float) -> UIColor {
        let p = CGFloat(min(max(progress, 0.0), 1.0))
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        start.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        end.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 + (r2 - r1) * p,
            green: g1 + (g2 - g1) * p,
            blue: b1 + (b2 - b1) * p,
            alpha: a1 + (a2 - a1) * p
        )
    }
    
    /// Smoothstep interpolation curve to avoid linear transitions at boundaries.
    @inlinable
    static func smoothstep(from start: Float, to end: Float, progress: Float) -> Float {
        let t = min(max((progress - start) / (end - start), 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }
    
    /// Converts degrees to radians.
    @inlinable
    static func degToRad(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }

    /// Converts radians to degrees.
    @inlinable
    static func radToDeg(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }
    
    /// Converts degrees to radians (Float).
    @inlinable
    static func degToRadF(_ degrees: Float) -> Float {
        degrees * .pi / 180.0
    }

    /// Converts radians to degrees (Float).
    @inlinable
    static func radToDegF(_ radians: Float) -> Float {
        radians * 180.0 / .pi
    }
}

// MARK: - Daylight Cycle State definitions

/// Describes the specific period of the day within the spiritual garden.
enum HasanaGardenDaylightState: String, CaseIterable, Codable, Hashable {
    case fajr       // Dawn, pre-sunrise spiritual stillness
    case sunrise    // The golden hour of rising sun
    case morning    // Crisp morning light, growth activation
    case dhuhr      // Noon, high sun, bright neutral lighting
    case afternoon  // Golden afternoon lighting
    case asr        // Late afternoon, warm shadows lengthening
    case maghrib    // Sunset, vibrant orange and purple gradients
    case dusk       // Civil twilight, calming blue hour transition
    case isha       // Deep night sky, starlight activation
    case midnight   // Absolute quietude, moonlit garden paths
    
    /// Time of day fraction when this state is at its peak (0.0 to 1.0, starting at midnight).
    var peakTimeFraction: Double {
        switch self {
        case .midnight:  0.0
        case .fajr:      0.20 // ~4:48 AM
        case .sunrise:   0.25 // ~6:00 AM
        case .morning:   0.375 // ~9:00 AM
        case .dhuhr:     0.50  // ~12:00 PM
        case .afternoon: 0.625 // ~3:00 PM
        case .asr:       0.70  // ~4:48 PM
        case .maghrib:   0.75  // ~6:00 PM
        case .dusk:      0.80  // ~7:12 PM
        case .isha:      0.875 // ~9:00 PM
        }
    }
}

/// Physical and visual atmospheric attributes defining the environment at a specific time.
struct HasanaGardenDaylightProperties: Equatable {
    var state: HasanaGardenDaylightState
    
    // Sky gradient configuration (spherical dome interpolation)
    var skyTopColor: UIColor
    var skyHorizonColor: UIColor
    var skyBottomColor: UIColor
    
    // Sunlight / Direct lighting properties
    var sunLightColor: UIColor
    var sunLightIntensity: Float
    var sunElevationAngle: Float // in radians
    var sunAzimuthAngle: Float   // in radians
    
    // Moonlight / Secondary lighting properties
    var moonLightColor: UIColor
    var moonLightIntensity: Float
    var moonElevationAngle: Float // in radians
    var moonAzimuthAngle: Float   // in radians
    
    // Ambient / Fill light properties
    var ambientColor: UIColor
    var ambientIntensity: Float
    
    // Atmospheric fog settings
    var fogColor: UIColor
    var fogDensity: Float
    
    // Starfield parameters
    var starOpacity: Float
    
    // Environmental properties
    var temperatureCelsius: Float
    var relativeHumidity: Float // 0.0 to 1.0
    var shadowIntensity: Float  // 0.0 to 1.0
    
    /// Static collection of daylight cycle definitions.
    static func properties(for state: HasanaGardenDaylightState) -> HasanaGardenDaylightProperties {
        switch state {
        case .fajr:
            return HasanaGardenDaylightProperties(
                state: .fajr,
                skyTopColor: UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.18, green: 0.16, blue: 0.28, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.28, green: 0.22, blue: 0.25, alpha: 1.0),
                sunLightColor: UIColor(red: 0.85, green: 0.55, blue: 0.40, alpha: 1.0),
                sunLightIntensity: 250.0,
                sunElevationAngle: -0.12, // slightly below horizon
                sunAzimuthAngle: 1.6,     // East-Northeast
                moonLightColor: UIColor(red: 0.70, green: 0.82, blue: 0.95, alpha: 1.0),
                moonLightIntensity: 120.0,
                moonElevationAngle: 0.38,
                moonAzimuthAngle: 4.8,    // West-Northwest
                ambientColor: UIColor(red: 0.12, green: 0.15, blue: 0.25, alpha: 1.0),
                ambientIntensity: 350.0,
                fogColor: UIColor(red: 0.18, green: 0.17, blue: 0.27, alpha: 1.0),
                fogDensity: 0.025,
                starOpacity: 0.42,
                temperatureCelsius: 16.5,
                relativeHumidity: 0.85,
                shadowIntensity: 0.15
            )
            
        case .sunrise:
            return HasanaGardenDaylightProperties(
                state: .sunrise,
                skyTopColor: UIColor(red: 0.12, green: 0.18, blue: 0.35, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.98, green: 0.58, blue: 0.22, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.95, green: 0.82, blue: 0.52, alpha: 1.0),
                sunLightColor: UIColor(red: 0.98, green: 0.72, blue: 0.45, alpha: 1.0),
                sunLightIntensity: 1800.0,
                sunElevationAngle: 0.08,  // just above horizon
                sunAzimuthAngle: 1.75,    // East
                moonLightColor: UIColor(red: 0.80, green: 0.88, blue: 0.98, alpha: 1.0),
                moonLightIntensity: 10.0,
                moonElevationAngle: 0.05,
                moonAzimuthAngle: 4.9,
                ambientColor: UIColor(red: 0.32, green: 0.28, blue: 0.32, alpha: 1.0),
                ambientIntensity: 900.0,
                fogColor: UIColor(red: 0.95, green: 0.75, blue: 0.60, alpha: 1.0),
                fogDensity: 0.018,
                starOpacity: 0.05,
                temperatureCelsius: 18.0,
                relativeHumidity: 0.80,
                shadowIntensity: 0.45
            )
            
        case .morning:
            return HasanaGardenDaylightProperties(
                state: .morning,
                skyTopColor: UIColor(red: 0.22, green: 0.48, blue: 0.85, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.62, green: 0.82, blue: 0.98, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.88, green: 0.95, blue: 0.92, alpha: 1.0),
                sunLightColor: UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1.0),
                sunLightIntensity: 3200.0,
                sunElevationAngle: 0.52,  // 30 degrees up
                sunAzimuthAngle: 2.1,
                moonLightColor: UIColor.white,
                moonLightIntensity: 0.0,
                moonElevationAngle: -0.5,
                moonAzimuthAngle: 5.5,
                ambientColor: UIColor(red: 0.52, green: 0.62, blue: 0.75, alpha: 1.0),
                ambientIntensity: 1400.0,
                fogColor: UIColor(red: 0.82, green: 0.90, blue: 0.95, alpha: 1.0),
                fogDensity: 0.008,
                starOpacity: 0.0,
                temperatureCelsius: 24.0,
                relativeHumidity: 0.60,
                shadowIntensity: 0.85
            )
            
        case .dhuhr:
            return HasanaGardenDaylightProperties(
                state: .dhuhr,
                skyTopColor: UIColor(red: 0.15, green: 0.45, blue: 0.92, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.52, green: 0.85, blue: 1.0, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.92, green: 0.98, blue: 0.95, alpha: 1.0),
                sunLightColor: UIColor(red: 1.0, green: 1.0, blue: 0.95, alpha: 1.0),
                sunLightIntensity: 4500.0,
                sunElevationAngle: 1.48,  // near zenith
                sunAzimuthAngle: 3.14,    // South
                moonLightColor: UIColor.white,
                moonLightIntensity: 0.0,
                moonElevationAngle: -1.2,
                moonAzimuthAngle: 0.0,
                ambientColor: UIColor(red: 0.68, green: 0.76, blue: 0.88, alpha: 1.0),
                ambientIntensity: 1800.0,
                fogColor: UIColor(red: 0.88, green: 0.95, blue: 0.98, alpha: 1.0),
                fogDensity: 0.004,
                starOpacity: 0.0,
                temperatureCelsius: 32.5,
                relativeHumidity: 0.45,
                shadowIntensity: 0.95
            )
            
        case .afternoon:
            return HasanaGardenDaylightProperties(
                state: .afternoon,
                skyTopColor: UIColor(red: 0.18, green: 0.42, blue: 0.85, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.58, green: 0.80, blue: 0.98, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.92, green: 0.92, blue: 0.82, alpha: 1.0),
                sunLightColor: UIColor(red: 1.0, green: 0.94, blue: 0.82, alpha: 1.0),
                sunLightIntensity: 3800.0,
                sunElevationAngle: 0.88,  // ~50 degrees up
                sunAzimuthAngle: 4.18,
                moonLightColor: UIColor.white,
                moonLightIntensity: 0.0,
                moonElevationAngle: -0.8,
                moonAzimuthAngle: 1.0,
                ambientColor: UIColor(red: 0.62, green: 0.68, blue: 0.78, alpha: 1.0),
                ambientIntensity: 1550.0,
                fogColor: UIColor(red: 0.90, green: 0.92, blue: 0.92, alpha: 1.0),
                fogDensity: 0.005,
                starOpacity: 0.0,
                temperatureCelsius: 34.0,
                relativeHumidity: 0.42,
                shadowIntensity: 0.90
            )
            
        case .asr:
            return HasanaGardenDaylightProperties(
                state: .asr,
                skyTopColor: UIColor(red: 0.12, green: 0.32, blue: 0.70, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.85, green: 0.62, blue: 0.42, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.82, green: 0.72, blue: 0.58, alpha: 1.0),
                sunLightColor: UIColor(red: 0.98, green: 0.82, blue: 0.55, alpha: 1.0),
                sunLightIntensity: 2800.0,
                sunElevationAngle: 0.42,  // 24 degrees up
                sunAzimuthAngle: 4.65,    // West-Southwest
                moonLightColor: UIColor.white,
                moonLightIntensity: 0.0,
                moonElevationAngle: -0.2,
                moonAzimuthAngle: 1.4,
                ambientColor: UIColor(red: 0.48, green: 0.45, blue: 0.55, alpha: 1.0),
                ambientIntensity: 1200.0,
                fogColor: UIColor(red: 0.92, green: 0.80, blue: 0.70, alpha: 1.0),
                fogDensity: 0.008,
                starOpacity: 0.0,
                temperatureCelsius: 29.5,
                relativeHumidity: 0.52,
                shadowIntensity: 0.80
            )
            
        case .maghrib:
            return HasanaGardenDaylightProperties(
                state: .maghrib,
                skyTopColor: UIColor(red: 0.08, green: 0.12, blue: 0.38, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.95, green: 0.35, blue: 0.22, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.42, green: 0.18, blue: 0.38, alpha: 1.0),
                sunLightColor: UIColor(red: 0.98, green: 0.45, blue: 0.18, alpha: 1.0),
                sunLightIntensity: 1200.0,
                sunElevationAngle: 0.02,  // setting below horizon
                sunAzimuthAngle: 4.88,    // West
                moonLightColor: UIColor(red: 0.88, green: 0.92, blue: 1.0, alpha: 1.0),
                moonLightIntensity: 30.0,
                moonElevationAngle: 0.10,
                moonAzimuthAngle: 1.5,
                ambientColor: UIColor(red: 0.28, green: 0.20, blue: 0.35, alpha: 1.0),
                ambientIntensity: 650.0,
                fogColor: UIColor(red: 0.45, green: 0.22, blue: 0.35, alpha: 1.0),
                fogDensity: 0.015,
                starOpacity: 0.08,
                temperatureCelsius: 25.0,
                relativeHumidity: 0.68,
                shadowIntensity: 0.35
            )
            
        case .dusk:
            return HasanaGardenDaylightProperties(
                state: .dusk,
                skyTopColor: UIColor(red: 0.02, green: 0.06, blue: 0.22, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.15, green: 0.15, blue: 0.38, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.12, green: 0.08, blue: 0.22, alpha: 1.0),
                sunLightColor: UIColor(red: 0.85, green: 0.32, blue: 0.12, alpha: 1.0),
                sunLightIntensity: 100.0,
                sunElevationAngle: -0.15,
                sunAzimuthAngle: 5.05,
                moonLightColor: UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1.0),
                moonLightIntensity: 150.0,
                moonElevationAngle: 0.32,
                moonAzimuthAngle: 1.7,
                ambientColor: UIColor(red: 0.15, green: 0.15, blue: 0.28, alpha: 1.0),
                ambientIntensity: 380.0,
                fogColor: UIColor(red: 0.12, green: 0.12, blue: 0.25, alpha: 1.0),
                fogDensity: 0.022,
                starOpacity: 0.32,
                temperatureCelsius: 22.0,
                relativeHumidity: 0.75,
                shadowIntensity: 0.10
            )
            
        case .isha:
            return HasanaGardenDaylightProperties(
                state: .isha,
                skyTopColor: UIColor(red: 0.01, green: 0.02, blue: 0.10, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.03, green: 0.04, blue: 0.15, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0),
                sunLightColor: UIColor.black,
                sunLightIntensity: 0.0,
                sunElevationAngle: -0.92,
                sunAzimuthAngle: 5.8,
                moonLightColor: UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1.0),
                moonLightIntensity: 450.0,
                moonElevationAngle: 0.82,  // High moon
                moonAzimuthAngle: 2.5,
                ambientColor: UIColor(red: 0.08, green: 0.08, blue: 0.16, alpha: 1.0),
                ambientIntensity: 180.0,
                fogColor: UIColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1.0),
                fogDensity: 0.012,
                starOpacity: 0.88,
                temperatureCelsius: 19.5,
                relativeHumidity: 0.78,
                shadowIntensity: 0.40
            )
            
        case .midnight:
            return HasanaGardenDaylightProperties(
                state: .midnight,
                skyTopColor: UIColor(red: 0.0, green: 0.0, blue: 0.06, alpha: 1.0),
                skyHorizonColor: UIColor(red: 0.01, green: 0.02, blue: 0.08, alpha: 1.0),
                skyBottomColor: UIColor(red: 0.0, green: 0.0, blue: 0.04, alpha: 1.0),
                sunLightColor: UIColor.black,
                sunLightIntensity: 0.0,
                sunElevationAngle: -1.57, // directly opposite zenith
                sunAzimuthAngle: 0.0,
                moonLightColor: UIColor(red: 0.80, green: 0.90, blue: 1.0, alpha: 1.0),
                moonLightIntensity: 550.0,
                moonElevationAngle: 1.25,  // near zenith
                moonAzimuthAngle: 3.14,
                ambientColor: UIColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1.0),
                ambientIntensity: 140.0,
                fogColor: UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0),
                fogDensity: 0.015,
                starOpacity: 1.0,
                temperatureCelsius: 17.5,
                relativeHumidity: 0.82,
                shadowIntensity: 0.48
            )
        }
    }
    
    /// Blends two properties configurations based on a progress value (0.0 to 1.0).
    static func blend(from first: HasanaGardenDaylightProperties, to second: HasanaGardenDaylightProperties, progress: Float) -> HasanaGardenDaylightProperties {
        let p = min(max(progress, 0.0), 1.0)
        
        return HasanaGardenDaylightProperties(
            state: p < 0.5 ? first.state : second.state,
            skyTopColor: WeatherMath.lerp(from: first.skyTopColor, to: second.skyTopColor, progress: p),
            skyHorizonColor: WeatherMath.lerp(from: first.skyHorizonColor, to: second.skyHorizonColor, progress: p),
            skyBottomColor: WeatherMath.lerp(from: first.skyBottomColor, to: second.skyBottomColor, progress: p),
            sunLightColor: WeatherMath.lerp(from: first.sunLightColor, to: second.sunLightColor, progress: p),
            sunLightIntensity: WeatherMath.lerp(from: first.sunLightIntensity, to: second.sunLightIntensity, progress: p),
            sunElevationAngle: WeatherMath.lerp(from: first.sunElevationAngle, to: second.sunElevationAngle, progress: p),
            sunAzimuthAngle: WeatherMath.lerp(from: first.sunAzimuthAngle, to: second.sunAzimuthAngle, progress: p),
            moonLightColor: WeatherMath.lerp(from: first.moonLightColor, to: second.moonLightColor, progress: p),
            moonLightIntensity: WeatherMath.lerp(from: first.moonLightIntensity, to: second.moonLightIntensity, progress: p),
            moonElevationAngle: WeatherMath.lerp(from: first.moonElevationAngle, to: second.moonElevationAngle, progress: p),
            moonAzimuthAngle: WeatherMath.lerp(from: first.moonAzimuthAngle, to: second.moonAzimuthAngle, progress: p),
            ambientColor: WeatherMath.lerp(from: first.ambientColor, to: second.ambientColor, progress: p),
            ambientIntensity: WeatherMath.lerp(from: first.ambientIntensity, to: second.ambientIntensity, progress: p),
            fogColor: WeatherMath.lerp(from: first.fogColor, to: second.fogColor, progress: p),
            fogDensity: WeatherMath.lerp(from: first.fogDensity, to: second.fogDensity, progress: p),
            starOpacity: WeatherMath.lerp(from: first.starOpacity, to: second.starOpacity, progress: p),
            temperatureCelsius: WeatherMath.lerp(from: first.temperatureCelsius, to: second.temperatureCelsius, progress: p),
            relativeHumidity: WeatherMath.lerp(from: first.relativeHumidity, to: second.relativeHumidity, progress: p),
            shadowIntensity: WeatherMath.lerp(from: first.shadowIntensity, to: second.shadowIntensity, progress: p)
        )
    }
}

// MARK: - Astronomical Solar & Lunar Path Calculator

/// Types of lunar phase configurations based on the synodic cycle.
enum HasanaGardenLunarPhase: String, CaseIterable, Codable, Hashable {
    case newMoon            // Invisible / dark moon
    case waxingCrescent     // Emerging sliver
    case firstQuarter       // Half illuminated waxing
    case waxingGibbous      // Mostly illuminated waxing
    case fullMoon           // Fully bright moon
    case waningGibbous      // Mostly illuminated waning
    case thirdQuarter       // Half illuminated waning
    case waningCrescent     // Muted sliver waning
    
    var titleEnglish: String {
        switch self {
        case .newMoon: return "New Moon"
        case .waxingCrescent: return "Waxing Crescent"
        case .firstQuarter: return "First Quarter"
        case .waxingGibbous: return "Waxing Gibbous"
        case .fullMoon: return "Full Moon"
        case .waningGibbous: return "Waning Gibbous"
        case .thirdQuarter: return "Third Quarter"
        case .waningCrescent: return "Waning Crescent"
        }
    }
    
    var titleArabic: String {
        switch self {
        case .newMoon: return "محاق"
        case .waxingCrescent: return "هلال متزايد"
        case .firstQuarter: return "تربيع أول"
        case .waxingGibbous: return "أحدب متزايد"
        case .fullMoon: return "بدر"
        case .waningGibbous: return "أحدب متناقص"
        case .thirdQuarter: return "تربيع ثاني"
        case .waningCrescent: return "هلال متناقص"
        }
    }
    
    /// Intensity multiplier for moonlight corresponding to the phase.
    var lightIntensityMultiplier: Float {
        switch self {
        case .newMoon:        0.02
        case .waxingCrescent: 0.15
        case .firstQuarter:   0.50
        case .waxingGibbous:  0.82
        case .fullMoon:       1.00
        case .waningGibbous:  0.80
        case .thirdQuarter:   0.48
        case .waningCrescent: 0.12
        }
    }
}

/// Computes accurate sun and moon positions in spherical coordinates, mapable to 3D Cartesian coordinates.
struct HasanaGardenSolarPathCalculator {
    var latitude: Double  // Degrees North
    var longitude: Double // Degrees East
    
    init(latitude: Double = 21.4225, longitude: Double = 39.8262) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Calculates solar coordinates (elevation and azimuth) using Keplerian elements simplified for real-time.
    /// - Parameters:
    ///   - date: Current calculation timestamp.
    ///   - dayFraction: Direct override for manual time adjustments (0.0 to 1.0). If nil, calculated from `date`.
    /// - Returns: A tuple of (altitude, azimuth) in radians. Altitude is elevation above the horizon.
    func calculateSolarAngles(for date: Date, dayFraction: Double? = nil) -> (altitude: Double, azimuth: Double) {
        let calendar = Calendar(identifier: .gregorian)
        
        // Calculate Day of Year (N)
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        
        // Time fraction of day
        let f: Double
        if let explicitFraction = dayFraction {
            f = explicitFraction
        } else {
            let hour = Double(calendar.component(.hour, from: date))
            let minute = Double(calendar.component(.minute, from: date))
            let second = Double(calendar.component(.second, from: date))
            f = (hour + (minute + second / 60.0) / 60.0) / 24.0
        }
        
        // 1. Calculate Solar Declination (delta)
        // Dec = 23.45 * sin(360/365 * (284 + N)) in degrees
        let decDegrees = 23.45 * sin(WeatherMath.degToRad(360.0 / 365.0 * (284.0 + dayOfYear)))
        let declination = WeatherMath.degToRad(decDegrees)
        
        // 2. Equation of Time (EoT) - correction for orbital eccentricity & axial tilt
        // B = 360/365 * (N - 81)
        let bVal = WeatherMath.degToRad(360.0 / 365.0 * (dayOfYear - 81.0))
        let eot = 9.87 * sin(2.0 * bVal) - 7.53 * cos(bVal) - 1.5 * sin(bVal) // in minutes
        
        // 3. Solar Time and Hour Angle (H)
        // Standard Time offset, local timezone meridian correction
        let timeZoneOffsetSeconds = Double(TimeZone.current.secondsFromGMT(for: date))
        let timeZoneOffsetHours = timeZoneOffsetSeconds / 3600.0
        let localMeridian = timeZoneOffsetHours * 15.0 // 15 degrees per hour
        let meridianCorrection = 4.0 * (longitude - localMeridian) // in minutes
        
        let localSolarTimeMinutes = (f * 24.0 * 60.0) + eot + meridianCorrection
        let localSolarTimeHours = localSolarTimeMinutes / 60.0
        
        // Hour angle (H): 15 degrees per hour, 0 at solar noon (12:00)
        let hourAngleDegrees = 15.0 * (localSolarTimeHours - 12.0)
        let hourAngle = WeatherMath.degToRad(hourAngleDegrees)
        
        // 4. Calculate Elevation (Solar Altitude)
        // sin(Alt) = sin(Lat) * sin(Dec) + cos(Lat) * cos(Dec) * cos(H)
        let latRad = WeatherMath.degToRad(latitude)
        let sinAlt = sin(latRad) * sin(declination) + cos(latRad) * cos(declination) * cos(hourAngle)
        let altitude = asin(max(min(sinAlt, 1.0), -1.0))
        
        // 5. Calculate Azimuth (A)
        // cos(A) = (sin(Dec) - sin(Alt)*sin(Lat)) / (cos(Alt)*cos(Lat))
        let cosA = (sin(declination) - sin(altitude) * sin(latRad)) / (cos(altitude) * cos(latRad))
        let cappedCosA = max(min(cosA, 1.0), -1.0)
        
        var azimuth = acos(cappedCosA)
        // If hour angle is positive (afternoon), solar azimuth is 360 - A
        if hourAngleDegrees > 0 {
            azimuth = 2.0 * .pi - azimuth
        }
        
        return (altitude: altitude, azimuth: azimuth)
    }
    
    /// Evaluates the current lunar phase and illuminated fraction.
    /// Based on the synodic month cycle (approx 29.53059 days) starting from a known reference point.
    func calculateLunarPhase(for date: Date) -> (phase: HasanaGardenLunarPhase, illuminatedFraction: Float) {
        // Reference new moon: January 6, 2000, 18:14 UTC
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let referenceNewMoon = formatter.date(from: "2000-01-06 18:14:00") else {
            return (.fullMoon, 1.0)
        }
        
        let synodicPeriod = 29.530588853 // in days
        let diffSeconds = date.timeIntervalSince(referenceNewMoon)
        let diffDays = diffSeconds / (24.0 * 3600.0)
        
        // Fraction of lunar cycle completed (0.0 to 1.0)
        let phaseFraction = diffDays.truncatingRemainder(dividingBy: synodicPeriod) / synodicPeriod
        let normalizedFraction = phaseFraction < 0 ? phaseFraction + 1.0 : phaseFraction
        
        // Illuminated fraction ranges from 0.0 (New) to 1.0 (Full) to 0.0 (New)
        // Computed as: (1 - cos(2 * pi * fraction)) / 2
        let illuminated = Float((1.0 - cos(2.0 * .pi * normalizedFraction)) / 2.0)
        
        // Map normalized fraction to Phase Enum
        // 8 phases of equal length (0.125 increments) centered around their points
        let phaseIndex = Int((normalizedFraction * 8.0 + 0.5).rounded()) % 8
        
        let phase: HasanaGardenLunarPhase
        switch phaseIndex {
        case 0:  phase = .newMoon
        case 1:  phase = .waxingCrescent
        case 2:  phase = .firstQuarter
        case 3:  phase = .waxingGibbous
        case 4:  phase = .fullMoon
        case 5:  phase = .waningGibbous
        case 6:  phase = .thirdQuarter
        default: phase = .waningCrescent
        }
        
        return (phase: phase, illuminatedFraction: illuminated)
    }
    
    /// Projects solar elevation and azimuth to 3D Cartesian coordinates relative to a viewing dome.
    /// - Parameters:
    ///   - altitude: elevation angle in radians.
    ///   - azimuth: azimuth angle in radians.
    ///   - radius: distance from origin.
    /// - Returns: A vector representing the 3D position (X = East/West, Y = Altitude Up, Z = North/South).
    static func projectToCartesian(altitude: Double, azimuth: Double, radius: Float) -> SIMD3<Float> {
        // Spherical coordinate mapping:
        // Y is pointing vertical up
        // Z is pointing North (South is negative)
        // X is pointing East (West is negative)
        let cosAlt = cos(altitude)
        let x = Double(radius) * cosAlt * sin(azimuth)
        let y = Double(radius) * sin(altitude)
        let z = Double(radius) * cosAlt * cos(azimuth)
        
        return SIMD3<Float>(Float(x), Float(y), Float(z))
    }
}

// MARK: - Weather Types & Detailed Configurations

/// The meteorology states supported by the garden simulation.
enum HasanaGardenWeatherType: String, CaseIterable, Codable, Hashable {
    case clear          // Sunny / clear night
    case partlyCloudy   // Moderate floating clouds
    case overcast       // Heavy grey cloud canopy
    case misty          // Ground fog, soft visibility
    case rainy          // Rain fall, wet grass
    case stormy         // Heavy rain, thunder flashes
    case snowy          // Snow fall, frosty atmosphere
    case windy          // High wind speed, bending foliage
    
    func titleEnglish() -> String {
        switch self {
        case .clear: return "Clear Sky"
        case .partlyCloudy: return "Partly Cloudy"
        case .overcast: return "Overcast"
        case .misty: return "Misty Fog"
        case .rainy: return "Rainy Showers"
        case .stormy: return "Thunderstorm"
        case .snowy: return "Winter Snow"
        case .windy: return "Gale Winds"
        }
    }
    
    func titleArabic() -> String {
        switch self {
        case .clear: return "صافٍ"
        case .partlyCloudy: return "غائم جزئياً"
        case .overcast: return "غائم كلياً"
        case .misty: return "ضباب خفيف"
        case .rainy: return "مُمطر"
        case .stormy: return "عاصفة رعدية"
        case .snowy: return "مثلج"
        case .windy: return "عاصف"
        }
    }
}

/// Quantitative meteorology configurations corresponding to a weather state.
struct HasanaGardenWeatherProperties: Equatable {
    var weatherType: HasanaGardenWeatherType
    
    // Cloud density parameter (0.0 = completely clear, 1.0 = completely overcast)
    var cloudCoverage: Float
    
    // Ambient physical parameters
    var rainIntensity: Float
    var snowIntensity: Float
    var fogMultiplier: Float  // Multiplier applied to daylight base fog
    var ambientMultiplier: Float // Light attenuation multiplier
    var temperatureDelta: Float  // Shift in base daylight temperature
    
    // Wind conditions
    var windSpeedBase: Float      // Base wind speed in m/s
    var windGustiness: Float     // Turbulence / gust frequency factor
    var windDirectionDegrees: Float // Angle in degrees
    
    // Special features
    var thunderProbability: Float
    var rainbowProbability: Float
    
    /// Properties database for all weather states.
    static func properties(for type: HasanaGardenWeatherType) -> HasanaGardenWeatherProperties {
        switch type {
        case .clear:
            return HasanaGardenWeatherProperties(
                weatherType: .clear,
                cloudCoverage: 0.05,
                rainIntensity: 0.0,
                snowIntensity: 0.0,
                fogMultiplier: 1.0,
                ambientMultiplier: 1.0,
                temperatureDelta: 1.5,
                windSpeedBase: 1.2,
                windGustiness: 0.1,
                windDirectionDegrees: 45.0,
                thunderProbability: 0.0,
                rainbowProbability: 0.0
            )
            
        case .partlyCloudy:
            return HasanaGardenWeatherProperties(
                weatherType: .partlyCloudy,
                cloudCoverage: 0.45,
                rainIntensity: 0.0,
                snowIntensity: 0.0,
                fogMultiplier: 1.1,
                ambientMultiplier: 0.92,
                temperatureDelta: -0.5,
                windSpeedBase: 3.5,
                windGustiness: 0.28,
                windDirectionDegrees: 60.0,
                thunderProbability: 0.0,
                rainbowProbability: 0.15
            )
            
        case .overcast:
            return HasanaGardenWeatherProperties(
                weatherType: .overcast,
                cloudCoverage: 0.95,
                rainIntensity: 0.0,
                snowIntensity: 0.0,
                fogMultiplier: 1.4,
                ambientMultiplier: 0.65,
                temperatureDelta: -2.0,
                windSpeedBase: 4.8,
                windGustiness: 0.35,
                windDirectionDegrees: 180.0,
                thunderProbability: 0.0,
                rainbowProbability: 0.0
            )
            
        case .misty:
            return HasanaGardenWeatherProperties(
                weatherType: .misty,
                cloudCoverage: 0.70,
                rainIntensity: 0.05, // very light drizzle
                snowIntensity: 0.0,
                fogMultiplier: 3.8, // dense fog activation
                ambientMultiplier: 0.72,
                temperatureDelta: -3.5,
                windSpeedBase: 0.8,  // calm winds are needed for mist
                windGustiness: 0.05,
                windDirectionDegrees: 90.0,
                thunderProbability: 0.0,
                rainbowProbability: 0.05
            )
            
        case .rainy:
            return HasanaGardenWeatherProperties(
                weatherType: .rainy,
                cloudCoverage: 0.90,
                rainIntensity: 0.65,
                snowIntensity: 0.0,
                fogMultiplier: 1.8,
                ambientMultiplier: 0.58,
                temperatureDelta: -4.0,
                windSpeedBase: 6.5,
                windGustiness: 0.52,
                windDirectionDegrees: 240.0,
                thunderProbability: 0.05,
                rainbowProbability: 0.40
            )
            
        case .stormy:
            return HasanaGardenWeatherProperties(
                weatherType: .stormy,
                cloudCoverage: 1.0,
                rainIntensity: 1.0,
                snowIntensity: 0.0,
                fogMultiplier: 2.2,
                ambientMultiplier: 0.35, // extremely dark clouds
                temperatureDelta: -5.5,
                windSpeedBase: 14.5, // strong storm wind
                windGustiness: 0.85,
                windDirectionDegrees: 280.0,
                thunderProbability: 0.88,
                rainbowProbability: 0.05
            )
            
        case .snowy:
            return HasanaGardenWeatherProperties(
                weatherType: .snowy,
                cloudCoverage: 0.85,
                rainIntensity: 0.0,
                snowIntensity: 0.75,
                fogMultiplier: 1.6,
                ambientMultiplier: 0.75, // snow reflects some light
                temperatureDelta: -12.0, // cold shift
                windSpeedBase: 4.2,
                windGustiness: 0.40,
                windDirectionDegrees: 315.0,
                thunderProbability: 0.0,
                rainbowProbability: 0.0
            )
            
        case .windy:
            return HasanaGardenWeatherProperties(
                weatherType: .windy,
                cloudCoverage: 0.55,
                rainIntensity: 0.0,
                snowIntensity: 0.0,
                fogMultiplier: 0.8, // wind disperses fog
                ambientMultiplier: 0.88,
                temperatureDelta: -1.0,
                windSpeedBase: 18.0, // gale force
                windGustiness: 0.95, // extreme gusts
                windDirectionDegrees: 120.0,
                thunderProbability: 0.0,
                rainbowProbability: 0.0
            )
        }
    }
    
    /// Blends two weather properties configurations.
    static func blend(from first: HasanaGardenWeatherProperties, to second: HasanaGardenWeatherProperties, progress: Float) -> HasanaGardenWeatherProperties {
        let p = min(max(progress, 0.0), 1.0)
        
        return HasanaGardenWeatherProperties(
            weatherType: p < 0.5 ? first.weatherType : second.weatherType,
            cloudCoverage: WeatherMath.lerp(from: first.cloudCoverage, to: second.cloudCoverage, progress: p),
            rainIntensity: WeatherMath.lerp(from: first.rainIntensity, to: second.rainIntensity, progress: p),
            snowIntensity: WeatherMath.lerp(from: first.snowIntensity, to: second.snowIntensity, progress: p),
            fogMultiplier: WeatherMath.lerp(from: first.fogMultiplier, to: second.fogMultiplier, progress: p),
            ambientMultiplier: WeatherMath.lerp(from: first.ambientMultiplier, to: second.ambientMultiplier, progress: p),
            temperatureDelta: WeatherMath.lerp(from: first.temperatureDelta, to: second.temperatureDelta, progress: p),
            windSpeedBase: WeatherMath.lerp(from: first.windSpeedBase, to: second.windSpeedBase, progress: p),
            windGustiness: WeatherMath.lerp(from: first.windGustiness, to: second.windGustiness, progress: p),
            windDirectionDegrees: WeatherMath.lerp(from: first.windDirectionDegrees, to: second.windDirectionDegrees, progress: p),
            thunderProbability: WeatherMath.lerp(from: first.thunderProbability, to: second.thunderProbability, progress: p),
            rainbowProbability: WeatherMath.lerp(from: first.rainbowProbability, to: second.rainbowProbability, progress: p)
        )
    }
}

// MARK: - Weather Transition Manager

/// Handles interpolating between weather states over time.
final class HasanaGardenWeatherTransitionManager {
    private(set) var currentProperties: HasanaGardenWeatherProperties
    private(set) var sourceProperties: HasanaGardenWeatherProperties
    private(set) var targetProperties: HasanaGardenWeatherProperties
    
    var transitionDuration: Double = 5.0 // seconds
    private(set) var elapsedTransitionTime: Double = 0.0
    private(set) var isTransitioning: Bool = false
    
    init(initialType: HasanaGardenWeatherType = .clear) {
        let initial = HasanaGardenWeatherProperties.properties(for: initialType)
        self.currentProperties = initial
        self.sourceProperties = initial
        self.targetProperties = initial
    }
    
    /// Begins a smooth transition to a target weather type.
    func transition(to targetType: HasanaGardenWeatherType, duration: Double) {
        self.sourceProperties = currentProperties
        self.targetProperties = HasanaGardenWeatherProperties.properties(for: targetType)
        self.transitionDuration = max(duration, 0.1)
        self.elapsedTransitionTime = 0.0
        self.isTransitioning = true
    }
    
    /// Immediate jump to weather state without transition.
    func setWeatherImmediately(to type: HasanaGardenWeatherType) {
        let props = HasanaGardenWeatherProperties.properties(for: type)
        self.currentProperties = props
        self.sourceProperties = props
        self.targetProperties = props
        self.isTransitioning = false
        self.elapsedTransitionTime = 0.0
    }
    
    /// Updates the transition state machine with elapsed delta time.
    func update(deltaTime: Double) {
        guard isTransitioning else { return }
        
        elapsedTransitionTime += deltaTime
        let fraction = Float(min(elapsedTransitionTime / transitionDuration, 1.0))
        
        // Easing interpolation curve (easeInOutCubic)
        let easedFraction = fraction < 0.5
            ? 4.0 * fraction * fraction * fraction
            : 1.0 - pow(-2.0 * fraction + 2.0, 3.0) / 2.0
        
        currentProperties = HasanaGardenWeatherProperties.blend(
            from: sourceProperties,
            to: targetProperties,
            progress: easedFraction
        )
        
        if elapsedTransitionTime >= transitionDuration {
            currentProperties = targetProperties
            isTransitioning = false
        }
    }
}

// MARK: - Cloud Drift Simulation System

/// Enumerates the cloud models supported.
enum HasanaGardenCloudType: String, CaseIterable, Codable {
    case cirrus    // Wispy high altitude
    case cumulus   // Puffy volumetric shapes
    case stratus   // Flattened blankets
    case nimbus    // Dark rain clouds
}

/// Represents a single cloud entity drifting across the sky above the garden.
final class HasanaGardenCloud: Identifiable, Equatable {
    let id: UUID = UUID()
    var cloudType: HasanaGardenCloudType
    var position: SIMD3<Float>
    var scale: SIMD3<Float>
    var opacity: Float
    var driftSpeedMultiplier: Float
    var rotationAngle: Float
    var volumeDensity: Float // Visual density
    
    init(
        cloudType: HasanaGardenCloudType,
        position: SIMD3<Float>,
        scale: SIMD3<Float>,
        opacity: Float = 0.8,
        driftSpeedMultiplier: Float = 1.0,
        rotationAngle: Float = 0.0,
        volumeDensity: Float = 0.5
    ) {
        self.cloudType = cloudType
        self.position = position
        self.scale = scale
        self.opacity = opacity
        self.driftSpeedMultiplier = driftSpeedMultiplier
        self.rotationAngle = rotationAngle
        self.volumeDensity = volumeDensity
    }
    
    static func == (lhs: HasanaGardenCloud, rhs: HasanaGardenCloud) -> Bool {
        lhs.id == rhs.id
    }
}

/// Simulates drift and cycle of clouds within volumetric boundaries.
final class HasanaGardenCloudDriftSystem {
    private(set) var activeClouds: [HasanaGardenCloud] = []
    
    // Coordinate boundaries where clouds are simulated
    let boundaryWidth: Float = 16.0  // X limits: -8 to 8
    let boundaryHeight: Float = 4.0  // Y limits: 3.5 to 7.5
    let boundaryDepth: Float = 16.0  // Z limits: -8 to 8
    
    private let minCloudCount = 3
    private let maxCloudCount = 35
    
    init() {
        populateInitialClouds()
    }
    
    /// Populates standard starting clouds throughout the boundary box.
    private func populateInitialClouds() {
        // Spawn standard clouds at different depths and heights
        let initialCount = 8
        for _ in 0..<initialCount {
            let x = Float.random(in: -7.0...7.0)
            let y = Float.random(in: 3.8...7.0)
            let z = Float.random(in: -7.0...7.0)
            
            let cloud = generateRandomCloud(at: SIMD3<Float>(x, y, z))
            activeClouds.append(cloud)
        }
    }
    
    /// Generates a randomized cloud configuration with structural variety.
    private func generateRandomCloud(at initialPosition: SIMD3<Float>) -> HasanaGardenCloud {
        let types: [HasanaGardenCloudType] = [.cirrus, .cumulus, .stratus]
        let selectedType = types.randomElement() ?? .cumulus
        
        let width = Float.random(in: 1.5...3.8)
        let height = Float.random(in: 0.4...1.2)
        let depth = Float.random(in: 1.2...2.6)
        
        let speedMult = Float.random(in: 0.6...1.4)
        let opacity = Float.random(in: 0.35...0.85)
        let density = Float.random(in: 0.2...0.9)
        let rot = Float.random(in: 0.0...Float.pi * 2.0)
        
        return HasanaGardenCloud(
            cloudType: selectedType,
            position: initialPosition,
            scale: SIMD3<Float>(width, height, depth),
            opacity: opacity,
            driftSpeedMultiplier: speedMult,
            rotationAngle: rot,
            volumeDensity: density
        )
    }
    
    /// Steps the cloud positions forward and manages bounds spawning.
    /// - Parameters:
    ///   - deltaTime: Time step in seconds.
    ///   - windSpeed: Current wind speed scalar (m/s).
    ///   - windDirectionDegrees: Wind vector angle.
    ///   - targetCloudCoverage: Cloud spawn density modifier (0.0 to 1.0).
    func update(deltaTime: Double, windSpeed: Float, windDirectionDegrees: Float, targetCloudCoverage: Float) {
        let dt = Float(deltaTime)
        
        // Convert wind direction degrees to a 3D unit force vector in the X-Z plane
        let windRad = WeatherMath.degToRadF(windDirectionDegrees)
        let windDirectionVector = SIMD3<Float>(sin(windRad), 0.0, cos(windRad))
        
        // Update all existing clouds
        var cloudsToRemove: [Int] = []
        
        for (index, cloud) in activeClouds.enumerated() {
            // Drift calculation: wind speed * drift multiplier * direction * time
            let velocity = windDirectionVector * windSpeed * cloud.driftSpeedMultiplier * 0.15
            cloud.position += velocity * dt
            
            // Boundary checks: check if cloud left the X-Z simulation limits
            let outX = abs(cloud.position.x) > boundaryWidth / 2.0 + 2.0
            let outZ = abs(cloud.position.z) > boundaryDepth / 2.0 + 2.0
            
            if outX || outZ {
                cloudsToRemove.append(index)
            }
        }
        
        // Remove dead clouds out of bounds
        for index in cloudsToRemove.sorted().reversed() {
            activeClouds.remove(at: index)
        }
        
        // Dynamic spawning based on target cloud coverage
        let desiredCount = Int(WeatherMath.lerp(
            from: Float(minCloudCount),
            to: Float(maxCloudCount),
            progress: targetCloudCoverage
        ))
        
        if activeClouds.count < desiredCount {
            // Spawn new cloud on the boundary opposite to wind direction
            let spawnPos = calculateSpawnPosition(windDirection: windDirectionVector)
            let newCloud = generateRandomCloud(at: spawnPos)
            
            // Override type to Nimbus if coverage is high (overcast/stormy)
            if targetCloudCoverage > 0.80 {
                newCloud.cloudType = .nimbus
                newCloud.opacity = Float.random(in: 0.8...0.95)
                newCloud.volumeDensity = Float.random(in: 0.7...1.0)
            }
            
            activeClouds.append(newCloud)
        } else if activeClouds.count > desiredCount + 4 && !activeClouds.isEmpty {
            // Gradually decay clouds to match lower coverage
            activeClouds.removeLast()
        }
    }
    
    /// Calculates a spawn position along the outer boundaries corresponding to where wind blows from.
    private func calculateSpawnPosition(windDirection: SIMD3<Float>) -> SIMD3<Float> {
        let oppositeWind = -windDirection
        
        // Position at the boundary edge with some perpendicular offset randomization
        let xOffset = oppositeWind.x * (boundaryWidth / 2.0)
        let zOffset = oppositeWind.z * (boundaryDepth / 2.0)
        
        var spawnX = xOffset
        var spawnZ = zOffset
        
        // Randomize the perpendicular component
        let randomFactor = Float.random(in: -4.0...4.0)
        if abs(oppositeWind.x) > abs(oppositeWind.z) {
            // Wind blowing mostly horizontally, randomize Z
            spawnZ = randomFactor
        } else {
            // Wind blowing mostly vertically, randomize X
            spawnX = randomFactor
        }
        
        let spawnY = Float.random(in: 4.0...7.2)
        return SIMD3<Float>(spawnX, spawnY, spawnZ)
    }
}

// MARK: - Wind Simulation Engine

/// Simulates physical wind forces using multi-frequency trigonometric noise layers.
final class HasanaGardenWindSimulator {
    private var totalElapsedTime: Double = 0.0
    
    init() {}
    
    /// Ticks the wind simulation timeline.
    func update(deltaTime: Double) {
        totalElapsedTime += deltaTime
    }
    
    /// Computes wind force vector at a specific coordinate and time, modeling local turbulence.
    /// - Parameters:
    ///   - position: The 3D position in the garden.
    ///   - baseSpeed: Current base wind speed.
    ///   - baseDirectionDegrees: Wind direction angle.
    ///   - gustiness: Factor controlling gust frequency and variance.
    /// - Returns: A vector representing the simulated wind force.
    func windForce(at position: SIMD3<Float>, baseSpeed: Float, baseDirectionDegrees: Float, gustiness: Float) -> SIMD3<Float> {
        let time = Float(totalElapsedTime)
        
        // Convert base direction angle to horizontal vector
        let dirRad = WeatherMath.degToRadF(baseDirectionDegrees)
        let baseDir = SIMD3<Float>(sin(dirRad), 0.0, cos(dirRad))
        
        // Turbulence approximation using multi-frequency sine wave combinations (Perlin-like noise approximation)
        // High frequency micro-gusts based on coordinate position
        let wave1 = sin(time * 1.5 + position.x * 0.4 + position.z * 0.3)
        let wave2 = cos(time * 0.8 - position.y * 0.6 + position.z * 0.5)
        let wave3 = sin(time * 3.2 + position.x * 1.2) * 0.4 // micro turbulence
        
        // Combine waves to get a turbulence multiplier
        let turbulence = (wave1 + wave2 + wave3) / 2.4 // yields values roughly between -1.0 and 1.0
        
        // Calculate dynamic gust factor
        // Gusts build up and fade over longer periods (low frequency waves)
        let gustPeriod = sin(time * 0.18) * cos(time * 0.05)
        let gustStrength = max(0.0, gustPeriod) * gustiness * 1.8
        
        // Final velocity scalar = base speed + gust contributions + local turbulence
        let finalSpeed = baseSpeed + (gustStrength * baseSpeed) + (turbulence * baseSpeed * gustiness * 0.5)
        
        // Slight direction shifting over time/position to simulate natural gusts wrapping around objects
        let dirShiftAngle = sin(time * 0.4 + position.x * 0.1) * 0.18 * gustiness
        let rotatedX = baseDir.x * cos(dirShiftAngle) - baseDir.z * sin(dirShiftAngle)
        let rotatedZ = baseDir.x * sin(dirShiftAngle) + baseDir.z * cos(dirShiftAngle)
        
        return SIMD3<Float>(rotatedX, 0.0, rotatedZ) * max(finalSpeed, 0.0)
    }
    
    /// Computes physical tree canopy deflection and oscillation parameters under current wind force.
    /// - Parameters:
    ///   - position: Tree root position.
    ///   - treeHeight: Trunk height.
    ///   - stiffness: Tree wood resistance coefficient (0.0 to 1.0).
    ///   - baseSpeed: Wind speed.
    ///   - baseDirectionDegrees: Wind direction.
    ///   - gustiness: Wind gustiness.
    /// - Returns: A translation vector to apply as a vertex tilt/bend factor.
    func foliageDeflection(
        at position: SIMD3<Float>,
        treeHeight: Float,
        stiffness: Float,
        baseSpeed: Float,
        baseDirectionDegrees: Float,
        gustiness: Float
    ) -> SIMD3<Float> {
        let force = windForce(at: position, baseSpeed: baseSpeed, baseDirectionDegrees: baseDirectionDegrees, gustiness: gustiness)
        
        // Bending force scales with wind speed squared (aerodynamic drag: F = 0.5 * rho * v^2 * Cd * A)
        let speed = simd_length(force)
        let dragForce = 0.08 * speed * speed
        
        // Flex increases along height of tree (cantilever beam model approximation: deflection proportional to height^3)
        // Adjust flex based on structural stiffness
        let flexCoefficient = (1.05 - stiffness) * 0.038
        let bendStrength = dragForce * flexCoefficient * (treeHeight * treeHeight)
        
        // Unit direction of wind
        let forceDirection = speed > 0.01 ? simd_normalize(force) : SIMD3<Float>(0.0, 0.0, 0.0)
        
        // Continuous sway oscillation (natural frequency)
        let naturalFrequency = 2.4 * stiffness
        let sway = sin(Float(totalElapsedTime) * naturalFrequency + position.x * 1.5) * 0.15 * speed * flexCoefficient
        
        // Combined steady deflection + dynamic harmonic sway
        let deflectionScalar = bendStrength + sway
        
        return forceDirection * deflectionScalar
    }
}

// MARK: - Programmatic RealityKit Particle System Emitters

/// Provides programmatically configured particle systems simulating atmospheric conditions.
/// Using fallback systems if native Metal particles are unsupported or in simulated/preview environments.
struct HasanaGardenParticlePresets {
    
    /// Safe wrapper containing either a native RealityKit particle system or fallback geometry meshes.
    struct VisualEffectSystem {
        var rootEntity: Entity
        var updateHandler: ((Double, SIMD3<Float>) -> Void)?
    }
    
    /// Instantiates a rain system using native `ParticleEmitterComponent` or dynamic physical fallback drops.
    static func createRainSystem(intensity: Float, boundsWidth: Float = 6.0, boundsDepth: Float = 4.2) -> VisualEffectSystem {
        let parent = Entity()
        parent.name = "RainSystemRoot"
        
        #if targetEnvironment(simulator)
        // Simulators fail to run heavy RealityKit particles smoothly. Use dynamic geometric drops pool.
        let fallback = createFallbackRainDrops(intensity: intensity, width: boundsWidth, depth: boundsDepth)
        parent.addChild(fallback.entity)
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            fallback.update(dt, wind, intensity)
        }
        #else
        // Physical Device execution: Build highly detailed ParticleEmitterComponent
        let emitterEntity = Entity()
        emitterEntity.name = "RainEmitterComponent"
        
        var emitter = ParticleEmitterComponent()
        
        // Main particle properties configuration
        emitter.timing = .repeating(warmUp: 2.0, emit: .init(duration: 1.0))
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [boundsWidth, 0.1, boundsDepth]
        
        // Configure rain visuals: elongated blue/grey streaks
        emitter.mainEmitter.birthRate = Float(120.0 * intensity)
        emitter.mainEmitter.birthRateVariation = Float(20.0 * intensity)
        emitter.mainEmitter.lifeSpan = 1.6
        emitter.mainEmitter.lifeSpanVariation = 0.2
        
        // Rain falls down rapidly
        emitter.speed = -4.5
        emitter.speedVariation = 0.8
        
        // Drop dimensions
        emitter.mainEmitter.size = 0.024
        emitter.mainEmitter.sizeVariation = 0.008
        
        // Drag and Gravity forces
        emitter.mainEmitter.acceleration = [0.0, -9.81, 0.0]
        emitter.mainEmitter.noiseScale = 0.2
        emitter.mainEmitter.noiseStrength = 0.05
        
        // Materials setup
        let rainColor = UIColor(red: 0.62, green: 0.76, blue: 0.88, alpha: 0.35)
        emitter.mainEmitter.color = .evolving(start: .single(rainColor), end: .single(rainColor))
        
        emitterEntity.components[ParticleEmitterComponent.self] = emitter
        emitterEntity.position = [0.0, 3.8, 0.0] // Spawn above canopy
        parent.addChild(emitterEntity)
        
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            // Update emitter angle and gravity vectors depending on wind force
            if var currentEmitter = emitterEntity.components[ParticleEmitterComponent.self] {
                // Apply wind force directly to gravity/acceleration vector
                currentEmitter.mainEmitter.acceleration = [wind.x * 0.6, -9.81, wind.z * 0.6]
                currentEmitter.mainEmitter.birthRate = Float(120.0 * intensity)
                emitterEntity.components[ParticleEmitterComponent.self] = currentEmitter
            }
        }
        #endif
    }
    
    /// Instantiates a snow system.
    static func createSnowSystem(intensity: Float, boundsWidth: Float = 6.0, boundsDepth: Float = 4.2) -> VisualEffectSystem {
        let parent = Entity()
        parent.name = "SnowSystemRoot"
        
        #if targetEnvironment(simulator)
        let fallback = createFallbackSnowFlakes(intensity: intensity, width: boundsWidth, depth: boundsDepth)
        parent.addChild(fallback.entity)
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            fallback.update(dt, wind, intensity)
        }
        #else
        let emitterEntity = Entity()
        emitterEntity.name = "SnowEmitterComponent"
        
        var emitter = ParticleEmitterComponent()
        emitter.timing = .repeating(warmUp: 3.0, emit: .init(duration: 1.0))
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [boundsWidth, 0.1, boundsDepth]
        
        // Snow drifts down slowly, with higher turbulence
        emitter.mainEmitter.birthRate = Float(48.0 * intensity)
        emitter.mainEmitter.lifeSpan = 4.5
        emitter.speed = -0.72
        emitter.speedVariation = 0.15
        emitter.mainEmitter.size = 0.038
        emitter.mainEmitter.sizeVariation = 0.012
        
        // Snowflake drifts: lower gravity, high noise influence
        emitter.mainEmitter.acceleration = [0.0, -0.42, 0.0]
        emitter.mainEmitter.noiseScale = 1.4
        emitter.mainEmitter.noiseStrength = 0.48
        
        let snowColor = UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 0.85)
        emitter.mainEmitter.color = .evolving(start: .single(snowColor), end: .single(snowColor))
        
        emitterEntity.components[ParticleEmitterComponent.self] = emitter
        emitterEntity.position = [0.0, 3.8, 0.0]
        parent.addChild(emitterEntity)
        
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            if var currentEmitter = emitterEntity.components[ParticleEmitterComponent.self] {
                // Wind blows light snowflakes significantly
                currentEmitter.mainEmitter.acceleration = [wind.x * 1.5, -0.35, wind.z * 1.5]
                currentEmitter.mainEmitter.birthRate = Float(48.0 * intensity)
                emitterEntity.components[ParticleEmitterComponent.self] = currentEmitter
            }
        }
        #endif
    }
    
    /// Instantiates a fireflies system.
    static func createFirefliesSystem(intensity: Float, boundsWidth: Float = 5.0, boundsDepth: Float = 3.5) -> VisualEffectSystem {
        let parent = Entity()
        parent.name = "FirefliesSystemRoot"
        
        #if targetEnvironment(simulator)
        let fallback = createFallbackFireflies(intensity: intensity, width: boundsWidth, depth: boundsDepth)
        parent.addChild(fallback.entity)
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            fallback.update(dt, wind, intensity)
        }
        #else
        let emitterEntity = Entity()
        emitterEntity.name = "FirefliesEmitterComponent"
        
        var emitter = ParticleEmitterComponent()
        emitter.timing = .repeating(warmUp: 1.0, emit: .init(duration: 1.0))
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [boundsWidth, 1.8, boundsDepth]
        
        // Fireflies spawn inside a volume close to the grass lawn
        emitter.mainEmitter.birthRate = Float(8.0 * intensity)
        emitter.mainEmitter.lifeSpan = 5.5
        emitter.speed = 0.08
        emitter.speedVariation = 0.04
        emitter.mainEmitter.size = 0.015
        
        // Swirly upward motion, zero gravity
        emitter.mainEmitter.acceleration = [0.0, 0.0, 0.0]
        emitter.mainEmitter.noiseScale = 2.0
        emitter.mainEmitter.noiseStrength = 0.38
        
        // Glowing gold/green color
        let glowColor = UIColor(red: 0.72, green: 0.95, blue: 0.22, alpha: 0.88)
        let fadeColor = UIColor(red: 0.72, green: 0.95, blue: 0.22, alpha: 0.0)
        emitter.mainEmitter.color = .evolving(start: .single(glowColor), end: .single(fadeColor))
        
        emitterEntity.components[ParticleEmitterComponent.self] = emitter
        emitterEntity.position = [0.0, 1.0, 0.0] // close to soil/foliage
        parent.addChild(emitterEntity)
        
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            if var currentEmitter = emitterEntity.components[ParticleEmitterComponent.self] {
                currentEmitter.mainEmitter.birthRate = Float(8.0 * intensity)
                emitterEntity.components[ParticleEmitterComponent.self] = currentEmitter
            }
        }
        #endif
    }
    
    /// Instantiates a dust motes system (glowing pollen/dust floating in sunlight shafts).
    static func createDustMotesSystem(intensity: Float, boundsWidth: Float = 5.0, boundsDepth: Float = 3.5) -> VisualEffectSystem {
        let parent = Entity()
        parent.name = "DustMotesSystemRoot"
        
        #if targetEnvironment(simulator)
        let fallback = createFallbackDustMotes(intensity: intensity, width: boundsWidth, depth: boundsDepth)
        parent.addChild(fallback.entity)
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            fallback.update(dt, wind, intensity)
        }
        #else
        let emitterEntity = Entity()
        emitterEntity.name = "DustMotesEmitterComponent"
        
        var emitter = ParticleEmitterComponent()
        emitter.timing = .repeating(warmUp: 1.0, emit: .init(duration: 1.0))
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [boundsWidth, 2.5, boundsDepth]
        
        emitter.mainEmitter.birthRate = Float(14.0 * intensity)
        emitter.mainEmitter.lifeSpan = 7.0
        emitter.speed = 0.02
        emitter.speedVariation = 0.01
        emitter.mainEmitter.size = 0.008
        
        emitter.mainEmitter.acceleration = [0.0, -0.01, 0.0] // almost floating
        emitter.mainEmitter.noiseScale = 1.0
        emitter.mainEmitter.noiseStrength = 0.12
        
        let moteColor = UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 0.45)
        let fadeColor = UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 0.0)
        emitter.mainEmitter.color = .evolving(start: .single(moteColor), end: .single(fadeColor))
        
        emitterEntity.components[ParticleEmitterComponent.self] = emitter
        emitterEntity.position = [0.0, 1.5, 0.0]
        parent.addChild(emitterEntity)
        
        return VisualEffectSystem(rootEntity: parent) { dt, wind in
            if var currentEmitter = emitterEntity.components[ParticleEmitterComponent.self] {
                currentEmitter.mainEmitter.birthRate = Float(14.0 * intensity)
                emitterEntity.components[ParticleEmitterComponent.self] = currentEmitter
            }
        }
        #endif
    }
    
    // MARK: - Simulator Fallback Geometric Implementations
    
    private final class FallbackGeometrySystem {
        var entity: Entity
        var update: (Double, SIMD3<Float>, Float) -> Void
        
        init(entity: Entity, update: @escaping (Double, SIMD3<Float>, Float) -> Void) {
            self.entity = entity
            self.update = update
        }
    }
    
    private static func createFallbackRainDrops(intensity: Float, width: Float, depth: Float) -> FallbackGeometrySystem {
        let container = Entity()
        container.name = "FallbackRainContainer"
        
        // Pre-instantiate a pool of ModelEntities representing drop streaks
        let dropCount = 45
        var drops: [ModelEntity] = []
        
        // Single shared mesh to save memory
        let dropMesh = MeshResource.generateBox(width: 0.004, height: 0.15, depth: 0.004)
        let dropMaterial = SimpleMaterial(color: UIColor(red: 0.65, green: 0.78, blue: 0.92, alpha: 0.38), roughness: 0.9, isMetallic: false)
        
        for _ in 0..<dropCount {
            let drop = ModelEntity(mesh: dropMesh, materials: [dropMaterial])
            let rx = Float.random(in: -width/2.0...width/2.0)
            let ry = Float.random(in: 0.1...3.6)
            let rz = Float.random(in: -depth/2.0...depth/2.0)
            
            drop.position = [rx, ry, rz]
            container.addChild(drop)
            drops.append(drop)
        }
        
        let updateBlock: (Double, SIMD3<Float>, Float) -> Void = { dt, wind, currentIntensity in
            let speed: Float = 5.2 * Float(dt)
            let limitY: Float = 0.08 // grass level
            
            for drop in drops {
                // If intensity is 0, hide drops
                if currentIntensity < 0.05 {
                    drop.isEnabled = false
                    continue
                } else {
                    drop.isEnabled = true
                }
                
                // Fall downwards and offset by wind vector
                drop.position.y -= speed
                drop.position.x += wind.x * 0.15 * Float(dt)
                drop.position.z += wind.z * 0.15 * Float(dt)
                
                // Tilt the drop to align with wind direction
                let fallVector = SIMD3<Float>(wind.x * 0.15, -5.2, wind.z * 0.15)
                let dir = simd_normalize(fallVector)
                drop.orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: dir)
                
                // Wrap around at floor boundary
                if drop.position.y < limitY {
                    drop.position.y = 3.6
                    drop.position.x = Float.random(in: -width/2.0...width/2.0)
                    drop.position.z = Float.random(in: -depth/2.0...depth/2.0)
                }
            }
        }
        
        return FallbackGeometrySystem(entity: container, update: updateBlock)
    }
    
    private static func createFallbackSnowFlakes(intensity: Float, width: Float, depth: Float) -> FallbackGeometrySystem {
        let container = Entity()
        container.name = "FallbackSnowContainer"
        
        let flakeCount = 35
        var flakes: [ModelEntity] = []
        
        let flakeMesh = MeshResource.generateSphere(radius: 0.015)
        let flakeMaterial = SimpleMaterial(color: UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 0.85), roughness: 0.95, isMetallic: false)
        
        for _ in 0..<flakeCount {
            let flake = ModelEntity(mesh: flakeMesh, materials: [flakeMaterial])
            let rx = Float.random(in: -width/2.0...width/2.0)
            let ry = Float.random(in: 0.1...3.6)
            let rz = Float.random(in: -depth/2.0...depth/2.0)
            
            flake.position = [rx, ry, rz]
            container.addChild(flake)
            flakes.append(flake)
        }
        
        var elapsed: Double = 0.0
        let updateBlock: (Double, SIMD3<Float>, Float) -> Void = { dt, wind, currentIntensity in
            elapsed += dt
            let speed: Float = 0.85 * Float(dt)
            let limitY: Float = 0.08
            
            for (index, flake) in flakes.enumerated() {
                if currentIntensity < 0.05 {
                    flake.isEnabled = false
                    continue
                } else {
                    flake.isEnabled = true
                }
                
                // Swirly sine wave offsets to simulate fluttering snowflake paths
                let phase = Float(index) * 0.42
                let flutterX = sin(Float(elapsed) * 2.2 + phase) * 0.12 * Float(dt)
                let flutterZ = cos(Float(elapsed) * 1.8 + phase) * 0.12 * Float(dt)
                
                flake.position.y -= speed
                flake.position.x += wind.x * 0.38 * Float(dt) + flutterX
                flake.position.z += wind.z * 0.38 * Float(dt) + flutterZ
                
                if flake.position.y < limitY {
                    flake.position.y = 3.6
                    flake.position.x = Float.random(in: -width/2.0...width/2.0)
                    flake.position.z = Float.random(in: -depth/2.0...depth/2.0)
                }
            }
        }
        
        return FallbackGeometrySystem(entity: container, update: updateBlock)
    }
    
    private static func createFallbackFireflies(intensity: Float, width: Float, depth: Float) -> FallbackGeometrySystem {
        let container = Entity()
        container.name = "FallbackFirefliesContainer"
        
        let count = 12
        var flies: [ModelEntity] = []
        
        let flyMesh = MeshResource.generateSphere(radius: 0.01)
        let flyMaterial = SimpleMaterial(color: UIColor(red: 0.75, green: 0.95, blue: 0.15, alpha: 0.90), roughness: 0.1, isMetallic: false)
        
        for _ in 0..<count {
            let fly = ModelEntity(mesh: flyMesh, materials: [flyMaterial])
            let rx = Float.random(in: -width/2.0...width/2.0)
            let ry = Float.random(in: 0.12...1.8)
            let rz = Float.random(in: -depth/2.0...depth/2.0)
            
            fly.position = [rx, ry, rz]
            container.addChild(fly)
            flies.append(fly)
        }
        
        var elapsed: Double = 0.0
        let updateBlock: (Double, SIMD3<Float>, Float) -> Void = { dt, wind, currentIntensity in
            elapsed += dt
            
            for (index, fly) in flies.enumerated() {
                if currentIntensity < 0.05 {
                    fly.isEnabled = false
                    continue
                } else {
                    fly.isEnabled = true
                }
                
                let phase = Float(index) * 0.68
                
                // Periodic glow pulsing: scale fly up/down and adjust color alpha
                let pulse = (sin(Float(elapsed) * 3.5 + phase) + 1.0) / 2.0 // 0.0 to 1.0
                let sizeFactor = 0.5 + pulse * 1.5
                fly.scale = SIMD3<Float>(repeating: sizeFactor)
                
                // Slow drift movement
                let driftX = sin(Float(elapsed) * 1.2 + phase) * 0.22 * Float(dt)
                let driftY = cos(Float(elapsed) * 0.8 + phase) * 0.15 * Float(dt)
                let driftZ = sin(Float(elapsed) * 0.5 + phase) * 0.22 * Float(dt)
                
                fly.position.x += driftX + wind.x * 0.04 * Float(dt)
                fly.position.y += driftY
                fly.position.z += driftZ + wind.z * 0.04 * Float(dt)
                
                // Wrap around within grass volume boundaries
                if abs(fly.position.x) > width/2.0 { fly.position.x = -fly.position.x }
                if fly.position.y < 0.12 || fly.position.y > 1.8 { fly.position.y = 0.9 }
                if abs(fly.position.z) > depth/2.0 { fly.position.z = -fly.position.z }
            }
        }
        
        return FallbackGeometrySystem(entity: container, update: updateBlock)
    }
    
    private static func createFallbackDustMotes(intensity: Float, width: Float, depth: Float) -> FallbackGeometrySystem {
        let container = Entity()
        container.name = "FallbackDustContainer"
        
        let count = 15
        var motes: [ModelEntity] = []
        
        let moteMesh = MeshResource.generateSphere(radius: 0.006)
        let moteMaterial = SimpleMaterial(color: UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 0.50), roughness: 0.8, isMetallic: false)
        
        for _ in 0..<count {
            let mote = ModelEntity(mesh: moteMesh, materials: [moteMaterial])
            let rx = Float.random(in: -width/2.0...width/2.0)
            let ry = Float.random(in: 0.1...2.8)
            let rz = Float.random(in: -depth/2.0...depth/2.0)
            
            mote.position = [rx, ry, rz]
            container.addChild(mote)
            motes.append(mote)
        }
        
        var elapsed: Double = 0.0
        let updateBlock: (Double, SIMD3<Float>, Float) -> Void = { dt, wind, currentIntensity in
            elapsed += dt
            
            for (index, mote) in motes.enumerated() {
                if currentIntensity < 0.05 {
                    mote.isEnabled = false
                    continue
                } else {
                    mote.isEnabled = true
                }
                
                let phase = Float(index) * 0.55
                
                // Fluttering motion, extremely slow downward drift
                let flutterX = sin(Float(elapsed) * 0.8 + phase) * 0.08 * Float(dt)
                let flutterZ = cos(Float(elapsed) * 0.6 + phase) * 0.08 * Float(dt)
                
                mote.position.y -= 0.08 * Float(dt)
                mote.position.x += wind.x * 0.02 * Float(dt) + flutterX
                mote.position.z += wind.z * 0.02 * Float(dt) + flutterZ
                
                if mote.position.y < 0.05 {
                    mote.position.y = 2.8
                    mote.position.x = Float.random(in: -width/2.0...width/2.0)
                    mote.position.z = Float.random(in: -depth/2.0...depth/2.0)
                }
            }
        }
        
        return FallbackGeometrySystem(entity: container, update: updateBlock)
    }
}

// MARK: - Main Weather and Atmospheric Coordinator

/// The central system orchestrating daylight progression, weather simulations, solar path tracking, wind force generators, and atmospheric effects.
@Observable
@MainActor
final class HasanaGardenWeatherSystem {
    // Spatial positioning of the garden (defaults to Makkah)
    var latitude: Double = 21.4225
    var longitude: Double = 39.8262
    
    // Simulation times
    var currentDate: Date = Date()
    var simulatedHourFraction: Double = 0.5 // 0.0 to 1.0 (noon default)
    var timeFlowMultiplier: Double = 0.0    // Fast forward factor (0.0 = static/paused)
    
    // Core Modules
    private(set) var solarPath: HasanaGardenSolarPathCalculator
    private(set) var weatherTransition: HasanaGardenWeatherTransitionManager
    private(set) var cloudDrift: HasanaGardenCloudDriftSystem
    private(set) var windSimulation: HasanaGardenWindSimulator
    
    // Active computed environment configurations (bindable by RealityKit)
    private(set) var computedDaylightProperties: HasanaGardenDaylightProperties
    private(set) var compositeFogColor: UIColor = .clear
    private(set) var compositeFogDensity: Float = 0.0
    private(set) var solarVector: SIMD3<Float> = [0, 1, 0]
    private(set) var lunarVector: SIMD3<Float> = [0, -1, 0]
    
    // Visual indicators
    private(set) var activeWeatherType: HasanaGardenWeatherType = .clear
    private(set) var currentRainIntensity: Float = 0.0
    private(set) var currentSnowIntensity: Float = 0.0
    private(set) var currentWindForceVector: SIMD3<Float> = [0, 0, 0]
    private(set) var currentMoonPhase: HasanaGardenLunarPhase = .fullMoon
    private(set) var currentMoonIllumination: Float = 1.0
    
    // Lightning event state machine
    private(set) var lightningFlashActive: Bool = false
    private(set) var lightningFlashIntensity: Float = 0.0
    private var timeUntilNextLightning: Double = 0.0
    private var lightningSequenceTime: Double = 0.0
    private var lightningPhase: Int = 0 // 0: Idle, 1: Flash 1, 2: Pause, 3: Flash 2, 4: Decay
    
    // Particles System state bindings
    var isMotesActive: Bool = true
    var isFirefliesActive: Bool = false
    
    // Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(initialWeather: HasanaGardenWeatherType = .clear) {
        self.solarPath = HasanaGardenSolarPathCalculator(latitude: 21.4225, longitude: 39.8262)
        self.weatherTransition = HasanaGardenWeatherTransitionManager(initialType: initialWeather)
        self.cloudDrift = HasanaGardenCloudDriftSystem()
        self.windSimulation = HasanaGardenWindSimulator()
        self.computedDaylightProperties = HasanaGardenDaylightProperties.properties(for: .dhuhr)
        
        syncTimeFractionFromDate()
        evaluateStaticOutputs()
    }
    
    /// Binds properties to coordinates from settings.
    func updateLocation(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.solarPath = HasanaGardenSolarPathCalculator(latitude: latitude, longitude: longitude)
    }
    
    /// Synchronizes the day fraction (0.0 to 1.0) from the actual system clock.
    func syncTimeFractionFromDate() {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: currentDate))
        let minute = Double(calendar.component(.minute, from: currentDate))
        let second = Double(calendar.component(.second, from: currentDate))
        self.simulatedHourFraction = (hour + (minute + second / 60.0) / 60.0) / 24.0
    }
    
    /// Triggers transition to new weather settings.
    func transitionWeather(to type: HasanaGardenWeatherType, duration: Double = 8.0) {
        weatherTransition.transition(to: type, duration: duration)
    }
    
    /// Forces manual override of time fraction (0.0 to 1.0).
    func setSimulatedTimeFraction(_ fraction: Double) {
        self.simulatedHourFraction = min(max(fraction, 0.0), 1.0)
    }
    
    /// Set simulated time by hours and minutes.
    func setSimulatedTime(hour: Int, minute: Int) {
        let frac = (Double(hour) + Double(minute) / 60.0) / 24.0
        setSimulatedTimeFraction(frac)
    }
    
    /// Steps the atmospheric simulation. Should be linked to a CADisplayLink or game tick loop.
    /// - Parameter deltaTime: Time elapsed since last frame in seconds.
    func tick(deltaTime: Double) {
        // 1. Progress simulated clock if time flow multiplier is active
        if timeFlowMultiplier > 0.0 {
            simulatedHourFraction += (timeFlowMultiplier * deltaTime) / (24.0 * 3600.0)
            if simulatedHourFraction >= 1.0 {
                simulatedHourFraction = simulatedHourFraction.truncatingRemainder(dividingBy: 1.0)
                currentDate = currentDate.addingTimeInterval(24.0 * 3600.0) // advance day
            }
        }
        
        // 2. Tick Weather Transition
        weatherTransition.update(deltaTime: deltaTime)
        activeWeatherType = weatherTransition.currentProperties.weatherType
        
        // 3. Tick Wind simulation
        windSimulation.update(deltaTime: deltaTime)
        
        // 4. Update daylight attributes depending on time of day
        updateDaylightStateProperties()
        
        // 5. Update cloud drifting positions
        let weather = weatherTransition.currentProperties
        cloudDrift.update(
            deltaTime: deltaTime,
            windSpeed: weather.windSpeedBase,
            windDirectionDegrees: weather.windDirectionDegrees,
            targetCloudCoverage: weather.cloudCoverage
        )
        
        // 6. Compute lighting matrices and vector projections
        updateSolarSystemTransforms()
        
        // 7. Core physical forces computations
        currentRainIntensity = weather.rainIntensity
        currentSnowIntensity = weather.snowIntensity
        currentWindForceVector = windSimulation.windForce(
            at: .zero,
            baseSpeed: weather.windSpeedBase,
            baseDirectionDegrees: weather.windDirectionDegrees,
            gustiness: weather.windGustiness
        )
        
        // 8. Handle stormy lightning flashes
        updateLightningEngine(deltaTime: deltaTime)
        
        // 9. Evaluate final composite fog configurations
        compositeFogColor = WeatherMath.lerp(
            from: computedDaylightProperties.fogColor,
            to: weatherTransition.currentProperties.weatherType == .misty ? UIColor(red: 0.65, green: 0.68, blue: 0.70, alpha: 1.0) : computedDaylightProperties.fogColor,
            progress: min((weather.fogMultiplier - 1.0) / 2.8, 1.0)
        )
        compositeFogDensity = computedDaylightProperties.fogDensity * weather.fogMultiplier
        
        // Activate/deactivate fireflies and dust motes automatically based on daylight cycles
        isFirefliesActive = computedDaylightProperties.starOpacity > 0.50 && weather.rainIntensity < 0.20
        isMotesActive = computedDaylightProperties.starOpacity < 0.50 && weather.rainIntensity < 0.10
    }
    
    /// Recalculates all parameters for static initialization.
    private func evaluateStaticOutputs() {
        updateDaylightStateProperties()
        updateSolarSystemTransforms()
        
        let weather = weatherTransition.currentProperties
        currentRainIntensity = weather.rainIntensity
        currentSnowIntensity = weather.snowIntensity
        currentWindForceVector = windSimulation.windForce(
            at: .zero,
            baseSpeed: weather.windSpeedBase,
            baseDirectionDegrees: weather.windDirectionDegrees,
            gustiness: weather.windGustiness
        )
        
        let lunar = solarPath.calculateLunarPhase(for: currentDate)
        currentMoonPhase = lunar.phase
        currentMoonIllumination = lunar.illuminatedFraction
    }
    
    /// Finds adjacent daylight states and blends them based on simulatedHourFraction.
    private func updateDaylightStateProperties() {
        let fraction = simulatedHourFraction
        let states = HasanaGardenDaylightState.allCases.sorted { $0.peakTimeFraction < $1.peakTimeFraction }
        
        var lowerState: HasanaGardenDaylightState = .midnight
        var upperState: HasanaGardenDaylightState = .fajr
        
        // Locate active slot
        for i in 0..<states.count {
            let currentPeak = states[i].peakTimeFraction
            let nextPeak = (i == states.count - 1) ? 1.0 : states[i+1].peakTimeFraction
            
            if fraction >= currentPeak && fraction < nextPeak {
                lowerState = states[i]
                upperState = (i == states.count - 1) ? states[0] : states[i+1]
                break
            }
        }
        
        let lowerPeak = lowerState.peakTimeFraction
        var upperPeak = upperState.peakTimeFraction
        if upperPeak < lowerPeak {
            upperPeak += 1.0 // handle wraparound at midnight
        }
        
        let adjustedFraction = (lowerPeak == upperPeak) ? 0.0 : (fraction - lowerPeak) / (upperPeak - lowerPeak)
        
        let lowerProps = HasanaGardenDaylightProperties.properties(for: lowerState)
        let upperProps = HasanaGardenDaylightProperties.properties(for: upperState)
        
        computedDaylightProperties = HasanaGardenDaylightProperties.blend(
            from: lowerProps,
            to: upperProps,
            progress: Float(adjustedFraction)
        )
    }
    
    /// Recalculates sun and moon coordinates.
    private func updateSolarSystemTransforms() {
        // Calculate raw astronomical elevation/azimuth
        let sunAngles = solarPath.calculateSolarAngles(for: currentDate, dayFraction: simulatedHourFraction)
        solarVector = HasanaGardenSolarPathCalculator.projectToCartesian(
            altitude: sunAngles.altitude,
            azimuth: sunAngles.azimuth,
            radius: 5.0
        )
        
        // Moon is roughly projected opposite of the solar coordinates
        let moonElevation = -sunAngles.altitude
        let moonAzimuth = sunAngles.azimuth + .pi
        lunarVector = HasanaGardenSolarPathCalculator.projectToCartesian(
            altitude: moonElevation,
            azimuth: moonAzimuth,
            radius: 5.0
        )
        
        let lunar = solarPath.calculateLunarPhase(for: currentDate)
        currentMoonPhase = lunar.phase
        currentMoonIllumination = lunar.illuminatedFraction
    }
    
    /// Handles episodic lightning discharge cycles during stormy weather.
    private func updateLightningEngine(deltaTime: Double) {
        let weather = weatherTransition.currentProperties
        guard weather.thunderProbability > 0.0 else {
            lightningFlashActive = false
            lightningFlashIntensity = 0.0
            lightningPhase = 0
            return
        }
        
        if lightningPhase == 0 {
            // Idle state: counting down to next lightning strikes
            timeUntilNextLightning -= deltaTime
            if timeUntilNextLightning <= 0.0 {
                // Trigger lightning cycle
                lightningPhase = 1
                lightningSequenceTime = 0.0
                lightningFlashActive = true
                // Randomize next interval (shorter if thunder probability is high)
                let baseWait = WeatherMath.lerp(from: 18.0, to: 4.0, progress: weather.thunderProbability)
                timeUntilNextLightning = Double.random(in: Double(baseWait)...Double(baseWait * 2.2))
            }
        } else {
            // Processing flash sequences: double flash simulation
            lightningSequenceTime += deltaTime
            
            switch lightningPhase {
            case 1: // Primary rising flash
                let p = Float(lightningSequenceTime / 0.08) // 80ms build
                lightningFlashIntensity = WeatherMath.lerp(from: 0.0, to: 1.0, progress: p)
                if lightningSequenceTime >= 0.08 {
                    lightningPhase = 2
                    lightningSequenceTime = 0.0
                }
                
            case 2: // Primary quick decay
                let p = Float(lightningSequenceTime / 0.12) // 120ms fade
                lightningFlashIntensity = WeatherMath.lerp(from: 1.0, to: 0.15, progress: p)
                if lightningSequenceTime >= 0.12 {
                    lightningPhase = 3
                    lightningSequenceTime = 0.0
                }
                
            case 3: // Secondary smaller rebound flash
                let p = Float(lightningSequenceTime / 0.06) // 60ms rebound
                lightningFlashIntensity = WeatherMath.lerp(from: 0.15, to: 0.65, progress: p)
                if lightningSequenceTime >= 0.06 {
                    lightningPhase = 4
                    lightningSequenceTime = 0.0
                }
                
            case 4: // Secondary slow final decay
                let p = Float(lightningSequenceTime / 0.45) // 450ms tail fade
                lightningFlashIntensity = WeatherMath.lerp(from: 0.65, to: 0.0, progress: p)
                if lightningSequenceTime >= 0.45 {
                    lightningPhase = 0
                    lightningFlashActive = false
                    lightningFlashIntensity = 0.0
                }
                
            default:
                lightningPhase = 0
                lightningFlashActive = false
            }
        }
    }
}

// MARK: - Integration Helpers for RealityKit Scenes

/// Direct renderer interface bridging the WeatherSystem state to RealityKit light entities and environments.
@MainActor
final class HasanaGardenWeatherRenderer {
    private weak var arView: ARView?
    private var weatherSystem: HasanaGardenWeatherSystem
    
    // Retained light entities in scene
    private var sunLightEntity: DirectionalLight?
    private var moonLightEntity: DirectionalLight?
    private var ambientLightEntity: PointLight? // using large attenuation radius pointlight as dynamic ambient
    
    // Retained particle system roots
    private var activeRainEffect: HasanaGardenParticlePresets.VisualEffectSystem?
    private var activeSnowEffect: HasanaGardenParticlePresets.VisualEffectSystem?
    private var activeMotesEffect: HasanaGardenParticlePresets.VisualEffectSystem?
    private var activeFirefliesEffect: HasanaGardenParticlePresets.VisualEffectSystem?
    
    // Scene anchors
    private let environmentAnchor = AnchorEntity(world: .zero)
    private var skyboxModel: ModelEntity?
    
    init(arView: ARView, weatherSystem: HasanaGardenWeatherSystem) {
        self.arView = arView
        self.weatherSystem = weatherSystem
        
        arView.scene.addAnchor(environmentAnchor)
        setupEnvironmentLighting()
        setupAtmosphereSkybox()
        synchronizeVisuals()
    }
    
    /// Initializes directional and point lights.
    private func setupEnvironmentLighting() {
        // Sun Light
        let sun = DirectionalLight()
        sun.name = "WeatherSunLight"
        sun.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 8.0,
            depthBias: 0.8
        )
        environmentAnchor.addChild(sun)
        self.sunLightEntity = sun
        
        // Moon Light
        let moon = DirectionalLight()
        moon.name = "WeatherMoonLight"
        environmentAnchor.addChild(moon)
        self.moonLightEntity = moon
        
        // Ambient Fill Light
        let fill = PointLight()
        fill.name = "WeatherAmbientLight"
        fill.light.attenuationRadius = 15.0
        fill.position = [0.0, 5.0, 0.0]
        environmentAnchor.addChild(fill)
        self.ambientLightEntity = fill
    }
    
    /// Builds a physical hemisphere representing the visible sky dome.
    private func setupAtmosphereSkybox() {
        // Generate a large inverted sphere to act as skybox
        let sphereMesh = MeshResource.generateSphere(radius: 8.0)
        
        // We set roughness to 1.0, metallic to 0.0. Basic unlit appearance using emissive properties.
        var skyMaterial = SimpleMaterial()
        skyMaterial.color = .init(tint: .white)
        skyMaterial.roughness = .float(1.0)
        
        let sky = ModelEntity(mesh: sphereMesh, materials: [skyMaterial])
        sky.name = "AtmosphericSkyboxDome"
        
        // Scale negative on Z to invert the normals, putting the texture/color on the inside of the sphere
        sky.scale = SIMD3<Float>(1.0, 1.0, -1.0)
        
        environmentAnchor.addChild(sky)
        self.skyboxModel = sky
    }
    
    /// Ticks rendering entities, aligning positions, colors, intensities and drifting cloud transforms.
    func renderTick(deltaTime: Double) {
        // 1. Advance logical simulation
        weatherSystem.tick(deltaTime: deltaTime)
        
        // 2. Update entities with computed parameters
        synchronizeVisuals()
        
        // 3. Update active particles and geometries
        let wind = weatherSystem.currentWindForceVector
        
        activeRainEffect?.updateHandler?(deltaTime, wind)
        activeSnowEffect?.updateHandler?(deltaTime, wind)
        activeMotesEffect?.updateHandler?(deltaTime, wind)
        activeFirefliesEffect?.updateHandler?(deltaTime, wind)
    }
    
    /// Synchronizes visual components (lights, sky dome, particle visibility).
    private func synchronizeVisuals() {
        let daylight = weatherSystem.computedDaylightProperties
        let weather = weatherSystem.weatherTransition.currentProperties
        
        // A. Handle Sunlight Intensity & Position
        if let sun = sunLightEntity {
            // Apply weather absorption modifiers to sunlight
            let targetIntensity = daylight.sunLightIntensity * weather.ambientMultiplier
            
            // Adjust intensity on lightning flash activity (storms)
            if weatherSystem.lightningFlashActive {
                // Extreme bright flash overriding solar light parameters
                sun.light.intensity = targetIntensity + (weatherSystem.lightningFlashIntensity * 6000.0)
                sun.light.color = WeatherMath.lerp(
                    from: daylight.sunLightColor,
                    to: UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1.0),
                    progress: weatherSystem.lightningFlashIntensity
                )
            } else {
                sun.light.intensity = targetIntensity
                sun.light.color = daylight.sunLightColor
            }
            
            // Reorient light based on computed vector
            let solarDir = simd_normalize(weatherSystem.solarVector)
            sun.orientation = simd_quatf(from: SIMD3<Float>(0, 0, -1), to: solarDir)
            
            // Enable shadow map casting only if elevation is positive
            sun.shadow = daylight.sunElevationAngle > 0.05
                ? DirectionalLightComponent.Shadow(maximumDistance: 8.0, depthBias: 0.8)
                : nil
        }
        
        // B. Handle Moonlight Intensity & Position
        if let moon = moonLightEntity {
            // Moonlight is scaled by the active lunar phase coefficient
            let phaseMultiplier = weatherSystem.currentMoonIllumination * weatherSystem.currentMoonPhase.lightIntensityMultiplier
            let targetIntensity = daylight.moonLightIntensity * weather.ambientMultiplier * phaseMultiplier
            
            moon.light.intensity = targetIntensity
            moon.light.color = daylight.moonLightColor
            
            let lunarDir = simd_normalize(weatherSystem.lunarVector)
            moon.orientation = simd_quatf(from: SIMD3<Float>(0, 0, -1), to: lunarDir)
        }
        
        // C. Handle Ambient Fill
        if let fill = ambientLightEntity {
            fill.light.intensity = daylight.ambientIntensity * weather.ambientMultiplier
            fill.light.color = daylight.ambientColor
        }
        
        // D. Update Skybox Colors
        if let sky = skyboxModel {
            // Interpolate colors based on sun position.
            // If night/dusk, sky has dark gradient, otherwise bright blue/gold.
            // Update material properties dynamically.
            var material = SimpleMaterial()
            
            // Blend horizon and top sky colors for overall sky dome appearance
            let compositeSkyColor = WeatherMath.lerp(
                from: daylight.skyHorizonColor,
                to: daylight.skyTopColor,
                progress: 0.5
            )
            
            material.color = .init(tint: compositeSkyColor)
            material.roughness = .float(1.0)
            
            sky.model?.materials = [material]
        }
        
        // E. Manage Particles Instantiation / Destruction cycles
        manageActiveParticles()
    }
    
    /// Spawns or deletes particle systems according to weather intensity changes.
    private func manageActiveParticles() {
        let rainIntensity = weatherSystem.currentRainIntensity
        let snowIntensity = weatherSystem.currentSnowIntensity
        
        // Rain particles
        if rainIntensity > 0.05 {
            if activeRainEffect == nil {
                let rain = HasanaGardenParticlePresets.createRainSystem(intensity: rainIntensity)
                environmentAnchor.addChild(rain.rootEntity)
                activeRainEffect = rain
            }
        } else {
            if let rain = activeRainEffect {
                environmentAnchor.removeChild(rain.rootEntity)
                activeRainEffect = nil
            }
        }
        
        // Snow particles
        if snowIntensity > 0.05 {
            if activeSnowEffect == nil {
                let snow = HasanaGardenParticlePresets.createSnowSystem(intensity: snowIntensity)
                environmentAnchor.addChild(snow.rootEntity)
                activeSnowEffect = snow
            }
        } else {
            if let snow = activeSnowEffect {
                environmentAnchor.removeChild(snow.rootEntity)
                activeSnowEffect = nil
            }
        }
        
        // Dust motes particles
        if weatherSystem.isMotesActive {
            if activeMotesEffect == nil {
                let motes = HasanaGardenParticlePresets.createDustMotesSystem(intensity: 1.0)
                environmentAnchor.addChild(motes.rootEntity)
                activeMotesEffect = motes
            }
        } else {
            if let motes = activeMotesEffect {
                environmentAnchor.removeChild(motes.rootEntity)
                activeMotesEffect = nil
            }
        }
        
        // Fireflies particles
        if weatherSystem.isFirefliesActive {
            if activeFirefliesEffect == nil {
                let fireflies = HasanaGardenParticlePresets.createFirefliesSystem(intensity: 1.0)
                environmentAnchor.addChild(fireflies.rootEntity)
                activeFirefliesEffect = fireflies
            }
        } else {
            if let fireflies = activeFirefliesEffect {
                environmentAnchor.removeChild(fireflies.rootEntity)
                activeFirefliesEffect = nil
            }
        }
    }
}

// MARK: - Diagnostic Testing & Verification Framework

/// A suite of utilities to verify the physical properties of the WeatherSystem during unit execution or layout debug.
final class HasanaGardenWeatherDiagnostics {
    
    struct DiagnosticReport {
        let date: Date
        let simulatedTimeFraction: Double
        let activeDaylightState: HasanaGardenDaylightState
        let sunAltitudeDeg: Double
        let sunAzimuthDeg: Double
        let moonPhase: HasanaGardenLunarPhase
        let illuminatedFraction: Float
        let temperatureCelsius: Float
        let windVelocity: SIMD3<Float>
        let cloudCount: Int
    }
    
    /// Generates a snapshot summary of the simulation state.
    @MainActor
    static func generateReport(from system: HasanaGardenWeatherSystem) -> DiagnosticReport {
        let angles = system.solarPath.calculateSolarAngles(for: system.currentDate, dayFraction: system.simulatedHourFraction)
        let lunar = system.solarPath.calculateLunarPhase(for: system.currentDate)
        let temp = system.computedDaylightProperties.temperatureCelsius + system.weatherTransition.currentProperties.temperatureDelta
        
        return DiagnosticReport(
            date: system.currentDate,
            simulatedTimeFraction: system.simulatedHourFraction,
            activeDaylightState: system.computedDaylightProperties.state,
            sunAltitudeDeg: WeatherMath.radToDeg(angles.altitude),
            sunAzimuthDeg: WeatherMath.radToDeg(angles.azimuth),
            moonPhase: lunar.phase,
            illuminatedFraction: lunar.illuminatedFraction,
            temperatureCelsius: temp,
            windVelocity: system.currentWindForceVector,
            cloudCount: system.cloudDrift.activeClouds.count
        )
    }
    
    /// Simulates a 24-hour cycle quickly to verify mathematical bounds.
    @MainActor
    static func run24HourDiagnosticDryRun(latitude: Double, longitude: Double) -> [DiagnosticReport] {
        let system = HasanaGardenWeatherSystem()
        system.updateLocation(latitude: latitude, longitude: longitude)
        system.timeFlowMultiplier = 0.0 // static
        
        var reports: [DiagnosticReport] = []
        let steps = 24
        
        for hour in 0..<steps {
            let fraction = Double(hour) / Double(steps)
            system.setSimulatedTimeFraction(fraction)
            system.tick(deltaTime: 0.1) // minimal step to enforce state updates
            
            let report = generateReport(from: system)
            reports.append(report)
        }
        
        return reports
    }
}
