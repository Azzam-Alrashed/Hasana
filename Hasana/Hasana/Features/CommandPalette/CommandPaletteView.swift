import SwiftUI

struct CommandPaletteView: View {
    let viewModel: CommandPaletteViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if viewModel.isPresented {
                HasanaTheme.overlayScrim.opacity(0.34)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.setPresented(false)
                    }
                    .transition(.opacity)

                VStack(spacing: 0) {
                    searchBar

                    Divider()
                        .overlay(HasanaTheme.border.opacity(0.38))

                    ScrollViewReader { proxy in
                        ScrollView {
                            CommandResultsList(
                                sections: viewModel.sections,
                                isSelected: viewModel.isSelected,
                                onConfirm: viewModel.confirm
                            )
                        }
                        .frame(maxHeight: 420)
                        .onChange(of: viewModel.selectedIndex) { _, newIndex in
                            let results = viewModel.results
                            guard newIndex >= 0, newIndex < results.count else { return }

                            withAnimation {
                                proxy.scrollTo(results[newIndex].id, anchor: .center)
                            }
                        }
                    }

                    footer
                }
                .background(HasanaTheme.paletteBackground)
                .background(.ultraThinMaterial)
                .frame(maxWidth: 520)
                .padding(.horizontal, 16)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(HasanaTheme.border.opacity(0.9), lineWidth: 0.7)
                )
                .shadow(color: HasanaTheme.shadow.opacity(0.24), radius: 28, x: 0, y: 16)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.94).combined(with: .opacity),
                    removal: .scale(scale: 0.94).combined(with: .opacity)
                ))
                .onAppear {
                    isFocused = true
                }
                .onKeyPress(.upArrow) {
                    viewModel.moveSelection(direction: .up)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    viewModel.moveSelection(direction: .down)
                    return .handled
                }
                .onKeyPress(.escape) {
                    viewModel.setPresented(false)
                    return .handled
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: viewModel.isPresented)
        .onChange(of: viewModel.isPresented) { _, isPresented in
            if isPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(HasanaTheme.gold)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("أوامر حسنة")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .textCase(.uppercase)
                    .accessibilityHidden(true)

                TextField(
                    "ابحث عن أمر أو اكتب ما تحتاجه",
                    text: Binding(
                        get: { viewModel.query },
                        set: { viewModel.query = $0 }
                    )
                )
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .tint(HasanaTheme.accent)
                    .submitLabel(.done)
                    .accessibilityLabel("البحث في أوامر حسنة")
                    .onSubmit {
                        viewModel.confirmSelection()
                    }
            }

            if viewModel.isSearching {
                Button {
                    viewModel.clearQuery()
                    isFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                    .accessibilityLabel("مسح البحث")
            }
        }
        .padding(16)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Label("تنقل", systemImage: "arrow.up.arrow.down")
            Label("فتح", systemImage: "return")
            Label("إغلاق", systemImage: "escape")
            Spacer(minLength: 0)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(HasanaTheme.textMuted)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HasanaTheme.accentSoft.opacity(0.44))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("استخدم الأسهم للتنقل، والرجوع للفتح، والهروب للإغلاق")
    }
}

private struct CommandResultsList: View {
    let sections: [CommandPaletteSection]
    let isSelected: (CommandPaletteResult) -> Bool
    let onConfirm: (CommandPaletteResult) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(sections) { section in
                if let title = section.title {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .textCase(.uppercase)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .accessibilityHidden(true)
                }

                ForEach(section.results) { result in
                    ResultRow(
                        result: result,
                        isSelected: isSelected(result)
                    ) {
                        onConfirm(result)
                    }
                    .id(result.id)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ResultRow: View {
    let result: CommandPaletteResult
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        switch result {
        case .command(let command):
            CommandRow(command: command, isSelected: isSelected, onSelect: onSelect)
        case .prompt(let prompt):
            PromptRow(prompt: prompt, isSelected: isSelected, onSelect: onSelect)
        }
    }
}

private struct CommandRow: View {
    let command: HasanaCommand
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: command.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(command.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HasanaTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(command.category.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(iconColor.opacity(0.12))
                            .clipShape(Capsule())
                            .lineLimit(1)
                    }

                    Text(command.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                trailingHint
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 58)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? HasanaTheme.accent.opacity(0.45) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .accessibilityLabel("\(command.title), \(command.category.title)")
        .accessibilityHint(command.subtitle)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var trailingHint: some View {
        if isSelected {
            Image(systemName: "return")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(HasanaTheme.accent)
                .frame(width: 26, height: 26)
                .background(HasanaTheme.accentSoft.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .accessibilityHidden(true)
        } else if let shortcutHint = command.shortcutHint {
            Text(shortcutHint)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HasanaTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var rowBackground: Color {
        isSelected ? HasanaTheme.accentSoft.opacity(0.82) : HasanaTheme.elevatedSurface.opacity(0.4)
    }

    private var iconColor: Color {
        HasanaTheme.categoryColor(command.category)
    }
}

private struct PromptRow: View {
    let prompt: String
    let isSelected: Bool
    let onSelect: () -> Void

    private var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HasanaTheme.accent)
                    .frame(width: 34, height: 34)
                    .background(HasanaTheme.accentSoft.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("حفظ كأولوية")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .lineLimit(1)

                    Text(trimmedPrompt)
                        .font(.system(size: 12))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                if isSelected {
                    Image(systemName: "return")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(HasanaTheme.accent)
                        .frame(width: 26, height: 26)
                        .background(HasanaTheme.accentSoft.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 58)
            .background(isSelected ? HasanaTheme.accentSoft.opacity(0.82) : HasanaTheme.elevatedSurface.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? HasanaTheme.accent.opacity(0.45) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .accessibilityLabel("حفظ كأولوية")
        .accessibilityHint(trimmedPrompt)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
