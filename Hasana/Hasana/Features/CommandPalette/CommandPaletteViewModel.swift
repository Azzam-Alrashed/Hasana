import Foundation
import Observation

enum CommandPaletteResult: Identifiable, Hashable {
    case command(HasanaCommand)
    case prompt(String)

    var id: String {
        switch self {
        case .command(let command):
            "command-\(command.id.rawValue)"
        case .prompt(let prompt):
            "prompt-\(prompt.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }
}

struct CommandPaletteSection: Identifiable, Hashable {
    let id: String
    let title: String?
    let results: [CommandPaletteResult]
}

@Observable
final class CommandPaletteViewModel {
    var query: String = "" {
        didSet {
            selectedIndex = 0
            clampSelection()
        }
    }

    var isPresented = false
    var selectedIndex = 0
    var commands: [HasanaCommand] = HasanaCommand.defaults

    var onExecute: ((HasanaCommandID) -> Void)?
    var onSubmitPrompt: ((String) -> Void)?

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSearching: Bool {
        !trimmedQuery.isEmpty
    }

    var results: [CommandPaletteResult] {
        let commandResults = rankedCommands.map(CommandPaletteResult.command)
        guard isSearching else { return commandResults }

        return commandResults + [.prompt(trimmedQuery)]
    }

    var sections: [CommandPaletteSection] {
        if isSearching {
            return [
                CommandPaletteSection(
                    id: "search-results",
                    title: rankedCommands.isEmpty ? nil : "Best matches",
                    results: results
                )
            ]
        }

        return HasanaCommandCategory.displayOrder.compactMap { category in
            let categoryCommands = commands.filter { $0.category == category }
            guard !categoryCommands.isEmpty else { return nil }

            return CommandPaletteSection(
                id: category.rawValue,
                title: category.title,
                results: categoryCommands.map(CommandPaletteResult.command)
            )
        }
    }

    var hasResults: Bool {
        !results.isEmpty
    }

    private var rankedCommands: [HasanaCommand] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return commands }

        let queryTokens = tokenize(trimmedQuery)
        guard !queryTokens.isEmpty else { return commands }

        return commands.enumerated()
            .compactMap { index, command -> RankedCommand? in
                guard let score = score(command, query: trimmedQuery, tokens: queryTokens) else {
                    return nil
                }

                return RankedCommand(command: command, score: score, index: index)
            }
            .sorted { first, second in
                if first.score == second.score {
                    return first.index < second.index
                }

                return first.score > second.score
            }
            .map(\.command)
    }

    private var totalResultCount: Int {
        results.count
    }

    func setPresented(_ presented: Bool) {
        isPresented = presented

        if !presented {
            query = ""
            selectedIndex = 0
        } else {
            clampSelection()
        }
    }

    func clearQuery() {
        query = ""
        selectedIndex = 0
    }

    func select(_ result: CommandPaletteResult) {
        guard let index = results.firstIndex(of: result) else { return }
        selectedIndex = index
    }

    func isSelected(_ result: CommandPaletteResult) -> Bool {
        results.indices.contains(selectedIndex) && results[selectedIndex] == result
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
        let count = totalResultCount
        guard count > 0 else { return }
        clampSelection()

        switch results[selectedIndex] {
        case .command(let command):
            executeCommand(command)
        case .prompt:
            submitPromptIfNeeded()
        }
    }

    func confirm(_ result: CommandPaletteResult) {
        select(result)
        confirmSelection()
    }

    func executeCommand(_ command: HasanaCommand) {
        onExecute?(command.id)
        setPresented(false)
    }

    func submitPromptIfNeeded() {
        let prompt = trimmedQuery
        guard !prompt.isEmpty else { return }

        onSubmitPrompt?(prompt)
        setPresented(false)
    }

    private func clampSelection() {
        let count = totalResultCount
        if count == 0 {
            selectedIndex = 0
        } else if selectedIndex >= count {
            selectedIndex = count - 1
        } else if selectedIndex < 0 {
            selectedIndex = 0
        }
    }

    private func score(_ command: HasanaCommand, query: String, tokens: [String]) -> Int? {
        let normalizedTitle = normalize(command.title)
        let normalizedSubtitle = normalize(command.subtitle)
        let normalizedCategory = normalize(command.category.rawValue)
        let normalizedKeywords = command.keywords.map(normalize)
        let titleTokens = tokenize(command.title)

        var score = 0

        if normalizedTitle == normalize(query) {
            score += 1_000
        } else if normalizedTitle.hasPrefix(normalize(query)) {
            score += 500
        }

        for token in tokens {
            var tokenScore = 0

            if titleTokens.contains(token) {
                tokenScore = max(tokenScore, 120)
            }

            if titleTokens.contains(where: { $0.hasPrefix(token) }) {
                tokenScore = max(tokenScore, 100)
            }

            if normalizedTitle.contains(token) {
                tokenScore = max(tokenScore, 80)
            }

            if normalizedKeywords.contains(token) {
                tokenScore = max(tokenScore, 75)
            }

            if normalizedKeywords.contains(where: { $0.hasPrefix(token) }) {
                tokenScore = max(tokenScore, 65)
            }

            if normalizedCategory.contains(token) {
                tokenScore = max(tokenScore, 45)
            }

            if normalizedSubtitle.contains(token) {
                tokenScore = max(tokenScore, 35)
            }

            guard tokenScore > 0 else { return nil }
            score += tokenScore
        }

        return score
    }

    private func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private func tokenize(_ value: String) -> [String] {
        normalize(value)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    enum Direction {
        case up
        case down
    }

    private struct RankedCommand {
        let command: HasanaCommand
        let score: Int
        let index: Int
    }
}

private extension HasanaCommandCategory {
    static let displayOrder: [HasanaCommandCategory] = [
        .canvas
    ]
}
