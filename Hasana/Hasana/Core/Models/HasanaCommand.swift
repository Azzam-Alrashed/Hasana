import SwiftUI

enum HasanaCommandID: String, CaseIterable, Identifiable, Hashable, Codable {
    case openToday
    case logGoodDeed
    case setIntention
    case addPriority
    case openPrayerTimes
    case startDhikr
    case reflect
    case addSadaqah

    var id: String { rawValue }
}

enum HasanaCommandCategory: String, Hashable {
    case today
    case worship
    case reflection
    case finance

    var title: String {
        switch self {
        case .today:
            "اليوم"
        case .worship:
            "العبادة"
        case .reflection:
            "المراجعة"
        case .finance:
            "العطاء"
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

    static let defaults: [HasanaCommand] = [
        HasanaCommand(
            id: .openToday,
            title: "فتح اليوم",
            subtitle: "العودة إلى مساحة يومك الهادئة",
            icon: "sun.max",
            category: .today,
            keywords: ["home", "dashboard", "daily", "start", "اليوم", "الرئيسية"],
            shortcutHint: "اليوم"
        ),
        HasanaCommand(
            id: .logGoodDeed,
            title: "تسجيل حسنة",
            subtitle: "احفظ الخير قبل أن يمرّ",
            icon: "heart.fill",
            category: .today,
            keywords: ["deed", "good", "hasana", "kindness", "record", "حسنة", "خير", "معروف"],
            shortcutHint: "حسنة"
        ),
        HasanaCommand(
            id: .setIntention,
            title: "تحديد النية",
            subtitle: "ابدأ العمل بنية واضحة",
            icon: "sparkles",
            category: .reflection,
            keywords: ["intention", "niyyah", "purpose", "focus", "نية", "نيّة", "قصد"],
            shortcutHint: "نية"
        ),
        HasanaCommand(
            id: .addPriority,
            title: "إضافة أولوية",
            subtitle: "اختر ما يستحق تركيزك اليوم",
            icon: "checkmark.circle",
            category: .today,
            keywords: ["task", "todo", "focus", "priority", "plan", "مهمة", "أولوية", "عمل"],
            shortcutHint: "أولوية"
        ),
        HasanaCommand(
            id: .openPrayerTimes,
            title: "أوقات الصلاة",
            subtitle: "حدّث الموقع واعرض صلاة اليوم",
            icon: "clock",
            category: .worship,
            keywords: ["prayer", "pray", "salah", "salat", "adhan", "time", "صلاة", "أذان", "مواقيت"],
            shortcutHint: "صلاة"
        ),
        HasanaCommand(
            id: .startDhikr,
            title: "ذكر سريع",
            subtitle: "زد عدّاد الذكر بلحظة قصيرة",
            icon: "circle.grid.cross",
            category: .worship,
            keywords: ["dhikr", "zikr", "remembrance", "tasbih", "worship", "ذكر", "تسبيح"],
            shortcutHint: "ذكر"
        ),
        HasanaCommand(
            id: .reflect,
            title: "مراجعة المساء",
            subtitle: "راجع اليوم بلطف وصدق",
            icon: "moon.stars",
            category: .reflection,
            keywords: ["reflect", "reflection", "journal", "review", "evening", "مراجعة", "تأمل", "مساء"],
            shortcutHint: "مراجعة"
        ),
        HasanaCommand(
            id: .addSadaqah,
            title: "تسجيل صدقة",
            subtitle: "احفظ العطاء أو نية العطاء",
            icon: "creditcard",
            category: .finance,
            keywords: ["sadaqah", "zakat", "charity", "giving", "donation", "صدقة", "زكاة", "عطاء"],
            shortcutHint: "عطاء"
        )
    ]
}
