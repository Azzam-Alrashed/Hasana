import SwiftUI

enum HasanaCommandID: String, CaseIterable, Identifiable, Hashable, Codable {
    case resetView
    case logWorship
    case openPayments
    case openSettings
    case openTasbih
    case openQuranTracker
    case openSunnahTracker
    case openAnalytics
    case openPrayerDashboard
    case openIslamicHub

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
                    id: .openPrayerDashboard,
                    title: "مواقيت الصلاة",
                    subtitle: "عرض أوقات الصلوات والعد التنازلي والاتجاه",
                    icon: "clock.fill",
                    category: .canvas,
                    keywords: ["prayer", "times", "calculation", "athan", "أوقات", "صلاة", "أذان", "مواقيت"],
                    shortcutHint: "مواقيت"
                ),
                HasanaCommand(
                    id: .openTasbih,
                    title: "المسبحة الإلكترونية",
                    subtitle: "تكرار التسبيح والأذكار اليومية",
                    icon: "sparkles",
                    category: .canvas,
                    keywords: ["tasbih", "dhikr", "counter", "تسبيح", "ذكر", "مسبحة"],
                    shortcutHint: "مسبحة"
                ),
                HasanaCommand(
                    id: .openQuranTracker,
                    title: "ورد القرآن الكريم",
                    subtitle: "متابعة الختمة وكتابة تدبر الآيات",
                    icon: "book.closed.fill",
                    category: .canvas,
                    keywords: ["quran", "khatm", "reflection", "tadabbur", "قرآن", "ختمة", "تدبر"],
                    shortcutHint: "قرآن"
                ),
                HasanaCommand(
                    id: .openSunnahTracker,
                    title: "السنن والصدقات",
                    subtitle: "تسجيل السنن الرواتب والصدقات اليومية",
                    icon: "heart.text.square.fill",
                    category: .canvas,
                    keywords: ["sunnah", "sadaqah", "charity", "سنة", "صدقة", "عمل صالح"],
                    shortcutHint: "سنن"
                ),
                HasanaCommand(
                    id: .openAnalytics,
                    title: "التحليلات الروحية",
                    subtitle: "متابعة إحصائيات ونشاطات العبادة والالتزام",
                    icon: "chart.bar.xaxis",
                    category: .canvas,
                    keywords: ["stats", "analytics", "progress", "إحصائيات", "تحليلات", "تقدم"],
                    shortcutHint: "تحليلات"
                ),
                HasanaCommand(
                    id: .openPayments,
                    title: "دعم التطبيق",
                    subtitle: "معاينة دعم التطوير، والدفع غير مفعل",
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
                ),
                HasanaCommand(
                    id: .openIslamicHub,
                    title: "المركز الإسلامي",
                    subtitle: "القبلة، حصن المسلم، التقويم الهجري، والعادات الروحية",
                    icon: "mosque.fill",
                    category: .canvas,
                    keywords: ["islamic", "hub", "qibla", "dua", "calendar", "hijri", "habit", "المركز", "الإسلامي", "القبلة", "البوصلة", "الأذكار", "التقويم", "الهجري", "العادات"],
                    shortcutHint: "المركز"
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
                    id: .openPrayerDashboard,
                    title: "Prayer Times",
                    subtitle: "View calculation times and alarms",
                    icon: "clock.fill",
                    category: .canvas,
                    keywords: ["prayer", "times", "calculation", "athan"],
                    shortcutHint: "Prayers"
                ),
                HasanaCommand(
                    id: .openTasbih,
                    title: "Tasbih Counter",
                    subtitle: "Count dhikr and praise Allah",
                    icon: "sparkles",
                    category: .canvas,
                    keywords: ["tasbih", "dhikr", "counter"],
                    shortcutHint: "Tasbih"
                ),
                HasanaCommand(
                    id: .openQuranTracker,
                    title: "Quran Tracker",
                    subtitle: "Manage Khatm goal & log reflections",
                    icon: "book.closed.fill",
                    category: .canvas,
                    keywords: ["quran", "khatm", "reflection", "tadabbur"],
                    shortcutHint: "Quran"
                ),
                HasanaCommand(
                    id: .openSunnahTracker,
                    title: "Sunnah & Sadaqah",
                    subtitle: "Log rawatib and daily charities",
                    icon: "heart.text.square.fill",
                    category: .canvas,
                    keywords: ["sunnah", "sadaqah", "charity"],
                    shortcutHint: "Sunnah"
                ),
                HasanaCommand(
                    id: .openAnalytics,
                    title: "Spiritual Analytics",
                    subtitle: "Track trends and charts of your worship",
                    icon: "chart.bar.xaxis",
                    category: .canvas,
                    keywords: ["stats", "analytics", "progress"],
                    shortcutHint: "Stats"
                ),
                HasanaCommand(
                    id: .openPayments,
                    title: "Support Hasana",
                    subtitle: "Preview development support; payments are off",
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
                ),
                HasanaCommand(
                    id: .openIslamicHub,
                    title: "Islamic Hub",
                    subtitle: "Qibla, Hisn al-Muslim, Hijri calendar, and habits",
                    icon: "mosque.fill",
                    category: .canvas,
                    keywords: ["islamic", "hub", "qibla", "compass", "dua", "calendar", "hijri", "habit"],
                    shortcutHint: "Hub"
                )
            ]
        }
    }
}
