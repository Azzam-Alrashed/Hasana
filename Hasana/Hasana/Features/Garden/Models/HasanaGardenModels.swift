import CoreGraphics
import Foundation
import SwiftUI

enum HasanaGardenPracticeID: String, CaseIterable, Codable, Hashable, Identifiable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha
    case quran
    case adhkar
    case witr

    var id: String { rawValue }
}

enum HasanaGardenWorshipType: String, Codable, Hashable {
    case prayer
    case quran
    case dhikr
}

enum HasanaGardenReligiousStatus: String, Codable, Hashable {
    case obligatory
    case quran
    case dhikr
    case sunnah
    case sunnahWajib

    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.obligatory, .arabic):
            "فرض"
        case (.obligatory, .english):
            "Obligatory"
        case (.quran, .arabic):
            "قرآن"
        case (.quran, .english):
            "Quran"
        case (.dhikr, .arabic):
            "ذكر"
        case (.dhikr, .english):
            "Dhikr"
        case (.sunnah, .arabic):
            "سنة"
        case (.sunnah, .english):
            "Sunnah"
        case (.sunnahWajib, .arabic):
            "سنة / واجب"
        case (.sunnahWajib, .english):
            "Sunnah / Wajib"
        }
    }
}

enum HasanaGardenVisualRole: String, Codable, Hashable {
    case foundationalTree
    case plant
    case flower
}

enum HasanaGardenGrowthStage: String, Codable, CaseIterable, Hashable {
    case seed
    case sprout
    case young
    case mature
    case flowering

    init(totalTendedDays: Int) {
        switch totalTendedDays {
        case 0:
            self = .seed
        case 1...2:
            self = .sprout
        case 3...6:
            self = .young
        case 7...13:
            self = .mature
        default:
            self = .flowering
        }
    }

    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.seed, .arabic):
            "بذرة"
        case (.seed, .english):
            "Seed"
        case (.sprout, .arabic):
            "برعم"
        case (.sprout, .english):
            "Sprout"
        case (.young, .arabic):
            "نبتة صغيرة"
        case (.young, .english):
            "Young"
        case (.mature, .arabic):
            "ناضجة"
        case (.mature, .english):
            "Mature"
        case (.flowering, .arabic):
            "مزدهرة"
        case (.flowering, .english):
            "Flowering"
        }
    }
}

struct HasanaGardenPractice: Identifiable, Codable, Hashable {
    let id: HasanaGardenPracticeID
    let worshipType: HasanaGardenWorshipType
    let religiousStatus: HasanaGardenReligiousStatus
    let icon: String
    let visualRole: HasanaGardenVisualRole
    let defaultPosition: CGPoint

    func title(for language: HasanaLanguage) -> String {
        switch (id, language) {
        case (.fajr, .arabic):
            "الفجر"
        case (.fajr, .english):
            "Fajr"
        case (.dhuhr, .arabic):
            "الظهر"
        case (.dhuhr, .english):
            "Dhuhr"
        case (.asr, .arabic):
            "العصر"
        case (.asr, .english):
            "Asr"
        case (.maghrib, .arabic):
            "المغرب"
        case (.maghrib, .english):
            "Maghrib"
        case (.isha, .arabic):
            "العشاء"
        case (.isha, .english):
            "Isha"
        case (.quran, .arabic):
            "ورد القرآن"
        case (.quran, .english):
            "Quran"
        case (.adhkar, .arabic):
            "أذكار الصباح والمساء"
        case (.adhkar, .english):
            "Morning/evening adhkar"
        case (.witr, .arabic):
            "الوتر"
        case (.witr, .english):
            "Witr"
        }
    }

    func subtitle(for language: HasanaLanguage) -> String {
        switch (id, language) {
        case (.fajr, .arabic):
            "بداية اليوم بنور"
        case (.fajr, .english):
            "Begin the day with light"
        case (.dhuhr, .arabic):
            "وقفة هادئة في منتصف اليوم"
        case (.dhuhr, .english):
            "A calm pause at midday"
        case (.asr, .arabic):
            "رعاية الثبات بعد الظهر"
        case (.asr, .english):
            "Care for steadiness later in the day"
        case (.maghrib, .arabic):
            "عودة لطيفة مع غروب الشمس"
        case (.maghrib, .english):
            "A gentle return at sunset"
        case (.isha, .arabic):
            "خاتمة اليوم بسكينة"
        case (.isha, .english):
            "Close the day with stillness"
        case (.quran, .arabic):
            "آيات قليلة تكفي لتنمو"
        case (.quran, .english):
            "Even a few verses can grow"
        case (.adhkar, .arabic):
            "ذكر يحفظ إيقاع القلب"
        case (.adhkar, .english):
            "Remembrance for the heart's rhythm"
        case (.witr, .arabic):
            "ركعة تختم الليل بلطف"
        case (.witr, .english):
            "A gentle closing prayer for the night"
        }
    }
}

struct HasanaGardenProgress: Identifiable, Codable, Equatable {
    var practiceID: HasanaGardenPracticeID
    var tendedDayKeys: [String]

    var id: HasanaGardenPracticeID { practiceID }
    var totalTendedDays: Int { tendedDayKeys.count }
    var growthStage: HasanaGardenGrowthStage {
        HasanaGardenGrowthStage(totalTendedDays: totalTendedDays)
    }

    init(practiceID: HasanaGardenPracticeID, tendedDayKeys: [String] = []) {
        self.practiceID = practiceID
        self.tendedDayKeys = Array(Set(tendedDayKeys)).sorted()
    }

    func isTended(on dayKey: String) -> Bool {
        tendedDayKeys.contains(dayKey)
    }

    /// The most recent day key on which this practice was tended, or nil if never.
    var lastTendedDayKey: String? {
        tendedDayKeys.sorted().last
    }

    /// Number of days since the last tended day, relative to today.
    /// Returns nil if never tended.
    func daysSinceLastTended(todayKey: String) -> Int? {
        guard let last = lastTendedDayKey else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard
            let lastDate = formatter.date(from: last),
            let todayDate = formatter.date(from: todayKey)
        else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastDate, to: todayDate)
        return components.day
    }

    /// A practice is dormant when it was tended at some point in history but
    /// hasn't been tended for 2 or more days and is not tended today.
    func isDormant(todayKey: String) -> Bool {
        guard !tendedDayKeys.isEmpty else { return false } // never tended = seed, not dormant
        guard !isTended(on: todayKey) else { return false } // tended today = not dormant
        guard let days = daysSinceLastTended(todayKey: todayKey) else { return false }
        return days >= 2
    }
}

struct HasanaGardenPracticeState: Identifiable, Equatable {
    let practice: HasanaGardenPractice
    let progress: HasanaGardenProgress
    let isTendedToday: Bool
    let isDormant: Bool

    var id: HasanaGardenPracticeID { practice.id }
}

struct HasanaGardenDisplayState: Equatable {
    let practices: [HasanaGardenPracticeState]
    let tendedTodayCount: Int
    let totalTendedDays: Int
}

struct HasanaCalendarDay: Identifiable, Hashable {
    let id: String // "YYYY-MM-DD"
    let date: Date
    let dayNumber: String

    func weekdayName(for language: HasanaLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

/// Schema v2: removed viewport fields (canvas dead code).
/// Migration: v1 snapshots can be decoded by reading just `progress`.
struct HasanaGardenSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var progress: [HasanaGardenProgress]

    /// Failable migration from the raw stored Data.
    /// Handles both v1 (with viewportOffset/viewportScale) and v2.
    static func decode(from data: Data) -> HasanaGardenSnapshot? {
        let decoder = JSONDecoder()
        // Try current v2 schema first
        if let snapshot = try? decoder.decode(HasanaGardenSnapshot.self, from: data),
           snapshot.schemaVersion == currentSchemaVersion {
            return snapshot
        }
        // Fallback: try decoding v1 (has extra fields — we only need `progress`)
        if let legacy = try? decoder.decode(HasanaGardenSnapshotV1.self, from: data) {
            return HasanaGardenSnapshot(schemaVersion: currentSchemaVersion, progress: legacy.progress)
        }
        return nil
    }
}

/// Internal v1 schema for migration purposes only.
private struct HasanaGardenSnapshotV1: Codable {
    var schemaVersion: Int
    var progress: [HasanaGardenProgress]
    var viewportOffset: CGSize?
    var viewportScale: CGFloat?
}

extension HasanaGardenPractice {
    static let defaults: [HasanaGardenPractice] = [
        HasanaGardenPractice(
            id: .fajr,
            worshipType: .prayer,
            religiousStatus: .obligatory,
            icon: "sunrise.fill",
            visualRole: .foundationalTree,
            defaultPosition: CGPoint(x: -220, y: -120)
        ),
        HasanaGardenPractice(
            id: .dhuhr,
            worshipType: .prayer,
            religiousStatus: .obligatory,
            icon: "sun.max.fill",
            visualRole: .foundationalTree,
            defaultPosition: CGPoint(x: 0, y: -150)
        ),
        HasanaGardenPractice(
            id: .asr,
            worshipType: .prayer,
            religiousStatus: .obligatory,
            icon: "sun.haze.fill",
            visualRole: .foundationalTree,
            defaultPosition: CGPoint(x: 220, y: -120)
        ),
        HasanaGardenPractice(
            id: .maghrib,
            worshipType: .prayer,
            religiousStatus: .obligatory,
            icon: "sunset.fill",
            visualRole: .foundationalTree,
            defaultPosition: CGPoint(x: -120, y: 90)
        ),
        HasanaGardenPractice(
            id: .isha,
            worshipType: .prayer,
            religiousStatus: .obligatory,
            icon: "moon.stars.fill",
            visualRole: .foundationalTree,
            defaultPosition: CGPoint(x: 120, y: 90)
        ),
        HasanaGardenPractice(
            id: .quran,
            worshipType: .quran,
            religiousStatus: .quran,
            icon: "book.closed.fill",
            visualRole: .plant,
            defaultPosition: CGPoint(x: -300, y: 160)
        ),
        HasanaGardenPractice(
            id: .adhkar,
            worshipType: .dhikr,
            religiousStatus: .dhikr,
            icon: "sparkles",
            visualRole: .flower,
            defaultPosition: CGPoint(x: 0, y: 230)
        ),
        HasanaGardenPractice(
            id: .witr,
            worshipType: .prayer,
            religiousStatus: .sunnahWajib,
            icon: "moon.zzz.fill",
            visualRole: .flower,
            defaultPosition: CGPoint(x: 300, y: 160)
        )
    ]
}
