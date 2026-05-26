import SwiftUI
import AVFoundation

struct DuaLibraryView: View {
    let language: HasanaLanguage
    
    @State private var searchField = ""
    @State private var selectedTab = 0 // 0: Categories, 1: Bookmarks, 2: My Duas
    @State private var selectedCategory: String? = nil
    
    // Core state loaded from UserDefaults
    @State private var builtInDuas: [DuaItem] = DuaItem.defaults
    @State private var customDuas: [DuaItem] = []
    
    // Sheet presentation
    @State private var isShowingAddDua = false
    
    // Form fields for Custom Dua
    @State private var customTitleAr = ""
    @State private var customTitleEn = ""
    @State private var customArabic = ""
    @State private var customTranslationAr = ""
    @State private var customTranslationEn = ""
    @State private var customTransliteration = ""
    @State private var customCategoryAr = "أدعية خاصة"
    @State private var customCategoryEn = "Custom Duas"
    
    // Audio Player TTS
    @State private var speakingDuaID: UUID? = nil
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @Environment(\.dismiss) private var dismiss
    
    private var allDuas: [DuaItem] {
        builtInDuas + customDuas
    }
    
    private var categories: [String] {
        let allCategories = allDuas.map { $0.category(for: language) }
        return Array(Set(allCategories)).sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented controller tabs
                    Picker("", selection: $selectedTab) {
                        Text(language == .arabic ? "الأقسام" : "Categories").tag(0)
                        Text(language == .arabic ? "المفضلة" : "Bookmarks").tag(1)
                        Text(language == .arabic ? "أدعيتي" : "My Duas").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(HasanaTheme.textMuted)
                        
                        TextField(language == .arabic ? "ابحث عن دعاء أو ذكر..." : "Search Duas...", text: $searchField)
                            .textFieldStyle(.plain)
                            .foregroundStyle(HasanaTheme.textPrimary)
                            .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                        
                        if !searchField.isEmpty {
                            Button {
                                searchField = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(HasanaTheme.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HasanaTheme.elevatedSurface.opacity(0.68), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    
                    if selectedTab == 0 {
                        // Categories tab
                        if let activeCategory = selectedCategory {
                            // Category details listing
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Button {
                                        withAnimation {
                                            selectedCategory = nil
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: language == .arabic ? "chevron.right" : "chevron.left")
                                            Text(language == .arabic ? "العودة للأقسام" : "Back")
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(HasanaTheme.accent)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 4)
                                
                                ScrollView {
                                    LazyVStack(spacing: 16) {
                                        let filtered = allDuas.filter { $0.category(for: language) == activeCategory && matchesSearch($0) }
                                        if filtered.isEmpty {
                                            emptyStateView(message: language == .arabic ? "لا يوجد نتائج مطابقة للبحث" : "No matching Duas found")
                                        } else {
                                            ForEach(filtered) { item in
                                                DuaCard(item: item)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 24)
                                }
                            }
                        } else {
                            // Category grid
                            ScrollView {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ],
                                    spacing: 16
                                ) {
                                    ForEach(categories, id: \.self) { category in
                                        Button {
                                            withAnimation {
                                                selectedCategory = category
                                            }
                                        } label: {
                                            VStack(alignment: .leading, spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(HasanaTheme.accent.opacity(0.12))
                                                        .frame(width: 44, height: 44)
                                                    
                                                    Image(systemName: getCategoryIcon(category))
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundStyle(HasanaTheme.accent)
                                                }
                                                
                                                Text(category)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(HasanaTheme.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(2)
                                                
                                                let count = allDuas.filter { $0.category(for: language) == category }.count
                                                Text("\(count) \(language == .arabic ? "أذكار" : "Duas")")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(HasanaTheme.textMuted)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                                            .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .padding(.bottom, 24)
                            }
                        }
                    } else if selectedTab == 1 {
                        // Bookmarks Tab
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                let bookmarked = allDuas.filter { $0.isBookmarked && matchesSearch($0) }
                                if bookmarked.isEmpty {
                                    emptyStateView(
                                        message: language == .arabic ? "لم تقم بإضافة أي ذكر للمفضلة بعد" : "No bookmarked Duas yet",
                                        subMessage: language == .arabic ? "اضغط على رمز النجمة لحفظ الأذكار الهامة" : "Tap the star icon on any card to save it here"
                                    )
                                } else {
                                    ForEach(bookmarked) { item in
                                        DuaCard(item: item)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    } else {
                        // My Duas Tab
                        VStack(spacing: 12) {
                            HStack {
                                Spacer()
                                Button {
                                    isShowingAddDua = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                        Text(language == .arabic ? "أضف دعاءً مخصصاً" : "Add Custom Dua")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(HasanaTheme.accent, in: Capsule())
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    let customs = customDuas.filter { matchesSearch($0) }
                                    if customs.isEmpty {
                                        emptyStateView(
                                            message: language == .arabic ? "لم تقم بكتابة أي دعاء مخصص بعد" : "No custom Duas written yet",
                                            subMessage: language == .arabic ? "احفظ أدعيتك الخاصة وأورادك لتستعرضها هنا" : "Create custom prayers or personal Duas to access them easily"
                                        )
                                    } else {
                                        ForEach(customs) { item in
                                            DuaCard(item: item)
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
            }
            .navigationTitle(language == .arabic ? "حصن المسلم والأدعية" : "Dua & Adhkar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        speechSynthesizer.stopSpeaking(at: .immediate)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $isShowingAddDua) {
                addDuaSheet
            }
            .onAppear {
                loadData()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    // Add custom Dua view
    private var addDuaSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(language == .arabic ? "عنوان الدعاء" : "Dua Title")) {
                    TextField(language == .arabic ? "العنوان بالعربية" : "Title (Arabic)", text: $customTitleAr)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    TextField(language == .arabic ? "العنوان بالإنجليزية" : "Title (English)", text: $customTitleEn)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                }
                
                Section(header: Text(language == .arabic ? "نص الدعاء" : "Dua Text")) {
                    TextField(language == .arabic ? "النص العربي كامل بالتسكين أو الحركات" : "Arabic text...", text: $customArabic, axis: .vertical)
                        .lineLimit(4...8)
                        .multilineTextAlignment(.center)
                }
                
                Section(header: Text(language == .arabic ? "الترجمة والنطق (اختياري)" : "Translation & Transliteration (Optional)")) {
                    TextField(language == .arabic ? "الترجمة العربية" : "Arabic translation", text: $customTranslationAr, axis: .vertical)
                        .lineLimit(2...4)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    
                    TextField(language == .arabic ? "الترجمة الإنجليزية" : "English translation", text: $customTranslationEn, axis: .vertical)
                        .lineLimit(2...4)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    
                    TextField(language == .arabic ? "كتابة اللفظ بالحروف اللاتينية" : "Latin Transliteration", text: $customTransliteration, axis: .vertical)
                        .lineLimit(2...4)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                }
            }
            .navigationTitle(language == .arabic ? "كتابة دعاء جديد" : "Write Custom Dua")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "إلغاء" : "Cancel") {
                        isShowingAddDua = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .arabic ? "حفظ" : "Save") {
                        saveCustomDua()
                    }
                    .disabled(customTitleAr.isEmpty || customArabic.isEmpty)
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    // Custom Card for displaying Duas
    @ViewBuilder
    private func DuaCard(item: DuaItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Category + bookmark button
            HStack {
                Text(item.category(for: language).uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(HasanaTheme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HasanaTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                // Copy Button
                Button {
                    copyToClipboard(item)
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .frame(width: 28, height: 28)
                        .background(HasanaTheme.elevatedSurfaceSoft, in: Circle())
                }
                
                // TTS Audio speaker Button
                Button {
                    toggleSpeech(for: item)
                } label: {
                    Image(systemName: speakingDuaID == item.id ? "stop.fill" : "speaker.wave.2.bubble.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(speakingDuaID == item.id ? HasanaTheme.accent : HasanaTheme.textMuted)
                        .frame(width: 28, height: 28)
                        .background(speakingDuaID == item.id ? HasanaTheme.accent.opacity(0.14) : HasanaTheme.elevatedSurfaceSoft, in: Circle())
                }
                
                // Delete button for custom ones
                if item.isCustom {
                    Button {
                        deleteCustomDua(item)
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.red.opacity(0.1), in: Circle())
                    }
                }
                
                // Bookmark Toggle Button
                Button {
                    toggleBookmark(for: item)
                } label: {
                    Image(systemName: item.isBookmarked ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.isBookmarked ? HasanaTheme.accent : HasanaTheme.textMuted)
                        .frame(width: 28, height: 28)
                        .background(item.isBookmarked ? HasanaTheme.accent.opacity(0.14) : HasanaTheme.elevatedSurfaceSoft, in: Circle())
                }
            }
            
            // Title
            Text(item.title(for: language))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(HasanaTheme.textPrimary)
            
            // Arabic Text (Centered and large)
            Text(item.arabic)
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundStyle(HasanaTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(HasanaTheme.accentSoft.opacity(0.24), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(HasanaTheme.accentSoft.opacity(0.44), lineWidth: 0.8)
                }
            
            // Transliteration
            if let translit = item.transliteration, !translit.isEmpty {
                Text(translit)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .italic()
                    .lineSpacing(4)
            }
            
            // Translation
            if let transl = item.translation(for: language), !transl.isEmpty {
                Text(transl)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HasanaTheme.textPrimary.opacity(0.85))
                    .lineSpacing(4)
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
    
    @ViewBuilder
    private func emptyStateView(message: String, subMessage: String? = nil) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 44))
                .foregroundStyle(HasanaTheme.textMuted.opacity(0.48))
            
            Text(message)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(HasanaTheme.textPrimary)
            
            if let sub = subMessage {
                Text(sub)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
    
    // MARK: - Logic Helper functions
    private func getCategoryIcon(_ category: String) -> String {
        if category.contains("اليومية") || category.contains("Daily") {
            return "sun.max.fill"
        } else if category.contains("الصلاة") || category.contains("Prayer") {
            return "mosque.fill"
        } else if category.contains("الاستغفار") || category.contains("Forgiveness") {
            return "sparkles"
        } else if category.contains("السفر") || category.contains("Travel") {
            return "airplane"
        } else if category.contains("الضيق") || category.contains("Anxiety") {
            return "cloud.rain.fill"
        }
        return "bookmark.fill"
    }
    
    private func matchesSearch(_ item: DuaItem) -> Bool {
        if searchField.isEmpty { return true }
        let query = searchField.lowercased()
        return item.titleAr.lowercased().contains(query) ||
               item.titleEn.lowercased().contains(query) ||
               item.arabic.contains(query) ||
               (item.translationAr?.lowercased().contains(query) ?? false) ||
               (item.translationEn?.lowercased().contains(query) ?? false)
    }
    
    private func toggleBookmark(for item: DuaItem) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if item.isCustom {
            if let idx = customDuas.firstIndex(where: { $0.id == item.id }) {
                customDuas[idx].isBookmarked.toggle()
                saveData()
            }
        } else {
            if let idx = builtInDuas.firstIndex(where: { $0.id == item.id }) {
                builtInDuas[idx].isBookmarked.toggle()
                saveData()
            }
        }
    }
    
    private func copyToClipboard(_ item: DuaItem) {
        UIPasteboard.general.string = "\(item.title(for: language))\n\n\(item.arabic)\n\n\(item.translation(for: language) ?? "")"
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func toggleSpeech(for item: DuaItem) {
        if speakingDuaID == item.id {
            speechSynthesizer.stopSpeaking(at: .immediate)
            speakingDuaID = nil
        } else {
            speechSynthesizer.stopSpeaking(at: .immediate)
            
            let utterance = AVSpeechUtterance(string: item.arabic)
            utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
            // Slightly slower for learning
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
            
            speakingDuaID = item.id
            speechSynthesizer.speak(utterance)
            
            // Audio Session setup to make sure speaker audio functions in mute switch state if needed
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    private func saveCustomDua() {
        let titleAr = customTitleAr.isEmpty ? (customTitleEn.isEmpty ? "دعاء مخصص" : customTitleEn) : customTitleAr
        let titleEn = customTitleEn.isEmpty ? titleAr : customTitleEn
        
        let newItem = DuaItem(
            categoryAr: "أدعية خاصة",
            categoryEn: "Custom Duas",
            titleAr: titleAr,
            titleEn: titleEn,
            arabic: customArabic,
            translationAr: customTranslationAr.isEmpty ? nil : customTranslationAr,
            translationEn: customTranslationEn.isEmpty ? nil : customTranslationEn,
            transliteration: customTransliteration.isEmpty ? nil : customTransliteration,
            isBookmarked: false,
            isCustom: true
        )
        
        customDuas.insert(newItem, at: 0)
        saveData()
        
        // Reset form
        customTitleAr = ""
        customTitleEn = ""
        customArabic = ""
        customTranslationAr = ""
        customTranslationEn = ""
        customTransliteration = ""
        isShowingAddDua = false
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func deleteCustomDua(_ item: DuaItem) {
        customDuas.removeAll { $0.id == item.id }
        saveData()
    }
    
    private func loadData() {
        // Load bookmarks state for built-in
        if let data = UserDefaults.standard.data(forKey: "hasana.duas.builtin") {
            if let decoded = try? JSONDecoder().decode([DuaItem].self, from: data) {
                // Merge default items with saved bookmarks
                for item in decoded {
                    if let idx = builtInDuas.firstIndex(where: { $0.id == item.id }) {
                        builtInDuas[idx].isBookmarked = item.isBookmarked
                    }
                }
            }
        }
        
        // Load custom duas
        if let data = UserDefaults.standard.data(forKey: "hasana.duas.custom") {
            if let decoded = try? JSONDecoder().decode([DuaItem].self, from: data) {
                customDuas = decoded
            }
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(builtInDuas) {
            UserDefaults.standard.set(data, forKey: "hasana.duas.builtin")
        }
        if let data = try? JSONEncoder().encode(customDuas) {
            UserDefaults.standard.set(data, forKey: "hasana.duas.custom")
        }
    }
}

#Preview {
    DuaLibraryView(language: .english)
}
