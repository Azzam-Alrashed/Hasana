import SwiftUI

struct CommandPaletteView: View {
    @Bindable var viewModel: CommandPaletteViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if viewModel.isPresented {
                Color.black.opacity(0.36)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.setPresented(false)
                    }
                    .transition(.opacity)

                VStack(spacing: 0) {
                    searchBar

                    Divider()
                        .background(Color.white.opacity(0.1))

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(viewModel.filteredCommands.enumerated()), id: \.element.id) { index, command in
                                    CommandRow(
                                        command: command,
                                        isSelected: index == viewModel.selectedIndex
                                    ) {
                                        viewModel.executeCommand(command)
                                    }
                                    .id(command.id.rawValue)
                                }

                                if viewModel.canSubmitPrompt {
                                    PromptRow(prompt: viewModel.query) {
                                        viewModel.submitPromptIfNeeded()
                                    }
                                    .id("hasana-prompt")
                                }
                            }
                        }
                        .frame(maxHeight: 420)
                        .onChange(of: viewModel.selectedIndex) { _, newIndex in
                            let commands = viewModel.filteredCommands
                            guard newIndex >= 0, newIndex < commands.count else { return }

                            withAnimation {
                                proxy.scrollTo(commands[newIndex].id.rawValue, anchor: .center)
                            }
                        }
                    }

                    HStack {
                        Text("Search actions or type what you need")
                            .font(.system(size: 11, weight: .medium))
                            .opacity(0.55)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.primary.opacity(0.04))
                }
                .background(.ultraThinMaterial)
                .frame(maxWidth: 520)
                .padding(.horizontal, 16)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.28), radius: 28, x: 0, y: 16)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.94).combined(with: .opacity),
                    removal: .scale(scale: 0.94).combined(with: .opacity)
                ))
                .onAppear {
                    isFocused = true
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
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.green)

            TextField("Search Hasana...", text: $viewModel.query)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .font(.system(size: 18, weight: .medium))
                .submitLabel(.done)
                .onSubmit {
                    viewModel.confirmSelection()
                }
        }
        .padding(16)
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
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(command.title)
                        .font(.system(size: 16, weight: .semibold))

                    Text(command.subtitle)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .opacity(0.62)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "return")
                        .font(.system(size: 12, weight: .semibold))
                        .opacity(0.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.green.opacity(0.16) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        switch command.category {
        case .today:
            .teal
        case .worship:
            .green
        case .reflection:
            .indigo
        case .finance:
            .orange
        }
    }
}

private struct PromptRow: View {
    let prompt: String
    let onSelect: () -> Void

    private var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Save idea")
                        .font(.system(size: 16, weight: .semibold))

                    Text(trimmedPrompt)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .opacity(0.62)
                }

                Spacer()

                Image(systemName: "return")
                    .font(.system(size: 12, weight: .semibold))
                    .opacity(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
