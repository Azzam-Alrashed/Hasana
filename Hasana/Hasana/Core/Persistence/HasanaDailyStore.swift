import Foundation
import Observation

@Observable
@MainActor
final class HasanaDailyStore {
    private static let storageKey = "hasana.daily.records.v1"

    var record: HasanaDailyRecord

    private var records: [String: HasanaDailyRecord] = [:]
    private let calendar: Calendar
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(calendar: Calendar = .current, userDefaults: UserDefaults = .standard) {
        self.calendar = calendar
        self.userDefaults = userDefaults
        self.record = HasanaDailyRecord(date: .now, calendar: calendar)
        load()
        refreshForToday()
    }

    func refreshForToday() {
        let todayID = HasanaDailyRecord.identifier(for: .now, calendar: calendar)
        if let existing = records[todayID] {
            record = existing
        } else {
            record = HasanaDailyRecord(date: .now, calendar: calendar)
            records[todayID] = record
            save()
        }
    }

    func updateIntention(_ value: String) {
        record.intention = value
        persistCurrentRecord()
    }

    func addPriority(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        record.priorities.insert(HasanaPriority(title: trimmed), at: 0)
        persistCurrentRecord()
    }

    func togglePriority(_ priority: HasanaPriority) {
        guard let index = record.priorities.firstIndex(where: { $0.id == priority.id }) else { return }
        record.priorities[index].isDone.toggle()
        persistCurrentRecord()
    }

    func togglePrayer(_ name: HasanaPrayerName) {
        guard name.isPrayer else { return }

        if record.completedPrayers.contains(name) {
            record.completedPrayers.remove(name)
        } else {
            record.completedPrayers.insert(name)
        }

        persistCurrentRecord()
    }

    func incrementDhikr(by amount: Int = 1) {
        record.dhikrCount = max(0, record.dhikrCount + amount)
        persistCurrentRecord()
    }

    func resetDhikr() {
        record.dhikrCount = 0
        persistCurrentRecord()
    }

    func addGoodDeed(_ text: String) {
        addEntry(text, to: \.goodDeeds)
    }

    func addSadaqahNote(_ text: String) {
        addEntry(text, to: \.sadaqahNotes)
    }

    func updateReflection(_ value: String) {
        record.reflection = value
        persistCurrentRecord()
    }

    private func addEntry(_ text: String, to keyPath: WritableKeyPath<HasanaDailyRecord, [HasanaJournalEntry]>) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        record[keyPath: keyPath].insert(HasanaJournalEntry(text: trimmed), at: 0)
        persistCurrentRecord()
    }

    private func persistCurrentRecord() {
        records[record.id] = record
        save()
    }

    private func load() {
        guard
            let data = userDefaults.data(forKey: Self.storageKey),
            let decoded = try? decoder.decode([String: HasanaDailyRecord].self, from: data)
        else {
            return
        }

        records = decoded
    }

    private func save() {
        guard let data = try? encoder.encode(records) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }
}
