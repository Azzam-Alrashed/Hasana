import Observation
import SwiftUI
import UIKit

enum HasanaSettingsKeys {
    static let language = "hasana.settings.language"
    static let theme = "hasana.settings.theme"
    static let appearance = "hasana.settings.appearance"
    static let appIcon = "hasana.settings.appIcon"
    static let hasCompletedOnboarding = "hasana.onboarding.completed"
}

enum HasanaLanguage: String, CaseIterable, Identifiable, Codable {
    case arabic = "ar"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arabic:
            "العربية"
        case .english:
            "English"
        }
    }

    var localeIdentifier: String { rawValue }

    var layoutDirection: LayoutDirection {
        switch self {
        case .arabic:
            .rightToLeft
        case .english:
            .leftToRight
        }
    }
}

enum HasanaAppearance: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.system, .arabic):
            "النظام"
        case (.system, .english):
            "System"
        case (.light, .arabic):
            "فاتح"
        case (.light, .english):
            "Light"
        case (.dark, .arabic):
            "داكن"
        case (.dark, .english):
            "Dark"
        }
    }
}

enum HasanaThemeChoice: String, CaseIterable, Identifiable, Codable {
    case garden
    case sunrise
    case ocean
    case lavender

    var id: String { rawValue }

    static var current: HasanaThemeChoice {
        let rawValue = UserDefaults.standard.string(forKey: HasanaSettingsKeys.theme)
        return HasanaThemeChoice(rawValue: rawValue ?? "") ?? .garden
    }

    var palette: HasanaThemePalette {
        switch self {
        case .garden:
            HasanaThemePalette(
                backgroundLight: "#F3F7FC",
                backgroundDark: "#0B131E",
                backgroundSecondaryLight: "#E6EEF7",
                backgroundSecondaryDark: "#111E30",
                elevatedSurfaceLight: "#FBFDFF",
                elevatedSurfaceDark: "#15243B",
                elevatedSurfaceSoftLight: "#F5F9FD",
                elevatedSurfaceSoftDark: "#192A44",
                accentLight: "#4C99E9",
                accentDark: "#7FB5F5",
                accentSoftLight: "#EBF3FC",
                accentSoftDark: "#182E4B",
                borderLight: "#D2E2F5",
                borderDark: "#223550",
                borderStrongLight: "#ADCBEF",
                borderStrongDark: "#3D5C85"
            )
        case .sunrise:
            HasanaThemePalette(
                backgroundLight: "#FFF7EE",
                backgroundDark: "#17120D",
                backgroundSecondaryLight: "#F3E7D9",
                backgroundSecondaryDark: "#241B13",
                elevatedSurfaceLight: "#FFFCF7",
                elevatedSurfaceDark: "#30251A",
                elevatedSurfaceSoftLight: "#FAF0E4",
                elevatedSurfaceSoftDark: "#3A2A1D",
                accentLight: "#C6723A",
                accentDark: "#F1B26F",
                accentSoftLight: "#F8E5D3",
                accentSoftDark: "#4A2B18",
                borderLight: "#E5CDB7",
                borderDark: "#513B2A",
                borderStrongLight: "#D6A77E",
                borderStrongDark: "#79593D"
            )
        case .ocean:
            HasanaThemePalette(
                backgroundLight: "#EFF8F7",
                backgroundDark: "#071716",
                backgroundSecondaryLight: "#DCEDEB",
                backgroundSecondaryDark: "#102523",
                elevatedSurfaceLight: "#FAFFFE",
                elevatedSurfaceDark: "#173431",
                elevatedSurfaceSoftLight: "#EEF9F7",
                elevatedSurfaceSoftDark: "#1E403C",
                accentLight: "#248D83",
                accentDark: "#63D0C5",
                accentSoftLight: "#DDF3F0",
                accentSoftDark: "#163C38",
                borderLight: "#BDE0DC",
                borderDark: "#28524D",
                borderStrongLight: "#77BEB6",
                borderStrongDark: "#3D7C75"
            )
        case .lavender:
            HasanaThemePalette(
                backgroundLight: "#F7F4FB",
                backgroundDark: "#12101A",
                backgroundSecondaryLight: "#EDE7F4",
                backgroundSecondaryDark: "#1F1A2D",
                elevatedSurfaceLight: "#FEFBFF",
                elevatedSurfaceDark: "#2A243A",
                elevatedSurfaceSoftLight: "#F5EFFA",
                elevatedSurfaceSoftDark: "#342C47",
                accentLight: "#7B65B5",
                accentDark: "#BEA8F2",
                accentSoftLight: "#ECE5F8",
                accentSoftDark: "#372A54",
                borderLight: "#D7CAE9",
                borderDark: "#4A4062",
                borderStrongLight: "#B6A0D9",
                borderStrongDark: "#75639B"
            )
        }
    }

    var previewColors: [Color] {
        [
            Color(hex: palette.backgroundLight),
            Color(hex: palette.accentLight),
            Color(hex: palette.borderStrongLight)
        ]
    }

    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.garden, .arabic):
            "الحديقة"
        case (.garden, .english):
            "Garden"
        case (.sunrise, .arabic):
            "الشروق"
        case (.sunrise, .english):
            "Sunrise"
        case (.ocean, .arabic):
            "المحيط"
        case (.ocean, .english):
            "Ocean"
        case (.lavender, .arabic):
            "لافندر"
        case (.lavender, .english):
            "Lavender"
        }
    }
}

struct HasanaThemePalette {
    let backgroundLight: String
    let backgroundDark: String
    let backgroundSecondaryLight: String
    let backgroundSecondaryDark: String
    let elevatedSurfaceLight: String
    let elevatedSurfaceDark: String
    let elevatedSurfaceSoftLight: String
    let elevatedSurfaceSoftDark: String
    let accentLight: String
    let accentDark: String
    let accentSoftLight: String
    let accentSoftDark: String
    let borderLight: String
    let borderDark: String
    let borderStrongLight: String
    let borderStrongDark: String
}

enum HasanaAppIcon: String, CaseIterable, Identifiable, Codable {
    case primary
    case icon1
    case icon2
    case icon3
    case icon4
    case icon5
    case icon6
    case icon7

    var id: String { rawValue }

    var alternateIconName: String? {
        switch self {
        case .primary:
            nil
        case .icon1:
            "AppIcon1"
        case .icon2:
            "AppIcon2"
        case .icon3:
            "AppIcon3"
        case .icon4:
            "AppIcon4"
        case .icon5:
            "AppIcon5"
        case .icon6:
            "AppIcon6"
        case .icon7:
            "AppIcon7"
        }
    }

    var symbolName: String {
        switch self {
        case .primary:
            "leaf.fill"
        case .icon1:
            "sparkles"
        case .icon2:
            "sun.max.fill"
        case .icon3:
            "moon.stars.fill"
        case .icon4:
            "drop.fill"
        case .icon5:
            "heart.fill"
        case .icon6:
            "star.fill"
        case .icon7:
            "circle.hexagongrid.fill"
        }
    }

    var previewColors: [Color] {
        switch self {
        case .primary:
            [Color(hex: "#2E7D68"), Color(hex: "#F0C65A")]
        case .icon1:
            [Color(hex: "#5F6596"), Color(hex: "#E9C883")]
        case .icon2:
            [Color(hex: "#C6723A"), Color(hex: "#F7D07B")]
        case .icon3:
            [Color(hex: "#1F2D4A"), Color(hex: "#A9AEE8")]
        case .icon4:
            [Color(hex: "#248D83"), Color(hex: "#83D9D0")]
        case .icon5:
            [Color(hex: "#B85668"), Color(hex: "#F3A6B4")]
        case .icon6:
            [Color(hex: "#706086"), Color(hex: "#D8C2F0")]
        case .icon7:
            [Color(hex: "#2F6F9F"), Color(hex: "#9DD7F3")]
        }
    }

    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.primary, .arabic):
            "الأصلي"
        case (.primary, .english):
            "Primary"
        case (.icon1, .arabic):
            "أيقونة ١"
        case (.icon1, .english):
            "Icon 1"
        case (.icon2, .arabic):
            "أيقونة ٢"
        case (.icon2, .english):
            "Icon 2"
        case (.icon3, .arabic):
            "أيقونة ٣"
        case (.icon3, .english):
            "Icon 3"
        case (.icon4, .arabic):
            "أيقونة ٤"
        case (.icon4, .english):
            "Icon 4"
        case (.icon5, .arabic):
            "أيقونة ٥"
        case (.icon5, .english):
            "Icon 5"
        case (.icon6, .arabic):
            "أيقونة ٦"
        case (.icon6, .english):
            "Icon 6"
        case (.icon7, .arabic):
            "أيقونة ٧"
        case (.icon7, .english):
            "Icon 7"
        }
    }
}

@Observable
final class HasanaAppSettings {
    var language: HasanaLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: HasanaSettingsKeys.language)
        }
    }

    var theme: HasanaThemeChoice {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: HasanaSettingsKeys.theme)
        }
    }

    var appearance: HasanaAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: HasanaSettingsKeys.appearance)
        }
    }

    var appIcon: HasanaAppIcon {
        didSet {
            UserDefaults.standard.set(appIcon.rawValue, forKey: HasanaSettingsKeys.appIcon)
            applyAppIcon(appIcon)
        }
    }

    var appIconErrorMessage: String?

    init(userDefaults: UserDefaults = .standard) {
        language = HasanaLanguage(rawValue: userDefaults.string(forKey: HasanaSettingsKeys.language) ?? "") ?? .arabic
        theme = HasanaThemeChoice(rawValue: userDefaults.string(forKey: HasanaSettingsKeys.theme) ?? "") ?? .garden
        appearance = HasanaAppearance(rawValue: userDefaults.string(forKey: HasanaSettingsKeys.appearance) ?? "") ?? .system
        appIcon = HasanaAppIcon(rawValue: userDefaults.string(forKey: HasanaSettingsKeys.appIcon) ?? "") ?? .primary
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    var layoutDirection: LayoutDirection {
        language.layoutDirection
    }

    var colorScheme: ColorScheme? {
        appearance.colorScheme
    }

    private func applyAppIcon(_ icon: HasanaAppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else {
            appIconErrorMessage = nil
            return
        }

        guard UIApplication.shared.alternateIconName != icon.alternateIconName else {
            appIconErrorMessage = nil
            return
        }

        UIApplication.shared.setAlternateIconName(icon.alternateIconName) { [weak self] error in
            DispatchQueue.main.async {
                self?.appIconErrorMessage = error?.localizedDescription
            }
        }
    }
}

extension Color {
    init(hex: String) {
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
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
