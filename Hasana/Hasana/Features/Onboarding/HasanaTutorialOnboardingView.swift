import SwiftUI
import AVFoundation
import CoreLocation
import Observation

// MARK: - Onboarding State Machine & Types

/// The steps representing different phases of the onboarding tutorial
enum TutorialStep: Int, CaseIterable, Comparable {
    case welcome = 0
    case customization = 1
    case prayerSetup = 2
    case habitSelection = 3
    case interactiveSimulator = 4
    case finalSummary = 5
    
    static func < (lhs: TutorialStep, rhs: TutorialStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A structure representing a single card in the welcome slider carousel
struct WelcomeCard: Identifiable, Hashable {
    let id: UUID = UUID()
    let titleAr: String
    let titleEn: String
    let descriptionAr: String
    let descriptionEn: String
    let iconName: String
    let highlightColor: Color
}

/// A structure representing a custom spiritual habit preset configured by the user
struct OnboardingHabitPreset: Identifiable, Hashable {
    let id: UUID = UUID()
    let habitID: String
    let titleAr: String
    let titleEn: String
    var targetCount: Int
    var isSelected: Bool
    let iconName: String
    let color: Color
}

/// Custom model for particle effects used in celebration and growth simulation
struct OnboardingParticle: Identifiable, Equatable {
    let id: UUID = UUID()
    var position: CGPoint
    var velocity: CGSize
    var color: Color
    var size: CGFloat
    var opacity: Double
    var rotation: Double
    var life: Double // Remaining duration of particle in seconds
}

// MARK: - Copy & Localized Strings
private struct TutorialCopy {
    let language: HasanaLanguage
    
    // Global Elements
    var skip: String { language == .arabic ? "تخطي" : "Skip" }
    var next: String { language == .arabic ? "التالي" : "Next" }
    var back: String { language == .arabic ? "السابق" : "Previous" }
    var getStarted: String { language == .arabic ? "ابدأ حديقتي" : "Start my garden" }
    var finish: String { language == .arabic ? "تأكيد والبدء" : "Confirm & Begin" }
    
    // Step Titles
    var welcomeTitle: String { language == .arabic ? "مرحباً بك في حسنة" : "Welcome to Hasana" }
    var welcomeSubtitle: String { language == .arabic ? "عبادتك اليومية تنبت حياة طيبة" : "Your daily worship grows a beautiful life" }
    var customizationTitle: String { language == .arabic ? "مظهر وتجربة الحديقة" : "Theme & Style" }
    var customizationSubtitle: String { language == .arabic ? "اختر الألوان واللغة المفضلة لديك" : "Select your preferred language and theme" }
    var prayerTitle: String { language == .arabic ? "مواقيت الصلاة الدقيقة" : "Accurate Prayer Times" }
    var prayerSubtitle: String { language == .arabic ? "اضبط مواقيت الصلاة والموقع الجغرافي" : "Set up your location and calculation parameters" }
    var habitsTitle: String { language == .arabic ? "بناء العادات الروحية" : "Build Spiritual Habits" }
    var habitsSubtitle: String { language == .arabic ? "اختر العبادات التي تريد تتبعها وتنميتها" : "Choose the acts of worship you want to track" }
    var simulatorTitle: String { language == .arabic ? "رعاية وتنمية حديقتك" : "Tend to Your Garden" }
    var simulatorSubtitle: String { language == .arabic ? "جرب سقي نبتتك الأولى لتشاهدها تزهر" : "Try watering your first plant to watch it bloom" }
    var summaryTitle: String { language == .arabic ? "حديقتك جاهزة للنمو!" : "Your Garden is Ready!" }
    var summarySubtitle: String { language == .arabic ? "مراجعة إعدادات رحلتك الإيمانية" : "Review your settings before we begin" }
    
    // Language picker labels
    var languageLabel: String { language == .arabic ? "اللغة:" : "Language:" }
    var appearanceLabel: String { language == .arabic ? "الوضع:" : "Appearance:" }
    var themeLabel: String { language == .arabic ? "السمة الروحية:" : "Spiritual Theme:" }
    
    // Theme names
    var gardenTheme: String { language == .arabic ? "الحديقة الوديعة" : "Serene Garden" }
    var sunriseTheme: String { language == .arabic ? "شروق الأمل" : "Hopeful Sunrise" }
    var oceanTheme: String { language == .arabic ? "المحيط الهادئ" : "Quiet Ocean" }
    var lavenderTheme: String { language == .arabic ? "لافندر السكينة" : "Peaceful Lavender" }
    
    // Appearance names
    var appLight: String { language == .arabic ? "نهاري" : "Light" }
    var appDark: String { language == .arabic ? "ليلي" : "Dark" }
    var appSystem: String { language == .arabic ? "تلقائي" : "System" }
    
    // Prayer settings copy
    var cityNameLabel: String { language == .arabic ? "المدينة أو المنطقة" : "City or Area" }
    var selectMethod: String { language == .arabic ? "طريقة الحساب" : "Calculation Method" }
    var hanafiAsr: String { language == .arabic ? "المذهب الحنفي للعصر" : "Hanafi School for Asr" }
    var notificationsAthan: String { language == .arabic ? "تنبيهات الأذان لكل صلاة" : "Athan Notifications for Prayers" }
    var locationAuto: String { language == .arabic ? "تحديد الموقع تلقائياً" : "Auto Detect Location" }
    var latitudeLabel: String { language == .arabic ? "خط العرض" : "Latitude" }
    var longitudeLabel: String { language == .arabic ? "خط الطول" : "Longitude" }
    var locationSuccess: String { language == .arabic ? "تم تحديد الموقع بنجاح!" : "Location locked successfully!" }
    var locationDetecting: String { language == .arabic ? "جاري تحديد الموقع..." : "Detecting coordinates..." }
    
    // Habits slide
    var habitTarget: String { language == .arabic ? "الهدف اليومي" : "Daily Goal" }
    var addCustomHabit: String { language == .arabic ? "+ إضافة عادة خاصة" : "+ Add Custom Habit" }
    var customHabitPlaceholder: String { language == .arabic ? "اسم العبادة (مثال: صلاة الضحى)" : "Habit Name (e.g. Duha Prayer)" }
    var addBtn: String { language == .arabic ? "إضافة" : "Add" }
    
    // Simulator instructions
    var simInstruction: String {
        language == .arabic 
        ? "اسحب مرش الماء بلطف وضعه فوق أصيص النبتة لسقايتها ورؤية أثر عبادتك"
        : "Drag the watering can and position it over the flowerpot to water it and see your growth"
    }
    var simWateredSuccess: String {
        language == .arabic
        ? "أحسنت! كل فعل صالح تسجله في حسنة هو قطرة ماء تنمي حديقتك الروحية."
        : "Excellent! Every good deed you log in Hasana is a drop of water that grows your spiritual garden."
    }
    var simCompletedBtn: String { language == .arabic ? "متابعة" : "Proceed" }
    
    // Final Summary page
    var privacyDeclaration: String {
        language == .arabic
        ? "تنبيه: جميع بيانات عبادتك مشفرة ومحفوظة محلياً بالكامل على جهازك ولا نرفعها إلى أي خوادم."
        : "Privacy Note: All your worship logs are fully encrypted and stored locally. We never upload them to servers."
    }
    
    // Welcome slides data
    var welcomeCards: [WelcomeCard] {
        [
            WelcomeCard(
                titleAr: "شاهد عبادتك تنمو",
                titleEn: "Watch Your Worship Grow",
                descriptionAr: "كلما صليت، ذكرت الله، أو تصدقت، تنمو نباتات حية وفريدة في حديقتك الـ 3D الخاصة.",
                descriptionEn: "Every prayer, remembrance, or charity grows unique living plants in your private 3D spiritual garden.",
                iconName: "leaf.fill",
                highlightColor: HasanaTheme.accent
            ),
            WelcomeCard(
                titleAr: "رفيق روحي بدون ضغط",
                titleEn: "A Pressure-Free Companion",
                descriptionAr: "الرجوع جزء من الطريق. لن تهدم حديقتك بسبب يوم صعب، نساعدك لتعود وتكمل بهدوء.",
                descriptionEn: "Returning is part of the path. A difficult day will not destroy your progress; we help you resume calmly.",
                iconName: "heart.fill",
                highlightColor: HasanaTheme.gold
            ),
            WelcomeCard(
                titleAr: "خصوصية مطلقة",
                titleEn: "Absolute Privacy",
                descriptionAr: "بيانات عبادتك تهمك أنت وحدك. مساحتك الروحية محلية بالكامل ومحفوظة على جهازك بأمان.",
                descriptionEn: "Your spiritual logs are yours alone. Your data is completely localized and securely kept on your device.",
                iconName: "lock.fill",
                highlightColor: HasanaTheme.reflection
            )
        ]
    }
}

// MARK: - Hasana Tutorial Onboarding View

struct HasanaTutorialOnboardingView: View {
    let onFinished: () -> Void
    
    @State private var settings: HasanaAppSettings
    
    // Flow control state
    @State private var currentStep: TutorialStep = .welcome
    @State private var welcomePageIndex: Int = 0
    
    // Language shortcut
    private var language: HasanaLanguage {
        settings.language
    }
    
    private var copy: TutorialCopy {
        TutorialCopy(language: language)
    }
    
    // Theme Choice binding proxy
    private var selectedTheme: Binding<HasanaThemeChoice> {
        Binding(
            get: { settings.theme },
            set: { settings.theme = $0 }
        )
    }
    
    // Appearance Choice binding proxy
    private var selectedAppearance: Binding<HasanaAppearance> {
        Binding(
            get: { settings.appearance },
            set: { settings.appearance = $0 }
        )
    }
    
    // Habit config state
    @State private var selectedHabits: [OnboardingHabitPreset] = []
    @State private var showCustomHabitSheet = false
    @State private var customHabitNameAr = ""
    @State private var customHabitNameEn = ""
    
    // Location Simulation state
    @State private var isDetectingLocation = false
    @State private var locationFeedbackMessage: String? = nil
    
    // Simulator states
    @State private var waterCanOffset: CGSize = .zero
    @State private var waterCanPosition: CGPoint = .zero
    @State private var isWatering = false
    @State private var wateringProgress: Double = 0.0
    @State private var showSimSuccess = false
    @State private var simulatorParticles: [OnboardingParticle] = []
    @State private var isDraggingWaterCan = false
    
    // Celebration state
    @State private var celebrationParticles: [OnboardingParticle] = []
    
    // Sound & Mute preferences
    @State private var isMuted = SoundManager.shared.getMuted()
    
    // MARK: - Initializer
    
    init(settings: HasanaAppSettings = HasanaAppSettings(), onFinished: @escaping () -> Void) {
        self._settings = State(initialValue: settings)
        self.onFinished = onFinished
    }
    
    // MARK: - Body View
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Gradient with animated transitions based on settings and themes
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: settings.theme)
                
                // Floating Background Elements (Cosmic atmosphere)
                InteractiveStarsBackground()
                    .opacity(settings.appearance == .dark ? 0.8 : 0.2)
                
                VStack(spacing: 0) {
                    // Top Progress Bar and Sound Controls
                    onboardingHeader(isCompact: geometry.size.height < 700)
                    
                    // Main Slider and Dynamic Form Space
                    ZStack {
                        switch currentStep {
                        case .welcome:
                            welcomeStepView(geometry: geometry)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        case .customization:
                            customizationStepView(geometry: geometry)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        case .prayerSetup:
                            prayerSetupStepView(geometry: geometry)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        case .habitSelection:
                            habitSelectionStepView(geometry: geometry)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        case .interactiveSimulator:
                            interactiveSimulatorStepView(geometry: geometry)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        case .finalSummary:
                            finalSummaryStepView(geometry: geometry)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Footer action controls
                    onboardingFooter(isCompact: geometry.size.height < 700)
                }
                
                // Custom overlays (e.g. Custom Habit sheet and Celebration Particles)
                if showCustomHabitSheet {
                    customHabitModal()
                }
                
                // Celebration Particle Emitter Overlay
                if !celebrationParticles.isEmpty {
                    TimelineView(.animation) { timeline in
                        Canvas { context, size in
                            for particle in celebrationParticles {
                                var particleContext = context
                                particleContext.opacity = particle.opacity
                                particleContext.translateBy(x: particle.position.x, y: particle.position.y)
                                particleContext.rotate(by: .degrees(particle.rotation))
                                
                                let rect = CGRect(
                                    x: -particle.size / 2,
                                    y: -particle.size / 2,
                                    width: particle.size,
                                    height: particle.size
                                )
                                
                                // Draw particle shape (Sparkle or Circle)
                                if particle.size > 8 {
                                    var path = Path()
                                    path.move(to: CGPoint(x: 0, y: -particle.size / 2))
                                    path.addQuadCurve(to: CGPoint(x: particle.size / 2, y: 0), control: .zero)
                                    path.addQuadCurve(to: CGPoint(x: 0, y: particle.size / 2), control: .zero)
                                    path.addQuadCurve(to: CGPoint(x: -particle.size / 2, y: 0), control: .zero)
                                    path.addQuadCurve(to: CGPoint(x: 0, y: -particle.size / 2), control: .zero)
                                    particleContext.fill(path, with: .color(particle.color))
                                } else {
                                    particleContext.fill(Path(ellipseIn: rect), with: .color(particle.color))
                                }
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            }
        }
        .environment(\.layoutDirection, settings.layoutDirection)
        .environment(\.locale, settings.locale)
        .preferredColorScheme(settings.colorScheme)
        .onAppear {
            initializeDefaultHabits()
            // Ambient sound playback setup based on preference
            if !isMuted {
                SoundManager.shared.playAmbientSound()
            }
        }
        .onDisappear {
            SoundManager.shared.stopAmbientSound()
        }
    }
    
    // MARK: - Header Component
    
    private func onboardingHeader(isCompact: Bool) -> some View {
        HStack(spacing: 12) {
            // Step dots / progress bars
            HStack(spacing: 6) {
                ForEach(TutorialStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step == currentStep ? HasanaTheme.accent : HasanaTheme.borderStrong.opacity(0.35))
                        .frame(height: 6)
                        .frame(maxWidth: step == currentStep ? 28 : 10)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
                }
            }
            .accessibilityLabel("Step \(currentStep.rawValue + 1) of \(TutorialStep.allCases.count)")
            
            Spacer()
            
            // Sound toggler button
            Button {
                isMuted = SoundManager.shared.toggleMuted()
                triggerHapticFeedback(.light)
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(HasanaTheme.elevatedSurface.opacity(0.8), in: Circle())
                    .overlay {
                        Circle().stroke(HasanaTheme.border.opacity(0.6), lineWidth: 0.8)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isMuted ? "Unmute Ambient Music" : "Mute Ambient Music")
            
            // Language selector button shortcut (if welcome step)
            if currentStep == .welcome {
                Menu {
                    ForEach(HasanaLanguage.allCases) { lang in
                        Button(lang.displayName) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                settings.language = lang
                            }
                            triggerHapticFeedback(.medium)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        Text(settings.language.displayName)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(HasanaTheme.elevatedSurface.opacity(0.8), in: Capsule())
                    .overlay {
                        Capsule().stroke(HasanaTheme.border.opacity(0.6), lineWidth: 0.8)
                    }
                }
            }
        }
        .padding(.horizontal, isCompact ? 16 : 24)
        .padding(.top, isCompact ? 10 : 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Footer Component
    
    private func onboardingFooter(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 10 : 16) {
            HStack(spacing: 12) {
                // Prev button (show unless we're on the welcome screen)
                if currentStep != .welcome {
                    Button {
                        navigateBack()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: language == .arabic ? "chevron.right" : "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text(copy.back)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .frame(width: 100, height: 52)
                        .background(HasanaTheme.elevatedSurface.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.7), lineWidth: 0.8)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Next / Confirm Button
                Button {
                    navigateNext()
                } label: {
                    HStack(spacing: 8) {
                        Text(actionButtonText())
                            .font(.system(size: 17, weight: .bold))
                        
                        if currentStep != .finalSummary {
                            Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(HasanaTheme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: HasanaTheme.accent.opacity(0.24), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(currentStep == .interactiveSimulator && !showSimSuccess)
                .opacity((currentStep == .interactiveSimulator && !showSimSuccess) ? 0.6 : 1.0)
            }
            
            // Skip button option on early settings pages
            if currentStep == .welcome || currentStep == .customization || currentStep == .prayerSetup {
                Button {
                    skipToFinish()
                } label: {
                    Text(copy.skip)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isCompact ? 16 : 24)
        .padding(.bottom, isCompact ? 16 : 30)
        .padding(.top, 10)
        .background(
            HasanaTheme.elevatedSurface.opacity(0.1)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Navigation Logic
    
    private func navigateNext() {
        triggerHapticFeedback(.medium)
        
        if currentStep == .welcome {
            // First step is carousel
            if welcomePageIndex < copy.welcomeCards.count - 1 {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    welcomePageIndex += 1
                }
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    currentStep = .customization
                }
            }
        } else if currentStep == .finalSummary {
            completeOnboarding()
        } else {
            // General step advancement
            if let nextStep = TutorialStep(rawValue: currentStep.rawValue + 1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    currentStep = nextStep
                }
            }
        }
    }
    
    private func navigateBack() {
        triggerHapticFeedback(.light)
        
        if currentStep == .welcome {
            if welcomePageIndex > 0 {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    welcomePageIndex -= 1
                }
            }
        } else {
            if let prevStep = TutorialStep(rawValue: currentStep.rawValue - 1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    currentStep = prevStep
                }
            }
        }
    }
    
    private func skipToFinish() {
        triggerHapticFeedback(.heavy)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            currentStep = .finalSummary
        }
    }
    
    private func actionButtonText() -> String {
        switch currentStep {
        case .welcome:
            return welcomePageIndex < copy.welcomeCards.count - 1 ? copy.next : copy.getStarted
        case .interactiveSimulator:
            return showSimSuccess ? copy.simCompletedBtn : copy.next
        case .finalSummary:
            return copy.finish
        default:
            return copy.next
        }
    }
    
    // MARK: - Step 1: Welcome Carousel
    
    private func welcomeStepView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        
        return VStack(spacing: isCompact ? 16 : 28) {
            VStack(spacing: 6) {
                Text(copy.welcomeTitle)
                    .font(.system(size: isCompact ? 28 : 34, weight: .bold, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(copy.welcomeSubtitle)
                    .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, isCompact ? 8 : 20)
            
            // Carousel cards view
            TabView(selection: $welcomePageIndex) {
                ForEach(0..<copy.welcomeCards.count, id: \.self) { index in
                    let card = copy.welcomeCards[index]
                    WelcomeCarouselCard(card: card, isCompact: isCompact)
                        .tag(index)
                        .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: isCompact ? 300 : 380)
            
            // Carousel Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<copy.welcomeCards.count, id: \.self) { index in
                    Circle()
                        .fill(index == welcomePageIndex ? HasanaTheme.accent : HasanaTheme.borderStrong.opacity(0.35))
                        .frame(width: index == welcomePageIndex ? 10 : 7, height: index == welcomePageIndex ? 10 : 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: welcomePageIndex)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Language & Theme Selection
    
    private func customizationStepView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        
        return ScrollView {
            VStack(spacing: isCompact ? 18 : 24) {
                VStack(spacing: 6) {
                    Text(copy.customizationTitle)
                        .font(.system(size: isCompact ? 24 : 30, weight: .bold, design: .rounded))
                        .foregroundStyle(HasanaTheme.textPrimary)
                    
                    Text(copy.customizationSubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 10)
                
                // Theme Mockup Preview widget showing real-time changes
                ThemePreviewCard(language: language)
                    .frame(height: isCompact ? 160 : 190)
                    .padding(.horizontal, 24)
                
                // Settings Control Card
                VStack(alignment: .leading, spacing: 18) {
                    // Language option
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy.languageLabel)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HasanaTheme.textMuted)
                        
                        HStack(spacing: 12) {
                            ForEach(HasanaLanguage.allCases) { lang in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        settings.language = lang
                                    }
                                    triggerHapticFeedback(.light)
                                } label: {
                                    Text(lang.displayName)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(settings.language == lang ? .white : HasanaTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            settings.language == lang ? HasanaTheme.accent : HasanaTheme.elevatedSurfaceSoft,
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        )
                                        .overlay {
                                            if settings.language != lang {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(HasanaTheme.border.opacity(0.6), lineWidth: 0.8)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Appearance mode option
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy.appearanceLabel)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HasanaTheme.textMuted)
                        
                        HStack(spacing: 8) {
                            ForEach(HasanaAppearance.allCases) { appMode in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        settings.appearance = appMode
                                    }
                                    triggerHapticFeedback(.light)
                                } label: {
                                    Text(appearanceTitle(for: appMode))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(settings.appearance == appMode ? .white : HasanaTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(
                                            settings.appearance == appMode ? HasanaTheme.accent : HasanaTheme.elevatedSurfaceSoft,
                                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        )
                                        .overlay {
                                            if settings.appearance != appMode {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(HasanaTheme.border.opacity(0.6), lineWidth: 0.8)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Theme Choice Options
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy.themeLabel)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HasanaTheme.textMuted)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(HasanaThemeChoice.allCases) { theme in
                                    Button {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                            settings.theme = theme
                                        }
                                        triggerHapticFeedback(.light)
                                    } label: {
                                        VStack(spacing: 6) {
                                            HStack(spacing: 4) {
                                                Circle().fill(theme.previewColors[0]).frame(width: 14, height: 14)
                                                Circle().fill(theme.previewColors[1]).frame(width: 14, height: 14)
                                                Circle().fill(theme.previewColors[2]).frame(width: 14, height: 14)
                                            }
                                            .padding(6)
                                            .background(HasanaTheme.background.opacity(0.2), in: Capsule())
                                            
                                            Text(themeTitle(for: theme))
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(settings.theme == theme ? .white : HasanaTheme.textPrimary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            settings.theme == theme ? HasanaTheme.accent : HasanaTheme.elevatedSurfaceSoft,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                        .overlay {
                                            if settings.theme != theme {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(HasanaTheme.border.opacity(0.6), lineWidth: 0.8)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(20)
                .background(HasanaTheme.elevatedSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HasanaTheme.border.opacity(0.4), lineWidth: 0.8)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func themeTitle(for choice: HasanaThemeChoice) -> String {
        switch choice {
        case .garden: return copy.gardenTheme
        case .sunrise: return copy.sunriseTheme
        case .ocean: return copy.oceanTheme
        case .lavender: return copy.lavenderTheme
        }
    }
    
    private func appearanceTitle(for value: HasanaAppearance) -> String {
        switch value {
        case .light: return copy.appLight
        case .dark: return copy.appDark
        case .system: return copy.appSystem
        }
    }
    
    // MARK: - Step 3: Prayer Times Location Setup
    
    private func prayerSetupStepView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        
        return ScrollView {
            VStack(spacing: isCompact ? 16 : 24) {
                VStack(spacing: 6) {
                    Text(copy.prayerTitle)
                        .font(.system(size: isCompact ? 24 : 30, weight: .bold, design: .rounded))
                        .foregroundStyle(HasanaTheme.textPrimary)
                    
                    Text(copy.prayerSubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 10)
                
                // Form Container
                VStack(spacing: 16) {
                    // City Name input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(copy.cityNameLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(HasanaTheme.textMuted)
                        
                        TextField(language == .arabic ? "مثال: مكة المكرمة" : "e.g. London", text: Binding(
                            get: { settings.prayerSettings.cityName },
                            set: { settings.prayerSettings.cityName = $0 }
                        ))
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(HasanaTheme.elevatedSurfaceSoft, in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10).stroke(HasanaTheme.border, lineWidth: 0.8)
                        }
                    }
                    
                    // Coordinates Row & Automatic Lock Button
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(copy.latitudeLabel)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(HasanaTheme.textMuted)
                            
                            Text(String(format: "%.4f", settings.prayerSettings.latitude))
                                .font(.system(size: 14, weight: .bold).monospacedDigit())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(HasanaTheme.elevatedSurfaceSoft, in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(copy.longitudeLabel)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(HasanaTheme.textMuted)
                            
                            Text(String(format: "%.4f", settings.prayerSettings.longitude))
                                .font(.system(size: 14, weight: .bold).monospacedDigit())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(HasanaTheme.elevatedSurfaceSoft, in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Button {
                            simulateLocationDetection()
                        } label: {
                            VStack {
                                if isDetectingLocation {
                                    ProgressView()
                                        .tint(HasanaTheme.accent)
                                } else {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundStyle(HasanaTheme.accent)
                            .frame(width: 44, height: 44)
                            .background(HasanaTheme.accentSoft, in: RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8).stroke(HasanaTheme.accent.opacity(0.3), lineWidth: 0.8)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 20)
                    }
                    
                    if let message = locationFeedbackMessage {
                        Text(message)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(message.contains("!") ? Color.green : HasanaTheme.accent)
                            .transition(.opacity)
                    }
                    
                    Divider()
                        .background(HasanaTheme.border)
                    
                    // Calculation Method selection dropdown (wrapped in a Picker menu)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(copy.selectMethod)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(HasanaTheme.textMuted)
                        
                        Menu {
                            ForEach(CalculationMethod.allCases) { method in
                                Button(method.title(for: language)) {
                                    settings.prayerSettings.method = method
                                    triggerHapticFeedback(.light)
                                }
                            }
                        } label: {
                            HStack {
                                Text(settings.prayerSettings.method.title(for: language))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(HasanaTheme.textMuted)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(HasanaTheme.elevatedSurfaceSoft, in: RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10).stroke(HasanaTheme.border, lineWidth: 0.8)
                            }
                        }
                    }
                    
                    // Toggles
                    VStack(spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { settings.prayerSettings.useHanafiAsr },
                            set: { settings.prayerSettings.useHanafiAsr = $0 }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(copy.hanafiAsr)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                            }
                        }
                        .tint(HasanaTheme.accent)
                        
                        Toggle(isOn: Binding(
                            get: { settings.prayerSettings.enableAthanNotifications },
                            set: { settings.prayerSettings.enableAthanNotifications = $0 }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(copy.notificationsAthan)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                            }
                        }
                        .tint(HasanaTheme.accent)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(HasanaTheme.elevatedSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HasanaTheme.border.opacity(0.4), lineWidth: 0.8)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func simulateLocationDetection() {
        guard !isDetectingLocation else { return }
        triggerHapticFeedback(.light)
        isDetectingLocation = true
        locationFeedbackMessage = copy.locationDetecting
        
        // Emulate network lookup delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            isDetectingLocation = false
            // Simulate locating Makkah or London depending on locale
            if language == .arabic {
                settings.prayerSettings.latitude = 21.4225
                settings.prayerSettings.longitude = 39.8262
                settings.prayerSettings.cityName = "مكة المكرمة"
            } else {
                settings.prayerSettings.latitude = 51.5074
                settings.prayerSettings.longitude = -0.1278
                settings.prayerSettings.cityName = "London"
            }
            locationFeedbackMessage = copy.locationSuccess
            triggerHapticFeedback(.heavy)
            
            // Auto hide success feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if locationFeedbackMessage == copy.locationSuccess {
                    withAnimation { locationFeedbackMessage = nil }
                }
            }
        }
    }
    
    // MARK: - Step 4: Spiritual Habits Configuration
    
    private func habitSelectionStepView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        
        return VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(copy.habitsTitle)
                    .font(.system(size: isCompact ? 24 : 30, weight: .bold, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)
                
                Text(copy.habitsSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 10)
            
            // List of Habits presets
            ScrollView {
                VStack(spacing: 10) {
                    ForEach($selectedHabits, id: \.id) { $habit in
                        HStack(spacing: 12) {
                            // Checked State
                            Button {
                                habit.isSelected.toggle()
                                triggerHapticFeedback(.light)
                            } label: {
                                Image(systemName: habit.isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(habit.isSelected ? HasanaTheme.accent : HasanaTheme.textMuted)
                            }
                            .buttonStyle(.plain)
                            
                            // Habit Icon
                            Image(systemName: habit.iconName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(habit.color, in: Circle())
                            
                            // Habit Name
                            VStack(alignment: .leading, spacing: 2) {
                                Text(language == .arabic ? habit.titleAr : habit.titleEn)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                
                                Text("\(copy.habitTarget): \(habit.targetCount)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(HasanaTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            // Quantity adjusts
                            if habit.isSelected {
                                HStack(spacing: 12) {
                                    Button {
                                        if habit.targetCount > 1 {
                                            habit.targetCount -= 1
                                            triggerHapticFeedback(.light)
                                        }
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(HasanaTheme.textPrimary)
                                            .frame(width: 28, height: 28)
                                            .background(HasanaTheme.elevatedSurfaceSoft, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("\(habit.targetCount)")
                                        .font(.system(size: 15, weight: .bold).monospacedDigit())
                                        .frame(minWidth: 24)
                                    
                                    Button {
                                        habit.targetCount += 1
                                        triggerHapticFeedback(.light)
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(HasanaTheme.textPrimary)
                                            .frame(width: 28, height: 28)
                                            .background(HasanaTheme.elevatedSurfaceSoft, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            habit.isSelected 
                            ? HasanaTheme.elevatedSurface.opacity(0.8)
                            : HasanaTheme.elevatedSurface.opacity(0.4)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(habit.isSelected ? HasanaTheme.accent.opacity(0.4) : HasanaTheme.border.opacity(0.4), lineWidth: 0.8)
                        }
                    }
                    
                    // Custom Add Button
                    Button {
                        customHabitNameAr = ""
                        customHabitNameEn = ""
                        showCustomHabitSheet = true
                    } label: {
                        Text(copy.addCustomHabit)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HasanaTheme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(HasanaTheme.accentSoft.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(HasanaTheme.accent.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
        }
    }
    
    private func customHabitModal() -> some View {
        ZStack {
            // Shadow overlay backdrop
            HasanaTheme.overlayScrim.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showCustomHabitSheet = false
                }
            
            VStack(spacing: 16) {
                Text(copy.addCustomHabit)
                    .font(.headline)
                    .foregroundStyle(HasanaTheme.textPrimary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(language == .arabic ? "اسم العبادة بالعربية" : "Arabic Name")
                        .font(.caption)
                        .foregroundStyle(HasanaTheme.textMuted)
                    
                    TextField(copy.customHabitPlaceholder, text: $customHabitNameAr)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(HasanaTheme.elevatedSurfaceSoft, in: RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(language == .arabic ? "اسم العبادة بالإنجليزية" : "English Name")
                        .font(.caption)
                        .foregroundStyle(HasanaTheme.textMuted)
                    
                    TextField(copy.customHabitPlaceholder, text: $customHabitNameEn)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(HasanaTheme.elevatedSurfaceSoft, in: RoundedRectangle(cornerRadius: 8))
                }
                
                HStack(spacing: 12) {
                    Button(language == .arabic ? "إلغاء" : "Cancel") {
                        showCustomHabitSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button(copy.addBtn) {
                        guard !customHabitNameAr.isEmpty || !customHabitNameEn.isEmpty else { return }
                        let newHabit = OnboardingHabitPreset(
                            habitID: "custom_\(UUID().uuidString)",
                            titleAr: customHabitNameAr.isEmpty ? customHabitNameEn : customHabitNameAr,
                            titleEn: customHabitNameEn.isEmpty ? customHabitNameAr : customHabitNameEn,
                            targetCount: 1,
                            isSelected: true,
                            iconName: "sparkles",
                            color: HasanaTheme.reflection
                        )
                        selectedHabits.append(newHabit)
                        showCustomHabitSheet = false
                        triggerHapticFeedback(.success)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HasanaTheme.accent)
                }
            }
            .padding(24)
            .frame(width: 320)
            .background(HasanaTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
    }
    
    private func initializeDefaultHabits() {
        selectedHabits = [
            OnboardingHabitPreset(
                habitID: "fard",
                titleAr: "صلوات الفريضة",
                titleEn: "Obligatory Prayers",
                targetCount: 5,
                isSelected: true,
                iconName: "building.2.fill",
                color: HasanaTheme.gold
            ),
            OnboardingHabitPreset(
                habitID: "quran",
                titleAr: "قراءة الورد القرآني",
                titleEn: "Daily Quran Reading",
                targetCount: 4,
                isSelected: true,
                iconName: "book.fill",
                color: HasanaTheme.reflection
            ),
            OnboardingHabitPreset(
                habitID: "adhkar",
                titleAr: "أذكار الصباح والمساء",
                titleEn: "Morning & Evening Adhkar",
                targetCount: 2,
                isSelected: true,
                iconName: "sun.max.fill",
                color: HasanaTheme.accent
            ),
            OnboardingHabitPreset(
                habitID: "sadaqah",
                titleAr: "الصدقة اليومية أو التبسم",
                titleEn: "Daily Sadaqah or Kindness",
                targetCount: 1,
                isSelected: false,
                iconName: "heart.fill",
                color: HasanaTheme.finance
            )
        ]
    }
    
    // MARK: - Step 5: Interactive Simulator (Drag & Bloom)
    
    private func interactiveSimulatorStepView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        
        return VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(copy.simulatorTitle)
                    .font(.system(size: isCompact ? 24 : 30, weight: .bold, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)
                
                Text(copy.simulatorSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 10)
            
            // Watering Interaction Box
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HasanaTheme.elevatedSurface.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(HasanaTheme.border.opacity(0.5), lineWidth: 0.8)
                    }
                
                // Simulation Background (Hills and Ground)
                GardenBackgroundGraphics()
                    .opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Flowing stream animation at the bottom
                VStack {
                    Spacer()
                    WaveShape(percent: CGFloat(wateringProgress * 100))
                        .fill(HasanaTheme.accent.opacity(0.15))
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Water particles being emitted from can spout
                if isWatering {
                    TimelineView(.animation) { timeline in
                        Canvas { context, size in
                            for particle in simulatorParticles {
                                var particleContext = context
                                particleContext.opacity = particle.opacity
                                let rect = CGRect(
                                    x: particle.position.x - particle.size/2,
                                    y: particle.position.y - particle.size/2,
                                    width: particle.size,
                                    height: particle.size
                                )
                                particleContext.fill(Path(ellipseIn: rect), with: .color(particle.color))
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
                
                // Centered Pot & Growing Flower View
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Blooming Flower Representation
                    BloomingFlowerView(progress: wateringProgress, themeColor: Color(hex: settings.theme.palette.accentLight))
                        .frame(width: 140, height: 180)
                    
                    // Plant Pot
                    GardenPotView()
                        .frame(width: 80, height: 50)
                        .padding(.bottom, 24)
                }
                
                // Instructions floating card
                VStack {
                    Text(showSimSuccess ? copy.simWateredSuccess : copy.simInstruction)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(showSimSuccess ? Color.green : HasanaTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(HasanaTheme.elevatedSurface.opacity(0.92), in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(showSimSuccess ? Color.green.opacity(0.5) : HasanaTheme.border.opacity(0.7), lineWidth: 0.8)
                        }
                        .padding(14)
                    
                    Spacer()
                }
                
                // Interactive Drag-and-drop Watering Can
                WateringCanIconView(isWatering: isWatering, isDragging: isDraggingWaterCan)
                    .frame(width: 70, height: 50)
                    .position(waterCanPosition == .zero ? CGPoint(x: geometry.size.width / 2 - 32, y: isCompact ? 100 : 130) : waterCanPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingWaterCan = true
                                let newLoc = value.location
                                // Constrain water can boundary movements
                                waterCanPosition = CGPoint(
                                    x: min(max(newLoc.x, 30), geometry.size.width - 70),
                                    y: min(max(newLoc.y, 40), isCompact ? 280 : 360)
                                )
                                
                                // Detect if water can is positioned right above the flowerpot to water it
                                // Pot center is roughly at geometry X-center and Y-bottom
                                let potX = geometry.size.width / 2 - 20
                                let potY = isCompact ? 220.0 : 280.0
                                
                                let distance = sqrt(pow(waterCanPosition.x - potX, 2) + pow(waterCanPosition.y - potY, 2))
                                
                                if distance < 85 && !showSimSuccess {
                                    if !isWatering {
                                        triggerHapticFeedback(.medium)
                                    }
                                    isWatering = true
                                    growPlant()
                                } else {
                                    isWatering = false
                                }
                            }
                            .onEnded { _ in
                                isDraggingWaterCan = false
                                isWatering = false
                                // Reset to default float position if not completed
                                if !showSimSuccess {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.76)) {
                                        waterCanPosition = CGPoint(x: geometry.size.width / 2 - 32, y: isCompact ? 100 : 130)
                                    }
                                }
                            }
                    )
            }
            .frame(height: isCompact ? 290 : 370)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            waterCanPosition = .zero
        }
    }
    
    private func growPlant() {
        guard wateringProgress < 1.0 else {
            if !showSimSuccess {
                completeWateringSimulation()
            }
            return
        }
        
        // Advance grow status
        wateringProgress = min(wateringProgress + 0.007, 1.0)
        
        // Spawn water droplets falling down
        // Water spout is at the left bottom of the watering can
        let spoutOffset = CGPoint(x: waterCanPosition.x - 30, y: waterCanPosition.y + 10)
        
        for _ in 0..<3 {
            let p = OnboardingParticle(
                position: spoutOffset,
                velocity: CGSize(
                    width: Double.random(in: -12...2), // Spraying direction
                    height: Double.random(in: 45...85)  // Gravity speed
                ),
                color: Color(hex: "#4C99E9").opacity(Double.random(in: 0.6...0.9)),
                size: CGFloat.random(in: 3.5...6.0),
                opacity: 1.0,
                rotation: 0.0,
                life: Double.random(in: 0.4...0.7)
            )
            simulatorParticles.append(p)
        }
        
        // Physics update simulation particles
        var index = 0
        while index < simulatorParticles.count {
            simulatorParticles[index].position.x += simulatorParticles[index].velocity.width * 0.1
            simulatorParticles[index].position.y += simulatorParticles[index].velocity.height * 0.1
            simulatorParticles[index].life -= 0.08
            
            if simulatorParticles[index].life <= 0 {
                simulatorParticles.remove(at: index)
            } else {
                index += 1
            }
        }
        
        // Play haptic tap ticks during watering
        if Int(wateringProgress * 100) % 8 == 0 {
            triggerHapticFeedback(.light)
        }
    }
    
    private func completeWateringSimulation() {
        showSimSuccess = true
        isWatering = false
        triggerHapticFeedback(.success)
        
        // Water Can flies away nicely
        withAnimation(.spring(response: 0.6, dampingFraction: 0.74)) {
            waterCanPosition = CGPoint(x: -100, y: 100)
        }
        
        // Trigger flower bloom celebration sparks
        spawnFlowerBloomCelebration()
    }
    
    private func spawnFlowerBloomCelebration() {
        let flowerCenter = CGPoint(x: 180, y: 220) // Approximate coordinates in box
        for _ in 0..<40 {
            let p = OnboardingParticle(
                position: flowerCenter,
                velocity: CGSize(
                    width: Double.random(in: -80...80),
                    height: Double.random(in: -100...20)
                ),
                color: [HasanaTheme.accent, HasanaTheme.gold, Color.yellow, Color.green].randomElement()!,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                life: Double.random(in: 1.0...2.0)
            )
            simulatorParticles.append(p)
        }
    }
    
    // MARK: - Step 6: Final Summary & Launch Page
    
    private func finalSummaryStepView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        
        return ScrollView {
            VStack(spacing: isCompact ? 16 : 24) {
                VStack(spacing: 6) {
                    Text(copy.summaryTitle)
                        .font(.system(size: isCompact ? 24 : 30, weight: .bold, design: .rounded))
                        .foregroundStyle(HasanaTheme.textPrimary)
                    
                    Text(copy.summarySubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 10)
                
                // Summary Config Cards
                VStack(spacing: 12) {
                    // Card: Core settings chosen
                    SummaryDetailRow(
                        iconName: "globe",
                        title: language == .arabic ? "اللغة المفضلة" : "Selected Language",
                        value: settings.language.displayName
                    )
                    
                    SummaryDetailRow(
                        iconName: "paintpalette.fill",
                        title: language == .arabic ? "سمة المظهر" : "Worship theme",
                        value: themeTitle(for: settings.theme)
                    )
                    
                    SummaryDetailRow(
                        iconName: "mappin.and.ellipse",
                        title: language == .arabic ? "الموقع الجغرافي" : "Calculation Location",
                        value: settings.prayerSettings.cityName.isEmpty ? "Makkah" : settings.prayerSettings.cityName
                    )
                    
                    let activeHabitsCount = selectedHabits.filter { $0.isSelected }.count
                    SummaryDetailRow(
                        iconName: "checkmark.seal.fill",
                        title: language == .arabic ? "العادات النشطة" : "Active Habits",
                        value: language == .arabic ? "(\(activeHabitsCount)) عبادات مخصصة" : "(\(activeHabitsCount)) acts chosen"
                    )
                }
                .padding(18)
                .background(HasanaTheme.elevatedSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HasanaTheme.border.opacity(0.4), lineWidth: 0.8)
                }
                .padding(.horizontal, 24)
                
                // Privacy note badge
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundStyle(HasanaTheme.accent)
                    
                    Text(copy.privacyDeclaration)
                        .font(.caption)
                        .foregroundStyle(HasanaTheme.textMuted)
                        .lineSpacing(4)
                }
                .padding(14)
                .background(HasanaTheme.accentSoft.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(HasanaTheme.accent.opacity(0.2), lineWidth: 0.8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
        }
    }
    
    // MARK: - Save and Complete Onboarding Action
    
    private func completeOnboarding() {
        triggerHapticFeedback(.success)
        
        // Save selected habits configuration into SwiftData / UserDefaults models
        // In Hasana, habits are loaded and managed. We will save the enabled ones to local database
        saveOnboardingConfig()
        
        // Perform completion animation before firing callback
        spawnLaunchCelebrationParticles()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onFinished()
        }
    }
    
    private func saveOnboardingConfig() {
        // Mark onboarding complete in AppStorage key
        UserDefaults.shared.set(true, forKey: HasanaSettingsKeys.hasCompletedOnboarding)
        
        // Update main settings configuration
        // In Xcode projects, this links straight to Shared UserDefaults bindings
        UserDefaults.shared.set(settings.language.rawValue, forKey: HasanaSettingsKeys.language)
        UserDefaults.shared.set(settings.theme.rawValue, forKey: HasanaSettingsKeys.theme)
        UserDefaults.shared.set(settings.appearance.rawValue, forKey: HasanaSettingsKeys.appearance)
        
        if let data = try? JSONEncoder().encode(settings.prayerSettings) {
            UserDefaults.shared.set(data, forKey: HasanaSettingsKeys.prayerSettings)
        }
        
        // Map selected presets into standard app format
        let activePresets = selectedHabits.filter { $0.isSelected }
        var habitsList: [SpiritualHabit] = []
        for preset in activePresets {
            let habit = SpiritualHabit(
                titleAr: preset.titleAr,
                titleEn: preset.titleEn,
                frequency: "daily",
                targetCount: preset.targetCount,
                icon: preset.iconName,
                colorHex: "#" + preset.color.description.suffix(6), // Parse hex description if applicable
                isLinkedToGarden: true,
                gardenPracticeID: preset.habitID
            )
            habitsList.append(habit)
        }
        
        // Save habits to local key for load sync
        if let encoded = try? JSONEncoder().encode(habitsList) {
            UserDefaults.standard.set(encoded, forKey: "hasana.onboarding.habits")
        }
    }
    
    private func spawnLaunchCelebrationParticles() {
        let size = UIScreen.main.bounds.size
        
        // Create random confetti particles across the screen
        for _ in 0..<120 {
            let p = OnboardingParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 20),
                velocity: CGSize(
                    width: Double.random(in: -120...120),
                    height: Double.random(in: (-450.0)...(-250.0)) // Shooting upward speed
                ),
                color: [HasanaTheme.accent, HasanaTheme.gold, Color.yellow, Color.pink, Color.cyan, Color.purple].randomElement()!,
                size: CGFloat.random(in: 8...16),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                life: Double.random(in: 2.0...3.5)
            )
            celebrationParticles.append(p)
        }
        
        // Run continuous physics simulator update
        var timerCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            timerCount += 1
            if celebrationParticles.isEmpty || timerCount > 200 {
                timer.invalidate()
                celebrationParticles.removeAll()
                return
            }
            
            for i in celebrationParticles.indices {
                // Apply simulated gravity and wind sway
                celebrationParticles[i].position.x += celebrationParticles[i].velocity.width * 0.02
                celebrationParticles[i].position.y += celebrationParticles[i].velocity.height * 0.02
                celebrationParticles[i].velocity.height += 9.8 * 0.35 // Gravity constant
                celebrationParticles[i].rotation += 5.0
                
                // Slow decay opacity as lifetime draws to close
                celebrationParticles[i].life -= 0.02
                if celebrationParticles[i].life < 0.8 {
                    celebrationParticles[i].opacity = max(celebrationParticles[i].life / 0.8, 0.0)
                }
            }
            
            celebrationParticles.removeAll { $0.position.y > size.height + 50 || $0.life <= 0 }
        }
    }
    
    // MARK: - Feedback & Utilities
    
    private func triggerHapticFeedback(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(style)
    }
    
    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Auxiliary Subviews & Components

/// A styled carousel page representing one slides message
private struct WelcomeCarouselCard: View {
    let card: WelcomeCard
    let isCompact: Bool
    
    @State private var scale: CGFloat = 0.85
    @State private var rotation: Double = -5.0
    
    var body: some View {
        VStack(spacing: isCompact ? 14 : 20) {
            // Icon illustration sphere
            ZStack {
                Circle()
                    .fill(card.highlightColor.opacity(0.12))
                    .frame(width: isCompact ? 100 : 130, height: isCompact ? 100 : 130)
                
                Image(systemName: card.iconName)
                    .font(.system(size: isCompact ? 40 : 54, weight: .semibold))
                    .foregroundStyle(card.highlightColor)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
            }
            .padding(.top, 10)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                    scale = 1.0
                    rotation = 0.0
                }
            }
            
            VStack(spacing: 8) {
                // Title and Body Text
                Text(card.titleAr)
                    .font(.system(size: isCompact ? 18 : 22, weight: .bold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(card.descriptionEn) // fallback context for dual display
                    .font(.system(size: isCompact ? 13 : 15, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(isCompact ? 2 : 4)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(HasanaTheme.elevatedSurface.opacity(0.65), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.4), lineWidth: 0.8)
        }
    }
}

/// Simulated mockup preview card of active widget/canvas interface
private struct ThemePreviewCard: View {
    let language: HasanaLanguage
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HasanaTheme.elevatedSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(HasanaTheme.border.opacity(0.8), lineWidth: 0.8)
                }
                .shadow(color: HasanaTheme.shadow.opacity(0.08), radius: 15, x: 0, y: 5)
            
            VStack(spacing: 12) {
                // Widget Top Panel
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(language == .arabic ? "الحديقة الروحية" : "Spiritual Garden")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(HasanaTheme.textPrimary)
                        
                        Text(language == .arabic ? "اليوم، ٢٦ ذو القعدة" : "Today, 26 Dhu al-Qi'dah")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(HasanaTheme.textMuted)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text(language == .arabic ? "مستوى ٣" : "Lvl 3")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HasanaTheme.accent, in: Capsule())
                }
                
                // Widget body (Mock landscape)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(HasanaTheme.accentSoft.opacity(0.5))
                        .frame(height: 75)
                    
                    GardenBackgroundGraphics()
                        .opacity(0.2)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Simple Mock flower models sways
                    HStack(spacing: 20) {
                        Circle()
                            .fill(HasanaTheme.accent)
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .offset(y: 10)
                        
                        Circle()
                            .fill(HasanaTheme.gold)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .offset(y: 4)
                        
                        Circle()
                            .fill(HasanaTheme.reflection)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .offset(y: 14)
                    }
                    .padding(.top, 10)
                }
                
                // Mock Action Stats
                HStack(spacing: 8) {
                    MockStatBubble(icon: "checkmark.circle.fill", label: language == .arabic ? "صلوات" : "Prayers", color: HasanaTheme.gold)
                    MockStatBubble(icon: "book.closed.fill", label: language == .arabic ? "ورد" : "Quran", color: HasanaTheme.reflection)
                    MockStatBubble(icon: "sparkles", label: language == .arabic ? "ذكر" : "Dhikr", color: HasanaTheme.accent)
                }
            }
            .padding(14)
        }
    }
}

private struct MockStatBubble: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(HasanaTheme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(HasanaTheme.elevatedSurfaceSoft, in: Capsule())
        .overlay {
            Capsule().stroke(HasanaTheme.border.opacity(0.4), lineWidth: 0.6)
        }
    }
}

/// Custom Canvas drawn flower shapes
private struct BloomingFlowerView: View {
    let progress: Double
    let themeColor: Color
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Swaying Stem lines
            StemShape(progress: progress)
                .stroke(Color.green.opacity(0.8), lineWidth: 5)
                .frame(width: 10, height: 120 * CGFloat(progress))
            
            // Glowing Aura
            if progress > 0.8 {
                Circle()
                    .fill(themeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .blur(radius: 8)
                    .offset(y: -110)
            }
            
            // Flower Head (Blooming scale & rotation)
            if progress > 0.3 {
                ZStack {
                    // Petals
                    ForEach(0..<6, id: \.self) { i in
                        FlowerPetal()
                            .fill(themeColor)
                            .frame(width: 25, height: 40)
                            .rotationEffect(.degrees(Double(i) * 60))
                    }
                    
                    // Golden Center Core
                    Circle()
                        .fill(HasanaTheme.gold)
                        .frame(width: 14, height: 14)
                }
                .scaleEffect(max(0, CGFloat((progress - 0.3) / 0.7)))
                .offset(y: -110)
            }
        }
    }
}

private struct StemShape: Shape {
    var progress: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        // Curve to simulate growth sway bend
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - 10, y: rect.maxY - rect.height),
            control: CGPoint(x: rect.midX + 20, y: rect.maxY - rect.height / 2)
        )
        return path
    }
}

private struct FlowerPetal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX - 10, y: rect.midY),
            control2: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY),
            control2: CGPoint(x: rect.maxX + 10, y: rect.midY)
        )
        return path
    }
}

/// Trapezoidal shape of the garden pot
private struct GardenPotView: View {
    var body: some View {
        ZStack {
            // Main body
            PotShape()
                .fill(HasanaTheme.borderStrong.opacity(0.8))
                .overlay {
                    PotShape()
                        .stroke(HasanaTheme.border, lineWidth: 1.2)
                }
            
            // Rim lip
            VStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(HasanaTheme.elevatedSurfaceSoft)
                    .frame(height: 8)
                Spacer()
            }
        }
    }
}

private struct PotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 10, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 6))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 6))
        path.closeSubpath()
        return path
    }
}

/// Custom drawn vector Watering Can view
private struct WateringCanIconView: View {
    let isWatering: Bool
    let isDragging: Bool
    
    var body: some View {
        ZStack {
            WateringCanShape()
                .fill(HasanaTheme.accent)
                .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
            
            // Handle accent
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 20, height: 20)
                .offset(x: 20, y: -4)
        }
        .scaleEffect(isDragging ? 1.15 : 1.0)
        .rotationEffect(.degrees(isWatering ? -35 : 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isWatering)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }
}

private struct WateringCanShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Main Tank Cylinder body
        path.addRoundedRect(
            in: CGRect(x: rect.minX + 10, y: rect.minY + 12, width: rect.width - 32, height: rect.height - 18),
            cornerSize: CGSize(width: 6, height: 6)
        )
        
        // Spout pipe extending to the left
        path.move(to: CGPoint(x: rect.minX + 10, y: rect.maxY - 14))
        path.addLine(to: CGPoint(x: rect.minX - 18, y: rect.minY + 10))
        path.addLine(to: CGPoint(x: rect.minX - 16, y: rect.minY + 8))
        path.addLine(to: CGPoint(x: rect.minX + 10, y: rect.maxY - 8))
        path.closeSubpath()
        
        // Spout head shower
        path.addEllipse(in: CGRect(x: rect.minX - 25, y: rect.minY + 4, width: 14, height: 8))
        
        return path
    }
}

/// Static nature landscape background simulator drawings
private struct GardenBackgroundGraphics: View {
    var body: some View {
        Canvas { context, size in
            // Draw background mountains/hills
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height - 30),
                control1: CGPoint(x: size.width * 0.3, y: size.height - 70),
                control2: CGPoint(x: size.width * 0.7, y: size.height)
            )
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
            context.fill(path, with: .color(HasanaTheme.borderStrong.opacity(0.3)))
            
            // Draw foreground grass layer
            var grass = Path()
            grass.move(to: CGPoint(x: 0, y: size.height))
            grass.addCurve(
                to: CGPoint(x: size.width, y: size.height - 10),
                control1: CGPoint(x: size.width * 0.4, y: size.height - 25),
                control2: CGPoint(x: size.width * 0.8, y: size.height - 15)
            )
            grass.addLine(to: CGPoint(x: size.width, y: size.height))
            grass.addLine(to: CGPoint(x: 0, y: size.height))
            grass.closeSubpath()
            context.fill(grass, with: .color(HasanaTheme.accentSoft))
        }
    }
}

/// Ambient flowing wave layer simulation
private struct WaveShape: Shape {
    var percent: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.height * (1.0 - percent / 100.0)
        
        path.move(to: CGPoint(x: 0, y: midY))
        path.addCurve(
            to: CGPoint(x: rect.width, y: midY),
            control1: CGPoint(x: rect.width * 0.35, y: midY - 14),
            control2: CGPoint(x: rect.width * 0.75, y: midY + 14)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// Cosmic floating elements and stars for visual ambient
private struct InteractiveStarsBackground: View {
    @State private var pulse: Bool = false
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let systemTime = timeline.date.timeIntervalSinceReferenceDate
                
                // Draw 15 stars pulsing gently
                for i in 0..<15 {
                    let seed = Double(i)
                    let x = sin(seed * 4324.23) * 0.5 + 0.5
                    let y = cos(seed * 9832.84) * 0.5 + 0.5
                    let position = CGPoint(x: x * size.width, y: y * size.height)
                    
                    let phase = sin(systemTime + seed * 2.0) * 0.5 + 0.5
                    let scale = 1.0 + phase * 1.5
                    
                    var starContext = context
                    starContext.opacity = 0.2 + phase * 0.5
                    
                    let rect = CGRect(
                        x: position.x - scale,
                        y: position.y - scale,
                        width: scale * 2,
                        height: scale * 2
                    )
                    
                    starContext.fill(Path(ellipseIn: rect), with: .color(HasanaTheme.gold.opacity(0.8)))
                }
            }
        }
    }
}

/// Grid row containing settings choice summary details
private struct SummaryDetailRow: View {
    let iconName: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(HasanaTheme.accent)
                .frame(width: 32, height: 32)
                .background(HasanaTheme.accentSoft, in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(HasanaTheme.textMuted)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HasanaTheme.textPrimary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(HasanaTheme.elevatedSurfaceSoft.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(HasanaTheme.border.opacity(0.3), lineWidth: 0.8)
        }
    }
}

// MARK: - Canvas Previews

#Preview {
    ZStack {
        HasanaTutorialOnboardingView(settings: HasanaAppSettings()) {
            print("Onboarding finished!")
        }
    }
}
