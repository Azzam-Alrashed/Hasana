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
            guard query != oldValue else { return }
            selectedIndex = 0
            rebuildPresentationState()
        }
    }

    var isPresented = false
    var selectedIndex = 0
    var commands: [HasanaCommand] = HasanaCommand.defaults {
        didSet {
            refreshCommandIndex()
            rebuildPresentationState()
        }
    }

    var onExecute: ((HasanaCommandID) -> Void)?
    var onSubmitPrompt: ((String) -> Void)? {
        didSet {
            rebuildPresentationState()
        }
    }

    private(set) var results: [CommandPaletteResult] = []
    private(set) var sections: [CommandPaletteSection] = []

    @ObservationIgnored private var indexedCommands: [IndexedCommand] = []

    init() {
        refreshCommandIndex()
        rebuildPresentationState()
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSearching: Bool {
        !trimmedQuery.isEmpty
    }

    var hasResults: Bool {
        !results.isEmpty
    }

    private var rankedCommands: [HasanaCommand] {
        guard !trimmedQuery.isEmpty else { return commands }

        let queryTokens = tokenize(trimmedQuery)
        guard !queryTokens.isEmpty else { return commands }
        let normalizedQuery = normalize(trimmedQuery)

        return indexedCommands
            .compactMap { indexedCommand -> RankedCommand? in
                guard let score = score(indexedCommand, normalizedQuery: normalizedQuery, tokens: queryTokens) else {
                    return nil
                }

                return RankedCommand(
                    command: indexedCommand.command,
                    score: score,
                    index: indexedCommand.index
                )
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

    private var bestMatchesTitle: String {
        switch HasanaLanguage(rawValue: UserDefaults.standard.string(forKey: HasanaSettingsKeys.language) ?? "") ?? .arabic {
        case .arabic:
            "أفضل النتائج"
        case .english:
            "Best matches"
        }
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
        guard !prompt.isEmpty, let onSubmitPrompt else { return }

        onSubmitPrompt(prompt)
        setPresented(false)
    }

    private func refreshCommandIndex() {
        indexedCommands = commands.enumerated().map { index, command in
            IndexedCommand(
                command: command,
                normalizedTitle: normalize(command.title),
                normalizedSubtitle: normalize(command.subtitle),
                normalizedCategory: normalize(command.category.rawValue),
                normalizedKeywords: command.keywords.map(normalize),
                titleTokens: tokenize(command.title),
                index: index
            )
        }
    }

    private func rebuildPresentationState() {
        let ranked = rankedCommands
        let commandResults = ranked.map(CommandPaletteResult.command)

        if isSearching {
            results = onSubmitPrompt == nil ? commandResults : commandResults + [.prompt(trimmedQuery)]
            sections = [
                CommandPaletteSection(
                    id: "search-results",
                    title: ranked.isEmpty ? nil : bestMatchesTitle,
                    results: results
                )
            ]
        } else {
            results = commandResults
            sections = HasanaCommandCategory.displayOrder.compactMap { category in
                let categoryCommands = commands.filter { $0.category == category }
                guard !categoryCommands.isEmpty else { return nil }

                return CommandPaletteSection(
                    id: category.rawValue,
                    title: category.title,
                    results: categoryCommands.map(CommandPaletteResult.command)
                )
            }
        }

        clampSelection()
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

    private func score(_ indexedCommand: IndexedCommand, normalizedQuery: String, tokens: [String]) -> Int? {
        var score = 0

        if indexedCommand.normalizedTitle == normalizedQuery {
            score += 1_000
        } else if indexedCommand.normalizedTitle.hasPrefix(normalizedQuery) {
            score += 500
        }

        for token in tokens {
            var tokenScore = 0

            if indexedCommand.titleTokens.contains(token) {
                tokenScore = max(tokenScore, 120)
            }

            if indexedCommand.titleTokens.contains(where: { $0.hasPrefix(token) }) {
                tokenScore = max(tokenScore, 100)
            }

            if indexedCommand.normalizedTitle.contains(token) {
                tokenScore = max(tokenScore, 80)
            }

            if indexedCommand.normalizedKeywords.contains(token) {
                tokenScore = max(tokenScore, 75)
            }

            if indexedCommand.normalizedKeywords.contains(where: { $0.hasPrefix(token) }) {
                tokenScore = max(tokenScore, 65)
            }

            if indexedCommand.normalizedCategory.contains(token) {
                tokenScore = max(tokenScore, 45)
            }

            if indexedCommand.normalizedSubtitle.contains(token) {
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

    private struct IndexedCommand {
        let command: HasanaCommand
        let normalizedTitle: String
        let normalizedSubtitle: String
        let normalizedCategory: String
        let normalizedKeywords: [String]
        let titleTokens: [String]
        let index: Int
    }
}

private extension HasanaCommandCategory {
    static let displayOrder: [HasanaCommandCategory] = [
        .canvas,
        .giving,
        .app
    ]
}
