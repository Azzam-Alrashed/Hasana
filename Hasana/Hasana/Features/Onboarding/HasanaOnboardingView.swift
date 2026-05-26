import SwiftUI

struct HasanaOnboardingView: View {
    let onFinished: () -> Void

    @AppStorage(HasanaSettingsKeys.language) private var languageRawValue = HasanaLanguage.arabic.rawValue
    @State private var selectedPage = 0

    private var language: HasanaLanguage {
        HasanaLanguage(rawValue: languageRawValue) ?? .arabic
    }

    private var copy: OnboardingCopy {
        OnboardingCopy(language: language)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                onboardingHeader

                TabView(selection: $selectedPage) {
                    ForEach(Array(copy.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page, geometry: geometry)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                onboardingFooter
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HasanaTheme.canvasBackground.ignoresSafeArea())
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
    }

    private var onboardingHeader: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(HasanaLanguage.allCases) { language in
                    Button(language.displayName) {
                        languageRawValue = language.rawValue
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "globe")
                        .font(.system(size: 13, weight: .semibold))

                    Text(language.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(HasanaTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(HasanaTheme.elevatedSurface.opacity(0.78), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(HasanaTheme.border.opacity(0.72), lineWidth: 0.8)
                }
            }

            Spacer()

            Text(copy.progressText(current: selectedPage + 1, total: copy.pages.count))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(HasanaTheme.textMuted)
                .monospacedDigit()

            Button(copy.skip) {
                onFinished()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(HasanaTheme.textMuted)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    private var onboardingFooter: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                ForEach(copy.pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedPage ? HasanaTheme.accent : HasanaTheme.borderStrong.opacity(0.42))
                        .frame(width: index == selectedPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: selectedPage)
                }
            }

            HStack(spacing: 12) {
                if selectedPage > 0 {
                    Button {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            selectedPage -= 1
                        }
                    } label: {
                        Image(systemName: language == .arabic ? "arrow.right" : "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(HasanaTheme.textPrimary)
                            .frame(width: 56, height: 56)
                            .background(HasanaTheme.elevatedSurface.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.76), lineWidth: 0.8)
                            }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if selectedPage == copy.pages.count - 1 {
                        onFinished()
                    } else {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            selectedPage += 1
                        }
                    }
                } label: {
                    HStack(spacing: 9) {
                        Text(selectedPage == copy.pages.count - 1 ? copy.start : copy.next)
                            .font(.system(size: 17, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Image(systemName: selectedPage == copy.pages.count - 1 ? "checkmark" : (language == .arabic ? "arrow.left" : "arrow.right"))
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(HasanaTheme.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: HasanaTheme.shadow.opacity(0.16), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let geometry: GeometryProxy

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 8)

            OnboardingGardenScene(page: page)
                .frame(
                    width: min(geometry.size.width - 64, 310),
                    height: min(max(geometry.size.height * 0.34, 230), 310)
                )

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)

                Text(page.message)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 330)
                    .lineLimit(5)
                    .minimumScaleFactor(0.86)

                VStack(spacing: 8) {
                    ForEach(page.highlights) { highlight in
                        OnboardingHighlightRow(highlight: highlight)
                    }
                }
                .padding(.top, 8)
                .frame(maxWidth: 342)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingGardenScene: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HasanaTheme.elevatedSurface.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(HasanaTheme.border.opacity(0.68), lineWidth: 0.8)
                }

            Circle()
                .fill(HasanaTheme.gold.opacity(0.16))
                .frame(width: 106, height: 106)
                .offset(x: 86, y: -82)

            GardenGround()
                .fill(HasanaTheme.accentSoft.opacity(0.88))
                .frame(height: 104)
                .offset(y: 84)

            ForEach(page.plants) { plant in
                OnboardingPlant(plant: plant)
                    .frame(width: plant.size.width, height: plant.size.height)
                    .offset(plant.offset)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: page.metricSymbolName)
                        .font(.system(size: 11, weight: .bold))

                    Text(page.metricValue)
                        .font(.system(size: 14, weight: .bold))
                        .monospacedDigit()
                }
                .foregroundStyle(HasanaTheme.textPrimary)

                Text(page.metricCaption)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(HasanaTheme.elevatedSurface.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(HasanaTheme.border.opacity(0.72), lineWidth: 0.8)
            }
            .offset(x: 58, y: -62)

            Image(systemName: page.symbolName)
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(HasanaTheme.accent)
                .frame(width: 58, height: 58)
                .background(HasanaTheme.elevatedSurface.opacity(0.9), in: Circle())
                .overlay {
                    Circle()
                        .stroke(HasanaTheme.border.opacity(0.82), lineWidth: 0.8)
                }
                .offset(x: -96, y: -82)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: HasanaTheme.shadow.opacity(0.12), radius: 28, x: 0, y: 18)
    }
}

private struct OnboardingHighlightRow: View {
    let highlight: OnboardingHighlight

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: highlight.symbolName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(HasanaTheme.accent)
                .frame(width: 28, height: 28)
                .background(HasanaTheme.accentSoft.opacity(0.72), in: Circle())

            Text(highlight.text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HasanaTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.84)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HasanaTheme.elevatedSurface.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.54), lineWidth: 0.8)
        }
    }
}

private struct OnboardingPlant: View {
    let plant: OnboardingPlantModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(plant.stemColor)
                .frame(width: max(5, plant.size.width * 0.1), height: plant.size.height * 0.72)

            ForEach(0..<plant.petals, id: \.self) { index in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(plant.color)
                    .frame(width: plant.size.width * 0.48, height: plant.size.height * 0.24)
                    .rotationEffect(.degrees(Double(index) * (360 / Double(max(plant.petals, 1)))))
                    .offset(y: -plant.size.height * 0.52)
            }

            Circle()
                .fill(HasanaTheme.gold)
                .frame(width: plant.size.width * 0.24, height: plant.size.width * 0.24)
                .offset(y: -plant.size.height * 0.52)
        }
    }
}

private struct GardenGround: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.36))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.22),
            control1: CGPoint(x: rect.width * 0.32, y: 0),
            control2: CGPoint(x: rect.width * 0.68, y: rect.height * 0.52)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct OnboardingPage: Identifiable {
    let id: String
    let title: String
    let message: String
    let symbolName: String
    let metricSymbolName: String
    let metricValue: String
    let metricCaption: String
    let highlights: [OnboardingHighlight]
    let plants: [OnboardingPlantModel]
}

private struct OnboardingHighlight: Identifiable {
    let id: String
    let symbolName: String
    let text: String
}

private struct OnboardingPlantModel: Identifiable {
    let id: String
    let color: Color
    let stemColor: Color
    let petals: Int
    let size: CGSize
    let offset: CGSize
}

private struct OnboardingCopy {
    let language: HasanaLanguage

    var skip: String {
        switch language {
        case .arabic:
            "تخطي"
        case .english:
            "Skip"
        }
    }

    var next: String {
        switch language {
        case .arabic:
            "التالي"
        case .english:
            "Next"
        }
    }

    var start: String {
        switch language {
        case .arabic:
            "ابدأ حديقتي"
        case .english:
            "Start my garden"
        }
    }

    func progressText(current: Int, total: Int) -> String {
        switch language {
        case .arabic:
            "\(current) من \(total)"
        case .english:
            "\(current) of \(total)"
        }
    }

    var pages: [OnboardingPage] {
        switch language {
        case .arabic:
            [
                OnboardingPage(
                    id: "garden",
                    title: "عباداتك تصنع حديقة عمر",
                    message: "ابدأ من أفعال صغيرة قابلة للاستمرار، وشاهد أثرها ينمو أمامك.",
                    symbolName: "leaf.fill",
                    metricSymbolName: "checkmark.seal.fill",
                    metricValue: "٨",
                    metricCaption: "عبادات أساسية",
                    highlights: [
                        highlight("garden-a", "checkmark.circle.fill", "سجل حسنة اليوم بضغطة واحدة"),
                        highlight("garden-b", "leaf.fill", "تابع نمو الحديقة بلا ضغط")
                    ],
                    plants: plantSetOne
                ),
                OnboardingPage(
                    id: "gentle",
                    title: "الرجوع جزء من الطريق",
                    message: "لن تهدم الحديقة بسبب يوم صعب. الهدف أن تعود وتكمل بهدوء.",
                    symbolName: "heart.fill",
                    metricSymbolName: "arrow.uturn.backward.circle.fill",
                    metricValue: "بلا لوم",
                    metricCaption: "عودة هادئة",
                    highlights: [
                        highlight("gentle-a", "moon.stars.fill", "الفوات لا يمحو ما سبق"),
                        highlight("gentle-b", "sparkle.magnifyingglass", "اختر خطوة مناسبة لطاقتك")
                    ],
                    plants: plantSetTwo
                ),
                OnboardingPage(
                    id: "discovery",
                    title: "حديقة خاصة بك",
                    message: "تقدمك يبقى على جهازك، وتعود للعبادات الأساسية متى احتجت.",
                    symbolName: "lock.fill",
                    metricSymbolName: "leaf.circle.fill",
                    metricValue: "محلي",
                    metricCaption: "بياناتك لك",
                    highlights: [
                        highlight("discovery-a", "lock.fill", "سجل عبادتك بخصوصية وطمأنينة"),
                        highlight("discovery-b", "sun.max.fill", "ابدأ بحديقة جاهزة للرعاية")
                    ],
                    plants: plantSetThree
                )
            ]
        case .english:
            [
                OnboardingPage(
                    id: "garden",
                    title: "Your worship grows a lifelong garden",
                    message: "Begin with small actions you can keep, then watch their impact grow.",
                    symbolName: "leaf.fill",
                    metricSymbolName: "checkmark.seal.fill",
                    metricValue: "8",
                    metricCaption: "Core practices",
                    highlights: [
                        highlight("garden-a", "checkmark.circle.fill", "Log today’s good deed in one tap"),
                        highlight("garden-b", "leaf.fill", "Follow garden growth without pressure")
                    ],
                    plants: plantSetOne
                ),
                OnboardingPage(
                    id: "gentle",
                    title: "Returning is part of the path",
                    message: "A difficult day will not destroy your garden. Come back and continue calmly.",
                    symbolName: "heart.fill",
                    metricSymbolName: "arrow.uturn.backward.circle.fill",
                    metricValue: "No blame",
                    metricCaption: "A calm return",
                    highlights: [
                        highlight("gentle-a", "moon.stars.fill", "Missing a day never erases the past"),
                        highlight("gentle-b", "sparkle.magnifyingglass", "Choose a step that fits your energy")
                    ],
                    plants: plantSetTwo
                ),
                OnboardingPage(
                    id: "discovery",
                    title: "A garden that stays yours",
                    message: "Your progress stays on this device, ready whenever you return to the core practices.",
                    symbolName: "lock.fill",
                    metricSymbolName: "leaf.circle.fill",
                    metricValue: "Local",
                    metricCaption: "Your data stays yours",
                    highlights: [
                        highlight("discovery-a", "lock.fill", "Log worship with privacy and calm"),
                        highlight("discovery-b", "sun.max.fill", "Start with a garden ready to tend")
                    ],
                    plants: plantSetThree
                )
            ]
        }
    }

    private var plantSetOne: [OnboardingPlantModel] {
        [
            plant("one-a", color: HasanaTheme.accent, petals: 6, width: 74, height: 138, x: -36, y: 28),
            plant("one-b", color: HasanaTheme.gold, petals: 5, width: 54, height: 96, x: 60, y: 52),
            plant("one-c", color: HasanaTheme.reflection, petals: 4, width: 42, height: 76, x: -94, y: 60)
        ]
    }

    private var plantSetTwo: [OnboardingPlantModel] {
        [
            plant("two-a", color: HasanaTheme.reflection, petals: 6, width: 64, height: 116, x: -64, y: 44),
            plant("two-b", color: HasanaTheme.accent, petals: 5, width: 76, height: 138, x: 34, y: 26),
            plant("two-c", color: HasanaTheme.gold, petals: 5, width: 42, height: 76, x: 100, y: 64)
        ]
    }

    private var plantSetThree: [OnboardingPlantModel] {
        [
            plant("three-a", color: HasanaTheme.gold, petals: 7, width: 70, height: 130, x: -48, y: 32),
            plant("three-b", color: HasanaTheme.summary, petals: 5, width: 50, height: 92, x: 64, y: 54),
            plant("three-c", color: HasanaTheme.accent, petals: 4, width: 40, height: 70, x: -104, y: 70)
        ]
    }

    private func plant(
        _ id: String,
        color: Color,
        petals: Int,
        width: Double,
        height: Double,
        x: Double,
        y: Double
    ) -> OnboardingPlantModel {
        OnboardingPlantModel(
            id: id,
            color: color,
            stemColor: HasanaTheme.accent.opacity(0.76),
            petals: petals,
            size: CGSize(width: width, height: height),
            offset: CGSize(width: x, height: y)
        )
    }

    private func highlight(_ id: String, _ symbolName: String, _ text: String) -> OnboardingHighlight {
        OnboardingHighlight(id: id, symbolName: symbolName, text: text)
    }
}

#Preview {
    HasanaOnboardingView {}
}
