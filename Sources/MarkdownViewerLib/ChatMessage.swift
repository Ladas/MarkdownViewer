import Foundation
import CryptoKit

public struct ChatMessage: Identifiable, Codable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date

    public enum Role: String, Codable {
        case user
        case assistant
    }

    public init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

public struct ChatHistory: Codable {
    /// Claude CLI session UUID — nil until first response
    public var sessionId: String?
    public let filePath: String
    public var messages: [ChatMessage]

    public init(filePath: String) {
        self.sessionId = nil
        self.filePath = filePath
        self.messages = []
    }
}

public final class ChatHistoryManager {
    private let historyURL: URL
    private let relativePath: String

    /// Claude CLI session UUID — nil until first response from Claude
    public private(set) var sessionId: String?

    public init(gitRoot: URL, fileURL: URL) {
        let chatDir = gitRoot.appendingPathComponent(".claude-chat")
        let rootPath = gitRoot.path.hasSuffix("/") ? gitRoot.path : gitRoot.path + "/"
        if fileURL.path.hasPrefix(rootPath) {
            self.relativePath = String(fileURL.path.dropFirst(rootPath.count))
        } else {
            self.relativePath = fileURL.lastPathComponent
        }

        // File key: deterministic hash of relative path, used for the history filename
        let fileKey = Self.fileKey(for: relativePath)

        if !FileManager.default.fileExists(atPath: chatDir.path) {
            try? FileManager.default.createDirectory(at: chatDir, withIntermediateDirectories: true)
        }

        self.historyURL = chatDir.appendingPathComponent("\(fileKey).json")

        // Load existing session ID from history
        if let existing = Self.loadHistory(from: historyURL) {
            self.sessionId = existing.sessionId
        }
    }

    /// Deterministic file key from relative path (for the history filename)
    static func fileKey(for relativePath: String) -> String {
        let data = Data(relativePath.utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    /// Store the Claude CLI session UUID (called after first response)
    public func setSessionId(_ id: String) {
        sessionId = id
        // Persist immediately
        var history = Self.loadHistory(from: historyURL) ?? ChatHistory(filePath: relativePath)
        history.sessionId = id
        writeHistory(history)
    }

    public func load() -> [ChatMessage] {
        Self.loadHistory(from: historyURL)?.messages ?? []
    }

    private static func loadHistory(from url: URL) -> ChatHistory? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ChatHistory.self, from: data)
    }

    public func save(_ messages: [ChatMessage]) {
        var history = Self.loadHistory(from: historyURL) ?? ChatHistory(filePath: relativePath)
        history.messages = messages
        history.sessionId = sessionId
        writeHistory(history)
    }

    public func append(_ message: ChatMessage) {
        var messages = load()
        messages.append(message)
        save(messages)
    }

    public func clear() {
        // Clear messages and session — next message starts a fresh Claude session
        sessionId = nil
        var history = ChatHistory(filePath: relativePath)
        history.sessionId = nil
        history.messages = []
        writeHistory(history)
    }

    private func writeHistory(_ history: ChatHistory) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(history) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }
}
