import SwiftUI

struct QuranJournalView: View {
    let language: HasanaLanguage
    let onLoggedQuran: () -> Void
    
    @State private var goal = KhatmGoal()
    @State private var reflections: [QuranReflection] = []
    
    @State private var isShowingAddReflection = false
    @State private var isShowingGoalSetup = false
    
    // Form fields for new reflection
    @State private var newSurah = ""
    @State private var newVerse = ""
    @State private var newArabic = ""
    @State private var newNote = ""
    
    // Page logging field
    @State private var logPagesCount = 1
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Goal progress card
                        VStack(spacing: 18) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(language == .arabic ? "ختم القرآن الكريم" : "Khatm Goal Tracker")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textPrimary)
                                    
                                    Text("\(language == .arabic ? "الهدف:" : "Goal:") \(goal.targetDays) \(language == .arabic ? "يومًا" : "days")")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                                
                                Spacer()
                                
                                Button {
                                    isShowingGoalSetup = true
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(HasanaTheme.accent)
                                }
                            }
                            
                            // ProgressBar
                            VStack(spacing: 6) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(HasanaTheme.border.opacity(0.48))
                                            .frame(height: 10)
                                        
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [HasanaTheme.gold, HasanaTheme.accent],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(geometry.size.width * CGFloat(goal.progressFraction), 0), height: 10)
                                    }
                                }
                                .frame(height: 10)
                                
                                HStack {
                                    Text("\(language == .arabic ? "الصفحة" : "Page") \(goal.currentPage)/604")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textPrimary)
                                        .monospacedDigit()
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f%%", goal.progressFraction * 100))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(HasanaTheme.gold)
                                        .monospacedDigit()
                                }
                            }
                            
                            // Daily Target Indicator
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(language == .arabic ? "المطلوب اليوم" : "Required Today")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                    
                                    Text(String(format: language == .arabic ? "%.1f صفحة" : "%.1f pages", goal.pagesPerDayRequired))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(HasanaTheme.accent)
                                        .monospacedDigit()
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(language == .arabic ? "الأيام المتبقية" : "Days Left")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                    
                                    Text("\(goal.daysRemaining) \(language == .arabic ? "يوم" : "days")")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textPrimary)
                                }
                            }
                            .padding(.top, 4)
                            
                            // Log Pages Input
                            HStack(spacing: 12) {
                                Stepper(value: $logPagesCount, in: 1...100) {
                                    Text("\(language == .arabic ? "قرأت:" : "Read:") \(logPagesCount) \(language == .arabic ? "صفحة" : "pages")")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                
                                Button {
                                    logPagesRead()
                                } label: {
                                    Text(language == .arabic ? "تسجيل" : "Log")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(HasanaTheme.accent, in: Capsule())
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        
                        // Reflections Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(language == .arabic ? "دفتر التدبر والخواطر" : "Reflections & Tadabbur")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                
                                Spacer()
                                
                                Button {
                                    isShowingAddReflection = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                        Text(language == .arabic ? "تدبر آية" : "New Note")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(HasanaTheme.gold, in: Capsule())
                                }
                            }
                            .padding(.horizontal)
                            
                            if reflections.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "book.closed.fill")
                                        .font(.system(size: 38))
                                        .foregroundStyle(HasanaTheme.textMuted.opacity(0.48))
                                    
                                    Text(language == .arabic ? "لم تقم بتسجيل أي تدبر بعد" : "No reflections logged yet")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                ForEach(reflections) { note in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("\(language == .arabic ? "سورة" : "Surah") \(note.surahName)")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(HasanaTheme.gold)
                                            
                                            Text(":\(note.verseNumber)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(HasanaTheme.textMuted)
                                            
                                            Spacer()
                                            
                                            Text(formatDate(note.date))
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(HasanaTheme.textMuted)
                                        }
                                        
                                        if let arabic = note.arabicText, !arabic.isEmpty {
                                            Text(arabic)
                                                .font(.system(size: 16, weight: .medium, design: .serif))
                                                .foregroundStyle(HasanaTheme.textPrimary)
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity)
                                                .padding(10)
                                                .background(HasanaTheme.accentSoft.opacity(0.44), in: RoundedRectangle(cornerRadius: 8))
                                        }
                                        
                                        Text(note.reflectionText)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(HasanaTheme.textPrimary.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding()
                                    .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(language == .arabic ? "ورد القرآن والتدبر" : "Quran & Tadabbur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $isShowingGoalSetup) {
                goalSetupSheet
            }
            .sheet(isPresented: $isShowingAddReflection) {
                addReflectionSheet
            }
            .onAppear {
                loadData()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private var goalSetupSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(language == .arabic ? "إعداد الهدف" : "Khatm Goal Setup")) {
                    Stepper(value: $goal.targetDays, in: 5...365) {
                        Text("\(language == .arabic ? "المدة المستهدفة:" : "Target Days:") \(goal.targetDays)")
                    }
                    
                    Stepper(value: $goal.currentPage, in: 1...604) {
                        Text("\(language == .arabic ? "الصفحة الحالية:" : "Current Page:") \(goal.currentPage)")
                    }
                }
            }
            .navigationTitle(language == .arabic ? "تحديث الهدف" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .arabic ? "حفظ" : "Save") {
                        saveData()
                        isShowingGoalSetup = false
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private var addReflectionSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(language == .arabic ? "معلومات الآية" : "Verse Information")) {
                    TextField(language == .arabic ? "اسم السورة" : "Surah Name", text: $newSurah)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    TextField(language == .arabic ? "رقم الآية" : "Verse Number", text: $newVerse)
                        .keyboardType(.numberPad)
                    
                    TextField(language == .arabic ? "نص الآية (اختياري)" : "Verse Text (Optional)", text: $newArabic, axis: .vertical)
                        .lineLimit(2...4)
                        .multilineTextAlignment(.center)
                }
                
                Section(header: Text(language == .arabic ? "تدبرات وخواطر" : "Reflections")) {
                    TextField(language == .arabic ? "اكتب هنا خواطرك وتدبرك للآية..." : "Write your Tadabbur notes here...", text: $newNote, axis: .vertical)
                        .lineLimit(4...8)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                }
            }
            .navigationTitle(language == .arabic ? "تدبر آية جديدة" : "Add Tadabbur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "إلغاء" : "Cancel") {
                        isShowingAddReflection = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .arabic ? "حفظ" : "Save") {
                        if !newSurah.isEmpty && !newVerse.isEmpty && !newNote.isEmpty {
                            let note = QuranReflection(
                                surahName: newSurah,
                                verseNumber: newVerse,
                                arabicText: newArabic.isEmpty ? nil : newArabic,
                                reflectionText: newNote
                            )
                            reflections.insert(note, at: 0)
                            saveData()
                            onLoggedQuran()
                            isShowingAddReflection = false
                            
                            // Reset
                            newSurah = ""
                            newVerse = ""
                            newArabic = ""
                            newNote = ""
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private func logPagesRead() {
        goal.currentPage = min(goal.currentPage + logPagesCount, 604)
        if goal.currentPage >= 604 {
            goal.isCompleted = true
        }
        saveData()
        onLoggedQuran()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "hasana.quran.goal") {
            if let decoded = try? JSONDecoder().decode(KhatmGoal.self, from: data) {
                goal = decoded
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "hasana.quran.reflections") {
            if let decoded = try? JSONDecoder().decode([QuranReflection].self, from: data) {
                reflections = decoded
            }
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(goal) {
            UserDefaults.standard.set(data, forKey: "hasana.quran.goal")
        }
        
        if let data = try? JSONEncoder().encode(reflections) {
            UserDefaults.standard.set(data, forKey: "hasana.quran.reflections")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
