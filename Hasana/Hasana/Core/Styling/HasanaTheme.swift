import SwiftUI

public enum HasanaTheme {
    public static var background: Color {
        adaptive(light: palette.backgroundLight, dark: palette.backgroundDark)
    }

    public static var backgroundSecondary: Color {
        adaptive(light: palette.backgroundSecondaryLight, dark: palette.backgroundSecondaryDark)
    }

    public static var elevatedSurface: Color {
        adaptive(light: palette.elevatedSurfaceLight, dark: palette.elevatedSurfaceDark)
    }

    public static var elevatedSurfaceSoft: Color {
        adaptive(light: palette.elevatedSurfaceSoftLight, dark: palette.elevatedSurfaceSoftDark)
    }

    public static var textPrimary: Color {
        adaptive(light: "#0E1724", dark: "#F0F5FA")
    }

    public static var textMuted: Color {
        adaptive(light: "#5F7085", dark: "#A3B5C9")
    }

    public static var accent: Color {
        adaptive(light: palette.accentLight, dark: palette.accentDark)
    }

    public static var accentSoft: Color {
        adaptive(light: palette.accentSoftLight, dark: palette.accentSoftDark)
    }

    public static let gold = adaptive(light: "#D5A754", dark: "#E9C883")
    public static let goldSoft = adaptive(light: "#FDF6E2", dark: "#3F3219")
    public static let reflection = adaptive(light: "#5F6596", dark: "#A9AEE8")
    public static let reflectionSoft = adaptive(light: "#E4E5F2", dark: "#282B49")
    public static let finance = adaptive(light: "#9A6234", dark: "#E0A267")
    public static let idea = adaptive(light: "#64B5F6", dark: "#90CAF9")
    public static let summary = adaptive(light: "#706086", dark: "#C2A7E4")

    public static var border: Color {
        adaptive(light: palette.borderLight, dark: palette.borderDark)
    }

    public static var borderStrong: Color {
        adaptive(light: palette.borderStrongLight, dark: palette.borderStrongDark)
    }

    public static let overlayScrim = adaptive(light: "#0B131E", dark: "#030508")
    public static let shadow = adaptive(light: "#182E4B", dark: "#000000")

    public static var paletteBackground: LinearGradient {
        LinearGradient(
            colors: [
                elevatedSurface.opacity(0.94),
                elevatedSurfaceSoft.opacity(0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var canvasBackground: LinearGradient {
        LinearGradient(
            colors: [
                background,
                accentSoft.opacity(0.58),
                backgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func categoryColor(_ category: HasanaCommandCategory) -> Color {
        switch category {
        case .canvas:
            accent
        case .giving:
            finance
        case .app:
            gold
        }
    }

    private static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? dark : light)
        })
    }

    private static var palette: HasanaThemePalette {
        HasanaThemeChoice.current.palette
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
