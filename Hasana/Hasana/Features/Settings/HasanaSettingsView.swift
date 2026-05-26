import SwiftUI

struct HasanaSettingsView: View {
    @Bindable var settings: HasanaAppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var isAmbientMuted = SoundManager.shared.getMuted()

    private var copy: SettingsCopy {
        SettingsCopy(selectedLanguage: settings.language)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SettingsSection(title: copy.language, icon: "globe") {
                        Picker(copy.language, selection: $settings.language) {
                            ForEach(HasanaLanguage.allCases) { language in
                                Text(language.displayName)
                                    .tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel(copy.language)
                    }

                    SettingsSection(title: copy.appearance, icon: "circle.lefthalf.filled") {
                        Picker(copy.appearance, selection: $settings.appearance) {
                            ForEach(HasanaAppearance.allCases) { appearance in
                                Text(appearance.title(for: settings.language))
                                    .tag(appearance)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel(copy.appearance)
                    }

                    SettingsSection(title: settings.language == .arabic ? "الصوت والبيئة" : "Sound & Ambience", icon: "speaker.wave.2.fill") {
                        Toggle(settings.language == .arabic ? "كتم الأصوات الخلفية" : "Mute Background Sounds", isOn: Binding(
                            get: { isAmbientMuted },
                            set: { newValue in
                                isAmbientMuted = newValue
                                SoundManager.shared.setMuted(newValue)
                            }
                        ))
                        .accessibilityHint(settings.language == .arabic ? "يشغل أو يكتم أصوات الخلفية." : "Turns background ambience on or off.")
                    }

                    SettingsSection(title: copy.theme, icon: "paintpalette.fill") {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 150), spacing: 10)
                            ],
                            spacing: 10
                        ) {
                            ForEach(HasanaThemeChoice.allCases) { theme in
                                ThemeChoiceButton(
                                    theme: theme,
                                    language: settings.language,
                                    isSelected: settings.theme == theme
                                ) {
                                    settings.theme = theme
                                }
                            }
                        }
                    }

                    SettingsSection(title: copy.appIcon, icon: "app.badge.fill") {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 150), spacing: 10)
                            ],
                            spacing: 10
                        ) {
                            ForEach(HasanaAppIcon.allCases) { appIcon in
                                AppIconChoiceButton(
                                    appIcon: appIcon,
                                    language: settings.language,
                                    isSelected: settings.appIcon == appIcon
                                ) {
                                    settings.appIcon = appIcon
                                }
                            }
                        }

                        if let errorMessage = settings.appIconErrorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
            }
            .background(HasanaTheme.background.ignoresSafeArea())
            .navigationTitle(copy.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy.done) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .environment(\.layoutDirection, settings.layoutDirection)
        .environment(\.locale, settings.locale)
        .preferredColorScheme(settings.colorScheme)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HasanaTheme.accent)
                    .frame(width: 24, height: 24)
                    .background(HasanaTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)

                Spacer()
            }

            content
        }
        .padding(14)
        .background(HasanaTheme.elevatedSurface.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.7), lineWidth: 0.8)
        }
    }
}

private struct ThemeChoiceButton: View {
    let theme: HasanaThemeChoice
    let language: HasanaLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: -4) {
                    ForEach(Array(theme.previewColors.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(0.7), lineWidth: 1)
                            }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(HasanaTheme.accent)
                            .accessibilityHidden(true)
                    }
                }

                Text(theme.title(for: language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(isSelected ? HasanaTheme.accentSoft.opacity(0.72) : HasanaTheme.elevatedSurfaceSoft.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? HasanaTheme.accent.opacity(0.85) : HasanaTheme.border.opacity(0.7), lineWidth: isSelected ? 1.2 : 0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityLabel: String {
        let title = theme.title(for: language)
        let state = language == .arabic
            ? (isSelected ? "محدد" : "غير محدد")
            : (isSelected ? "Selected" : "Not selected")
        return "\(title), \(state)"
    }

    private var accessibilityHint: String {
        language == .arabic ? "اضغط لاختيار هذه السمة." : "Tap to choose this theme."
    }
}

private struct AppIconChoiceButton: View {
    let appIcon: HasanaAppIcon
    let language: HasanaLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(appIcon.previewAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(HasanaTheme.border.opacity(0.46), lineWidth: 0.6)
                    }
                    .shadow(color: HasanaTheme.shadow.opacity(0.12), radius: 7, x: 0, y: 4)
                    .accessibilityHidden(true)

                Text(appIcon.title(for: language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(HasanaTheme.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(isSelected ? HasanaTheme.accentSoft.opacity(0.72) : HasanaTheme.elevatedSurfaceSoft.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? HasanaTheme.accent.opacity(0.85) : HasanaTheme.border.opacity(0.7), lineWidth: isSelected ? 1.2 : 0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityLabel: String {
        let title = appIcon.title(for: language)
        let state = language == .arabic
            ? (isSelected ? "محددة" : "غير محددة")
            : (isSelected ? "Selected" : "Not selected")
        return "\(title), \(state)"
    }

    private var accessibilityHint: String {
        language == .arabic ? "اضغط لاختيار أيقونة التطبيق هذه." : "Tap to choose this app icon."
    }
}

private struct SettingsCopy {
    let selectedLanguage: HasanaLanguage

    var title: String {
        switch selectedLanguage {
        case .arabic:
            "الإعدادات"
        case .english:
            "Settings"
        }
    }

    var done: String {
        switch selectedLanguage {
        case .arabic:
            "تم"
        case .english:
            "Done"
        }
    }

    var language: String {
        switch selectedLanguage {
        case .arabic:
            "اللغة"
        case .english:
            "Language"
        }
    }

    var appearance: String {
        switch selectedLanguage {
        case .arabic:
            "الوضع"
        case .english:
            "Mode"
        }
    }

    var theme: String {
        switch selectedLanguage {
        case .arabic:
            "السمة"
        case .english:
            "Theme"
        }
    }

    var appIcon: String {
        switch selectedLanguage {
        case .arabic:
            "أيقونة التطبيق"
        case .english:
            "App Icon"
        }
    }
}

#Preview {
    HasanaSettingsView(settings: HasanaAppSettings())
}
