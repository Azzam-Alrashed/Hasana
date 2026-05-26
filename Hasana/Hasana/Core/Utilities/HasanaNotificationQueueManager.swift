//
//  HasanaNotificationQueueManager.swift
//  Hasana
//
//  Created by Azzam Alrashed on 26/05/2026.
//

import Foundation
import UserNotifications
import CoreLocation
import Combine
import UIKit

// MARK: - Notification Priority
enum HasanaNotificationPriority: Int, Codable, Comparable, CaseIterable {
    case critical = 0  // Athan alerts (must fire immediately, high priority sound)
    case high = 1      // Actionable habit reminders, user-defined schedules
    case medium = 2    // General daily reminders (Adhkar, Morning/Evening)
    case low = 3       // Educational tips, reflections, updates
    
    static func < (lhs: HasanaNotificationPriority, rhs: HasanaNotificationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Notification Type
enum HasanaNotificationType: String, Codable {
    case athan
    case preAthan
    case dailyReminder
    case habitStreak
    case customMessage
    case systemAlert
    case geofenceEnter
    case geofenceExit
}

// MARK: - Recurrence Rule
enum HasanaRecurrenceRule: Codable, Equatable {
    case none
    case daily(hour: Int, minute: Int)
    case weekly(daysOfWeek: [Int], hour: Int, minute: Int) // 1 = Sunday, 2 = Monday, etc.
    case customInterval(seconds: TimeInterval)
    
    private enum CodingKeys: String, CodingKey {
        case type, hour, minute, daysOfWeek, seconds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "none":
            self = .none
        case "daily":
            let hour = try container.decode(Int.self, forKey: .hour)
            let minute = try container.decode(Int.self, forKey: .minute)
            self = .daily(hour: hour, minute: minute)
        case "weekly":
            let days = try container.decode([Int].self, forKey: .daysOfWeek)
            let hour = try container.decode(Int.self, forKey: .hour)
            let minute = try container.decode(Int.self, forKey: .minute)
            self = .weekly(daysOfWeek: days, hour: hour, minute: minute)
        case "customInterval":
            let seconds = try container.decode(TimeInterval.self, forKey: .seconds)
            self = .customInterval(seconds: seconds)
        default:
            self = .none
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode("none", forKey: .type)
        case .daily(let hour, let minute):
            try container.encode("daily", forKey: .type)
            try container.encode(hour, forKey: .hour)
            try container.encode(minute, forKey: .minute)
        case .weekly(let daysOfWeek, let hour, let minute):
            try container.encode("weekly", forKey: .type)
            try container.encode(daysOfWeek, forKey: .daysOfWeek)
            try container.encode(hour, forKey: .hour)
            try container.encode(minute, forKey: .minute)
        case .customInterval(let seconds):
            try container.encode("customInterval", forKey: .type)
            try container.encode(seconds, forKey: .seconds)
        }
    }
}

// MARK: - Queued Notification Struct
struct QueuedNotification: Codable, Identifiable, Equatable {
    let id: UUID
    let identifier: String // Stable key for updates/cancellations (e.g. "hasana.athan.fajr.2026-05-26")
    var title: String
    var body: String
    var triggerDate: Date
    var category: String // UNNotificationCategory identifier
    var sound: String? // Filename in project bundle or default
    var userInfo: [String: String]
    var priority: HasanaNotificationPriority
    var type: HasanaNotificationType
    var recurrence: HasanaRecurrenceRule
    var isScheduledBySystem: Bool
    
    init(
        id: UUID = UUID(),
        identifier: String,
        title: String,
        body: String,
        triggerDate: Date,
        category: String,
        sound: String? = nil,
        userInfo: [String: String] = [:],
        priority: HasanaNotificationPriority = .medium,
        type: HasanaNotificationType = .customMessage,
        recurrence: HasanaRecurrenceRule = .none,
        isScheduledBySystem: Bool = false
    ) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.body = body
        self.triggerDate = triggerDate
        self.category = category
        self.sound = sound
        self.userInfo = userInfo
        self.priority = priority
        self.type = type
        self.recurrence = recurrence
        self.isScheduledBySystem = isScheduledBySystem
    }
}

// MARK: - Custom Athan Sounds Settings
struct AthanSoundSetting: Codable, Equatable {
    var fajr: String
    var dhuhr: String
    var asr: String
    var maghrib: String
    var isha: String
    
    static let `default` = AthanSoundSetting(
        fajr: "athan_fajr.caf",
        dhuhr: "athan_standard.caf",
        asr: "athan_standard.caf",
        maghrib: "athan_standard.caf",
        isha: "athan_standard.caf"
    )
}

// MARK: - Masjid Geofence Model
struct MasjidGeofence: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double // meters
    
    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double, radius: Double = 100.0) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}

// MARK: - Debug Notification Event Log
struct NotificationHistoryLog: Codable, Identifiable {
    let id: UUID
    let identifier: String
    let title: String
    let body: String
    let actionTaken: String // "delivered", "dismissed", "snoozed", "logged_done", "tapped"
    let timestamp: Date
}

// MARK: - Core Alerts Engine & Scheduler
final class HasanaNotificationQueueManager: NSObject {
    
    // MARK: - Singleton & Config
    static let shared = HasanaNotificationQueueManager()
    
    private let queue = DispatchQueue(label: "sa.Alrashed.Azzam.Hasana.NotificationQueue", qos: .userInitiated)
    
    // Safety buffer. iOS limits pending notifications to 64.
    // Keeping a small margin for immediate calendar alerts.
    let maxActiveSlots = 60
    
    // MARK: - State Cache
    private var pendingNotifications: [QueuedNotification] = []
    private var recurringTemplates: [QueuedNotification] = []
    private var activeGeofences: [MasjidGeofence] = []
    private var notificationHistory: [NotificationHistoryLog] = []
    
    // MARK: - Actions & Routing
    let actionSubject = PassthroughSubject<(action: String, userInfo: [String: String]), Never>()
    
    // Callback handlers to bind view model or analytics updates without hard coupling
    var onHabitLoggedAction: ((String, Date) -> Void)?
    var onPrayerLoggedAction: ((String, Date) -> Void)?
    var onDuaNavigateAction: ((UUID) -> Void)?
    
    // MARK: - Local Paths
    private var storageDirectoryURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let root = paths[0].appendingPathComponent("HasanaNotifications", isDirectory: true)
        if !FileManager.default.fileExists(atPath: root.path) {
            try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
        }
        return root
    }
    
    private var queueFileURL: URL {
        return storageDirectoryURL.appendingPathComponent("pending_queue.json")
    }
    
    private var templateFileURL: URL {
        return storageDirectoryURL.appendingPathComponent("recurring_templates.json")
    }
    
    private var geofenceFileURL: URL {
        return storageDirectoryURL.appendingPathComponent("masjid_geofences.json")
    }
    
    private var historyFileURL: URL {
        return storageDirectoryURL.appendingPathComponent("notification_history.json")
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        loadLocalState()
        setupNotificationCategories()
    }
    
    /// Binds the manager to become the delegate of the shared UNUserNotificationCenter
    func registerDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Category & Action Config
    private func setupNotificationCategories() {
        // 1. Athan categories (Actions: Snooze 10m, Log Prayer Done)
        let athanSnoozeAction = UNNotificationAction(
            identifier: "hasana.action.athan.snooze",
            title: "Snooze 10 Min (غفوة ١٠ دقائق)",
            options: []
        )
        let athanLoggedAction = UNNotificationAction(
            identifier: "hasana.action.athan.logged",
            title: "Prayed (تمت الصلاة)",
            options: [.foreground]
        )
        let athanCategory = UNNotificationCategory(
            identifier: "hasana.category.athan",
            actions: [athanLoggedAction, athanSnoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 2. Habit categories (Actions: Log Habit Done, Remind in 1h)
        let habitDoneAction = UNNotificationAction(
            identifier: "hasana.action.habit.done",
            title: "Done! (أنجزت)",
            options: [.foreground]
        )
        let habitSnoozeAction = UNNotificationAction(
            identifier: "hasana.action.habit.snooze",
            title: "Remind me in 1 Hour (ذكرني بعد ساعة)",
            options: []
        )
        let habitCategory = UNNotificationCategory(
            identifier: "hasana.category.habit",
            actions: [habitDoneAction, habitSnoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 3. Daily Dua reminders (Actions: Read Now, Share)
        let duaReadAction = UNNotificationAction(
            identifier: "hasana.action.dua.read",
            title: "Read Now (اقرأ الآن)",
            options: [.foreground]
        )
        let duaCategory = UNNotificationCategory(
            identifier: "hasana.category.dua",
            actions: [duaReadAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            athanCategory,
            habitCategory,
            duaCategory
        ])
    }
    
    // MARK: - Queue State Persistence
    private func loadLocalState() {
        queue.sync {
            let decoder = JSONDecoder()
            if let queueData = try? Data(contentsOf: queueFileURL),
               let decodedQueue = try? decoder.decode([QueuedNotification].self, from: queueData) {
                self.pendingNotifications = decodedQueue
            }
            
            if let templateData = try? Data(contentsOf: templateFileURL),
               let decodedTemplates = try? decoder.decode([QueuedNotification].self, from: templateData) {
                self.recurringTemplates = decodedTemplates
            }
            
            if let geofenceData = try? Data(contentsOf: geofenceFileURL),
               let decodedGeofences = try? decoder.decode([MasjidGeofence].self, from: geofenceData) {
                self.activeGeofences = decodedGeofences
            }
            
            if let historyData = try? Data(contentsOf: historyFileURL),
               let decodedHistory = try? decoder.decode([NotificationHistoryLog].self, from: historyData) {
                self.notificationHistory = decodedHistory
            }
        }
    }
    
    private func saveLocalState() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let encoder = JSONEncoder()
            if let queueData = try? encoder.encode(self.pendingNotifications) {
                try? queueData.write(to: self.queueFileURL, options: .atomic)
            }
            if let templateData = try? encoder.encode(self.recurringTemplates) {
                try? templateData.write(to: self.templateFileURL, options: .atomic)
            }
            if let geofenceData = try? encoder.encode(self.activeGeofences) {
                try? geofenceData.write(to: self.geofenceFileURL, options: .atomic)
            }
            if let historyData = try? encoder.encode(self.notificationHistory) {
                try? historyData.write(to: self.historyFileURL, options: .atomic)
            }
        }
    }
    
    // MARK: - Debug Logger ring-buffer
    private func recordHistory(identifier: String, title: String, body: String, action: String) {
        queue.sync {
            let log = NotificationHistoryLog(
                id: UUID(),
                identifier: identifier,
                title: title,
                body: body,
                actionTaken: action,
                timestamp: Date()
            )
            self.notificationHistory.insert(log, at: 0)
            
            // Cap history at 100 entries
            if self.notificationHistory.count > 100 {
                self.notificationHistory = Array(self.notificationHistory.prefix(100))
            }
        }
        saveLocalState()
    }
    
    func getHistory() -> [NotificationHistoryLog] {
        queue.sync { notificationHistory }
    }
    
    func clearHistory() {
        queue.sync { notificationHistory.removeAll() }
        saveLocalState()
    }
    
    // MARK: - Basic Operations (Thread-safe Wrapper)
    
    func addOneOffNotification(_ notification: QueuedNotification) {
        queue.sync {
            // Remove matching identifier first to avoid duplicates
            self.pendingNotifications.removeAll { $0.identifier == notification.identifier }
            self.pendingNotifications.append(notification)
        }
        saveLocalState()
    }
    
    func addRecurringTemplate(_ template: QueuedNotification) {
        queue.sync {
            self.recurringTemplates.removeAll { $0.identifier == template.identifier }
            self.recurringTemplates.append(template)
        }
        saveLocalState()
    }
    
    func cancelNotification(identifier: String) {
        queue.sync {
            self.pendingNotifications.removeAll { $0.identifier == identifier }
            self.recurringTemplates.removeAll { $0.identifier == identifier }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        saveLocalState()
    }
    
    func cancelNotifications(matching type: HasanaNotificationType) {
        queue.sync {
            self.pendingNotifications.removeAll { $0.type == type }
            self.recurringTemplates.removeAll { $0.type == type }
        }
        saveLocalState()
    }
    
    func clearAllQueues() {
        queue.sync {
            self.pendingNotifications.removeAll()
            self.recurringTemplates.removeAll()
        }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        saveLocalState()
    }
    
    func getPendingQueue() -> [QueuedNotification] {
        queue.sync { pendingNotifications }
    }
    
    func getRecurringTemplates() -> [QueuedNotification] {
        queue.sync { recurringTemplates }
    }
    
    // MARK: - Custom Athan Sound Accessors
    private func fetchAthanSoundSetting() -> AthanSoundSetting {
        if let data = UserDefaults.shared.data(forKey: "hasana.settings.athan_sounds"),
           let decoded = try? JSONDecoder().decode(AthanSoundSetting.self, from: data) {
            return decoded
        }
        return .default
    }
    
    func setCustomAthanSounds(setting: AthanSoundSetting) {
        if let data = try? JSONEncoder().encode(setting) {
            UserDefaults.shared.set(data, forKey: "hasana.settings.athan_sounds")
        }
    }
    
    // MARK: - Athan Alert Scheduler Engine
    
    /// Populates prayer alerts in the pending notifications list for a given range of days.
    func scheduleAthanAlerts(
        latitude: Double,
        longitude: Double,
        method: CalculationMethod,
        useHanafiAsr: Bool,
        days: Int = 7,
        language: HasanaLanguage,
        enablePreAthan: Bool = false
    ) {
        let calendar = Calendar.current
        let today = Date()
        let offset = Double(TimeZone.current.secondsFromGMT(for: today)) / 3600.0
        
        var newlyGenerated: [QueuedNotification] = []
        let sounds = fetchAthanSoundSetting()
        
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let dayString = formatDateKey(targetDate)
            
            // Calculate using existing PrayerTimesEngine
            let calculated = PrayerTimesEngine.calculateTimes(
                for: targetDate,
                latitude: latitude,
                longitude: longitude,
                timeZoneOffset: offset,
                method: method,
                useHanafiAsr: useHanafiAsr
            )
            
            let prayers = [
                ("fajr", calculated.fajr, language == .arabic ? "حان الآن موعد صلاة الفجر" : "It's time for Fajr prayer", sounds.fajr),
                ("dhuhr", calculated.dhuhr, language == .arabic ? "حان الآن موعد صلاة الظهر" : "It's time for Dhuhr prayer", sounds.dhuhr),
                ("asr", calculated.asr, language == .arabic ? "حان الآن موعد صلاة العصر" : "It's time for Asr prayer", sounds.asr),
                ("maghrib", calculated.maghrib, language == .arabic ? "حان الآن موعد صلاة المغرب" : "It's time for Maghrib prayer", sounds.maghrib),
                ("isha", calculated.isha, language == .arabic ? "حان الآن موعد صلاة العشاء" : "It's time for Isha prayer", sounds.isha)
            ]
            
            for (prayerKey, prayerTime, localizedMsg, soundFile) in prayers {
                // Skip times in the past
                guard prayerTime > today else { continue }
                
                let identifier = "hasana.athan.\(prayerKey).\(dayString)"
                
                // Primary Athan Notification
                let athanNotif = QueuedNotification(
                    identifier: identifier,
                    title: language == .arabic ? "حسنة - الأذان" : "Hasana - Athan",
                    body: localizedMsg,
                    triggerDate: prayerTime,
                    category: "hasana.category.athan",
                    sound: soundFile,
                    userInfo: ["prayerName": prayerKey, "prayerDate": dayString],
                    priority: .critical,
                    type: .athan
                )
                newlyGenerated.append(athanNotif)
                
                // Pre-Athan Alert (Optional, e.g. 10 minutes before)
                if enablePreAthan {
                    let preTime = prayerTime.addingTimeInterval(-600) // 10m early
                    if preTime > today {
                        let preIdentifier = "hasana.athan.pre.\(prayerKey).\(dayString)"
                        let preMsgAr = "بقي ١٠ دقائق لصلاة \(calculated.arabicName(for: prayerKey.capitalized))"
                        let preMsgEn = "10 minutes left until \(prayerKey.capitalized) prayer"
                        
                        let preNotif = QueuedNotification(
                            identifier: preIdentifier,
                            title: language == .arabic ? "اقترب موعد الصلاة" : "Prayer Time Approaching",
                            body: language == .arabic ? preMsgAr : preMsgEn,
                            triggerDate: preTime,
                            category: "hasana.category.dua",
                            sound: "pre_athan.caf",
                            userInfo: ["prayerName": prayerKey, "prayerDate": dayString, "isPreAlert": "true"],
                            priority: .medium,
                            type: .preAthan
                        )
                        newlyGenerated.append(preNotif)
                    }
                }
            }
        }
        
        queue.sync {
            // Remove old athans first
            self.pendingNotifications.removeAll { $0.type == .athan || $0.type == .preAthan }
            self.pendingNotifications.append(contentsOf: newlyGenerated)
        }
        saveLocalState()
    }
    
    // MARK: - Daily Reminders Generator
    
    /// Populates static templates for daily Morning/Evening/Friday updates
    func scheduleDailyReminders(language: HasanaLanguage) {
        // Morning Adhkar Template
        let morningTemplate = QueuedNotification(
            identifier: "hasana.reminder.morning_adhkar",
            title: language == .arabic ? "أذكار الصباح" : "Morning Adhkar",
            body: language == .arabic ? "ألا بذكر الله تطمئن القلوب. حان وقت أذكار الصباح." : "Remember Allah in the morning. Time for Morning Adhkar.",
            triggerDate: Date(), // Will be calculated by recurrence expander
            category: "hasana.category.dua",
            sound: "adhkar_sound.caf",
            userInfo: ["reminderType": "morning_adhkar"],
            priority: .medium,
            type: .dailyReminder,
            recurrence: .daily(hour: 6, minute: 30)
        )
        
        // Evening Adhkar Template
        let eveningTemplate = QueuedNotification(
            identifier: "hasana.reminder.evening_adhkar",
            title: language == .arabic ? "أذكار المساء" : "Evening Adhkar",
            body: language == .arabic ? "حان وقت أذكار المساء لحفظك وسلامتك اليوم." : "Protect yourself tonight. Time for Evening Adhkar.",
            triggerDate: Date(),
            category: "hasana.category.dua",
            sound: "adhkar_sound.caf",
            userInfo: ["reminderType": "evening_adhkar"],
            priority: .medium,
            type: .dailyReminder,
            recurrence: .daily(hour: 17, minute: 0)
        )
        
        // Friday Kahf Reminder Template
        let FridayKahfTemplate = QueuedNotification(
            identifier: "hasana.reminder.friday_kahf",
            title: language == .arabic ? "سورة الكهف" : "Surah Al-Kahf",
            body: language == .arabic ? "يوم الجمعة مبارك، لا تنسَ قراءة سورة الكهف لنورٍ يضيء لك ما بين الجمعتين." : "Friday is here. Don't forget reading Surah Al-Kahf for light until next Friday.",
            triggerDate: Date(),
            category: "hasana.category.dua",
            sound: "default",
            userInfo: ["reminderType": "friday_kahf"],
            priority: .high,
            type: .dailyReminder,
            recurrence: .weekly(daysOfWeek: [6], hour: 9, minute: 0) // Friday (6 = Friday)
        )
        
        // Daily Quran reading prompt
        let quranDailyTemplate = QueuedNotification(
            identifier: "hasana.reminder.daily_quran",
            title: language == .arabic ? "ورد القرآن الكريم" : "Daily Quran Portion",
            body: language == .arabic ? "خصص دقائق من يومك لكتاب الله لتبني حديقتك الروحية." : "Dedicate a few minutes to the Book of Allah to grow your spiritual garden.",
            triggerDate: Date(),
            category: "hasana.category.dua",
            sound: "default",
            userInfo: ["reminderType": "daily_quran"],
            priority: .medium,
            type: .dailyReminder,
            recurrence: .daily(hour: 13, minute: 0)
        )
        
        addRecurringTemplate(morningTemplate)
        addRecurringTemplate(eveningTemplate)
        addRecurringTemplate(FridayKahfTemplate)
        addRecurringTemplate(quranDailyTemplate)
    }
    
    // MARK: - Habit Reminders Configurator
    
    func scheduleHabitReminders(habits: [SpiritualHabit], language: HasanaLanguage) {
        // Clear old habit notifications from the template and pending queue
        queue.sync {
            self.recurringTemplates.removeAll { $0.type == .habitStreak }
            self.pendingNotifications.removeAll { $0.type == .habitStreak }
        }
        
        for habit in habits {
            let identifier = "hasana.habit.\(habit.id.uuidString)"
            let title = language == .arabic ? "متابعة العادات" : "Habit Tracker"
            
            // Craft dynamic message content based on the type of habit
            let body: String
            if language == .arabic {
                body = "حان الوقت لإكمال: \(habit.titleAr). حافظ على حديقتك الإيمانية نامية!"
            } else {
                body = "Time to complete: \(habit.titleEn). Keep your spiritual garden growing!"
            }
            
            // Convert frequency into recurrence rules
            let rule: HasanaRecurrenceRule
            if habit.frequency == "daily" {
                rule = .daily(hour: 20, minute: 0)
            } else {
                rule = .weekly(daysOfWeek: [6], hour: 18, minute: 0)
            }
            
            let habitNotif = QueuedNotification(
                identifier: identifier,
                title: title,
                body: body,
                triggerDate: Date(),
                category: "hasana.category.habit",
                sound: "habit_reminder.caf",
                userInfo: ["habitID": habit.id.uuidString, "gardenPracticeID": habit.gardenPracticeID ?? ""],
                priority: .high,
                type: .habitStreak,
                recurrence: rule
            )
            
            addRecurringTemplate(habitNotif)
        }
    }
    
    // MARK: - Masjid Geofencing Registration
    
    func getGeofences() -> [MasjidGeofence] {
        queue.sync { activeGeofences }
    }
    
    /// Registers a masjid geofence trigger in iOS notification center.
    /// This bypasses the chronological queues since OS handles regional alerts asynchronously.
    func registerMasjidGeofence(_ geofence: MasjidGeofence, language: HasanaLanguage) {
        queue.sync {
            self.activeGeofences.removeAll { $0.id == geofence.id }
            self.activeGeofences.append(geofence)
        }
        saveLocalState()
        
        let center = UNUserNotificationCenter.current()
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: geofence.latitude, longitude: geofence.longitude),
            radius: geofence.radius,
            identifier: "hasana.geofence.masjid.\(geofence.id.uuidString)"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        // 1. Entry Notification Request
        let entryContent = UNMutableNotificationContent()
        entryContent.title = language == .arabic ? "دخول المسجد" : "Entering the Mosque"
        entryContent.body = language == .arabic ? "اللهم افتح لي أبواب رحمتك. تذكر إغلاق صوت هاتفك." : "O Allah, open the gates of Your mercy. Please remember to mute your device."
        entryContent.categoryIdentifier = "hasana.category.dua"
        entryContent.sound = .default
        entryContent.userInfo = ["geofenceID": geofence.id.uuidString, "type": "entry"]
        
        let entryTrigger = UNLocationNotificationTrigger(region: region, repeats: true)
        let entryRequest = UNNotificationRequest(
            identifier: "hasana.geofence.entry.\(geofence.id.uuidString)",
            content: entryContent,
            trigger: entryTrigger
        )
        
        // 2. Exit Notification Request
        let exitContent = UNMutableNotificationContent()
        exitContent.title = language == .arabic ? "الخروج من المسجد" : "Leaving the Mosque"
        exitContent.body = language == .arabic ? "اللهم إني أسألك من فضلك. تذكر تشغيل صوت هاتفك." : "O Allah, I ask You from Your bounty. Remember to restore your device sound."
        exitContent.categoryIdentifier = "hasana.category.dua"
        exitContent.sound = .default
        exitContent.userInfo = ["geofenceID": geofence.id.uuidString, "type": "exit"]
        
        let exitRequest = UNNotificationRequest(
            identifier: "hasana.geofence.exit.\(geofence.id.uuidString)",
            content: exitContent,
            trigger: entryTrigger // Shares same circular region
        )
        
        center.add(entryRequest)
        center.add(exitRequest)
    }
    
    func removeMasjidGeofence(id: UUID) {
        queue.sync {
            self.activeGeofences.removeAll { $0.id == id }
        }
        saveLocalState()
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "hasana.geofence.entry.\(id.uuidString)",
            "hasana.geofence.exit.\(id.uuidString)"
        ])
    }
    
    // MARK: - Dynamic Recurrence Expander Engine
    
    /// Resolves recurring templates into concrete future notification schedules
    /// - Parameters:
    ///   - start: Starting reference date
    ///   - limitDays: Range of days in the future to compute (typically 7 days)
    private func expandTemplates(startingFrom start: Date, limitDays: Int) -> [QueuedNotification] {
        let calendar = Calendar.current
        var resolved: [QueuedNotification] = []
        
        let templates = getRecurringTemplates()
        
        for template in templates {
            switch template.recurrence {
            case .none:
                continue
                
            case .daily(let hour, let minute):
                for dayOffset in 0..<limitDays {
                    guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
                    
                    var comps = calendar.dateComponents([.year, .month, .day], from: targetDay)
                    comps.hour = hour
                    comps.minute = minute
                    comps.second = 0
                    
                    guard let triggerDate = calendar.date(from: comps) else { continue }
                    
                    // Only schedule if the trigger is in the future
                    if triggerDate > start {
                        let dayString = formatDateKey(triggerDate)
                        let resolvedID = "\(template.identifier).\(dayString)"
                        
                        // Inject random spiritual content if this is a general daily reminder
                        var bodyText = template.body
                        if template.type == .dailyReminder {
                            bodyText = IslamicContentRepository.shared.getSpiritualQuote(for: dayOffset, language: template.identifier.contains("morning") ? .morning : .evening) ?? template.body
                        }
                        
                        let instance = QueuedNotification(
                            identifier: resolvedID,
                            title: template.title,
                            body: bodyText,
                            triggerDate: triggerDate,
                            category: template.category,
                            sound: template.sound,
                            userInfo: template.userInfo,
                            priority: template.priority,
                            type: template.type,
                            recurrence: .none, // Instantiated item is one-off
                            isScheduledBySystem: false
                        )
                        resolved.append(instance)
                    }
                }
                
            case .weekly(let daysOfWeek, let hour, let minute):
                for dayOffset in 0..<limitDays {
                    guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
                    let weekday = calendar.component(.weekday, from: targetDay) // Sunday = 1, Saturday = 7
                    
                    if daysOfWeek.contains(weekday) {
                        var comps = calendar.dateComponents([.year, .month, .day], from: targetDay)
                        comps.hour = hour
                        comps.minute = minute
                        comps.second = 0
                        
                        guard let triggerDate = calendar.date(from: comps) else { continue }
                        
                        if triggerDate > start {
                            let dayString = formatDateKey(triggerDate)
                            let resolvedID = "\(template.identifier).\(dayString)"
                            
                            let instance = QueuedNotification(
                                identifier: resolvedID,
                                title: template.title,
                                body: template.body,
                                triggerDate: triggerDate,
                                category: template.category,
                                sound: template.sound,
                                userInfo: template.userInfo,
                                priority: template.priority,
                                type: template.type,
                                recurrence: .none,
                                isScheduledBySystem: false
                            )
                            resolved.append(instance)
                        }
                    }
                }
                
            case .customInterval(let seconds):
                var triggerDate = start.addingTimeInterval(seconds)
                let limitDate = calendar.date(byAdding: .day, value: limitDays, to: start) ?? start.addingTimeInterval(86400 * 7)
                
                var counter = 1
                while triggerDate < limitDate {
                    let resolvedID = "\(template.identifier).\(counter)"
                    let instance = QueuedNotification(
                        identifier: resolvedID,
                        title: template.title,
                        body: template.body,
                        triggerDate: triggerDate,
                        category: template.category,
                        sound: template.sound,
                        userInfo: template.userInfo,
                        priority: template.priority,
                        type: template.type,
                        recurrence: .none,
                        isScheduledBySystem: false
                    )
                    resolved.append(instance)
                    triggerDate = triggerDate.addingTimeInterval(seconds)
                    counter += 1
                }
            }
        }
        
        return resolved
    }
    
    // MARK: - Queue Limit & Sync System
    
    /// Main pipeline of the alerts engine. Cleans expired alerts, builds templates,
    /// prioritizes all future instances, and applies changes directly to iOS userNotifications system.
    func syncAndSchedule(completion: @escaping (Result<Int, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else {
                completion(.failure(NSError(domain: "HasanaNotificationQueueManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self released"])))
                return
            }
            
            let center = UNUserNotificationCenter.current()
            let now = Date()
            
            // 1. Remove expired items from pending queue (older than 10 minutes ago)
            self.pendingNotifications.removeAll { $0.triggerDate < now.addingTimeInterval(-600) }
            
            // 2. Expand all recurring templates into concrete future instances
            let concreteInstances = self.expandTemplates(startingFrom: now, limitDays: 7)
            
            // 3. Gather manually enqueued one-off notifications (future only)
            let futureOneOffs = self.pendingNotifications.filter { $0.triggerDate > now && $0.recurrence == .none }
            
            // 4. Combine and Sort (Priority first, then triggerDate)
            var allCandidates = concreteInstances + futureOneOffs
            
            // Deduplicate matching identifiers (favoring manual items)
            var seenIdentifiers = Set<String>()
            var deduplicated: [QueuedNotification] = []
            
            // Sort by priority so we keep the most important alerts in case of duplicates or queue limits
            allCandidates.sort { (lhs, rhs) -> Bool in
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority // Critical < High < Medium < Low
                }
                return lhs.triggerDate < rhs.triggerDate
            }
            
            for candidate in allCandidates {
                if !seenIdentifiers.contains(candidate.identifier) {
                    seenIdentifiers.insert(candidate.identifier)
                    deduplicated.append(candidate)
                }
            }
            
            // 5. Slice to iOS limits
            let finalSelection = Array(deduplicated.prefix(self.maxActiveSlots))
            
            // Get currently scheduled notifications, but exclude Geofences (to avoid resetting geofences unless changed)
            center.getPendingNotificationRequests { [weak self] pendingRequests in
                guard let self = self else { return }
                
                // Track geofence requests that must be preserved
                let geofenceIDs = pendingRequests
                    .filter { $0.identifier.contains(".geofence.") }
                    .map { $0.identifier }
                
                // Cancel all chronological ones (keep geofences)
                let nonGeofenceIDs = pendingRequests
                    .filter { !$0.identifier.contains(".geofence.") }
                    .map { $0.identifier }
                
                center.removePendingNotificationRequests(withIdentifiers: nonGeofenceIDs)
                
                let group = DispatchGroup()
                var successfullyAdded = 0
                var lastError: Error?
                
                for item in finalSelection {
                    group.enter()
                    
                    let content = UNMutableNotificationContent()
                    content.title = item.title
                    content.body = item.body
                    content.categoryIdentifier = item.category
                    
                    // Bind custom audio files if set
                    if let soundName = item.sound, soundName != "default" {
                        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
                    } else {
                        content.sound = .default
                    }
                    
                    // Add dictionary identifiers
                    var userInfoDict = item.userInfo
                    userInfoDict["notification_id"] = item.id.uuidString
                    userInfoDict["system_identifier"] = item.identifier
                    userInfoDict["priority_level"] = String(item.priority.rawValue)
                    userInfoDict["category_identifier"] = item.category
                    content.userInfo = userInfoDict
                    
                    // Construct Date trigger trigger
                    let triggerComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: item.triggerDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
                    
                    let request = UNNotificationRequest(
                        identifier: item.identifier,
                        content: content,
                        trigger: trigger
                    )
                    
                    center.add(request) { error in
                        if let error = error {
                            print("❌ Hasana Notification Scheduler failure for \(item.identifier): \(error.localizedDescription)")
                            lastError = error
                        } else {
                            successfullyAdded += 1
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: self.queue) {
                    // Update internal markers
                    for i in 0..<self.pendingNotifications.count {
                        if seenIdentifiers.contains(self.pendingNotifications[i].identifier) {
                            self.pendingNotifications[i].isScheduledBySystem = true
                        }
                    }
                    
                    self.saveLocalState()
                    
                    if let error = lastError {
                        completion(.failure(error))
                    } else {
                        completion(.success(successfullyAdded))
                    }
                }
            }
        }
    }
    
    // MARK: - Background Maintenance Sync Entry
    
    /// Intended to be invoked by the Background Task Scheduler (`BGAppRefreshTask`) or on scene phase changes.
    /// Re-evaluates location, fetches next prayer times, updates habit alerts, trims expired items, and synchronizes.
    func performBackgroundSync(
        location: CLLocationCoordinate2D?,
        settings: PrayerSettings,
        language: HasanaLanguage,
        habits: [SpiritualHabit]
    ) async -> Int {
        return await withCheckedContinuation { continuation in
            // 1. Re-schedule Athan times if location is present
            if let lat = location?.latitude, let lon = location?.longitude {
                self.scheduleAthanAlerts(
                    latitude: lat,
                    longitude: lon,
                    method: settings.method,
                    useHanafiAsr: settings.useHanafiAsr,
                    days: 7,
                    language: language,
                    enablePreAthan: true
                )
            } else {
                // Fallback to Makkah if coordinate is absent but enabled
                self.scheduleAthanAlerts(
                    latitude: settings.latitude,
                    longitude: settings.longitude,
                    method: settings.method,
                    useHanafiAsr: settings.useHanafiAsr,
                    days: 7,
                    language: language,
                    enablePreAthan: true
                )
            }
            
            // 2. Refresh Daily reminders structure
            self.scheduleDailyReminders(language: language)
            
            // 3. Refresh Habit trackers
            self.scheduleHabitReminders(habits: habits, language: language)
            
            // 4. Synchronize state with system queue
            self.syncAndSchedule { result in
                switch result {
                case .success(let scheduledCount):
                    print("🚀 Hasana Engine: Successfully synced and scheduled \(scheduledCount) active alerts.")
                    continuation.resume(returning: scheduledCount)
                case .failure(let error):
                    print("⚠️ Hasana Engine: Failed syncing schedules: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    // MARK: - Custom Notification Builders
    
    /// Safely pushes an immediate custom message onto the scheduler queue
    func scheduleCustomMessage(
        title: String,
        body: String,
        triggerDate: Date,
        priority: HasanaNotificationPriority = .medium,
        identifier: String = UUID().uuidString,
        category: String = "hasana.category.dua",
        sound: String? = nil,
        userInfo: [String: String] = [:]
    ) {
        let msg = QueuedNotification(
            identifier: identifier,
            title: title,
            body: body,
            triggerDate: triggerDate,
            category: category,
            sound: sound,
            userInfo: userInfo,
            priority: priority,
            type: .customMessage,
            recurrence: .none
        )
        addOneOffNotification(msg)
        
        // Sync triggers automatically
        syncAndSchedule { _ in }
    }
    
    // MARK: - Diagnostic Methods
    
    func getPendingSystemRequests() async -> [UNNotificationRequest] {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
    
    func generateDiagnosticReport() async -> String {
        let centerRequests = await getPendingSystemRequests()
        let activeQueue = getPendingQueue()
        let templates = getRecurringTemplates()
        let geofences = getGeofences()
        let logs = getHistory()
        
        var report = "=== Hasana Notification Diagnostics ===\n"
        report += "Timestamp: \(Date().description)\n"
        report += "Total Pending Engine Queues: \(activeQueue.count)\n"
        report += "Total Loaded Recurring Templates: \(templates.count)\n"
        report += "Masjid Geofences Registered: \(geofences.count)\n"
        report += "System Pending Notifications (Active): \(centerRequests.count) / \(maxActiveSlots)\n\n"
        
        report += "--- Active iOS Schedules ---\n"
        if centerRequests.isEmpty {
            report += "None found.\n"
        } else {
            let sortedRequests = centerRequests.sorted {
                let d1 = ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
                let d2 = ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
                return d1 < d2
            }
            
            for (index, request) in sortedRequests.prefix(15).enumerated() {
                let triggerDate = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()?.description ?? "Location Triggered"
                report += "\(index + 1). ID: \(request.identifier) | Trigger: \(triggerDate) | Title: \(request.content.title)\n"
            }
            if centerRequests.count > 15 {
                report += "... and \(centerRequests.count - 15) more\n"
            }
        }
        
        report += "\n--- Engine Queue Backlog ---\n"
        if activeQueue.isEmpty {
            report += "No backlogged items.\n"
        } else {
            let sortedQueue = activeQueue.sorted { $0.triggerDate < $1.triggerDate }
            for (index, item) in sortedQueue.prefix(15).enumerated() {
                report += "\(index + 1). [\(item.priority)] \(item.identifier) at \(item.triggerDate.description) | Title: \(item.title)\n"
            }
            if activeQueue.count > 15 {
                report += "... and \(activeQueue.count - 15) more\n"
            }
        }
        
        report += "\n--- Notification Logs (Recent 10) ---\n"
        if logs.isEmpty {
            report += "No events logged.\n"
        } else {
            for (idx, log) in logs.prefix(10).enumerated() {
                report += "\(idx + 1). [\(log.actionTaken)] ID: \(log.identifier) | Msg: \(log.body) | Time: \(log.timestamp)\n"
            }
        }
        
        return report
    }
    
    /// Utility for sandbox testing
    func triggerImmediateTestNotification(title: String, body: String, delay: TimeInterval = 3) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: "hasana.test.immediate.\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed scheduling immediate test alert: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled test alert inside \(delay) seconds.")
            }
        }
    }
    
    // MARK: - Private Helpers
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func stringDictionary(from userInfo: [AnyHashable: Any]) -> [String: String] {
        userInfo.reduce(into: [String: String]()) { result, entry in
            guard let key = entry.key as? String, let value = entry.value as? String else { return }
            result[key] = value
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension HasanaNotificationQueueManager: UNUserNotificationCenterDelegate {
    
    /// Handles showing notifications in-app (Foreground)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let identifier = notification.request.identifier
        let title = notification.request.content.title
        let body = notification.request.content.body
        
        print("🔔 Received Foreground Notification: \(identifier), UserInfo: \(userInfo)")
        recordHistory(identifier: identifier, title: title, body: body, action: "delivered_foreground")
        
        // Broadcast in-app event trigger
        actionSubject.send(("willPresent", stringDictionary(from: userInfo)))
        
        // Show banner and play sound if allowed
        completionHandler([.banner, .sound, .list])
    }
    
    /// Handles user action responses when clicking notification alerts or actions buttons
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        let stringUserInfo = stringDictionary(from: userInfo)
        let identifier = response.notification.request.identifier
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body
        
        print("👉 User took Action '\(actionIdentifier)' on notification '\(identifier)'")
        recordHistory(identifier: identifier, title: title, body: body, action: actionIdentifier)
        
        // Broadcast action response to listeners
        actionSubject.send((actionIdentifier, stringUserInfo))
        
        // Route Action logic
        switch actionIdentifier {
        case "hasana.action.athan.snooze":
            if let prayerName = stringUserInfo["prayerName"] {
                // Schedule a snoozed alert in 10 minutes (600 seconds)
                let snoozeDate = Date().addingTimeInterval(600)
                let snoozeID = "hasana.snooze.\(prayerName).\(UUID().uuidString)"
                
                self.scheduleCustomMessage(
                    title: "Snoozed Alert (تذكير الأذان المؤجل)",
                    body: "It has been 10 minutes since the Athan of \(prayerName.capitalized).",
                    triggerDate: snoozeDate,
                    priority: .critical,
                    identifier: snoozeID,
                    category: "hasana.category.athan",
                    sound: "default",
                    userInfo: stringUserInfo
                )
            }
            
        case "hasana.action.athan.logged":
            if let prayerName = stringUserInfo["prayerName"] {
                onPrayerLoggedAction?(prayerName, Date())
            }
            
        case "hasana.action.habit.done":
            if let habitIDString = stringUserInfo["habitID"] {
                onHabitLoggedAction?(habitIDString, Date())
            }
            
        case "hasana.action.habit.snooze":
            if let habitIDString = stringUserInfo["habitID"] {
                let snoozeDate = Date().addingTimeInterval(3600) // 1 hour snooze
                let snoozeID = "hasana.snooze.habit.\(habitIDString).\(UUID().uuidString)"
                
                self.scheduleCustomMessage(
                    title: "Habit Reminder (ساعة إضافية)",
                    body: body,
                    triggerDate: snoozeDate,
                    priority: .high,
                    identifier: snoozeID,
                    category: "hasana.category.habit",
                    sound: "default",
                    userInfo: stringUserInfo
                )
            }
            
        case "hasana.action.dua.read":
            if let targetUUIDString = stringUserInfo["duaID"], let uuid = UUID(uuidString: targetUUIDString) {
                onDuaNavigateAction?(uuid)
            }
            
        case UNNotificationDefaultActionIdentifier:
            // App was opened directly via tapping the alert itself
            if let habitIDString = stringUserInfo["habitID"] {
                print("Navigation Request: Open habit ID \(habitIDString)")
            } else if let prayerName = stringUserInfo["prayerName"] {
                print("Navigation Request: Open prayer detail for \(prayerName)")
            }
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Local Spiritual Content Repository
fileprivate struct IslamicContentRepository {
    static let shared = IslamicContentRepository()
    
    enum AdhkarTime {
        case morning
        case evening
    }
    
    // Static lists of morning reminders
    private let morningAdhkarAr = [
        "أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له.",
        "اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور.",
        "يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين.",
        "رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.",
        "اللهم إني أسألك علماً نافعاً، ورزقاً طيباً، وعملاً متقبلاً.",
        "سبحان الله وبحمده: عدد خلقه، ورضا نفسه، وزنة عرشه، ومداد كلماته.",
        "اللهم عافني في بدني، اللهم عافني في سمعي، اللهم عافني في بصري.",
        "أعوذ بكلمات الله التامات من شر ما خلق.",
        "اللهم إني أسألك العفو والعافية في الدنيا والآخرة.",
        "أستغفر الله العظيم الذي لا إله إلا هو الحي القيوم وأتوب إليه."
    ]
    
    private let morningAdhkarEn = [
        "We have entered a new day and with it all dominion belongs to Allah. Praise be to Allah.",
        "O Allah, by Your leave we have entered the morning and by Your leave we enter the evening.",
        "O Ever Living One, O Sustainer of all, by Your mercy I call upon You to set right all my affairs.",
        "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad as my Prophet.",
        "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that are accepted.",
        "Glory is to Allah and praise is to Him, by the number of His creation and His pleasure.",
        "O Allah, make me healthy in my body. O Allah, make me healthy in my hearing.",
        "I seek refuge in the Perfect Words of Allah from the evil of what He has created.",
        "O Allah, I ask You for forgiveness and security in this world and in the Hereafter.",
        "I seek the forgiveness of Allah the Mighty, whom there is no deity except Him, the Living."
    ]
    
    // Static lists of evening reminders
    private let eveningAdhkarAr = [
        "أمسينا وأمسى الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له.",
        "اللهم بك أمسينا، وبك أصبحنا، وبك نحيا، وبك نموت، وإليك المصير.",
        "اللهم إني أسألك العفو والعافية في الدنيا والآخرة وفي أهلي ومالي.",
        "بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.",
        "حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.",
        "اللهم ما أمسى بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك.",
        "أمسيت أثني عليك حمداً، وأشهد أن لا إله إلا أنت.",
        "اللهم عالم الغيب والشهادة فاطر السموات والأرض رب كل شيء ومليكه.",
        "اللهم إني أعوذ بك من الكفر والفقر، وأعوذ بك من عذاب القبر.",
        "يا رب لك الحمد كما ينبغي لجلال وجهك وعظيم سلطانك."
    ]
    
    private let eveningAdhkarEn = [
        "We have reached the evening and with it all dominion belongs to Allah.",
        "O Allah, by Your leave we have entered the evening and by Your leave we enter the morning.",
        "O Allah, I ask You for forgiveness and well-being in this world and the next.",
        "In the Name of Allah, who with His Name nothing can cause harm in the earth nor in the heavens.",
        "Allah is sufficient for me. There is no deity except Him. In Him I put my trust.",
        "O Allah, whatever blessing has come to me or any of Your creation is from You alone.",
        "I have reached the evening praising You, and I bear witness that there is no deity but You.",
        "O Allah, Knower of the unseen and the witnessed, Creator of the heavens and the earth.",
        "O Allah, I seek refuge in You from disbelief and poverty, and from the punishment of the grave.",
        "My Lord, all praise is due to You as matches the Glory of Your Face and greatness of Your Power."
    ]
    
    func getSpiritualQuote(for offset: Int, language time: AdhkarTime) -> String? {
        let index = abs(offset) % 10
        let lang = UserDefaults.shared.string(forKey: HasanaSettingsKeys.language) ?? "ar"
        switch time {
        case .morning:
            return lang == "ar" ? morningAdhkarAr[index] : morningAdhkarEn[index]
        case .evening:
            return lang == "ar" ? eveningAdhkarAr[index] : eveningAdhkarEn[index]
        }
    }
}
