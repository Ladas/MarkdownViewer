import Foundation

public struct InlineComment: Codable, Identifiable {
    public let id: UUID
    public let referenceText: String
    public let comment: String
    public let timestamp: Date

    public init(referenceText: String, comment: String) {
        self.id = UUID()
        self.referenceText = referenceText
        self.comment = comment
        self.timestamp = Date()
    }
}

public final class InlineCommentStore {
    private let sidecarURL: URL

    public init(fileURL: URL) {
        let dir = fileURL.deletingLastPathComponent()
        let name = ".\(fileURL.lastPathComponent).comments.json"
        self.sidecarURL = dir.appendingPathComponent(name)
    }

    public func load() -> [InlineComment] {
        guard let data = try? Data(contentsOf: sidecarURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([InlineComment].self, from: data)) ?? []
    }

    public func save(_ comments: [InlineComment]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(comments) else { return }
        try? data.write(to: sidecarURL, options: .atomic)
    }

    public func append(_ comment: InlineComment) {
        var comments = load()
        comments.append(comment)
        save(comments)
    }

    public func delete(id: UUID) {
        var comments = load()
        comments.removeAll { $0.id == id }
        save(comments)
    }

    public func update(id: UUID, newComment: String) {
        var comments = load()
        guard let index = comments.firstIndex(where: { $0.id == id }) else { return }
        let old = comments[index]
        comments[index] = InlineComment(referenceText: old.referenceText, comment: newComment)
        save(comments)
    }
}
