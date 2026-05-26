import WidgetKit
import SwiftUI

// MARK: - Widgets Bundle Entry Point
@main
struct HasanaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GardenDailyWidget()   // Most important: shows all 8 practices
        PrayerTimesWidget()
        QuranJournalWidget()
        TasbihWidget()
        WitrGardenWidget()
        HijriCalendarWidget()
        HabitsWidget()
        QiblaWidget()
        DailyDuaWidget()
    }
}

// MARK: - Core Shared Models & Layout Helpers
struct WidgetTheme {
    static let primaryBackground = Color(hex: "#0A0C10") // Deep dark periwinkle-indigo
    static let surface = Color(hex: "#161922")
    static let border = Color(hex: "#202838")
    
    static let periwinkle = Color(hex: "#7EB5F5")
    static let gold = Color(hex: "#EED08E")
    static let goldSoft = Color(hex: "#342A15")
    static let textPrimary = Color(hex: "#F0F5FA")
    static let textMuted = Color(hex: "#A3B5C9")
}

// MARK: - 1. PRAYER TIMES WIDGET
struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let prayerTimes: [String: String] // Name : Time
    let nextPrayerName: String
    let nextPrayerTime: String
    let timeRemaining: String
}

struct PrayerTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry(
            date: Date(),
            prayerTimes: ["Fajr": "04:12", "Dhuhr": "12:22", "Asr": "15:45", "Maghrib": "18:52", "Isha": "20:20"],
            nextPrayerName: "Maghrib",
            nextPrayerTime: "18:52",
            timeRemaining: "1h 10m"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        let entry = getPrayerTimesEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let currentDate = Date()
        var entries: [PrayerTimesEntry] = []
        
        // Generate entries for the next 24 hours (updating every hour)
        for hourOffset in 0 ..< 24 {
            if let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) {
                let entry = getPrayerTimesEntry(for: entryDate)
                entries.append(entry)
            }
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getPrayerTimesEntry(for date: Date) -> PrayerTimesEntry {
        // Load settings from shared UserDefaults
        let methodRaw = UserDefaults.shared.integer(forKey: "hasana.prayer.method")
        let latitude = UserDefaults.shared.double(forKey: "hasana.prayer.latitude")
        let longitude = UserDefaults.shared.double(forKey: "hasana.prayer.longitude")
        let useHanafi = UserDefaults.shared.bool(forKey: "hasana.prayer.hanafi")
        
        let lat = latitude == 0 ? 24.7136 : latitude // Default to Riyadh
        let lon = longitude == 0 ? 46.6753 : longitude
        
        let offset = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600.0
        
        // Calculate times using calculations engine
        let times = PrayerTimesEngine.calculateTimes(
            for: date,
            latitude: lat,
            longitude: lon,
            timeZoneOffset: offset,
            method: methodRaw,
            useHanafiAsr: useHanafi
        )
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let timeStrings = [
            "Fajr": formatter.string(from: times.fajr),
            "Dhuhr": formatter.string(from: times.dhuhr),
            "Asr": formatter.string(from: times.asr),
            "Maghrib": formatter.string(from: times.maghrib),
            "Isha": formatter.string(from: times.isha)
        ]
        
        // Find next prayer
        let currentString = formatter.string(from: date)
        var nextName = "Fajr"
        var nextTime = timeStrings["Fajr"] ?? "04:12"
        var timeRemaining = "2h 30m"
        
        let sortedPrayers = [
            ("Fajr", times.fajr),
            ("Dhuhr", times.dhuhr),
            ("Asr", times.asr),
            ("Maghrib", times.maghrib),
            ("Isha", times.isha)
        ]
        
        for (name, prayerDate) in sortedPrayers {
            if prayerDate > date {
                nextName = name
                nextTime = formatter.string(from: prayerDate)
                let diff = Int(prayerDate.timeIntervalSince(date))
                let hrs = diff / 3600
                let mins = (diff % 3600) / 60
                timeRemaining = hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m"
                break
            }
        }
        
        return PrayerTimesEntry(
            date: date,
            prayerTimes: timeStrings,
            nextPrayerName: nextName,
            nextPrayerTime: nextTime,
            timeRemaining: timeRemaining
        )
    }
}

struct PrayerTimesWidgetView: View {
    var entry: PrayerTimesProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(entry.nextPrayerName, systemImage: "clock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WidgetTheme.periwinkle)
                    
                    Spacer()
                    
                    Text(entry.nextPrayerTime)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(WidgetTheme.textPrimary)
                }
                
                Text(entry.timeRemaining)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(WidgetTheme.gold)
                
                Text("until next prayer")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textMuted)
                
                if family == .systemMedium {
                    Spacer(minLength: 4)
                    Divider().background(WidgetTheme.border)
                    Spacer(minLength: 4)
                    
                    HStack {
                        ForEach(["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"], id: \.self) { name in
                            VStack(spacing: 2) {
                                Text(name)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(name == entry.nextPrayerName ? WidgetTheme.periwinkle : WidgetTheme.textMuted)
                                
                                Text(entry.prayerTimes[name] ?? "--:--")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(name == entry.nextPrayerName ? WidgetTheme.periwinkle : WidgetTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(name == entry.nextPrayerName ? WidgetTheme.periwinkle.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Track daily prayers and countdown to the next Athan.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 2. QURAN JOURNAL WIDGET
struct QuranEntry: TimelineEntry {
    let date: Date
    let readPages: Int
    let targetPages: Int
    let lastReflection: String
}

struct QuranProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuranEntry {
        QuranEntry(date: Date(), readPages: 4, targetPages: 10, lastReflection: "Reflecting on Surah Al-Kahf...")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuranEntry) -> Void) {
        completion(getQuranEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuranEntry>) -> Void) {
        completion(Timeline(entries: [getQuranEntry()], policy: .after(Date().addingTimeInterval(3600))))
    }
    
    private func getQuranEntry() -> QuranEntry {
        // Load Quran Journal configurations
        var read = 0
        var target = 10
        var reflection = ""
        
        if let data = UserDefaults.shared.data(forKey: "hasana.quran.goal") {
            if let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
                // Approximate today's progress if tracked
                read = decoded["todayProgress"] ?? 0
                target = decoded["pagesTarget"] ?? 10
            }
        }
        
        if let data = UserDefaults.shared.data(forKey: "hasana.quran.reflections") {
            if let decoded = try? JSONDecoder().decode([String].self, from: data) {
                reflection = decoded.first ?? ""
            }
        }
        
        return QuranEntry(
            date: Date(),
            readPages: read,
            targetPages: target,
            lastReflection: reflection.isEmpty ? "Keep logging reflections to build your garden." : reflection
        )
    }
}

struct QuranWidgetView: View {
    var entry: QuranProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Quran Journal", systemImage: "book.closed.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WidgetTheme.gold)
                    
                    Spacer()
                    
                    Text("\(entry.readPages) / \(entry.targetPages)")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(WidgetTheme.textPrimary)
                    
                    Text("pages read today")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetTheme.textMuted)
                    
                    Spacer()
                }
                
                if family == .systemMedium {
                    Divider().background(WidgetTheme.border)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST REFLECTION")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(WidgetTheme.textMuted)
                        
                        Text(entry.lastReflection)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundStyle(WidgetTheme.textPrimary)
                            .lineLimit(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(8)
                    .background(WidgetTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                } else {
                    // Small progress arc
                    ZStack {
                        Circle()
                            .stroke(WidgetTheme.border, lineWidth: 6)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(entry.readPages) / CGFloat(max(1, entry.targetPages)))
                            .stroke(WidgetTheme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(WidgetTheme.gold)
                            .opacity(entry.readPages >= entry.targetPages ? 1 : 0)
                    }
                    .frame(width: 44, height: 44)
                }
            }
            .padding()
        }
    }
}

struct QuranJournalWidget: Widget {
    let kind: String = "QuranJournalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranProvider()) { entry in
            QuranWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Quran Journal")
        .description("Track daily Quran pages read and review recent reflections.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 3. TASBIH ADHKAR WIDGET
struct TasbihEntry: TimelineEntry {
    let date: Date
    let currentCount: Int
    let targetCount: Int
    let dhikrName: String
}

struct TasbihProvider: TimelineProvider {
    func placeholder(in context: Context) -> TasbihEntry {
        TasbihEntry(date: Date(), currentCount: 33, targetCount: 99, dhikrName: "Alhamdulillah")
    }

    func getSnapshot(in context: Context, completion: @escaping (TasbihEntry) -> Void) {
        completion(getTasbihEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasbihEntry>) -> Void) {
        completion(Timeline(entries: [getTasbihEntry()], policy: .after(Date().addingTimeInterval(1800))))
    }
    
    private func getTasbihEntry() -> TasbihEntry {
        // Load custom adhkar state from shared container
        let current = UserDefaults.shared.integer(forKey: "hasana.tasbih.current")
        let target = UserDefaults.shared.integer(forKey: "hasana.tasbih.target")
        let name = UserDefaults.shared.string(forKey: "hasana.tasbih.name") ?? "SubhanAllah"
        
        return TasbihEntry(
            date: Date(),
            currentCount: current,
            targetCount: target == 0 ? 33 : target,
            dhikrName: name
        )
    }
}

struct TasbihWidgetView: View {
    var entry: TasbihProvider.Entry
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Tasbih", systemImage: "circle.grid.cross.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetTheme.periwinkle)
                
                Text(entry.dhikrName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WidgetTheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    Text("\(entry.currentCount)")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(WidgetTheme.periwinkle)
                        .monospacedDigit()
                    
                    Text("/ \(entry.targetCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WidgetTheme.textMuted)
                        .padding(.bottom, 6)
                }
                
                Spacer()
                
                // Horizontal Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(WidgetTheme.border)
                            .frame(height: 6)
                        Capsule().fill(WidgetTheme.periwinkle)
                            .frame(width: geo.size.width * CGFloat(entry.currentCount) / CGFloat(max(1, entry.targetCount)), height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding()
        }
    }
}

struct TasbihWidget: Widget {
    let kind: String = "TasbihWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TasbihProvider()) { entry in
            TasbihWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Tasbih Clicker")
        .description("Keep tabs on today's target Adhkar progress.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 4. WITR GARDEN WIDGET
struct WitrEntry: TimelineEntry {
    let date: Date
    let isTendedToday: Bool
    let growthStage: HasanaGardenGrowthStage
}

struct WitrProvider: TimelineProvider {
    func placeholder(in context: Context) -> WitrEntry {
        WitrEntry(date: Date(), isTendedToday: false, growthStage: .young)
    }

    func getSnapshot(in context: Context, completion: @escaping (WitrEntry) -> Void) {
        completion(getWitrEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WitrEntry>) -> Void) {
        completion(Timeline(entries: [getWitrEntry()], policy: .after(Date().addingTimeInterval(3600))))
    }
    
    private func getWitrEntry() -> WitrEntry {
        // Load Witr state from garden snapshot
        var tended = false
        var stage: HasanaGardenGrowthStage = .seed
        
        let decoder = JSONDecoder()
        if let data = UserDefaults.shared.data(forKey: "hasana.garden.snapshot.v1") {
            if let snapshot = try? decoder.decode(HasanaGardenSnapshot.self, from: data) {
                // Find Witr practice ID
                if let witrRecord = snapshot.progress.first(where: { $0.practiceID == .witr }) {
                    let key = HasanaGardenStore.currentLocalDayKey()
                    tended = witrRecord.tendedDayKeys.contains(key)
                    stage = witrRecord.growthStage
                }
            }
        }
        
        return WitrEntry(date: Date(), isTendedToday: tended, growthStage: stage)
    }
}

struct WitrWidgetView: View {
    var entry: WitrProvider.Entry
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: 8) {
                Text("Witr Plant")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetTheme.textMuted)
                
                // Mini growth plant illustration
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(WidgetTheme.goldSoft)
                        .frame(width: 44, height: 8)
                        .offset(y: 2)
                    
                    // Simple stem/flower depiction
                    if entry.growthStage == .seed {
                        Circle()
                            .fill(WidgetTheme.gold)
                            .frame(width: 10, height: 10)
                            .offset(y: -4)
                    } else {
                        // Stem
                        Capsule()
                            .fill(WidgetTheme.periwinkle)
                            .frame(width: 4, height: entry.isTendedToday ? 34 : 24)
                        
                        // Flower/Leaves
                        Circle()
                            .fill(entry.isTendedToday ? WidgetTheme.gold : WidgetTheme.periwinkle.opacity(0.8))
                            .frame(width: entry.growthStage == .flowering ? 14 : 8, height: entry.growthStage == .flowering ? 14 : 8)
                            .offset(y: entry.isTendedToday ? -30 : -20)
                    }
                }
                .frame(height: 48)
                
                Text(entry.isTendedToday ? "Tended Today" : "Needs Water")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(entry.isTendedToday ? WidgetTheme.periwinkle : WidgetTheme.gold)
                    .lineLimit(1)
                
                Text(entry.growthStage.title(for: .english))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textMuted)
            }
            .padding(10)
        }
    }
}

struct WitrGardenWidget: Widget {
    let kind: String = "WitrGardenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WitrProvider()) { entry in
            WitrWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Witr Plant")
        .description("Tend your spiritual garden. View the growth of your Witr plant.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 5. HIJRI CALENDAR WIDGET
struct HijriEntry: TimelineEntry {
    let date: Date
    let hijriDay: Int
    let hijriMonth: String
    let hijriYear: Int
    let holyEvent: String
}

struct HijriProvider: TimelineProvider {
    func placeholder(in context: Context) -> HijriEntry {
        HijriEntry(date: Date(), hijriDay: 15, hijriMonth: "Ramadan", hijriYear: 1447, holyEvent: "Mid-Ramadan")
    }

    func getSnapshot(in context: Context, completion: @escaping (HijriEntry) -> Void) {
        completion(getHijriEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HijriEntry>) -> Void) {
        completion(Timeline(entries: [getHijriEntry()], policy: .after(Date().addingTimeInterval(86400)))) // updates daily
    }
    
    private func getHijriEntry() -> HijriEntry {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        let date = Date()
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let monthNames = [
            "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani", "Jumada al-Awwal", "Jumada al-Thani",
            "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qadah", "Dhu al-Hijjah"
        ]
        
        let monthName = monthNames[min(max(0, month - 1), 11)]
        
        // Approximate holy event finder
        var event = "Normal Day"
        if month == 9 {
            event = "Month of Ramadan"
        } else if month == 10 && day == 1 {
            event = "Eid al-Fitr"
        } else if month == 12 && day == 10 {
            event = "Eid al-Adha"
        } else if month == 1 && day == 10 {
            event = "Day of Ashura"
        }
        
        return HijriEntry(date: date, hijriDay: day, hijriMonth: monthName, hijriYear: year, holyEvent: event)
    }
}

struct HijriWidgetView: View {
    var entry: HijriProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: 4) {
                Text(entry.hijriMonth.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(WidgetTheme.periwinkle)
                
                Text("\(entry.hijriDay)")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(WidgetTheme.gold)
                
                Text("\(entry.hijriYear) AH")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textMuted)
                
                if family == .systemMedium && entry.holyEvent != "Normal Day" {
                    Spacer(minLength: 2)
                    Text(entry.holyEvent)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WidgetTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(WidgetTheme.goldSoft, in: Capsule())
                }
            }
            .padding()
        }
    }
}

struct HijriCalendarWidget: Widget {
    let kind: String = "HijriCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HijriProvider()) { entry in
            HijriWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Hijri Calendar")
        .description("Display the current Islamic Hijri date and holy events.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 6. HABIT STREAKS WIDGET
struct HabitsEntry: TimelineEntry {
    let date: Date
    let completionPercent: Double
    let activeStreaks: Int
}

struct HabitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitsEntry {
        HabitsEntry(date: Date(), completionPercent: 0.66, activeStreaks: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitsEntry) -> Void) {
        completion(getHabitsEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitsEntry>) -> Void) {
        completion(Timeline(entries: [getHabitsEntry()], policy: .after(Date().addingTimeInterval(3600))))
    }
    
    private func getHabitsEntry() -> HabitsEntry {
        var habitsList: [SpiritualHabit] = []
        if let data = UserDefaults.shared.data(forKey: "hasana.habits.list") {
            if let decoded = try? JSONDecoder().decode([SpiritualHabit].self, from: data) {
                habitsList = decoded
            }
        }
        
        var logsList: [HabitLog] = []
        if let data = UserDefaults.shared.data(forKey: "hasana.habits.logs") {
            if let decoded = try? JSONDecoder().decode([HabitLog].self, from: data) {
                logsList = decoded
            }
        }
        
        if habitsList.isEmpty {
            return HabitsEntry(date: Date(), completionPercent: 0.0, activeStreaks: 0)
        }
        
        let key = HasanaGardenStore.currentLocalDayKey()
        var totalFraction = 0.0
        for habit in habitsList {
            let count = logsList.first { $0.habitID == habit.id && $0.dateKey == key }?.count ?? 0
            let fraction = Double(count) / Double(habit.targetCount)
            totalFraction += min(fraction, 1.0)
        }
        
        let completion = totalFraction / Double(habitsList.count)
        
        // Compute streak for each habit from HabitLog history
        // A streak is consecutive days up to today where count >= targetCount
        let today = HasanaGardenStore.currentLocalDayKey()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var totalStreaks = 0
        for habit in habitsList {
            var streak = 0
            var checkDate = dateFormatter.date(from: today) ?? Date()
            while true {
                let checkKey = dateFormatter.string(from: checkDate)
                let count = logsList.first { $0.habitID == habit.id && $0.dateKey == checkKey }?.count ?? 0
                if count >= habit.targetCount {
                    streak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                } else {
                    break
                }
            }
            totalStreaks += streak
        }
        let averageStreak = habitsList.isEmpty ? 0 : totalStreaks / habitsList.count
        
        return HabitsEntry(date: Date(), completionPercent: completion, activeStreaks: averageStreak)
    }
}

struct HabitsWidgetView: View {
    var entry: HabitsProvider.Entry
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Habits Streak", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetTheme.gold)
                
                Text("\(entry.activeStreaks) Days")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(WidgetTheme.textPrimary)
                
                Text("average streak")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textMuted)
                
                Spacer()
                
                HStack {
                    Text(String(format: "%.0f%% Completed", entry.completionPercent * 100))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WidgetTheme.gold)
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct HabitsWidget: Widget {
    let kind: String = "HabitsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitsProvider()) { entry in
            HabitsWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Habit Streaks")
        .description("Monitor daily streaks and habit completions.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 7. QIBLA SHORTCUT WIDGET
struct QiblaEntry: TimelineEntry {
    let date: Date
    let angle: Double
}

struct QiblaProvider: TimelineProvider {
    func placeholder(in context: Context) -> QiblaEntry {
        QiblaEntry(date: Date(), angle: 255.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (QiblaEntry) -> Void) {
        completion(QiblaEntry(date: Date(), angle: 255.0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QiblaEntry>) -> Void) {
        completion(Timeline(entries: [QiblaEntry(date: Date(), angle: 255.0)], policy: .never))
    }
}

struct QiblaWidgetView: View {
    var entry: QiblaProvider.Entry
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: 8) {
                Text("Qibla Finder")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetTheme.periwinkle)
                
                // Simple compass dial
                ZStack {
                    Circle()
                        .stroke(WidgetTheme.border, lineWidth: 4)
                        .frame(width: 52, height: 52)
                    
                    // Arrow pointing to Qibla
                    Image(systemName: "safari.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(WidgetTheme.periwinkle)
                        .rotationEffect(.degrees(entry.angle))
                }
                .frame(width: 56, height: 56)
                
                Text("Tap to Open")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textMuted)
            }
            .padding()
        }
    }
}

struct QiblaWidget: Widget {
    let kind: String = "QiblaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QiblaProvider()) { entry in
            QiblaWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Qibla Finder")
        .description("Quick home screen access to the Qibla Compass.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 8. DAILY DUA WIDGET
struct DailyDuaEntry: TimelineEntry {
    let date: Date
    let title: String
    let arabicText: String
}

struct DailyDuaProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyDuaEntry {
        DailyDuaEntry(date: Date(), title: "For morning & evening", arabicText: "الحَمْدُ للهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ")
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyDuaEntry) -> Void) {
        completion(getDailyDuaEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyDuaEntry>) -> Void) {
        completion(Timeline(entries: [getDailyDuaEntry()], policy: .after(Date().addingTimeInterval(43200)))) // updates twice a day
    }
    
    private func getDailyDuaEntry() -> DailyDuaEntry {
        // Load from default Hisn al-Muslim library
        let day = Calendar.current.component(.day, from: Date())
        let list = DuaItem.defaults
        let index = day % list.count
        let item = list[index]
        
        return DailyDuaEntry(date: Date(), title: item.titleEn, arabicText: item.arabic)
    }
}

struct DailyDuaWidgetView: View {
    var entry: DailyDuaProvider.Entry
    
    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Dua of the Day", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetTheme.gold)
                
                Text(entry.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WidgetTheme.periwinkle)
                    .lineLimit(1)
                
                Spacer(minLength: 2)
                
                Text(entry.arabicText)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(WidgetTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(8)
                    .background(WidgetTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(12)
        }
    }
}

struct DailyDuaWidget: Widget {
    let kind: String = "DailyDuaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyDuaProvider()) { entry in
            DailyDuaWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Suggested Dua")
        .description("Read a new recommended spiritual Supplication daily.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - 9. GARDEN DAILY WIDGET (Core MVP)

struct GardenDailyEntry: TimelineEntry {
    let date: Date
    let practices: [GardenWidgetPractice]
    let tendedCount: Int
    let totalCount: Int
    let totalTendedDays: Int
}

struct GardenWidgetPractice: Identifiable {
    let id: String
    let name: String
    let icon: String
    let isTended: Bool
    let isDormant: Bool
    let growthStage: HasanaGardenGrowthStage
}

struct GardenDailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> GardenDailyEntry {
        GardenDailyEntry(
            date: Date(),
            practices: HasanaGardenPractice.defaults.map { practice in
                GardenWidgetPractice(
                    id: practice.id.rawValue,
                    name: practice.title(for: .arabic),
                    icon: practice.icon,
                    isTended: false,
                    isDormant: false,
                    growthStage: .young
                )
            },
            tendedCount: 3,
            totalCount: 8,
            totalTendedDays: 21
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GardenDailyEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GardenDailyEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh at midnight so the tended state resets for a new day
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 0
        components.minute = 1
        let midnight = Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func loadEntry() -> GardenDailyEntry {
        let decoder = JSONDecoder()
        let todayKey = HasanaGardenStore.currentLocalDayKey()
        var progressMap: [String: HasanaGardenProgress] = [:]

        if let data = UserDefaults.shared.data(forKey: HasanaGardenStore.storageKey),
           let snapshot = HasanaGardenSnapshot.decode(from: data) {
            for record in snapshot.progress {
                progressMap[record.practiceID.rawValue] = record
            }
        }

        var tendedCount = 0
        var totalTendedDays = 0

        let widgetPractices: [GardenWidgetPractice] = HasanaGardenPractice.defaults.map { practice in
            let record = progressMap[practice.id.rawValue] ?? HasanaGardenProgress(practiceID: practice.id)
            let isTended = record.isTended(on: todayKey)
            let dormant = record.isDormant(todayKey: todayKey)

            if isTended { tendedCount += 1 }
            totalTendedDays += record.totalTendedDays

            return GardenWidgetPractice(
                id: practice.id.rawValue,
                name: practice.title(for: .arabic),
                icon: practice.icon,
                isTended: isTended,
                isDormant: dormant,
                growthStage: record.growthStage
            )
        }

        return GardenDailyEntry(
            date: Date(),
            practices: widgetPractices,
            tendedCount: tendedCount,
            totalCount: widgetPractices.count,
            totalTendedDays: totalTendedDays
        )
    }
}

struct GardenDailyWidgetView: View {
    var entry: GardenDailyProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            WidgetTheme.primaryBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Label("حسنة", systemImage: "leaf.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WidgetTheme.gold)

                    Spacer()

                    Text("\(entry.tendedCount)/\(entry.totalCount)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(WidgetTheme.textPrimary)
                        .monospacedDigit()

                    Text(family == .systemSmall ? "" : "today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WidgetTheme.textMuted)
                }

                if family == .systemSmall {
                    // Small: show 4 practices in a 2x2 grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(entry.practices.prefix(4)) { practice in
                            GardenWidgetPracticeCell(practice: practice, compact: true)
                        }
                    }
                } else {
                    // Medium/Large: show all 8
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                        spacing: 6
                    ) {
                        ForEach(entry.practices) { practice in
                            GardenWidgetPracticeCell(practice: practice, compact: false)
                        }
                    }
                }

                Spacer(minLength: 0)

                // Footer
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(WidgetTheme.gold)
                    Text("\(entry.totalTendedDays) total days")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(WidgetTheme.textMuted)
                }
            }
            .padding(12)
        }
    }
}

private struct GardenWidgetPracticeCell: View {
    let practice: GardenWidgetPractice
    let compact: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: practice.icon)
                .font(.system(size: compact ? 14 : 12, weight: .bold))
                .foregroundStyle(cellColor)

            if !compact {
                Text(practice.growthStage.rawValue.prefix(1).uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(WidgetTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 36 : 32)
        .background(
            practice.isTended
                ? WidgetTheme.gold.opacity(0.15)
                : (practice.isDormant ? WidgetTheme.border.opacity(0.5) : WidgetTheme.surface),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    practice.isTended ? WidgetTheme.gold.opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        }
    }

    private var cellColor: Color {
        if practice.isTended { return WidgetTheme.gold }
        if practice.isDormant { return WidgetTheme.textMuted.opacity(0.5) }
        return WidgetTheme.periwinkle.opacity(0.7)
    }
}

struct GardenDailyWidget: Widget {
    let kind: String = "GardenDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GardenDailyProvider()) { entry in
            GardenDailyWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Today's Garden")
        .description("See your 8 worship practices at a glance. Glowing icons mean tended today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
