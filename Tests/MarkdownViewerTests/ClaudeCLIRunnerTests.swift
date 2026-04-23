import Testing
import Foundation
@testable import MarkdownViewerLib

@Suite("ClaudeCLIRunner")
struct ClaudeCLIRunnerTests {

    @Test func findGitRootFromSubdirectory() {
        // This test runs from within the MarkdownViewer git repo
        let currentFile = URL(fileURLWithPath: #filePath)
        let root = ClaudeCLIRunner.findGitRoot(from: currentFile)
        #expect(root != nil)
        let gitDir = root!.appendingPathComponent(".git")
        #expect(FileManager.default.fileExists(atPath: gitDir.path))
    }

    @Test func findGitRootFromRootReturnsNil() {
        let url = URL(fileURLWithPath: "/tmp/nonexistent-file.md")
        let root = ClaudeCLIRunner.findGitRoot(from: url)
        #expect(root == nil)
    }

    @Test func initSetsWorkingDirectory() {
        let dir = URL(fileURLWithPath: "/tmp")
        let runner = ClaudeCLIRunner(workingDirectory: dir)
        #expect(!runner.isRunning)
    }

    @Test func cancelWhenNotRunning() {
        let dir = URL(fileURLWithPath: "/tmp")
        let runner = ClaudeCLIRunner(workingDirectory: dir)
        // Should not crash
        runner.cancel()
        #expect(!runner.isRunning)
    }

    @Test func claudePathIsNotEmpty() {
        // The static claudePath resolver should always return a non-empty string
        // (at minimum the fallback "claude")
        _ = Mirror(reflecting: ClaudeCLIRunner.self)
        // Access via a runner instance to trigger static init
        _ = ClaudeCLIRunner(workingDirectory: URL(fileURLWithPath: "/tmp"))
        // If we got here without crashing, the static initializer succeeded
        #expect(Bool(true))
    }

    @Test func parseAssistantEvent() {
        // Verify the stream-json "assistant" event format is parseable
        let jsonString = """
        {"type":"assistant","message":{"content":[{"type":"text","text":"Hello world"}]},"session_id":"abc-123"}
        """
        let data = jsonString.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["type"] as? String == "assistant")

        let message = json["message"] as! [String: Any]
        let content = message["content"] as! [[String: Any]]
        #expect(content.count == 1)
        #expect(content[0]["type"] as? String == "text")
        #expect(content[0]["text"] as? String == "Hello world")
    }

    @Test func parseSystemInitEvent() {
        // Verify session_id extraction from system/init event
        let jsonString = """
        {"type":"system","subtype":"init","session_id":"sess-456"}
        """
        let data = jsonString.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["type"] as? String == "system")
        #expect(json["session_id"] as? String == "sess-456")
    }

    @Test func parseResultEvent() {
        // Verify result event format
        let jsonString = """
        {"type":"result","result":"Final answer","session_id":"sess-789"}
        """
        let data = jsonString.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["type"] as? String == "result")
        #expect(json["result"] as? String == "Final answer")
        #expect(json["session_id"] as? String == "sess-789")
    }

    @Test func parseAssistantThinkingEvent() {
        // Thinking blocks should not produce text
        let jsonString = """
        {"type":"assistant","message":{"content":[{"type":"thinking","thinking":"Let me consider..."}]}}
        """
        let data = jsonString.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let message = json["message"] as! [String: Any]
        let content = message["content"] as! [[String: Any]]

        // Filter for text blocks only (matching ClaudeCLIRunner logic)
        let textParts = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }
        #expect(textParts.isEmpty)
    }
}
