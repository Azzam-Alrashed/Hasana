import SwiftUI

struct IslamicHubView: View {
    let language: HasanaLanguage
    let selectedDayKey: String
    let onLoggedWorship: (String) -> Void // Propagate completions to Garden Store
    
    // Presentation States
    @State private var isShowingQibla = false
    @State private var isShowingDuaLibrary = false
    @State private var isShowingCalendar = false
    @State private var isShowingHabitTracker = false
    
    // Today's preview states
    @State private var dailyDua: DuaItem = DuaItem.defaults[4] // Default to Sayyid al-Istighfar
    @State private var todayHabitCompletion = 0.0
    @State private var activeHabitsCount = 0
    
    @Environment(\.dismiss) private var dismiss
    
    private let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
    private let hijriMonthNamesAr = [
        "محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة",
        "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
    ]
    
    private let hijriMonthNamesEn = [
        "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani", "Jumada al-Awwal", "Jumada al-Thani",
        "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qadah", "Dhu al-Hijjah"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Hijri Date Header Card
                        VStack(spacing: 6) {
                            Text(todayHijriDateString)
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(HasanaTheme.gold)
                                .shadow(color: HasanaTheme.gold.opacity(0.12), radius: 4)
                            
                            Text(todayGregorianDateString)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(HasanaTheme.textMuted)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        
                        // 2. Qibla & Calendar Horizontal Cards Row
                        HStack(spacing: 16) {
                            // Qibla Widget Shortcut
                            Button {
                                isShowingQibla = true
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(HasanaTheme.accent.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "safari.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(HasanaTheme.accent)
                                    }
                                    
                                    Text(language == .arabic ? "اتجاه القبلة" : "Qibla Finder")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textPrimary)
                                    
                                    Text(language == .arabic ? "بوصلة تفاعلية سريعة" : "Live compass direction")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                                }
                            }
                            
                            // Calendar Widget Shortcut
                            Button {
                                isShowingCalendar = true
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(HasanaTheme.gold.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "calendar")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(HasanaTheme.gold)
                                    }
                                    
                                    Text(language == .arabic ? "التقويم والمناسبات" : "Hijri Calendar")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textPrimary)
                                    
                                    Text(language == .arabic ? "تتبع الأيام الفاضلة" : "Holy events & dates")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. Habit Tracker Quick Dashboard Widget
                        Button {
                            isShowingHabitTracker = true
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(HasanaTheme.summary.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(HasanaTheme.summary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(language == .arabic ? "مؤشر الالتزام اليومي" : "Habit Streaks Tracker")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(HasanaTheme.textPrimary)
                                        
                                        Text(language == .arabic ? "عاداتك وأورادك المضافة" : "Daily custom goals")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(HasanaTheme.textMuted)
                                    }
                                    Spacer()
                                    
                                    Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                                
                                // Progress Bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(HasanaTheme.border.opacity(0.32))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [HasanaTheme.summary, HasanaTheme.accent],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(geometry.size.width * CGFloat(todayHabitCompletion), 0), height: 8)
                                    }
                                }
                                .frame(height: 8)
                                .padding(.top, 4)
                                
                                HStack {
                                    Text(String(format: language == .arabic ? "تم إنجاز %.0f%%" : "%.0f%% Completed Today", todayHabitCompletion * 100))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(HasanaTheme.summary)
                                    Spacer()
                                    Text("\(activeHabitsCount) \(language == .arabic ? "عادات نشطة" : "Active Habits")")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                            }
                            .padding()
                            .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        // 4. Dua of the Day Card
                        Button {
                            isShowingDuaLibrary = true
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(HasanaTheme.reflection.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "sparkle")
                                            .font(.system(size: 16))
                                            .foregroundStyle(HasanaTheme.reflection)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(language == .arabic ? "ذكر اليوم المقترح" : "Suggested Daily Dua")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(HasanaTheme.textPrimary)
                                        
                                        Text(language == .arabic ? "حصن المسلم" : "Hisn al-Muslim")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(HasanaTheme.textMuted)
                                    }
                                    Spacer()
                                    
                                    Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                                
                                // Dua Title
                                Text(dailyDua.title(for: language))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.gold)
                                
                                // Dua Arabic text (Small preview)
                                Text(dailyDua.arabic)
                                    .font(.system(size: 15, weight: .medium, design: .serif))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(HasanaTheme.accentSoft.opacity(0.24), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .padding()
                            .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(language == .arabic ? "المركز الإسلامي" : "Islamic Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $isShowingQibla) {
                QiblaCompassView(language: language)
            }
            .sheet(isPresented: $isShowingCalendar) {
                HijriCalendarView(language: language)
            }
            .sheet(isPresented: $isShowingDuaLibrary) {
                DuaLibraryView(language: language)
            }
            .sheet(isPresented: $isShowingHabitTracker) {
                HabitTrackerView(language: language, selectedDayKey: selectedDayKey, onLoggedHabit: { practiceID in
                    onLoggedWorship(practiceID)
                    loadHabitStats()
                })
            }
            .onAppear {
                pickDailyDua()
                loadHabitStats()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    // MARK: - Helper calculations
    private var todayHijriDateString: String {
        let date = Date()
        let day = hijriCalendar.component(.day, from: date)
        let month = hijriCalendar.component(.month, from: date)
        let year = hijriCalendar.component(.year, from: date)
        let monthName = language == .arabic ? hijriMonthNamesAr[month - 1] : hijriMonthNamesEn[month - 1]
        
        return language == .arabic ? "\(day) \(monthName) \(year) هـ" : "\(day) \(monthName) \(year) AH"
    }
    
    private var todayGregorianDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    private func pickDailyDua() {
        // Simple day-of-month picker for daily variety
        let day = Calendar.current.component(.day, from: Date())
        let index = day % DuaItem.defaults.count
        dailyDua = DuaItem.defaults[index]
    }
    
    private func loadHabitStats() {
        // Load custom habits
        var habitsList: [SpiritualHabit] = []
        if let data = UserDefaults.standard.data(forKey: "hasana.habits.list") {
            if let decoded = try? JSONDecoder().decode([SpiritualHabit].self, from: data) {
                habitsList = decoded
            }
        } else {
            habitsList = SpiritualHabit.defaults
        }
        
        activeHabitsCount = habitsList.count
        
        var logsList: [HabitLog] = []
        if let data = UserDefaults.standard.data(forKey: "hasana.habits.logs") {
            if let decoded = try? JSONDecoder().decode([HabitLog].self, from: data) {
                logsList = decoded
            }
        }
        
        if habitsList.isEmpty {
            todayHabitCompletion = 0.0
            return
        }
        
        // Sum progress fractions
        var totalFraction = 0.0
        for habit in habitsList {
            let count = logsList.first { $0.habitID == habit.id && $0.dateKey == selectedDayKey }?.count ?? 0
            let fraction = Double(count) / Double(habit.targetCount)
            totalFraction += min(fraction, 1.0)
        }
        
        todayHabitCompletion = totalFraction / Double(habitsList.count)
    }
}

#Preview {
    IslamicHubView(language: .english, selectedDayKey: "2026-05-26", onLoggedWorship: { _ in })
}
