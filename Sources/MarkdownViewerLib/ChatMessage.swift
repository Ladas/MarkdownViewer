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
    public var sessionId: String
    public let filePath: String
    public var messages: [ChatMessage]
    public var clearCount: Int

    public init(sessionId: String, filePath: String) {
        self.sessionId = sessionId
        self.filePath = filePath
        self.messages = []
        self.clearCount = 0
    }
}

public final class ChatHistoryManager {
    private let historyURL: URL
    private let relativePath: String
    private let chatDir: URL

    public private(set) var sessionId: String

    public init(gitRoot: URL, fileURL: URL) {
        let chatDir = gitRoot.appendingPathComponent(".claude-chat")
        self.chatDir = chatDir
        let rootPath = gitRoot.path.hasSuffix("/") ? gitRoot.path : gitRoot.path + "/"
        if fileURL.path.hasPrefix(rootPath) {
            self.relativePath = String(fileURL.path.dropFirst(rootPath.count))
        } else {
            self.relativePath = fileURL.lastPathComponent
        }

        let baseId = Self.generateSessionId(for: relativePath)
        self.sessionId = baseId

        if !FileManager.default.fileExists(atPath: chatDir.path) {
            try? FileManager.default.createDirectory(at: chatDir, withIntermediateDirectories: true)
        }

        // Try to load existing history to get the current session ID
        self.historyURL = chatDir.appendingPathComponent("\(baseId).json")
        if let existing = Self.loadHistory(from: historyURL) {
            self.sessionId = existing.sessionId
        }
    }

    public static func generateSessionId(for relativePath: String) -> String {
        let data = Data(relativePath.utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    public func load() -> [ChatMessage] {
        Self.loadHistory(from: historyURL)?.messages ?? []
    }

    private static func loadHistory(from url: URL) -> ChatHistory? {
        guard let data = try? Data(contentsOf: url),
              let history = try? JSONDecoder().decode(ChatHistory.self, from: data) else {
            return nil
        }
        return history
    }

    public func save(_ messages: [ChatMessage]) {
        var history = Self.loadHistory(from: historyURL) ?? ChatHistory(sessionId: sessionId, filePath: relativePath)
        history.messages = messages
        history.sessionId = sessionId
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(history) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    public func append(_ message: ChatMessage) {
        var messages = load()
        messages.append(message)
        save(messages)
    }

    public func clear() {
        var history = Self.loadHistory(from: historyURL) ?? ChatHistory(sessionId: sessionId, filePath: relativePath)
        history.clearCount += 1
        history.messages = []
        let baseId = Self.generateSessionId(for: relativePath)
        history.sessionId = "\(baseId)-\(history.clearCount)"
        sessionId = history.sessionId
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(history) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }
}
