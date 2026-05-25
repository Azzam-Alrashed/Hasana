import SwiftUI

enum HasanaCommandID: String, CaseIterable, Identifiable, Hashable {
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
}

struct HasanaCommand: Identifiable, Hashable {
    let id: HasanaCommandID
    let title: String
    let subtitle: String
    let icon: String
    let category: HasanaCommandCategory

    static let defaults: [HasanaCommand] = [
        HasanaCommand(
            id: .openToday,
            title: "Open Today",
            subtitle: "Return to your daily command center",
            icon: "sun.max",
            category: .today
        ),
        HasanaCommand(
            id: .logGoodDeed,
            title: "Log Good Deed",
            subtitle: "Capture a hasana before the moment passes",
            icon: "heart.fill",
            category: .today
        ),
        HasanaCommand(
            id: .setIntention,
            title: "Set Intention",
            subtitle: "Start with niyyah before the work begins",
            icon: "sparkles",
            category: .reflection
        ),
        HasanaCommand(
            id: .addPriority,
            title: "Add Priority",
            subtitle: "Choose what deserves focus today",
            icon: "checkmark.circle",
            category: .today
        ),
        HasanaCommand(
            id: .openPrayerTimes,
            title: "Prayer Times",
            subtitle: "See today's salah windows",
            icon: "clock",
            category: .worship
        ),
        HasanaCommand(
            id: .startDhikr,
            title: "Start Dhikr",
            subtitle: "Take a short remembrance break",
            icon: "circle.grid.cross",
            category: .worship
        ),
        HasanaCommand(
            id: .reflect,
            title: "Evening Reflection",
            subtitle: "Review the day with gentleness",
            icon: "moon.stars",
            category: .reflection
        ),
        HasanaCommand(
            id: .addSadaqah,
            title: "Track Sadaqah",
            subtitle: "Record giving and zakat-related notes",
            icon: "creditcard",
            category: .finance
        )
    ]
}
