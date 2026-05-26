import Foundation
import Observation

@Observable
@MainActor
final class HasanaGardenStore {
    static let storageKey = "hasana.garden.snapshot.v1"

    let practices: [HasanaGardenPractice] = HasanaGardenPractice.defaults

    var progress: [HasanaGardenPracticeID: HasanaGardenProgress] = [:]
    var selectedPracticeID: HasanaGardenPracticeID?
    var selectedDayKey: String

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let dayKeyProvider: () -> String

    init(
        userDefaults: UserDefaults = .shared,
        dayKeyProvider: @escaping () -> String = HasanaGardenStore.currentLocalDayKey
    ) {
        self.userDefaults = userDefaults
        self.dayKeyProvider = dayKeyProvider
        self.selectedDayKey = dayKeyProvider()
        load()
    }

    var todayKey: String {
        dayKeyProvider()
    }

    var displayState: HasanaGardenDisplayState {
        displayState(for: selectedDayKey)
    }

    func displayState(for dayKey: String) -> HasanaGardenDisplayState {
        var tendedTodayCount = 0
        var totalTendedDays = 0

        let states = practices.map { practice in
            let record = progress(for: practice.id)
            let isTendedToday = record.isTended(on: dayKey)
            let dormant = record.isDormant(todayKey: dayKey)

            if isTendedToday {
                tendedTodayCount += 1
            }
            totalTendedDays += record.totalTendedDays

            return HasanaGardenPracticeState(
                practice: practice,
                progress: record,
                isTendedToday: isTendedToday,
                isDormant: dormant
            )
        }

        return HasanaGardenDisplayState(
            practices: states,
            tendedTodayCount: tendedTodayCount,
            totalTendedDays: totalTendedDays
        )
    }

    func progress(for practiceID: HasanaGardenPracticeID) -> HasanaGardenProgress {
        progress[practiceID] ?? HasanaGardenProgress(practiceID: practiceID)
    }

    func isTendedToday(_ practiceID: HasanaGardenPracticeID) -> Bool {
        progress(for: practiceID).isTended(on: todayKey)
    }

    func toggleToday(for practiceID: HasanaGardenPracticeID) {
        var record = progress(for: practiceID)
        let dayKey = selectedDayKey

        if record.tendedDayKeys.contains(dayKey) {
            record.tendedDayKeys.removeAll { $0 == dayKey }
        } else {
            record.tendedDayKeys.append(dayKey)
        }

        record.tendedDayKeys = Array(Set(record.tendedDayKeys)).sorted()
        progress[practiceID] = record
        save()
    }

    func getLast7Days() -> [HasanaCalendarDay] {
        let calendar = Calendar.current
        let today = Date()
        var days: [HasanaCalendarDay] = []

        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                let year = components.year ?? 0
                let month = components.month ?? 0
                let day = components.day ?? 0
                let dayKey = String(format: "%04d-%02d-%02d", year, month, day)

                let formatter = DateFormatter()
                formatter.dateFormat = "d"
                let dayNumber = formatter.string(from: date)

                days.append(HasanaCalendarDay(id: dayKey, date: date, dayNumber: dayNumber))
            }
        }
        return days
    }

    func selectPractice(_ practiceID: HasanaGardenPracticeID?) {
        selectedPracticeID = practiceID
    }

    // MARK: - Persistence

    private func load() {
        guard let data = userDefaults.data(forKey: Self.storageKey) else {
            progress = defaultProgress()
            return
        }

        guard let snapshot = HasanaGardenSnapshot.decode(from: data) else {
            // Corrupt data — fall back to defaults rather than crashing.
            progress = defaultProgress()
            return
        }

        progress = mergeProgress(snapshot.progress)
    }

    private func save() {
        let snapshot = HasanaGardenSnapshot(
            schemaVersion: HasanaGardenSnapshot.currentSchemaVersion,
            progress: practices.map { progress(for: $0.id) }
        )

        guard let data = try? encoder.encode(snapshot) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }

    private func defaultProgress() -> [HasanaGardenPracticeID: HasanaGardenProgress] {
        Dictionary(
            uniqueKeysWithValues: practices.map {
                ($0.id, HasanaGardenProgress(practiceID: $0.id))
            }
        )
    }

    private func mergeProgress(_ persistedProgress: [HasanaGardenProgress]) -> [HasanaGardenPracticeID: HasanaGardenProgress] {
        var merged = defaultProgress()
        let validIDs = Set(practices.map(\.id))

        for record in persistedProgress where validIDs.contains(record.practiceID) {
            merged[record.practiceID] = HasanaGardenProgress(
                practiceID: record.practiceID,
                tendedDayKeys: record.tendedDayKeys
            )
        }

        return merged
    }

    nonisolated static func currentLocalDayKey() -> String {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent

        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
