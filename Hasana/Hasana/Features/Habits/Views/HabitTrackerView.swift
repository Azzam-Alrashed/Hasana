import SwiftUI

struct HabitTrackerView: View {
    let language: HasanaLanguage
    let selectedDayKey: String // YYYY-MM-DD
    let onLoggedHabit: (String) -> Void // Callback when habit linked to garden is updated
    
    @State private var habits: [SpiritualHabit] = []
    @State private var logs: [HabitLog] = []
    
    // Sheet presentation
    @State private var isShowingAddHabit = false
    
    // Form fields for new Habit
    @State private var newTitleAr = ""
    @State private var newTitleEn = ""
    @State private var targetCount = 1
    @State private var selectedIcon = "heart.fill"
    @State private var selectedColorHex = "#D5A754"
    @State private var linkToGarden = false
    @State private var selectedGardenPractice = "fard"
    
    @Environment(\.dismiss) private var dismiss
    
    private let availableIcons = [
        "heart.fill", "sparkles", "book.fill", "mosque.fill", "bell.fill",
        "star.fill", "hands.clap.fill", "hand.raised.fill", "gift.fill", "sun.max.fill"
    ]
    
    private let availableColors = [
        "#D5A754", "#9A6234", "#5F6596", "#706086", "#64B5F6", "#E9C883", "#E0A267", "#A9AEE8"
    ]
    
    private let gardenPractices = [
        ("fard", "الصلوات المفروضة", "Obligatory Prayers"),
        ("quran", "ورد القرآن الكريم", "Quran Recitation"),
        ("adhkar", "الأذكار والتسابيح", "Morning/Evening Adhkar"),
        ("witr", "صلاة الوتر والنوافل", "Witr & Sunnahs")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Quick Streaks Banner
                        HStack(spacing: 16) {
                            streakCard(
                                icon: "flame.fill",
                                value: "\(calculateOverallStreak())",
                                label: language == .arabic ? "سلسلة الالتزام" : "Spiritual Streak",
                                color: HasanaTheme.finance
                            )
                            
                            streakCard(
                                icon: "checkmark.seal.fill",
                                value: "\(calculateCompletionsToday())",
                                label: language == .arabic ? "أنجزت اليوم" : "Done Today",
                                color: HasanaTheme.accent
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // Habit Header
                        HStack {
                            Text(language == .arabic ? "أورادي وعاداتي اليومية" : "Spiritual Habits")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(HasanaTheme.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                isShowingAddHabit = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text(language == .arabic ? "عادت جديدة" : "New Habit")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(HasanaTheme.accent, in: Capsule())
                            }
                        }
                        .padding(.horizontal)
                        
                        if habits.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 48))
                                    .foregroundStyle(HasanaTheme.textMuted.opacity(0.48))
                                
                                Text(language == .arabic ? "لا يوجد عادات مضافة بعد" : "No habits added yet")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                
                                Text(language == .arabic ? "اضغط على زر عادت جديدة للبدء في تتبع التزامك اليومي" : "Tap 'New Habit' to build your customized spiritual schedule")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(HasanaTheme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            // Habits listing
                            LazyVStack(spacing: 16) {
                                ForEach(habits) { habit in
                                    habitRowCard(habit: habit)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(language == .arabic ? "مستشعر العادات الروحية" : "Spiritual Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $isShowingAddHabit) {
                addHabitSheet
            }
            .onAppear {
                loadData()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    // Add Habit Sheet View
    private var addHabitSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(language == .arabic ? "اسم العادة والهدف" : "Habit Name & Goal")) {
                    TextField(language == .arabic ? "العادة بالعربية (مثال: قراءة أذكار الصباح)" : "Name (Arabic)", text: $newTitleAr)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    
                    TextField(language == .arabic ? "العادة بالإنجليزية" : "Name (English)", text: $newTitleEn)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    
                    Stepper(value: $targetCount, in: 1...100) {
                        Text("\(language == .arabic ? "الهدف اليومي:" : "Daily Target:") \(targetCount)")
                    }
                }
                
                Section(header: Text(language == .arabic ? "المظهر والرمز" : "Appearance & Icon")) {
                    // Icon picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(selectedIcon == icon ? .white : HasanaTheme.textPrimary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? HasanaTheme.accent : HasanaTheme.elevatedSurfaceSoft, in: Circle())
                                        .overlay {
                                            if selectedIcon != icon {
                                                Circle().stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Color picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { colorHex in
                                Button {
                                    selectedColorHex = colorHex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Circle()
                                                .stroke(selectedColorHex == colorHex ? Color.white : Color.clear, lineWidth: 2)
                                        }
                                        .shadow(color: Color(hex: colorHex).opacity(0.4), radius: 4)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text(language == .arabic ? "ربط بحديقة حسنة" : "Link to Hasana Garden")) {
                    Toggle(language == .arabic ? "اربط بتمثيل نباتات الحديقة" : "Link completions to Garden plants", isOn: $linkToGarden)
                    
                    if linkToGarden {
                        Picker(language == .arabic ? "اختر النبتة" : "Target Plant", selection: $selectedGardenPractice) {
                            ForEach(gardenPractices, id: \.0) { item in
                                Text(language == .arabic ? item.1 : item.2)
                                    .tag(item.0)
                            }
                        }
                    }
                }
            }
            .navigationTitle(language == .arabic ? "إضافة عادة مخصصة" : "Add Spiritual Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "إلغاء" : "Cancel") {
                        isShowingAddHabit = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .arabic ? "حفظ" : "Save") {
                        saveNewHabit()
                    }
                    .disabled(newTitleAr.isEmpty)
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    // Streak Widget UI Component
    private func streakCard(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .monospacedDigit()
                
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HasanaTheme.textMuted)
            }
            Spacer()
        }
        .padding()
        .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
        }
    }
    
    // Row Item card displaying habit status
    @ViewBuilder
    private func habitRowCard(habit: SpiritualHabit) -> some View {
        let currentCount = getLogCount(for: habit.id)
        let isDone = currentCount >= habit.targetCount
        let fraction = Double(currentCount) / Double(habit.targetCount)
        
        HStack(spacing: 16) {
            // Habit Icon
            ZStack {
                Circle()
                    .fill(habit.themeColor.opacity(0.12))
                    .frame(width: 46, height: 46)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(habit.themeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title(for: language))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .strikethrough(isDone, color: HasanaTheme.textMuted.opacity(0.4))
                
                // Target count details
                Text("\(currentCount)/\(habit.targetCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isDone ? HasanaTheme.accent : HasanaTheme.textMuted)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Adjust buttons row
            HStack(spacing: 8) {
                // Minus count
                Button {
                    updateCount(for: habit, delta: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(HasanaTheme.elevatedSurfaceSoft, in: Circle())
                }
                .disabled(currentCount == 0)
                
                // Plus count
                Button {
                    updateCount(for: habit, delta: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(habit.themeColor, in: Circle())
                }
                .disabled(isDone)
                
                // Delete habit
                Button {
                    deleteHabit(habit)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1), in: Circle())
                }
            }
        }
        .padding()
        .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isDone ? HasanaTheme.accent.opacity(0.6) : HasanaTheme.border.opacity(0.48), lineWidth: isDone ? 1.2 : 0.8)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Logic Calculations
    private func getLogCount(for habitID: UUID) -> Int {
        logs.first { $0.habitID == habitID && $0.dateKey == selectedDayKey }?.count ?? 0
    }
    
    private func updateCount(for habit: SpiritualHabit, delta: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if let idx = logs.firstIndex(where: { $0.habitID == habit.id && $0.dateKey == selectedDayKey }) {
            let newVal = max(logs[idx].count + delta, 0)
            logs[idx].count = newVal
        } else {
            let newVal = max(delta, 0)
            let log = HabitLog(habitID: habit.id, count: newVal, dateKey: selectedDayKey)
            logs.append(log)
        }
        
        saveData()
        
        // Notify Garden Store of linkages
        if habit.isLinkedToGarden, let practiceID = habit.gardenPracticeID {
            let currentCount = getLogCount(for: habit.id)
            if currentCount >= habit.targetCount {
                onLoggedHabit(practiceID)
            }
        }
    }
    
    private func calculateCompletionsToday() -> Int {
        habits.filter { habit in
            let count = getLogCount(for: habit.id)
            return count >= habit.targetCount
        }.count
    }
    
    private func calculateOverallStreak() -> Int {
        // Mock streak calculation based on dates completed
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        // Check days backward to see if habits were completed
        for _ in 0..<30 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let key = formatter.string(from: checkDate)
            
            let dayCompletions = habits.filter { habit in
                let count = logs.first { $0.habitID == habit.id && $0.dateKey == key }?.count ?? 0
                return count >= habit.targetCount
            }.count
            
            if dayCompletions > 0 {
                streak += 1
            } else {
                break
            }
            
            // Go back 1 day
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = yesterday
        }
        
        return streak
    }
    
    private func saveNewHabit() {
        let titleAr = newTitleAr
        let titleEn = newTitleEn.isEmpty ? titleAr : newTitleEn
        
        let habit = SpiritualHabit(
            titleAr: titleAr,
            titleEn: titleEn,
            frequency: "daily",
            targetCount: targetCount,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            isLinkedToGarden: linkToGarden,
            gardenPracticeID: linkToGarden ? selectedGardenPractice : nil
        )
        
        habits.append(habit)
        saveData()
        
        // Reset Form
        newTitleAr = ""
        newTitleEn = ""
        targetCount = 1
        linkToGarden = false
        isShowingAddHabit = false
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func deleteHabit(_ habit: SpiritualHabit) {
        habits.removeAll { $0.id == habit.id }
        logs.removeAll { $0.habitID == habit.id }
        saveData()
    }
    
    private func loadData() {
        // Load custom habits
        if let data = UserDefaults.standard.data(forKey: "hasana.habits.list") {
            if let decoded = try? JSONDecoder().decode([SpiritualHabit].self, from: data) {
                habits = decoded
            }
        } else {
            // Load default pre-seeded habits on first run
            habits = SpiritualHabit.defaults
            saveData()
        }
        
        // Load completion logs
        if let data = UserDefaults.standard.data(forKey: "hasana.habits.logs") {
            if let decoded = try? JSONDecoder().decode([HabitLog].self, from: data) {
                logs = decoded
            }
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: "hasana.habits.list")
        }
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: "hasana.habits.logs")
        }
    }
}

#Preview {
    HabitTrackerView(language: .english, selectedDayKey: "2026-05-26", onLoggedHabit: { _ in })
}
