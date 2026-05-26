//
//  HasanaLayoutLocalizationHelper.swift
//  Hasana
//
//  Created by Azzam Developer on 2026-05-26.
//

import SwiftUI
import UIKit
import Foundation
import Combine

// MARK: - 1. Numeral Localization Systems

/// Specifies the target numeral system for formatting numbers in localized text views.
public enum HasanaNumeralSystem: String, CaseIterable, Identifiable, Codable {
    /// Western Arabic digits (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
    case western = "en"
    /// Eastern Arabic (Arabic-Indic) digits (٠, ١, ٢, ٣, ٤, ٥, ٦, ٧, ٨, ٩)
    case arabicIndic = "ar"
    
    public var id: String { rawValue }
    
    /// Map of Western digits to Eastern Arabic digits.
    private static let westernToIndicMap: [Character: Character] = [
        "0": "٠", "1": "١", "2": "٢", "3": "٣", "4": "٤",
        "5": "٥", "6": "٦", "7": "٧", "8": "٨", "9": "٩"
    ]
    
    /// Map of Eastern Arabic digits to Western digits.
    private static let indicToWesternMap: [Character: Character] = [
        "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
        "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
    ]
    
    /// Converts all digits inside a string to the target numeral system.
    /// - Parameter text: The input string containing digits.
    /// - Returns: A string with digits mapped to the requested numeral system.
    public func convert(in text: String) -> String {
        switch self {
        case .western:
            return String(text.map { Self.indicToWesternMap[$0] ?? $0 })
        case .arabicIndic:
            return String(text.map { Self.westernToIndicMap[$0] ?? $0 })
        }
    }
}

/// A highly customized number formatter wrapper that handles localized Arabic/English formatting,
/// supporting decimals, percentages, currency, and compact forms, outputting the correct numeral script.
public struct HasanaNumberFormatter {
    
    /// Formats an integer value using the requested language setting.
    /// - Parameters:
    ///   - value: The integer value to format.
    ///   - system: The numeral system to use.
    /// - Returns: Localized string representation.
    public static func format(integer value: Int, system: HasanaNumeralSystem) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: system.rawValue)
        formatter.numberStyle = .none
        let formattedString = formatter.string(from: NSNumber(value: value)) ?? String(value)
        return system.convert(in: formattedString)
    }
    
    /// Formats a double value with specific fractional constraints.
    /// - Parameters:
    ///   - value: The double value.
    ///   - maxDecimals: Maximum fractional digits.
    ///   - minDecimals: Minimum fractional digits.
    ///   - system: Numeral system.
    /// - Returns: Formatted localized double.
    public static func format(double value: Double, maxDecimals: Int = 2, minDecimals: Int = 0, system: HasanaNumeralSystem) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: system.rawValue)
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maxDecimals
        formatter.minimumFractionDigits = minDecimals
        let formattedString = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(maxDecimals)f", value)
        return system.convert(in: formattedString)
    }
    
    /// Formats a percentage value.
    /// - Parameters:
    ///   - value: Floating point fraction (e.g. 0.725 for 72.5%).
    ///   - decimals: Number of decimal digits.
    ///   - system: Numeral system.
    /// - Returns: Formatted percentage.
    public static func format(percentage value: Double, decimals: Int = 1, system: HasanaNumeralSystem) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: system.rawValue)
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = decimals
        let formattedString = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f%%", value * 100)
        return system.convert(in: formattedString)
    }
    
    /// Formats dynamic count strings (e.g., "15 Duas" -> "١٥ أدعية" / "15 prayers").
    /// - Parameters:
    ///   - count: The numerical value.
    ///   - singularKey: Singular form of localized noun.
    ///   - pluralKey: Plural form of localized noun.
    ///   - system: Numeral system to use.
    /// - Returns: Combined count and plural noun string.
    public static func formatCount(_ count: Int, singularKey: String, pluralKey: String, system: HasanaNumeralSystem) -> String {
        let countStr = format(integer: count, system: system)
        let noun = count == 1 ? singularKey : pluralKey
        if system == .arabicIndic {
            return "\(noun) \(countStr)" // Arabic typical ordering or simple presentation
        } else {
            return "\(countStr) \(noun)"
        }
    }
}

// MARK: - 2. Arabic Text & Tashkeel Processing

/// Comprehensive diacritic processing options for sanitizing, searching, and normalizing Arabic strings.
public struct HasanaTashkeelProcessor {
    
    /// Unicode ranges for Arabic diacritics (Harakat, Tanween, Shaddah, Sukun).
    private static let diacriticsSet: CharacterSet = {
        var set = CharacterSet()
        // Fatha, Damma, Kasra, Fathatayn, Dammatayn, Kasratayn, Shaddah, Sukun, Superscript Alef
        set.insert(charactersIn: "\u{064B}"..."\u{0652}")
        set.insert(charactersIn: "\u{0670}") // Dagger Alef
        set.insert(charactersIn: "\u{0654}"..."\u{0656}") // Hamza above/below
        return set
    }()
    
    /// Removes all diacritics (Harakat, Tanween, Sukun, Shaddah, etc.) from Arabic text.
    /// - Parameter text: The source Arabic string.
    /// - Returns: Diacritic-free Arabic text.
    public static func stripTashkeel(from text: String) -> String {
        return text.filter { char in
            guard let unicodeScalar = char.unicodeScalars.first else { return true }
            return !diacriticsSet.contains(unicodeScalar)
        }
    }
    
    /// Normalizes Arabic characters to simplify searches (e.g. mapping آ أ إ to ا, and ة to ه, and ى to ي).
    /// - Parameter text: The input text.
    /// - Returns: A simplified string ideal for fuzzy search.
    public static func normalizeArabic(text: String) -> String {
        let cleanText = stripTashkeel(from: text)
        var result = ""
        
        for char in cleanText {
            switch char {
            // Normalizing different forms of Alef
            case "أ", "إ", "آ", "ٱ":
                result.append("ا")
            // Normalizing Teh Marbuta to Heh
            case "ة":
                result.append("ه")
            // Normalizing Alef Maksura to Yeh
            case "ى":
                result.append("ي")
            default:
                result.append(char)
            }
        }
        return result
    }
    
    /// Checks if a query matches a target Arabic string, ignoring diacritics and Alef variations.
    /// - Parameters:
    ///   - query: Search query term.
    ///   - target: The text to search within.
    /// - Returns: Boolean indicating a match.
    public static func searchMatch(query: String, in target: String) -> Bool {
        let normalizedQuery = normalizeArabic(text: query).lowercased()
        let normalizedTarget = normalizeArabic(text: target).lowercased()
        return normalizedTarget.contains(normalizedQuery)
    }
}

// MARK: - 3. Bi-Directional Mixed Text (BiDi) Engine

/// Utility that detects, overrides, and properly formats strings containing mixed RTL and LTR scripts.
public struct HasanaBiDiProcessor {
    
    /// Directional Unicode Control characters.
    public enum ControlCharacter {
        /// Left-to-Right Marker (LRM): Acts like a zero-width LTR character.
        public static let lrm = "\u{200E}"
        /// Right-to-Left Marker (RLM): Acts like a zero-width RTL character.
        public static let rlm = "\u{200F}"
        /// Left-to-Right Embedding (LRE): Starts LTR context.
        public static let lre = "\u{202A}"
        /// Right-to-Left Embedding (RLE): Starts RTL context.
        public static let rle = "\u{202B}"
        /// Pop Directional Formatting (PDF): Restores previous embedding level.
        public static let pdf = "\u{202C}"
        /// Right-to-Left Override (RLO): Forces succeeding characters to render RTL.
        public static let rlo = "\u{202E}"
        /// Left-to-Right Override (LRO): Forces succeeding characters to render LTR.
        public static let lro = "\u{202D}"
    }
    
    /// Analyzes a string and determines its dominant script direction.
    /// - Parameter text: String to evaluate.
    /// - Returns: True if the string is predominantly Right-to-Left.
    public static func isPredominantlyRTL(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        
        var rtlCount = 0
        var ltrCount = 0
        
        for scalar in text.unicodeScalars {
            // Basic Arabic block: U+0600 to U+06FF
            // Arabic Supplement: U+0750 to U+077F
            // Arabic Extended: U+08A0 to U+08FF
            // Hebrew block: U+0590 to U+05FF
            if (scalar.value >= 0x0600 && scalar.value <= 0x06FF) ||
               (scalar.value >= 0x0750 && scalar.value <= 0x077F) ||
               (scalar.value >= 0x08A0 && scalar.value <= 0x08FF) ||
               (scalar.value >= 0x0590 && scalar.value <= 0x05FF) {
                rtlCount += 1
            } else if scalar.isASCII && scalar.value >= 65 && scalar.value <= 122 {
                ltrCount += 1
            }
        }
        
        return rtlCount >= ltrCount
    }
    
    /// Enforces RTL embedding on a string to prevent English brackets or symbols from flipping layout.
    /// - Parameter text: The source string.
    /// - Returns: Enveloped string with RLE and PDF wrappers.
    public static func enforceRTL(_ text: String) -> String {
        return "\(ControlCharacter.rle)\(text)\(ControlCharacter.pdf)"
    }
    
    /// Enforces LTR embedding on a string (ideal for URLs, phone numbers, or code inside Arabic texts).
    /// - Parameter text: The source string.
    /// - Returns: Enveloped string with LRE and PDF wrappers.
    public static func enforceLTR(_ text: String) -> String {
        return "\(ControlCharacter.lre)\(text)\(ControlCharacter.pdf)"
    }
    
    /// Smartly wraps nested parts of a string. For example, if we have English numbers inside Arabic text,
    /// this appends LRM/RLM flags to ensure punctuation at the end of the text line renders at the correct side.
    /// - Parameters:
    ///   - text: The string to format.
    ///   - isRTLContext: The layout direction of the surrounding context.
    /// - Returns: Safely rendering BiDi text.
    public static func bidiSafeString(_ text: String, isRTLContext: Bool) -> String {
        let marker = isRTLContext ? ControlCharacter.rlm : ControlCharacter.lrm
        return "\(marker)\(text)\(marker)"
    }
}

// MARK: - 4. Typography Scale & Custom Fonts Engine

/// Text sizes mapping supporting different scales for Latin and complex Arabic typography.
public enum HasanaTextScale {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case subheadline
    case body
    case callout
    case footnote
    case caption1
    case caption2
    
    /// The default point size for English (Latin script) standard Dynamic Type.
    public var defaultLatinSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title1:     return 28
        case .title2:     return 22
        case .title3:     return 20
        case .headline:   return 17
        case .subheadline:return 15
        case .body:       return 17
        case .callout:    return 16
        case .footnote:   return 13
        case .caption1:   return 12
        case .caption2:   return 11
        }
    }
    
    /// Arabic requires larger sizes (+15-20%) because Arabic letters have high complexity
    /// and diacritics are otherwise rendered too small to read comfortably.
    public var defaultArabicSize: CGFloat {
        switch self {
        case .largeTitle: return 38
        case .title1:     return 32
        case .title2:     return 25
        case .title3:     return 23
        case .headline:   return 20
        case .subheadline:return 18
        case .body:       return 20
        case .callout:    return 19
        case .footnote:   return 16
        case .caption1:   return 14
        case .caption2:   return 13
        }
    }
    
    /// Returns the recommended line spacing (leading) multiplier.
    /// Arabic requires greater spacing to accommodate tashkeel (diacritics) without line overlapping.
    public func lineSpacingMultiplier(isArabic: Bool) -> CGFloat {
        if isArabic {
            switch self {
            case .largeTitle, .title1: return 1.35
            case .title2, .title3: return 1.40
            case .headline, .subheadline: return 1.45
            case .body, .callout: return 1.50
            case .footnote, .caption1, .caption2: return 1.55
            }
        } else {
            return 1.15
        }
    }
    
    /// Returns the standard System font text style mapping.
    public var systemTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title1:     return .title1
        case .title2:     return .title2
        case .title3:     return .title3
        case .headline:   return .headline
        case .subheadline:return .subheadline
        case .body:       return .body
        case .callout:    return .callout
        case .footnote:   return .footnote
        case .caption1:   return .caption1
        case .caption2:   return .caption2
        }
    }
}

/// Manages dynamic scale adjustments and font weights for custom or system typography.
public class HasanaTypographyEngine {
    
    /// Fetches the dynamically-scaled font matching a custom family or falls back to system.
    /// Supports automatic Arabic script scaling adjustments.
    /// - Parameters:
    ///   - scale: The layout size scale.
    ///   - weight: Desired font weight.
    ///   - customFontName: Optional name of the custom family.
    ///   - isArabic: Boolean marking Arabic script.
    /// - Returns: A SwiftUI Font instance.
    public static func font(
        for scale: HasanaTextScale,
        weight: Font.Weight = .regular,
        customFontName: String? = nil,
        isArabic: Bool
    ) -> Font {
        let baseSize = isArabic ? scale.defaultArabicSize : scale.defaultLatinSize
        
        // Match UIKit weight for proper system scaling
        let uiWeight = uiFontWeight(from: weight)
        
        if let customFontName, !customFontName.isEmpty {
            // Attempt to load custom font, fallback to system if missing
            return Font.custom(customFontName, size: baseSize).weight(weight)
        } else {
            // Apply system font with script-specific weight corrections
            // In Arabic, extra bold weight can overlap loops/letters, so we scale it down slightly in tiny labels
            let adjustedWeight = adjustWeight(weight, scale: scale, isArabic: isArabic)
            return Font.system(size: baseSize, weight: adjustedWeight, design: .default)
        }
    }
    
    /// Maps SwiftUI `Font.Weight` to UIKit `UIFont.Weight`.
    private static func uiFontWeight(from weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .regular
        }
    }
    
    /// Adjusts font weight for legibility. Arabic text can suffer from "ink trap" occlusion at bold weights.
    private static func adjustWeight(_ weight: Font.Weight, scale: HasanaTextScale, isArabic: Bool) -> Font.Weight {
        guard isArabic else { return weight }
        // For tiny Arabic text (footnote, caption), heavy/black fonts collapse letter openings. Downgrade to bold/semibold.
        if (scale == .footnote || scale == .caption1 || scale == .caption2) {
            if weight == .black || weight == .heavy {
                return .bold
            }
        }
        return weight
    }
}

// MARK: - 5. SwiftUI Layout Mirroring & Padding Extensions

/// A structured container for edge-insets that support automatic horizontal mirroring.
public struct HasanaDirectionalInsets {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat
    
    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
    
    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.top = vertical
        self.leading = horizontal
        self.bottom = vertical
        self.trailing = horizontal
    }
    
    public init(all: CGFloat) {
        self.top = all
        self.leading = all
        self.bottom = all
        self.trailing = all
    }
    
    /// Resolves the insets to standard `EdgeInsets` matching the current layout direction.
    public func resolve(for direction: LayoutDirection) -> EdgeInsets {
        switch direction {
        case .leftToRight:
            return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        case .rightToLeft:
            // Swap leading and trailing
            return EdgeInsets(top: top, leading: trailing, bottom: bottom, trailing: leading)
        @unknown default:
            return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        }
    }
}

/// Dynamic transition provider mirroring direction-based sliding.
public struct HasanaDirectionalTransition {
    
    /// Slide transition that follows the reading direction (e.g. entering from trailing side, exiting to leading side).
    /// - Parameter direction: Current UI layout direction.
    /// - Returns: A responsive AnyTransition.
    public static func slideIn(from direction: LayoutDirection) -> AnyTransition {
        switch direction {
        case .leftToRight:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .rightToLeft:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        @unknown default:
            return .slide
        }
    }
    
    /// Dynamic scale-and-slide transition matching reading layouts.
    public static func slideAndFade(from direction: LayoutDirection) -> AnyTransition {
        let edge: Edge = (direction == .rightToLeft) ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .opacity
        )
    }
}

// MARK: - 6. SwiftUI View Modifiers

public struct HasanaLocalizedTypographyModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection
    let scale: HasanaTextScale
    let weight: Font.Weight
    let customFontName: String?
    
    public func body(content: Content) -> some View {
        let isArabic = layoutDirection == .rightToLeft
        let font = HasanaTypographyEngine.font(
            for: scale,
            weight: weight,
            customFontName: customFontName,
            isArabic: isArabic
        )
        let spacing = scale.defaultArabicSize * (scale.lineSpacingMultiplier(isArabic: isArabic) - 1.0)
        
        content
            .font(font)
            .lineSpacing(spacing)
    }
}

public struct HasanaDirectionalPaddingModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection
    let edges: Edge.Set
    let length: CGFloat?
    
    public func body(content: Content) -> some View {
        // Evaluate directional modifications manually to guarantee mirrors
        if edges.contains(.leading) && edges.contains(.trailing) {
            content.padding(.horizontal, length)
        } else if edges.contains(.leading) {
            content.padding(layoutDirection == .rightToLeft ? .trailing : .leading, length)
        } else if edges.contains(.trailing) {
            content.padding(layoutDirection == .rightToLeft ? .leading : .trailing, length)
        } else {
            content.padding(edges, length)
        }
    }
}

public struct HasanaDirectionalOffsetModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection
    let dx: CGFloat
    let dy: CGFloat
    
    public func body(content: Content) -> some View {
        // A positive leading offset moves left in LTR, but should move right in RTL.
        let actualX = layoutDirection == .rightToLeft ? -dx : dx
        content.offset(x: actualX, y: dy)
    }
}

public struct HasanaMirrorableImageModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection
    let enabled: Bool
    
    public func body(content: Content) -> some View {
        content
            .rotationEffect(enabled && layoutDirection == .rightToLeft ? .degrees(180) : .degrees(0))
            // Scaling is often cleaner than rotation for 2D vectors
            .scaleEffect(x: enabled && layoutDirection == .rightToLeft ? -1 : 1, y: 1)
    }
}

public struct HasanaCornerRadiusModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection
    let radius: CGFloat
    let corners: [HasanaDirectionalCorner]
    
    public enum HasanaDirectionalCorner {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }
    
    public func body(content: Content) -> some View {
        content.clipShape(
            HasanaDirectionalCornerShape(
                radius: radius,
                corners: corners,
                direction: layoutDirection
            )
        )
    }
}

private struct HasanaDirectionalCornerShape: Shape {
    var radius: CGFloat
    var corners: [HasanaCornerRadiusModifier.HasanaDirectionalCorner]
    var direction: LayoutDirection
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let tl = corners.contains(.topLeading)
        let tr = corners.contains(.topTrailing)
        let bl = corners.contains(.bottomLeading)
        let br = corners.contains(.bottomTrailing)
        
        // Match left/right depending on locale
        let actualTL = (direction == .leftToRight) ? tl : tr
        let actualTR = (direction == .leftToRight) ? tr : tl
        let actualBL = (direction == .leftToRight) ? bl : br
        let actualBR = (direction == .leftToRight) ? br : bl
        
        let width = rect.width
        let height = rect.height
        
        // Draw custom paths with appropriate corner arcs
        path.move(to: CGPoint(x: width / 2, y: 0))
        
        // Top Right Corner
        if actualTR {
            path.addLine(to: CGPoint(x: width - radius, y: 0))
            path.addArc(
                center: CGPoint(x: width - radius, y: radius),
                radius: radius,
                startAngle: Angle(degrees: -90),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        // Bottom Right Corner
        if actualBR {
            path.addLine(to: CGPoint(x: width, y: height - radius))
            path.addArc(
                center: CGPoint(x: width - radius, y: height - radius),
                radius: radius,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        // Bottom Left Corner
        if actualBL {
            path.addLine(to: CGPoint(x: radius, y: height))
            path.addArc(
                center: CGPoint(x: radius, y: height - radius),
                radius: radius,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        // Top Left Corner
        if actualTL {
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(
                center: CGPoint(x: radius, y: radius),
                radius: radius,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - View Extension for Fluent APIs

public extension View {
    
    /// Applies language-sensitive typography styles that scale dynamically and adjust line leading.
    /// - Parameters:
    ///   - scale: Predefined text size styles.
    ///   - weight: Desired weight.
    ///   - customFontName: Custom Font family name.
    /// - Returns: Modified View.
    func hasanaTypography(
        _ scale: HasanaTextScale,
        weight: Font.Weight = .regular,
        customFontName: String? = nil
    ) -> some View {
        self.modifier(HasanaLocalizedTypographyModifier(scale: scale, weight: weight, customFontName: customFontName))
    }
    
    /// Mirrors horizontal layout margins relative to current layout direction.
    /// - Parameters:
    ///   - edges: Edges to apply.
    ///   - length: Padding size.
    /// - Returns: Padded view.
    func hasanaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        self.modifier(HasanaDirectionalPaddingModifier(edges: edges, length: length))
    }
    
    /// Offsets contents relative to LTR/RTL reading flows.
    /// - Parameters:
    ///   - dx: Horizontal shift (positive shifts forward, negative shifts backward).
    ///   - dy: Vertical shift.
    /// - Returns: Offset view.
    func hasanaOffset(dx: CGFloat = 0, dy: CGFloat = 0) -> some View {
        self.modifier(HasanaDirectionalOffsetModifier(dx: dx, dy: dy))
    }
    
    /// Flips the view horizontally when layout direction is Right-to-Left (useful for arrows or directional progress views).
    /// - Parameter enabled: Flag to activate mirroring.
    /// - Returns: Mirrored view.
    func hasanaMirror(enabled: Bool = true) -> some View {
        self.modifier(HasanaMirrorableImageModifier(enabled: enabled))
    }
    
    /// Custom corner radius clipping that respects logical leading/trailing positions.
    /// - Parameters:
    ///   - radius: Corner curve depth.
    ///   - corners: List of logical corners to clip.
    /// - Returns: Rounded corner view.
    func hasanaCornerRadius(_ radius: CGFloat, corners: [HasanaCornerRadiusModifier.HasanaDirectionalCorner] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]) -> some View {
        self.modifier(HasanaCornerRadiusModifier(radius: radius, corners: corners))
    }
}

// MARK: - 7. UIKit Mirroring & Layout Extensions

public extension UIEdgeInsets {
    
    /// Initializer creating directional UIEdgeInsets.
    /// - Parameters:
    ///   - top: Top margin.
    ///   - leading: Logical leading margin.
    ///   - bottom: Bottom margin.
    ///   - trailing: Logical trailing margin.
    ///   - isRTL: Direction flag.
    init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0, isRTL: Bool) {
        let left = isRTL ? trailing : leading
        let right = isRTL ? leading : trailing
        self.init(top: top, left: left, bottom: bottom, right: right)
    }
}

public extension UIView {
    
    /// Recursively mirrors subview layout constraints.
    /// Forces standard Left/Right constraints to map back to Leading/Trailing behaviors.
    func mirrorConstraints() {
        for constraint in self.constraints {
            let firstAttr = constraint.firstAttribute
            let secondAttr = constraint.secondAttribute
            
            // Map Left to Leading and Right to Trailing where applicable.
            let newFirstAttr = swapLeftRightAttributes(firstAttr)
            let newSecondAttr = swapLeftRightAttributes(secondAttr)
            
            if newFirstAttr != firstAttr || newSecondAttr != secondAttr {
                // Remove and recreate constraint if attributes changed
                self.removeConstraint(constraint)
                let replaced = NSLayoutConstraint(
                    item: constraint.firstItem as Any,
                    attribute: newFirstAttr,
                    relatedBy: constraint.relation,
                    toItem: constraint.secondItem,
                    attribute: newSecondAttr,
                    multiplier: constraint.multiplier,
                    constant: constraint.constant
                )
                replaced.priority = constraint.priority
                replaced.shouldBeArchived = constraint.shouldBeArchived
                replaced.identifier = constraint.identifier
                self.addConstraint(replaced)
            }
        }
        
        for subview in self.subviews {
            subview.mirrorConstraints()
        }
    }
    
    private func swapLeftRightAttributes(_ attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint.Attribute {
        switch attribute {
        case .left:
            return .leading
        case .right:
            return .trailing
        case .leftMargin:
            return .leadingMargin
        case .rightMargin:
            return .trailingMargin
        default:
            return attribute
        }
    }
}

// MARK: - 8. Localized Alignments & Stacks

/// Localized HAlignment helper mapping logical alignment tags to absolute layout directions.
public enum HasanaHAlignment {
    case leading
    case center
    case trailing
    
    public func resolve(for direction: LayoutDirection) -> TextAlignment {
        switch self {
        case .leading:
            return direction == .rightToLeft ? .trailing : .leading
        case .center:
            return .center
        case .trailing:
            return direction == .rightToLeft ? .leading : .trailing
        }
    }
    
    public func alignment(for direction: LayoutDirection) -> Alignment {
        switch self {
        case .leading:
            return direction == .rightToLeft ? .trailing : .leading
        case .center:
            return .center
        case .trailing:
            return direction == .rightToLeft ? .leading : .trailing
        }
    }
}

/// A custom vertical container grid that implements dynamic layout wrapping.
/// Perfect for organizing a grid of Tasbih tokens, habit counters, or command capsules that align correctly in Arabic.
public struct HasanaLayoutDirectionalFlow<Content: View, T: Hashable>: View {
    @Environment(\.layoutDirection) var layoutDirection
    
    public let items: [T]
    public let spacing: CGFloat
    public let content: (T) -> Content
    
    public init(items: [T], spacing: CGFloat = 8, @ViewBuilder content: @escaping (T) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    @State private var totalHeight = CGFloat.zero
    
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight = CGFloat.zero
        
        let isRTL = layoutDirection == .rightToLeft
        let limitWidth = g.size.width
        
        return ZStack(alignment: isRTL ? .topTrailing : .topLeading) {
            ForEach(items, id: \.self) { item in
                self.content(item)
                    .alignmentGuide(isRTL ? .trailing : .leading) { d in
                        if isRTL {
                            // RTL Offset calculations
                            if (abs(width - d.width) > limitWidth) {
                                width = 0
                                height -= lastHeight + spacing
                            }
                            lastHeight = d.height
                            let result = width
                            if item == items.last {
                                width = 0 // Last reset
                            } else {
                                width -= d.width + spacing
                            }
                            return result
                        } else {
                            // LTR Offset calculations
                            if (width + d.width > limitWidth) {
                                width = 0
                                height -= lastHeight + spacing
                            }
                            lastHeight = d.height
                            let result = width
                            if item == items.last {
                                width = 0 // Last reset
                            } else {
                                width += d.width + spacing
                            }
                            return result
                        }
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if item == items.last {
                            height = 0 // Last reset
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geo.size.height
            }
            return Color.clear
        }
    }
}

// MARK: - 9. Interactive Development Testbed (SwiftUI Previews)

public struct HasanaLayoutLocalizationHelper_Previews: PreviewProvider {
    
    struct TestContainer: View {
        @State private var selectedLanguage: HasanaLanguage = .arabic
        @State private var arabicQuery = "أدعية"
        @State private var arabicTargetText = "تشتمل هذه المجموعة على الأدعية اليومية والمأثورة."
        @State private var testNumber: Double = 10452.754
        @State private var habitPoints = 0.85
        
        // Demo items for flow layout
        let capsuleItems = ["SubhanAllah", "Alhamdulillah", "AllahuAkbar", "Astaghfirullah", "LaIlahaIllallah"]
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Section 1: Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Simulate App Language Context")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Picker("App Language", selection: $selectedLanguage) {
                                Text("Arabic (RTL)").tag(HasanaLanguage.arabic)
                                Text("English (LTR)").tag(HasanaLanguage.english)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Apply layout parameters based on simulator choice
                        VStack(alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 20) {
                            
                            // Section 2: Typography Scale Tests
                            VStack(alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 6) {
                                Text("Typography Scaling (Dynamic Leading)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .bold()
                                
                                Text("Large Title Text / العنوان العريض")
                                    .hasanaTypography(.largeTitle, weight: .bold)
                                
                                Text("Subheadline / العنوان الفرعي")
                                    .hasanaTypography(.subheadline, weight: .semibold)
                                    .foregroundColor(.secondary)
                                
                                Text("Body text rendering test for script scale verification. Arabic requires more line height.\nهذا النص لتجربة قياس الخط وتباعد الأسطر المناسب لعلامات التشكيل والتنقيح.")
                                    .hasanaTypography(.body)
                                    .foregroundColor(.primary)
                            }
                            
                            Divider()
                            
                            // Section 3: Numeral Conversions
                            VStack(alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 8) {
                                Text("Numeral Formatting Engine")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .bold()
                                
                                let numSystem: HasanaNumeralSystem = selectedLanguage == .arabic ? .arabicIndic : .western
                                
                                Text("Integer Format: \(HasanaNumberFormatter.format(integer: 42, system: numSystem))")
                                    .hasanaTypography(.body)
                                
                                Text("Decimal Float: \(HasanaNumberFormatter.format(double: testNumber, maxDecimals: 2, system: numSystem))")
                                    .hasanaTypography(.body)
                                
                                Text("Percentage Format: \(HasanaNumberFormatter.format(percentage: habitPoints, system: numSystem))")
                                    .hasanaTypography(.body)
                                
                                Text(HasanaNumberFormatter.formatCount(selectedLanguage == .arabic ? 7 : 7, singularKey: selectedLanguage == .arabic ? "دعاء" : "dua", pluralKey: selectedLanguage == .arabic ? "أدعية" : "duas", system: numSystem))
                                    .hasanaTypography(.body)
                                    .foregroundColor(.blue)
                            }
                            
                            Divider()
                            
                            // Section 4: Directional Padding & Corner Radii
                            VStack(alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 10) {
                                Text("Directional Layout & Margins")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .bold()
                                
                                HStack {
                                    Text("Start Margin Card")
                                        .hasanaTypography(.caption1, weight: .bold)
                                        .padding(8)
                                        .background(Color.green.opacity(0.2))
                                        .hasanaCornerRadius(10, corners: [.topLeading, .bottomLeading])
                                    
                                    Spacer()
                                    
                                    Text("End Margin Card")
                                        .hasanaTypography(.caption1, weight: .bold)
                                        .padding(8)
                                        .background(Color.purple.opacity(0.2))
                                        .hasanaCornerRadius(10, corners: [.topTrailing, .bottomTrailing])
                                }
                                .padding(.horizontal, 10)
                                
                                // Directional offset demo
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(.accentColor)
                                        .hasanaMirror(enabled: true)
                                    
                                    Text("Mirror Arrows & Horizontal Offset (+30 leading)")
                                        .hasanaTypography(.caption2)
                                }
                                .hasanaOffset(dx: 30, dy: 0)
                                .hasanaPadding(.leading, 10)
                                .frame(maxWidth: .infinity, alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading)
                            }
                            
                            Divider()
                            
                            // Section 5: Arabic Normalization & Fuzzy Matches
                            VStack(alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 8) {
                                Text("Tashkeel Stripping & Search Normalizer")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .bold()
                                
                                Text("Raw: الـدُّعَـاءُ (With Tashkeel)")
                                    .hasanaTypography(.body, weight: .regular)
                                
                                let stripped = HasanaTashkeelProcessor.stripTashkeel(from: "الـدُّعَـاءُ")
                                Text("Stripped: \(stripped)")
                                    .hasanaTypography(.body, weight: .medium)
                                
                                let targetText = "تشتمل هذه المجموعة على الأدعية اليومية والمأثورة."
                                let query = "ادعيه"
                                let matches = HasanaTashkeelProcessor.searchMatch(query: query, in: targetText)
                                
                                Text("Target: \(targetText)")
                                    .hasanaTypography(.caption1)
                                Text("Fuzzy Query: '\(query)' -> Match Found: \(matches ? "نعم / Yes" : "لا / No")")
                                    .hasanaTypography(.caption2)
                                    .foregroundColor(matches ? .green : .red)
                            }
                            
                            Divider()
                            
                            // Section 6: Bi-directional Text Layout Prevention
                            VStack(alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 8) {
                                Text("Bi-Directional Text Rendering (BiDi)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .bold()
                                
                                // Direct English + Arabic mixing can break parenthesis
                                let mixedTextRaw = "حديث: (Narrated by Bukhari) عن أبي هريرة."
                                Text("Broken Mixed: \(mixedTextRaw)")
                                    .hasanaTypography(.caption1)
                                
                                let safeMixed = "حديث: \(HasanaBiDiProcessor.enforceLTR("(Narrated by Bukhari)")) عن أبي هريرة."
                                Text("Safe Mixed: \(safeMixed)")
                                    .hasanaTypography(.body)
                                
                                let mixedContextStr = HasanaBiDiProcessor.bidiSafeString("English text: 123-ABC in RTL", isRTLContext: selectedLanguage.layoutDirection == .rightToLeft)
                                Text("BiDi String: \(mixedContextStr)")
                                    .hasanaTypography(.caption2)
                            }
                            
                            Divider()
                            
                            // Section 7: Directional Wrapped Grid Layout
                            VStack(alignment: selectedLanguage.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 8) {
                                Text("Dynamic Wrapped Grid Flow (LTR/RTL Aware)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .bold()
                                
                                HasanaLayoutDirectionalFlow(items: capsuleItems) { item in
                                    Text(item)
                                        .hasanaTypography(.caption2, weight: .medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.15))
                                        .cornerRadius(12)
                                }
                            }
                            
                        }
                        .padding()
                        .environment(\.layoutDirection, selectedLanguage.layoutDirection)
                        .environment(\.locale, Locale(identifier: selectedLanguage.localeIdentifier))
                    }
                    .padding()
                }
                .navigationTitle("Layout Localization")
            }
        }
    }
    
    public static var previews: some View {
        TestContainer()
    }
}
