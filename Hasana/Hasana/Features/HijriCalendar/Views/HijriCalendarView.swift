import SwiftUI

struct HijriCalendarView: View {
    let language: HasanaLanguage
    
    @State private var currentMonthDate = Date()
    @State private var selectedDate = Date()
    
    @Environment(\.dismiss) private var dismiss
    
    private let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
    private let gregorianCalendar = Calendar(identifier: .gregorian)
    
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
                        // Month Header Navigation
                        HStack {
                            Button {
                                changeMonth(by: -1)
                            } label: {
                                Image(systemName: language == .arabic ? "chevron.left" : "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(HasanaTheme.accent)
                                    .padding(10)
                                    .background(HasanaTheme.elevatedSurface.opacity(0.72), in: Circle())
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text(gregorianMonthYearString(for: currentMonthDate))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                
                                Text(hijriMonthYearString(for: currentMonthDate))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(HasanaTheme.gold)
                            }
                            
                            Spacer()
                            
                            Button {
                                changeMonth(by: 1)
                            } label: {
                                Image(systemName: language == .arabic ? "chevron.right" : "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(HasanaTheme.accent)
                                    .padding(10)
                                    .background(HasanaTheme.elevatedSurface.opacity(0.72), in: Circle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Days of week header labels
                        HStack(spacing: 0) {
                            ForEach(daysOfWeekLabels, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textMuted)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Calendar days grid
                        VStack(spacing: 10) {
                            let days = generateDaysInMonth(for: currentMonthDate)
                            let chunks = days.chunked(into: 7)
                            
                            ForEach(0..<chunks.count, id: \.self) { rowIndex in
                                HStack(spacing: 10) {
                                    ForEach(chunks[rowIndex], id: \.self) { dateOpt in
                                        if let date = dateOpt {
                                            calendarCell(for: date)
                                        } else {
                                            // Empty cell
                                            Spacer()
                                                .frame(maxWidth: .infinity)
                                                .aspectRatio(1.0, contentMode: .fit)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(HasanaTheme.elevatedSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        
                        // Legend
                        HStack(spacing: 20) {
                            legendItem(color: HasanaTheme.accent, textAr: "اليوم الحالي", textEn: "Today")
                            legendItem(color: HasanaTheme.gold, textAr: "صيام مسنون", textEn: "Sunnah Fasting")
                            legendItem(color: HasanaTheme.summary, textAr: "مناسبة إسلامية", textEn: "Islamic Event")
                        }
                        .padding(.horizontal)
                        
                        // Selected Date Event Details
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedGregorianLongString)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textPrimary)
                                    
                                    Text(selectedHijriLongString)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(HasanaTheme.gold)
                                }
                                Spacer()
                            }
                            
                            let events = getEvents(for: selectedDate)
                            if !events.isEmpty {
                                ForEach(events) { event in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                                .foregroundStyle(HasanaTheme.gold)
                                            Text(event.title(for: language))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(HasanaTheme.textPrimary)
                                        }
                                        
                                        Text(event.description(for: language))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(HasanaTheme.textMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(12)
                                    .background(HasanaTheme.accentSoft.opacity(0.32), in: RoundedRectangle(cornerRadius: 12))
                                }
                            } else {
                                // Default status when no holy events
                                let fastingRec = checkFastingRecommendation(selectedDate)
                                if fastingRec.isRecommended {
                                    HStack(spacing: 10) {
                                        Image(systemName: "flame.fill")
                                            .foregroundStyle(HasanaTheme.gold)
                                        Text(fastingRec.reason)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(HasanaTheme.textPrimary)
                                    }
                                    .padding(12)
                                    .background(HasanaTheme.goldSoft.opacity(0.44), in: RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Text(language == .arabic ? "لا توجد مناسبات رسمية لهذا اليوم" : "No specific historical events noted today.")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(HasanaTheme.textMuted)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle(language == .arabic ? "التقويم الهجري" : "Hijri Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    // Calendar Cell
    @ViewBuilder
    private func calendarCell(for date: Date) -> some View {
        let isToday = gregorianCalendar.isDateInToday(date)
        let isSelected = gregorianCalendar.isDate(date, inSameDayAs: selectedDate)
        let isFasting = checkFastingRecommendation(date).isRecommended
        let hasEvent = !getEvents(for: date).isEmpty
        
        let hijriDay = hijriCalendar.component(.day, from: date)
        let gregDay = gregorianCalendar.component(.day, from: date)
        
        Button {
            selectedDate = date
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            VStack {
                Text("\(gregDay)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? .white : (isToday ? HasanaTheme.accent : HasanaTheme.textPrimary))
                
                Spacer(minLength: 2)
                
                HStack(spacing: 3) {
                    if hasEvent {
                        Circle()
                            .fill(HasanaTheme.summary)
                            .frame(width: 4, height: 4)
                    }
                    if isFasting {
                        Circle()
                            .fill(HasanaTheme.gold)
                            .frame(width: 4, height: 4)
                    }
                    
                    Text("\(hijriDay)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : HasanaTheme.gold)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ? HasanaTheme.accent :
                        (isToday ? HasanaTheme.accentSoft.opacity(0.44) :
                        (isFasting ? HasanaTheme.goldSoft.opacity(0.44) : Color.clear))
                    )
            }
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(HasanaTheme.accent.opacity(0.6), lineWidth: 1)
                } else if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(HasanaTheme.accent, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // Legend component
    private func legendItem(color: Color, textAr: String, textEn: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(language == .arabic ? textAr : textEn)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(HasanaTheme.textMuted)
        }
    }
    
    // MARK: - Date Helpers
    private func changeMonth(by months: Int) {
        if let newDate = gregorianCalendar.date(byAdding: .month, value: months, to: currentMonthDate) {
            currentMonthDate = newDate
        }
    }
    
    private var daysOfWeekLabels: [String] {
        if language == .arabic {
            return ["أحد", "نثن", "ثلا", "ربع", "خمس", "جمع", "سبت"]
        } else {
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }
    
    private func gregorianMonthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func hijriMonthYearString(for date: Date) -> String {
        let month = hijriCalendar.component(.month, from: date)
        let year = hijriCalendar.component(.year, from: date)
        let monthName = language == .arabic ? hijriMonthNamesAr[month - 1] : hijriMonthNamesEn[month - 1]
        
        return language == .arabic ? "\(monthName) \(year) هـ" : "\(monthName) \(year) AH"
    }
    
    private var selectedGregorianLongString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    private var selectedHijriLongString: String {
        let day = hijriCalendar.component(.day, from: selectedDate)
        let month = hijriCalendar.component(.month, from: selectedDate)
        let year = hijriCalendar.component(.year, from: selectedDate)
        let monthName = language == .arabic ? hijriMonthNamesAr[month - 1] : hijriMonthNamesEn[month - 1]
        
        return language == .arabic ? "\(day) \(monthName) \(year) هـ" : "\(day) \(monthName) \(year) AH"
    }
    
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let range = gregorianCalendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = gregorianCalendar.date(from: gregorianCalendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let weekday = gregorianCalendar.component(.weekday, from: firstOfMonth)
        let offset = weekday - 1 // 0 offset means Sunday start
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in 1...range.count {
            if let dayDate = gregorianCalendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }
        
        // Pad to multiple of 7 to fill the grid rows
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    // MARK: - Islamic Events database query
    private func getEvents(for date: Date) -> [IslamicEvent] {
        let month = hijriCalendar.component(.month, from: date)
        let day = hijriCalendar.component(.day, from: date)
        
        return IslamicEvent.defaults.filter { $0.hijriMonth == month && $0.hijriDay == day }
    }
    
    // Check fasting recommendation (Mondays/Thursdays & Ayyam al-Beed: 13, 14, 15 of Hijri month)
    private func checkFastingRecommendation(_ date: Date) -> (isRecommended: Bool, reason: String) {
        // 1. Check direct historical event recommendations (e.g. Day of Arafah, Ashura, Ramadan)
        let events = getEvents(for: date)
        if let specialFasting = events.first(where: { $0.isFastingRecommended }) {
            let reason = language == .arabic ? "صيام \(specialFasting.titleAr)" : "Fasting for \(specialFasting.titleEn)"
            return (true, reason)
        }
        
        // Ramadan is full fasting, return false as it's obligatory, not optional Sunnah recommendation
        let hijriMonth = hijriCalendar.component(.month, from: date)
        if hijriMonth == 9 {
            return (false, "")
        }
        
        // 2. Check Ayyam al-Beed (13th, 14th, 15th)
        let hijriDay = hijriCalendar.component(.day, from: date)
        if hijriDay == 13 || hijriDay == 14 || hijriDay == 15 {
            let reason = language == .arabic ? "صيام الأيام البيض (\(hijriDay) من الشهر)" : "Ayyam al-Beed Fasting (\(hijriDay)th day)"
            return (true, reason)
        }
        
        // 3. Check Monday / Thursday Sunnah
        let weekday = gregorianCalendar.component(.weekday, from: date)
        if weekday == 2 { // Monday
            let reason = language == .arabic ? "صيام يوم الاثنين (سنة مؤكدة)" : "Monday Sunnah Fasting"
            return (true, reason)
        } else if weekday == 5 { // Thursday
            let reason = language == .arabic ? "صيام يوم الخميس (سنة مؤكدة)" : "Thursday Sunnah Fasting"
            return (true, reason)
        }
        
        return (false, "")
    }
}

// Helpers for chunking array
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    HijriCalendarView(language: .english)
}
