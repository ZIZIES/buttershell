import Foundation

struct StarterCommand: Decodable, Identifiable {
    let name: String
    let command: String
    let detail: String
    let tags: [String]

    var id: String { command }

    func score(for query: String) -> Int? {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return 0 }

        let fields = [name, command, detail] + tags
        if fields.contains(where: { $0.lowercased().hasPrefix(needle) }) { return 0 }
        if fields.contains(where: { $0.lowercased().contains(needle) }) { return 1 }

        let words = needle.split(whereSeparator: { $0.isWhitespace })
        guard !words.isEmpty, words.allSatisfy({ word in
            fields.contains(where: { $0.lowercased().contains(word) })
        }) else { return nil }
        return 2
    }

    static let bundled: [StarterCommand] = {
        guard let url = Bundle.module.url(forResource: "starter-commands", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let commands = try? JSONDecoder().decode([StarterCommand].self, from: data) else {
            return []
        }
        return commands
    }()
}
