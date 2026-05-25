import SwiftUI

enum HasanaTheme {
    static let background = adaptive(light: "#F3F7FC", dark: "#0B131E")
    static let backgroundSecondary = adaptive(light: "#E6EEF7", dark: "#111E30")
    static let elevatedSurface = adaptive(light: "#FBFDFF", dark: "#15243B")
    static let elevatedSurfaceSoft = adaptive(light: "#F5F9FD", dark: "#192A44")

    static let textPrimary = adaptive(light: "#0E1724", dark: "#F0F5FA")
    static let textMuted = adaptive(light: "#5F7085", dark: "#A3B5C9")

    static let accent = adaptive(light: "#4C99E9", dark: "#7FB5F5")
    static let accentSoft = adaptive(light: "#EBF3FC", dark: "#182E4B")
    static let gold = adaptive(light: "#D5A754", dark: "#E9C883")
    static let goldSoft = adaptive(light: "#FDF6E2", dark: "#3F3219")
    static let reflection = adaptive(light: "#5F6596", dark: "#A9AEE8")
    static let reflectionSoft = adaptive(light: "#E4E5F2", dark: "#282B49")
    static let finance = adaptive(light: "#9A6234", dark: "#E0A267")
    static let idea = adaptive(light: "#64B5F6", dark: "#90CAF9")
    static let summary = adaptive(light: "#706086", dark: "#C2A7E4")

    static let border = adaptive(light: "#D2E2F5", dark: "#223550")
    static let borderStrong = adaptive(light: "#ADCBEF", dark: "#3D5C85")
    static let overlayScrim = adaptive(light: "#0B131E", dark: "#030508")
    static let shadow = adaptive(light: "#182E4B", dark: "#000000")

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
        case .canvas:
            accent
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
