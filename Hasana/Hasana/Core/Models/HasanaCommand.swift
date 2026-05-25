import SwiftUI

enum HasanaCommandID: String, CaseIterable, Identifiable, Hashable, Codable {
    case resetView
    case clearCanvas

    var id: String { rawValue }
}

enum HasanaCommandCategory: String, Hashable {
    case canvas

    var title: String {
        switch self {
        case .canvas:
            "اللوحة"
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
        )
    ]
}
