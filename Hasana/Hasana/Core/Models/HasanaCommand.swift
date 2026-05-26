import SwiftUI

enum HasanaCommandID: String, CaseIterable, Identifiable, Hashable, Codable {
    case resetView
    case logWorship
    case openPayments
    case openSettings

    var id: String { rawValue }
}

enum HasanaCommandCategory: String, Hashable {
    case canvas
    case giving
    case app

    var title: String {
        title(for: HasanaLanguage(rawValue: UserDefaults.standard.string(forKey: HasanaSettingsKeys.language) ?? "") ?? .arabic)
    }

    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.canvas, .arabic):
            "الحديقة"
        case (.canvas, .english):
            "Garden"
        case (.giving, .arabic):
            "العطاء"
        case (.giving, .english):
            "Giving"
        case (.app, .arabic):
            "التطبيق"
        case (.app, .english):
            "App"
        }
    }
}

struct HasanaCommand: Identifiable, Hashable {
    let id: HasanaCommandID
    let title: String
    let subtitle: String
    let icon: String
    let category: HasanaCommandCategory
    let keywords: [String]
    let shortcutHint: String?

    init(
        id: HasanaCommandID,
        title: String,
        subtitle: String,
        icon: String,
        category: HasanaCommandCategory,
        keywords: [String] = [],
        shortcutHint: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.keywords = keywords
        self.shortcutHint = shortcutHint
    }

    static var defaults: [HasanaCommand] {
        defaults(language: HasanaLanguage(rawValue: UserDefaults.standard.string(forKey: HasanaSettingsKeys.language) ?? "") ?? .arabic)
    }

    static func defaults(language: HasanaLanguage) -> [HasanaCommand] {
        switch language {
        case .arabic:
            [
                HasanaCommand(
                    id: .resetView,
                    title: "إعادة ضبط المنظور",
                    subtitle: "العودة إلى المركز وضبط القياس",
                    icon: "scope",
                    category: .canvas,
                    keywords: ["reset", "center", "view", "المركز", "ضبط", "رؤية"],
                    shortcutHint: "المركز"
                ),
                HasanaCommand(
                    id: .logWorship,
                    title: "تسجيل عبادة",
                    subtitle: "ازرع لحظة اليوم في الحديقة",
                    icon: "heart.fill",
                    category: .canvas,
                    keywords: ["log", "worship", "garden", "tend", "prayer", "quran", "dhikr", "تسجيل", "عبادة", "حديقة", "صلاة", "قرآن", "ذكر"],
                    shortcutHint: "تسجيل"
                ),
                HasanaCommand(
                    id: .openPayments,
                    title: "دعم التطبيق",
                    subtitle: "تبرع للمساعدة في تطوير حسنة",
                    icon: "creditcard.fill",
                    category: .giving,
                    keywords: ["payments", "payment", "pay", "support", "development", "donation", "مدفوعات", "دعم", "تطوير", "تبرع"],
                    shortcutHint: "دعم"
                ),
                HasanaCommand(
                    id: .openSettings,
                    title: "الإعدادات",
                    subtitle: "تغيير اللغة والسمة والوضع والأيقونة",
                    icon: "gearshape.fill",
                    category: .app,
                    keywords: ["settings", "preferences", "language", "theme", "dark", "light", "icon", "إعدادات", "لغة", "سمة", "أيقونة"],
                    shortcutHint: "إعدادات"
                )
            ]
        case .english:
            [
                HasanaCommand(
                    id: .resetView,
                    title: "Reset View",
                    subtitle: "Return to center and reset zoom",
                    icon: "scope",
                    category: .canvas,
                    keywords: ["reset", "center", "view", "المركز", "ضبط", "رؤية"],
                    shortcutHint: "Center"
                ),
                HasanaCommand(
                    id: .logWorship,
                    title: "Log Worship",
                    subtitle: "Tend today's garden",
                    icon: "heart.fill",
                    category: .canvas,
                    keywords: ["log", "worship", "garden", "tend", "prayer", "quran", "dhikr", "تسجيل", "عبادة", "حديقة", "صلاة", "قرآن", "ذكر"],
                    shortcutHint: "Log"
                ),
                HasanaCommand(
                    id: .openPayments,
                    title: "Support Hasana",
                    subtitle: "Donate to support app development",
                    icon: "creditcard.fill",
                    category: .giving,
                    keywords: ["payments", "payment", "pay", "support", "development", "donation", "مدفوعات", "دعم", "تطوير", "تبرع"],
                    shortcutHint: "Support"
                ),
                HasanaCommand(
                    id: .openSettings,
                    title: "Settings",
                    subtitle: "Change language, theme, mode, and app icon",
                    icon: "gearshape.fill",
                    category: .app,
                    keywords: ["settings", "preferences", "language", "theme", "dark", "light", "icon", "إعدادات", "لغة", "سمة", "أيقونة"],
                    shortcutHint: "Settings"
                )
            ]
        }
    }
}
