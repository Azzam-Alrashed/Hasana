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

                    Image(systemName: language == .arabic ? "arrow.left" : "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(HasanaTheme.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: HasanaTheme.shadow.opacity(0.16), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
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
    let plants: [OnboardingPlantModel]
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

    var pages: [OnboardingPage] {
        switch language {
        case .arabic:
            [
                OnboardingPage(
                    id: "garden",
                    title: "عباداتك تصنع حديقة عمر",
                    message: "حسنة تساعدك على رؤية أثر الاستمرار بلطف، يوما بعد يوم.",
                    symbolName: "leaf.fill",
                    plants: plantSetOne
                ),
                OnboardingPage(
                    id: "gentle",
                    title: "الرجوع جزء من الطريق",
                    message: "لن تهدم الحديقة بسبب يوم صعب. الهدف أن تعود وتكمل بهدوء.",
                    symbolName: "heart.fill",
                    plants: plantSetTwo
                ),
                OnboardingPage(
                    id: "discovery",
                    title: "اكتشف سننا جميلة",
                    message: "مع الوقت، تظهر نباتات نادرة وفرص موسمية تقربك بخطوات صغيرة.",
                    symbolName: "sparkles",
                    plants: plantSetThree
                )
            ]
        case .english:
            [
                OnboardingPage(
                    id: "garden",
                    title: "Your worship grows a lifelong garden",
                    message: "Hasana helps you see gentle progress, one caring step at a time.",
                    symbolName: "leaf.fill",
                    plants: plantSetOne
                ),
                OnboardingPage(
                    id: "gentle",
                    title: "Returning is part of the path",
                    message: "A difficult day will not destroy your garden. Come back and continue calmly.",
                    symbolName: "heart.fill",
                    plants: plantSetTwo
                ),
                OnboardingPage(
                    id: "discovery",
                    title: "Discover beautiful Sunnahs",
                    message: "Over time, rare plants and seasonal opportunities appear in small, welcoming steps.",
                    symbolName: "sparkles",
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
}

#Preview {
    HasanaOnboardingView {}
}
