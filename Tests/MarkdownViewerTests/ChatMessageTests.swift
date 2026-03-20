import Testing
import Foundation
@testable import MarkdownViewerLib

@Suite("ChatMessage")
struct ChatMessageTests {

    @Test func initSetsFields() {
        let msg = ChatMessage(role: .user, content: "hello")
        #expect(msg.role == .user)
        #expect(msg.content == "hello")
        #expect(msg.id != UUID())
    }

    @Test func roleRawValues() {
        #expect(ChatMessage.Role.user.rawValue == "user")
        #expect(ChatMessage.Role.assistant.rawValue == "assistant")
    }

    @Test func encodeDecode() throws {
        let msg = ChatMessage(role: .assistant, content: "response")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(msg)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        #expect(decoded.id == msg.id)
        #expect(decoded.role == .assistant)
        #expect(decoded.content == "response")
    }
}

@Suite("ChatHistory")
struct ChatHistoryTests {

    @Test func initHasNoSession() {
        let history = ChatHistory(filePath: "test.md")
        #expect(history.sessionId == nil)
        #expect(history.filePath == "test.md")
        #expect(history.messages.isEmpty)
    }

    @Test func encodeDecode() throws {
        var history = ChatHistory(filePath: "doc.md")
        history.sessionId = "abc-123"
        history.messages = [ChatMessage(role: .user, content: "hi")]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(history)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChatHistory.self, from: data)

        #expect(decoded.sessionId == "abc-123")
        #expect(decoded.filePath == "doc.md")
        #expect(decoded.messages.count == 1)
        #expect(decoded.messages[0].content == "hi")
    }
}

@Suite("ChatHistoryManager")
struct ChatHistoryManagerTests {

    private func tempGitRoot() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("chat-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func fileKeyIsDeterministic() {
        let key1 = ChatHistoryManager.fileKey(for: "path/to/file.md")
        let key2 = ChatHistoryManager.fileKey(for: "path/to/file.md")
        #expect(key1 == key2)
        #expect(key1.count == 16) // 8 bytes * 2 hex chars
    }

    @Test func differentPathsDifferentKeys() {
        let key1 = ChatHistoryManager.fileKey(for: "a.md")
        let key2 = ChatHistoryManager.fileKey(for: "b.md")
        #expect(key1 != key2)
    }

    @Test func loadEmptyReturnsEmpty() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        let manager = ChatHistoryManager(gitRoot: root, fileURL: file)
        #expect(manager.load().isEmpty)
        #expect(manager.sessionId == nil)
    }

    @Test func appendAndLoad() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        let manager = ChatHistoryManager(gitRoot: root, fileURL: file)

        let msg = ChatMessage(role: .user, content: "hello")
        manager.append(msg)

        let loaded = manager.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].content == "hello")
    }

    @Test func setAndResetSessionId() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        let manager = ChatHistoryManager(gitRoot: root, fileURL: file)

        #expect(manager.sessionId == nil)

        manager.setSessionId("abc-123")
        #expect(manager.sessionId == "abc-123")

        manager.resetSessionId()
        #expect(manager.sessionId == nil)
    }

    @Test func sessionIdPersists() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        let manager1 = ChatHistoryManager(gitRoot: root, fileURL: file)
        manager1.setSessionId("persist-me")

        // New manager for same file should read persisted session ID
        let manager2 = ChatHistoryManager(gitRoot: root, fileURL: file)
        #expect(manager2.sessionId == "persist-me")
    }

    @Test func clearRemovesMessagesAndSession() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        let manager = ChatHistoryManager(gitRoot: root, fileURL: file)

        manager.append(ChatMessage(role: .user, content: "hello"))
        manager.setSessionId("session-1")
        manager.clear()

        #expect(manager.load().isEmpty)
        #expect(manager.sessionId == nil)
    }

    @Test func saveOverwrites() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        let manager = ChatHistoryManager(gitRoot: root, fileURL: file)

        manager.append(ChatMessage(role: .user, content: "one"))
        manager.append(ChatMessage(role: .user, content: "two"))
        #expect(manager.load().count == 2)

        manager.save([ChatMessage(role: .user, content: "only")])
        let loaded = manager.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].content == "only")
    }

    @Test func createsChatDirectory() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        _ = ChatHistoryManager(gitRoot: root, fileURL: file)

        let chatDir = root.appendingPathComponent(".claude-chat")
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: chatDir.path, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }
}
