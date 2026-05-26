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

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                let displayState = store.displayState

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayState.practices) { practiceState in
                            GardenPracticeLogCard(
                                practice: practiceState.practice,
                                progress: practiceState.progress,
                                isTendedToday: practiceState.isTendedToday,
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
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .background(HasanaTheme.background.ignoresSafeArea())
                .onAppear {
                    scrollToSelection(with: proxy)
                }
                .onChange(of: store.selectedPracticeID) {
                    scrollToSelection(with: proxy)
                }
            }
            .navigationTitle(copy.title)
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
}

private struct GardenPracticeLogCard: View {
    let practice: HasanaGardenPractice
    let progress: HasanaGardenProgress
    let isTendedToday: Bool
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
        case .sunnah:
            HasanaTheme.summary
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

                    if isTendedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(HasanaTheme.gold)
                    }
                }

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

                HStack(spacing: 8) {
                    Image(systemName: isTendedToday ? "checkmark.seal.fill" : "drop.fill")
                        .font(.system(size: 14, weight: .bold))

                    Text(isTendedToday ? copy.tendedToday : copy.tendToday)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .foregroundStyle(isTendedToday ? HasanaTheme.textPrimary : .white)
                .frame(maxWidth: .infinity, minHeight: 42)
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
            .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
            .background(HasanaTheme.elevatedSurface.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? accentColor.opacity(0.86) : HasanaTheme.border.opacity(0.58), lineWidth: isSelected ? 1.4 : 0.8)
            }
            .shadow(color: accentColor.opacity(isSelected ? 0.18 : 0.07), radius: isSelected ? 16 : 8, x: 0, y: 8)
        }
        .buttonStyle(GardenPressButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isTendedToday ? copy.untendHint : copy.tendHint)
    }

    private var accessibilityLabel: String {
        "\(practice.title(for: language)), \(practice.religiousStatus.title(for: language)), \(progress.growthStage.title(for: language)), \(isTendedToday ? copy.tendedToday : copy.notTendedToday)"
    }
}

private struct GardenChip: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
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

    var tendHint: String {
        switch language {
        case .arabic:
            "اضغط لتسجيل هذه العبادة لهذا اليوم."
        case .english:
            "Tap to mark this practice as tended today."
        }
    }

    var untendHint: String {
        switch language {
        case .arabic:
            "اضغط لإزالة تسجيل اليوم إذا كان بالخطأ."
        case .english:
            "Tap to remove today's mark if it was added by mistake."
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
