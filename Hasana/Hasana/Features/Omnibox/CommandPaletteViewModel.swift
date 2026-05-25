import Foundation
import Observation

@Observable
final class CommandPaletteViewModel {
    var query: String = "" {
        didSet {
            selectedIndex = 0
        }
    }

    var isPresented = false
    var selectedIndex = 0
    var commands: [HasanaCommand] = HasanaCommand.defaults

    var onExecute: ((HasanaCommandID) -> Void)?
    var onSubmitPrompt: ((String) -> Void)?

    var filteredCommands: [HasanaCommand] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return commands }

        return commands.filter { command in
            command.title.localizedCaseInsensitiveContains(trimmedQuery) ||
            command.subtitle.localizedCaseInsensitiveContains(trimmedQuery) ||
            command.category.rawValue.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    var canSubmitPrompt: Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedQuery.isEmpty && filteredCommands.isEmpty
    }

    private var totalResultCount: Int {
        filteredCommands.count + (canSubmitPrompt ? 1 : 0)
    }

    func setPresented(_ presented: Bool) {
        isPresented = presented

        if !presented {
            query = ""
            selectedIndex = 0
        }
    }

    func moveSelection(direction: Direction) {
        let count = totalResultCount
        guard count > 0 else { return }

        switch direction {
        case .up:
            selectedIndex = (selectedIndex - 1 + count) % count
        case .down:
            selectedIndex = (selectedIndex + 1) % count
        }
    }

    func confirmSelection() {
        let commands = filteredCommands

        if selectedIndex >= 0 && selectedIndex < commands.count {
            executeCommand(commands[selectedIndex])
        } else {
            submitPromptIfNeeded()
        }
    }

    func executeCommand(_ command: HasanaCommand) {
        onExecute?(command.id)
        setPresented(false)
    }

    func submitPromptIfNeeded() {
        let prompt = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, filteredCommands.isEmpty else { return }

        onSubmitPrompt?(prompt)
        setPresented(false)
    }

    enum Direction {
        case up
        case down
    }
}
