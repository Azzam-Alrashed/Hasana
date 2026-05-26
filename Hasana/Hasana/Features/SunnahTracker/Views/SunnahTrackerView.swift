import SwiftUI

struct SunnahTrackerView: View {
    let language: HasanaLanguage
    let selectedDayKey: String
    let onLoggedSunnah: () -> Void
    
    @State private var record = SunnahDayRecord(dateKey: "")
    @State private var showSadaqahDialog = false
    @State private var sadaqahText = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Rawatib Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(language == .arabic ? "السنن الرواتب (١٢ ركعة)" : "Rawatib Sunnah (12 Rakahs)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(HasanaTheme.textPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                rawatibToggle(id: "fajr_sunnah", titleAr: "ركعتان قبل الفجر", titleEn: "2 Rakahs before Fajr")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                rawatibToggle(id: "dhuhr_before", titleAr: "أربع ركعات قبل الظهر", titleEn: "4 Rakahs before Dhuhr")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                rawatibToggle(id: "dhuhr_after", titleAr: "ركعتان بعد الظهر", titleEn: "2 Rakahs after Dhuhr")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                rawatibToggle(id: "maghrib_sunnah", titleAr: "ركعتان بعد المغرب", titleEn: "2 Rakahs after Maghrib")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                rawatibToggle(id: "isha_sunnah", titleAr: "ركعتان بعد العشاء", titleEn: "2 Rakahs after Isha")
                            }
                            .padding(.vertical, 8)
                            .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Extra Sunnahs Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(language == .arabic ? "النوافل والسنن الأخرى" : "Other Sunnah Prayers & Fasting")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(HasanaTheme.textPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                sunnahToggle(isOn: $record.performedDuha, titleAr: "صلاة الضحى", titleEn: "Duha Prayer", icon: "sun.max.fill", color: HasanaTheme.gold)
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                sunnahToggle(isOn: $record.performedQiyam, titleAr: "قيام الليل", titleEn: "Qiyam al-Layl", icon: "moon.stars.fill", color: HasanaTheme.summary)
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                sunnahToggle(isOn: $record.performedWitr, titleAr: "صلاة الوتر", titleEn: "Witr Prayer", icon: "moon.zzz.fill", color: HasanaTheme.reflection)
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                sunnahToggle(isOn: $record.fastedToday, titleAr: "صيام اليوم", titleEn: "Fasting Today", icon: "flame.fill", color: HasanaTheme.finance)
                            }
                            .padding(.vertical, 8)
                            .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Sadaqah (Charity) Logger Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text(language == .arabic ? "العطاء والصدقة اليومية" : "Daily Sadaqah & Giving")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(HasanaTheme.textPrimary)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 14) {
                                if record.sadaqahLogged {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "heart.text.square.fill")
                                            .font(.system(size: 28))
                                            .foregroundStyle(HasanaTheme.finance)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(language == .arabic ? "تم تسجيل صدقة اليوم" : "Sadaqah logged for today")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(HasanaTheme.textPrimary)
                                            
                                            if let note = record.sadaqahNote, !note.isEmpty {
                                                Text(note)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(HasanaTheme.textMuted)
                                            }
                                        }
                                        Spacer()
                                        
                                        Button {
                                            deleteSadaqah()
                                        } label: {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(HasanaTheme.textMuted)
                                        }
                                    }
                                } else {
                                    Text(language == .arabic ? "كل معروف صدقة. ابتسامتك، مساعدتك للآخرين، أو الكلمة الطيبة تعد صدقة." : "Every good deed is charity. A smile, helping a colleague, or a kind word counts as Sadaqah.")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Button {
                                        showSadaqahDialog = true
                                    } label: {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "heart.fill")
                                            Text(language == .arabic ? "سجل عملاً صالحًا" : "Log a Good Deed")
                                            Spacer()
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 12)
                                        .background(HasanaTheme.finance, in: Capsule())
                                    }
                                }
                            }
                            .padding()
                            .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(language == .arabic ? "السنن والصدقات" : "Sunnah & Sadaqah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $showSadaqahDialog) {
                sadaqahLogSheet
            }
            .onAppear {
                loadRecord()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private func rawatibToggle(id: String, titleAr: String, titleEn: String) -> some View {
        HStack {
            Text(language == .arabic ? titleAr : titleEn)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(HasanaTheme.textPrimary)
            
            Spacer()
            
            let isSelected = record.performedRawatib.contains(id)
            Button {
                toggleRawatib(id)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? HasanaTheme.accent : HasanaTheme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func sunnahToggle(isOn: Binding<Bool>, titleAr: String, titleEn: String, icon: String, color: Color) -> some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(language == .arabic ? titleAr : titleEn)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HasanaTheme.textPrimary)
            }
            
            Spacer()
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                isOn.wrappedValue.toggle()
                saveRecord()
                onLoggedSunnah()
            } label: {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isOn.wrappedValue ? HasanaTheme.accent : HasanaTheme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var sadaqahLogSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(language == .arabic ? "ما العمل الصالح الذي قدمته؟" : "What good deed did you do?")) {
                    TextField(language == .arabic ? "مثال: الابتسامة في وجه أخيك صدقة..." : "Example: Fed a stray animal, helped a neighbor...", text: $sadaqahText, axis: .vertical)
                        .lineLimit(3...6)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                }
            }
            .navigationTitle(language == .arabic ? "تسجيل عمل صالح" : "Log Sadaqah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "إلغاء" : "Cancel") {
                        showSadaqahDialog = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .arabic ? "تسجيل" : "Log") {
                        if !sadaqahText.isEmpty {
                            record.sadaqahLogged = true
                            record.sadaqahNote = sadaqahText
                            saveRecord()
                            onLoggedSunnah()
                            sadaqahText = ""
                            showSadaqahDialog = false
                            
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private func toggleRawatib(_ id: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if record.performedRawatib.contains(id) {
            record.performedRawatib.removeAll { $0 == id }
        } else {
            record.performedRawatib.append(id)
        }
        saveRecord()
        onLoggedSunnah()
    }
    
    private func deleteSadaqah() {
        record.sadaqahLogged = false
        record.sadaqahNote = nil
        saveRecord()
        onLoggedSunnah()
    }
    
    private func loadRecord() {
        let key = "hasana.sunnah.record.\(selectedDayKey)"
        if let data = UserDefaults.standard.data(forKey: key) {
            if let decoded = try? JSONDecoder().decode(SunnahDayRecord.self, from: data) {
                record = decoded
                return
            }
        }
        record = SunnahDayRecord(dateKey: selectedDayKey)
    }
    
    private func saveRecord() {
        record.dateKey = selectedDayKey
        let key = "hasana.sunnah.record.\(selectedDayKey)"
        if let data = try? JSONEncoder().encode(record) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
