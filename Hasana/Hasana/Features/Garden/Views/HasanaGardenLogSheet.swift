import SwiftUI

struct HasanaGardenLogSheet: View {
    @Bindable var store: HasanaGardenStore
    let language: HasanaLanguage

    @Environment(\.dismiss) private var dismiss

    private var copy: GardenLogCopy {
        GardenLogCopy(language: language)
    }

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 12, alignment: .top)
        ]
    }

    private var navigationTitleText: String {
        if store.selectedDayKey == store.todayKey {
            return copy.title
        } else {
            let calendar = Calendar.current
            let today = Date()
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                let yesterdayKey = String(format: "%04d-%02d-%02d",
                                          calendar.component(.year, from: yesterday),
                                          calendar.component(.month, from: yesterday),
                                          calendar.component(.day, from: yesterday))
                if store.selectedDayKey == yesterdayKey {
                    return language == .arabic ? "حديقة الأمس" : "Yesterday's garden"
                }
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: language.localeIdentifier)
            formatter.dateStyle = .medium
            formatter.timeStyle = .none

            let parser = DateFormatter()
            parser.dateFormat = "yyyy-MM-dd"
            if let date = parser.date(from: store.selectedDayKey) {
                return formatter.string(from: date)
            }

            return copy.title
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                let displayState = store.displayState

                ScrollView {
                    // Calendar Picker Row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.getLast7Days()) { day in
                                let isSelected = store.selectedDayKey == day.id
                                let isToday = store.todayKey == day.id

                                Button {
                                    triggerHapticFeedback(.light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                        store.selectedDayKey = day.id
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(day.weekdayName(for: language))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(isSelected ? .white : HasanaTheme.textMuted)
                                            .textCase(.uppercase)

                                        Text(day.dayNumber)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(isSelected ? .white : HasanaTheme.textPrimary)

                                        if isToday {
                                            Circle()
                                                .fill(isSelected ? .white : HasanaTheme.accent)
                                                .frame(width: 4, height: 4)
                                        } else {
                                            Spacer().frame(height: 4)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(minWidth: 48, minHeight: 48)
                                    .background(
                                        isSelected ? HasanaTheme.accent : HasanaTheme.elevatedSurface.opacity(0.8),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isSelected ? Color.clear : HasanaTheme.border.opacity(0.54), lineWidth: 0.8)
                                    }
                                    .shadow(color: isSelected ? HasanaTheme.accent.opacity(0.24) : Color.clear, radius: 8, x: 0, y: 4)
                                }
                                .buttonStyle(CalendarPressButtonStyle())
                                .accessibilityLabel(calendarAccessibilityLabel(for: day, isToday: isToday, isSelected: isSelected))
                                .accessibilityHint(copy.calendarHint)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayState.practices) { practiceState in
                            GardenPracticeLogCard(
                                practice: practiceState.practice,
                                progress: practiceState.progress,
                                isTendedToday: practiceState.isTendedToday,
                                isDormant: practiceState.isDormant,
                                isTodaySelected: store.selectedDayKey == store.todayKey,
                                isSelected: store.selectedPracticeID == practiceState.practice.id,
                                language: language,
                                copy: copy
                            ) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    store.toggleToday(for: practiceState.practice.id)
                                    store.selectPractice(practiceState.practice.id)
                                }
                            }
                            .id(practiceState.practice.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                .background(HasanaTheme.background.ignoresSafeArea())
                .onAppear {
                    store.selectedDayKey = store.todayKey
                    scrollToSelection(with: proxy)
                }
                .onChange(of: store.selectedPracticeID) {
                    scrollToSelection(with: proxy)
                }
            }
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy.done) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
    }

    private func scrollToSelection(with proxy: ScrollViewProxy) {
        guard let selectedPracticeID = store.selectedPracticeID else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                proxy.scrollTo(selectedPracticeID, anchor: .center)
            }
        }
    }

    private func calendarAccessibilityLabel(for day: HasanaCalendarDay, isToday: Bool, isSelected: Bool) -> String {
        var parts = [
            day.weekdayName(for: language),
            day.dayNumber
        ]
        if isToday {
            parts.append(copy.today)
        }
        if isSelected {
            parts.append(copy.selected)
        }
        return parts.joined(separator: ", ")
    }
}

private struct GardenPracticeLogCard: View {
    let practice: HasanaGardenPractice
    let progress: HasanaGardenProgress
    let isTendedToday: Bool
    let isDormant: Bool
    let isTodaySelected: Bool
    let isSelected: Bool
    let language: HasanaLanguage
    let copy: GardenLogCopy
    let onToggle: () -> Void

    private var accentColor: Color {
        switch practice.religiousStatus {
        case .obligatory:
            HasanaTheme.accent
        case .quran:
            HasanaTheme.gold
        case .dhikr:
            HasanaTheme.reflection
        case .sunnah, .sunnahWajib:
            HasanaTheme.summary
        }
    }

    private var actionLabel: String {
        if isTendedToday {
            return isTodaySelected ? copy.tendedToday : (language == .arabic ? "تم" : "Tended")
        } else if isDormant {
            return copy.returnToCare
        } else {
            return isTodaySelected ? copy.tendToday : copy.tendSelectedDay
        }
    }

    private var stateLabel: String {
        if isTendedToday {
            copy.tendedToday
        } else if isDormant {
            copy.dormant
        } else {
            copy.notTendedToday
        }
    }

    private var stateIcon: String {
        if isTendedToday {
            "checkmark.seal.fill"
        } else if isDormant {
            "leaf.arrow.circlepath"
        } else {
            "circle"
        }
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(isTendedToday ? 0.2 : 0.1))

                        Image(systemName: practice.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(accentColor)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(practice.title(for: language))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(HasanaTheme.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        Text(practice.subtitle(for: language))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(HasanaTheme.textMuted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 5) {
                        Image(systemName: stateIcon)
                            .font(.caption.weight(.bold))
                            .accessibilityHidden(true)

                        Text(stateLabel)
                            .font(.caption2.weight(.bold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.76)
                    }
                    .foregroundStyle(isTendedToday ? HasanaTheme.textPrimary : accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        (isTendedToday ? HasanaTheme.goldSoft : accentColor.opacity(0.12)),
                        in: Capsule()
                    )
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        GardenChip(
                            title: practice.religiousStatus.title(for: language),
                            color: accentColor
                        )

                        GardenChip(
                            title: progress.growthStage.title(for: language),
                            color: HasanaTheme.textMuted
                        )

                        Spacer(minLength: 0)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        GardenChip(
                            title: practice.religiousStatus.title(for: language),
                            color: accentColor
                        )

                        GardenChip(
                            title: progress.growthStage.title(for: language),
                            color: HasanaTheme.textMuted
                        )
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: isTendedToday ? "checkmark.seal.fill" : "drop.fill")
                        .font(.system(size: 14, weight: .bold))
                        .accessibilityHidden(true)

                    Text(actionLabel)
                        .font(.body.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(isTendedToday ? HasanaTheme.textPrimary : .white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 8)
                .background(
                    isTendedToday ? HasanaTheme.goldSoft.opacity(0.86) : accentColor,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isTendedToday ? HasanaTheme.gold.opacity(0.44) : Color.clear, lineWidth: 0.8)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 188, alignment: .topLeading)
            .background(HasanaTheme.elevatedSurface.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? accentColor.opacity(0.86) : HasanaTheme.border.opacity(0.58), lineWidth: isSelected ? 1.4 : 0.8)
            }
            .shadow(color: accentColor.opacity(isSelected ? 0.18 : 0.07), radius: isSelected ? 16 : 8, x: 0, y: 8)
        }
        .buttonStyle(GardenPressButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isTendedToday ? copy.untendHint(isTodaySelected: isTodaySelected) : copy.tendHint(isTodaySelected: isTodaySelected))
    }

    private var accessibilityLabel: String {
        let tendedState = isTendedToday ? copy.tendedState(isTodaySelected: isTodaySelected) : copy.notTendedState(isTodaySelected: isTodaySelected)
        let restingState = isDormant ? ", \(copy.restingGently)" : ""
        return "\(practice.title(for: language)), \(practice.religiousStatus.title(for: language)), \(progress.growthStage.title(for: language)), \(tendedState)\(restingState)"
    }
}

private struct GardenChip: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .lineLimit(2)
            .minimumScaleFactor(0.76)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.1), in: Capsule())
    }
}

private struct GardenPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

struct GardenLogCopy {
    let language: HasanaLanguage

    var title: String {
        switch language {
        case .arabic:
            "ازرع لحظة اليوم"
        case .english:
            "Tend today's garden"
        }
    }

    var tendToday: String {
        switch language {
        case .arabic:
            "ازرع اليوم"
        case .english:
            "Tend today"
        }
    }

    var tendedToday: String {
        switch language {
        case .arabic:
            "تم اليوم"
        case .english:
            "Tended today"
        }
    }

    var notTendedToday: String {
        switch language {
        case .arabic:
            "لم يتم اليوم"
        case .english:
            "Not tended today"
        }
    }

    var tendSelectedDay: String {
        switch language {
        case .arabic:
            "ازرع هذا اليوم"
        case .english:
            "Tend this day"
        }
    }

    var dormant: String {
        switch language {
        case .arabic:
            "نائمة بلطف"
        case .english:
            "Gently dormant"
        }
    }

    var returnToCare: String {
        switch language {
        case .arabic:
            "عد للرعاية"
        case .english:
            "Return to care"
        }
    }

    var today: String {
        switch language {
        case .arabic:
            "اليوم"
        case .english:
            "Today"
        }
    }

    var selected: String {
        switch language {
        case .arabic:
            "محدد"
        case .english:
            "Selected"
        }
    }

    var calendarHint: String {
        switch language {
        case .arabic:
            "اضغط لتغيير يوم التسجيل."
        case .english:
            "Tap to change the logging day."
        }
    }

    var restingGently: String {
        switch language {
        case .arabic:
            "سكون لطيف"
        case .english:
            "Resting gently"
        }
    }

    func tendedState(isTodaySelected: Bool) -> String {
        if isTodaySelected {
            return tendedToday
        }

        switch language {
        case .arabic:
            return "تم في هذا اليوم"
        case .english:
            return "Tended this day"
        }
    }

    func notTendedState(isTodaySelected: Bool) -> String {
        if isTodaySelected {
            return notTendedToday
        }

        switch language {
        case .arabic:
            return "لم يتم في هذا اليوم"
        case .english:
            return "Not tended this day"
        }
    }

    func tendHint(isTodaySelected: Bool) -> String {
        if isTodaySelected {
            switch language {
            case .arabic:
                return "اضغط لتسجيل هذه العبادة لهذا اليوم."
            case .english:
                return "Tap to mark this practice as tended today."
            }
        }

        switch language {
        case .arabic:
            return "اضغط لتسجيل هذه العبادة لليوم المحدد."
        case .english:
            return "Tap to mark this practice as tended for the selected day."
        }
    }

    func untendHint(isTodaySelected: Bool) -> String {
        if isTodaySelected {
            switch language {
            case .arabic:
                return "اضغط لإزالة تسجيل اليوم إذا كان بالخطأ."
            case .english:
                return "Tap to remove today's mark if it was added by mistake."
            }
        }

        switch language {
        case .arabic:
            return "اضغط لإزالة تسجيل اليوم المحدد إذا كان بالخطأ."
        case .english:
            return "Tap to remove the selected day's mark if it was added by mistake."
        }
    }

    var done: String {
        switch language {
        case .arabic:
            "تم"
        case .english:
            "Done"
        }
    }
}

#Preview {
    HasanaGardenLogSheet(
        store: HasanaGardenStore(),
        language: .english
    )
}

private struct CalendarPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}
