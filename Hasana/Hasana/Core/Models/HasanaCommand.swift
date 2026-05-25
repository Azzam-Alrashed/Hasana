import SwiftUI

enum HasanaCommandID: String, CaseIterable, Identifiable, Hashable, Codable {
    case resetView
    case clearCanvas
    case openSettings

    var id: String { rawValue }
}

enum HasanaCommandCategory: String, Hashable {
    case canvas
    case app

    var title: String {
        title(for: HasanaLanguage(rawValue: UserDefaults.standard.string(forKey: HasanaSettingsKeys.language) ?? "") ?? .arabic)
    }

    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.canvas, .arabic):
            "اللوحة"
        case (.canvas, .english):
            "Canvas"
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
                    id: .clearCanvas,
                    title: "مسح اللوحة",
                    subtitle: "حذف جميع البطاقات المضافة",
                    icon: "trash",
                    category: .canvas,
                    keywords: ["clear", "delete", "remove", "clean", "مسح", "حذف", "تنظيف"],
                    shortcutHint: "مسح"
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
                    id: .clearCanvas,
                    title: "Clear Canvas",
                    subtitle: "Delete all added cards",
                    icon: "trash",
                    category: .canvas,
                    keywords: ["clear", "delete", "remove", "clean", "مسح", "حذف", "تنظيف"],
                    shortcutHint: "Clear"
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
