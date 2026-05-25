import SwiftUI

struct CommandPaletteView: View {
    let viewModel: CommandPaletteViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if viewModel.isPresented {
                HasanaTheme.overlayScrim.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.setPresented(false)
                    }
                    .transition(.opacity)

                VStack(spacing: 0) {
                    searchBar

                    if viewModel.hasResults {
                        Divider()
                            .overlay(HasanaTheme.border.opacity(0.24))

                        ScrollViewReader { proxy in
                            ScrollView {
                                CommandResultsList(
                                    sections: viewModel.sections,
                                    isSelected: viewModel.isSelected,
                                    onConfirm: viewModel.confirm
                                )
                                .padding(.bottom, 6)
                            }
                            .frame(maxHeight: 280)
                            .onChange(of: viewModel.selectedIndex) { _, newIndex in
                                let results = viewModel.results
                                guard newIndex >= 0, newIndex < results.count else { return }

                                withAnimation {
                                    proxy.scrollTo(results[newIndex].id, anchor: .center)
                                }
                            }
                        }
                    }
                }
                .background(HasanaTheme.paletteBackground)
                .background(.ultraThinMaterial)
                .frame(maxWidth: 480)
                .padding(.horizontal, 24)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HasanaTheme.border.opacity(0.5), lineWidth: 0.8)
                )
                .shadow(color: HasanaTheme.shadow.opacity(0.12), radius: 24, x: 0, y: 12)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.96).combined(with: .opacity),
                    removal: .scale(scale: 0.96).combined(with: .opacity)
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
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: viewModel.isPresented)
        .onChange(of: viewModel.isPresented) { _, isPresented in
            if isPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isFocused = true
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(HasanaTheme.textMuted)
                .accessibilityHidden(true)

            TextField(
                commandPalettePlaceholder,
                text: Binding(
                    get: { viewModel.query },
                    set: { viewModel.query = $0 }
                )
            )
            .textFieldStyle(.plain)
            .focused($isFocused)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(HasanaTheme.textPrimary)
            .tint(HasanaTheme.accent)
            .submitLabel(.done)
            .onSubmit {
                viewModel.confirmSelection()
            }

            if viewModel.isSearching {
                Button {
                    viewModel.clearQuery()
                    isFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(HasanaTheme.textMuted.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var commandPalettePlaceholder: String {
        switch HasanaLanguage(rawValue: UserDefaults.standard.string(forKey: HasanaSettingsKeys.language) ?? "") ?? .arabic {
        case .arabic:
            "اكتب فكرة جديدة أو ابحث..."
        case .english:
            "Type a new idea or search..."
        }
    }
}

private struct CommandResultsList: View {
    let sections: [CommandPaletteSection]
    let isSelected: (CommandPaletteResult) -> Bool
    let onConfirm: (CommandPaletteResult) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(sections) { section in
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
        .padding(.vertical, 6)
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? HasanaTheme.accent : HasanaTheme.textMuted)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? HasanaTheme.accent.opacity(0.12) : HasanaTheme.textMuted.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(command.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HasanaTheme.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "return")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(HasanaTheme.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(isSelected ? HasanaTheme.accentSoft.opacity(0.48) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
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
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HasanaTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(HasanaTheme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(promptTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "return")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(HasanaTheme.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(isSelected ? HasanaTheme.accentSoft.opacity(0.48) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    private var promptTitle: String {
        switch HasanaLanguage(rawValue: UserDefaults.standard.string(forKey: HasanaSettingsKeys.language) ?? "") ?? .arabic {
        case .arabic:
            "أنشئ بطاقة: \"\(trimmedPrompt)\""
        case .english:
            "Create card: \"\(trimmedPrompt)\""
        }
    }
}
