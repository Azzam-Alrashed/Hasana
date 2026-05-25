import SwiftUI

enum HasanaTheme {
    static let background = adaptive(light: "#F7F3EA", dark: "#07110D")
    static let backgroundSecondary = adaptive(light: "#EFE8DA", dark: "#101A15")
    static let elevatedSurface = adaptive(light: "#FFFBF2", dark: "#16211B")
    static let elevatedSurfaceSoft = adaptive(light: "#F8F0E2", dark: "#1B2A22")

    static let textPrimary = adaptive(light: "#18231D", dark: "#F2EEE4")
    static let textMuted = adaptive(light: "#667063", dark: "#B7B0A3")

    static let accent = adaptive(light: "#0F6B4D", dark: "#4FC58E")
    static let accentSoft = adaptive(light: "#DDEDE4", dark: "#153B2C")
    static let gold = adaptive(light: "#B08A3C", dark: "#D5B86C")
    static let goldSoft = adaptive(light: "#F0E3C3", dark: "#3E3219")
    static let reflection = adaptive(light: "#5F6596", dark: "#A9AEE8")
    static let reflectionSoft = adaptive(light: "#E4E5F2", dark: "#282B49")
    static let finance = adaptive(light: "#9A6234", dark: "#E0A267")
    static let idea = adaptive(light: "#4E8270", dark: "#78D7B2")
    static let summary = adaptive(light: "#706086", dark: "#C2A7E4")

    static let border = adaptive(light: "#DED3BC", dark: "#31443A")
    static let borderStrong = adaptive(light: "#C8B68F", dark: "#5A735F")
    static let overlayScrim = adaptive(light: "#17261F", dark: "#020604")
    static let shadow = adaptive(light: "#2A2112", dark: "#000000")

    static let paletteBackground = LinearGradient(
        colors: [
            elevatedSurface.opacity(0.94),
            elevatedSurfaceSoft.opacity(0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let canvasBackground = LinearGradient(
        colors: [
            background,
            accentSoft.opacity(0.58),
            backgroundSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func categoryColor(_ category: HasanaCommandCategory) -> Color {
        switch category {
        case .today:
            idea
        case .worship:
            accent
        case .reflection:
            reflection
        case .finance:
            finance
        }
    }

    static func canvasColor(_ theme: HasanaCanvasTheme) -> Color {
        switch theme {
        case .today:
            idea
        case .worship:
            accent
        case .reflection:
            reflection
        case .finance:
            finance
        case .idea:
            gold
        case .summary:
            summary
        }
    }

    private static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: String) {
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
            red = 0
            green = 0
            blue = 0
        }

        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }
}
