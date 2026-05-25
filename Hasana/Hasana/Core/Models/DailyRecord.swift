import Foundation

struct HasanaDailyRecord: Codable, Equatable, Identifiable {
    var id: String
    var date: Date
    var intention: String
    var priorities: [HasanaPriority]
    var completedPrayers: Set<HasanaPrayerName>
    var dhikrCount: Int
    var goodDeeds: [HasanaJournalEntry]
    var sadaqahNotes: [HasanaJournalEntry]
    var reflection: String

    init(date: Date = .now, calendar: Calendar = .current) {
        self.id = Self.identifier(for: date, calendar: calendar)
        self.date = date
        self.intention = ""
        self.priorities = []
        self.completedPrayers = []
        self.dhikrCount = 0
        self.goodDeeds = []
        self.sadaqahNotes = []
        self.reflection = ""
    }

    static func identifier(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

struct HasanaPriority: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, isDone: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
    }
}

struct HasanaJournalEntry: Codable, Equatable, Identifiable {
    var id: UUID
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}
