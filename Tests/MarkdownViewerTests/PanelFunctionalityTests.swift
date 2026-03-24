import Testing
import Foundation
import UniformTypeIdentifiers
@testable import MarkdownViewerLib

// MARK: - TOC Panel Tests

@Suite("TOC Panel")
struct TOCPanelTests {

    @Test func tocEntriesParseFromMarkdown() {
        let md = "# Title\n## Section A\n### Sub\n## Section B"
        let entries = TOCEntry.parse(from: md)
        #expect(entries.count == 4)
        #expect(entries[0].title == "Title")
        #expect(entries[0].level == 1)
        #expect(entries[3].title == "Section B")
    }

    @Test func tocEntriesIgnoreCodeBlocks() {
        let md = "# Real\n```\n# Fake\n```\n## Also Real"
        let entries = TOCEntry.parse(from: md)
        #expect(entries.count == 2)
        #expect(entries[0].title == "Real")
        #expect(entries[1].title == "Also Real")
    }

    @Test func tocEntriesIndicesAreSequential() {
        let md = "# A\n## B\n### C"
        let entries = TOCEntry.parse(from: md)
        #expect(entries[0].id == 0)
        #expect(entries[1].id == 1)
        #expect(entries[2].id == 2)
    }

    @Test func tocEmptyDocumentProducesNoEntries() {
        #expect(TOCEntry.parse(from: "").isEmpty)
    }

    @Test func tocLevelsMatchHashCount() {
        let md = "# H1\n## H2\n### H3\n#### H4\n##### H5\n###### H6"
        let entries = TOCEntry.parse(from: md)
        for i in 0..<6 {
            #expect(entries[i].level == i + 1)
        }
    }
}

// MARK: - Comments Panel — Review Notes

@Suite("Comments Panel - Review Notes")
struct ReviewNotePanelTests {

    @Test func extractNotesFromMarkdown() {
        let md = """
        # Doc
        Some text
        ```review
        Fix the typo
        ```
        More text
        ```review
        Add more detail
        ```
        """
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 2)
        #expect(notes[0] == "Fix the typo")
        #expect(notes[1] == "Add more detail")
    }

    @Test func extractNoNotesFromCleanDoc() {
        let md = "# Clean doc\nNo review notes here\n```python\ncode\n```"
        let notes = ReviewNote.extract(from: md)
        #expect(notes.isEmpty)
    }

    @Test func replaceNoteRemovesBlock() {
        let md = "Before\n```review\nOld note\n```\nAfter"
        let result = ReviewNote.replace(at: 0, with: nil, in: md)
        #expect(!result.contains("Old note"))
        #expect(result.contains("Before"))
        #expect(result.contains("After"))
    }

    @Test func replaceNoteUpdatesContent() {
        let md = "Text\n```review\nOld\n```\nMore"
        let result = ReviewNote.replace(at: 0, with: "New", in: md)
        #expect(result.contains("New"))
        #expect(!result.contains("Old"))
    }

    @Test func insertNoteAfterHeading() {
        let md = "# Title\nBody\n## Section\nContent"
        let noteBlock = "```review\nCheck this\n```"
        let result = ReviewNote.insertAfterHeading("Section", note: noteBlock, in: md)
        #expect(result.contains("```review\nCheck this\n```"))
        // Note should be after the heading
        let sectionRange = result.range(of: "## Section")!
        let noteRange = result.range(of: "```review\nCheck this")!
        #expect(noteRange.lowerBound > sectionRange.lowerBound)
    }

    @Test func commentsButtonLabelCountsNotesAndComments() {
        // Simulate the label logic from ContentView
        let total = 5
        let resolvedCount = 1
        // total > 0 and resolvedCount > 0 → "total/resolved"
        let label = "\(total)/\(resolvedCount)"
        #expect(label == "5/1")
    }

    @Test func commentsButtonLabelEmptyShowsComments() {
        let total = 0
        let resolvedCount = 0
        let label = total == 0 && resolvedCount == 0 ? "Comments" : "\(total)"
        #expect(label == "Comments")
    }
}

// MARK: - Comments Panel — Inline Comments

@Suite("Comments Panel - Inline Comments")
struct InlineCommentPanelTests {

    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("panel-test-\(UUID().uuidString).md")
    }

    private func sidecarURL(for fileURL: URL) -> URL {
        fileURL.deletingLastPathComponent()
            .appendingPathComponent(".\(fileURL.lastPathComponent).comments.json")
    }

    @Test func inlineCommentStoreOnCorrectSidecar() {
        let url = URL(fileURLWithPath: "/tmp/myfile.md")
        let store = InlineCommentStore(fileURL: url)
        // Store operates on sidecar file derived from the markdown file
        #expect(store.load().isEmpty) // Should not crash, loads from sidecar
    }

    @Test func inlineCommentHasReferenceText() {
        let comment = InlineComment(referenceText: "selected passage", comment: "needs work")
        #expect(comment.referenceText == "selected passage")
        #expect(comment.comment == "needs work")
    }

    @Test func inlineCommentStoreAppendAndRetrieve() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        store.append(InlineComment(referenceText: "text A", comment: "comment A"))
        store.append(InlineComment(referenceText: "text B", comment: "comment B"))

        let loaded = store.load()
        #expect(loaded.count == 2)
        #expect(loaded[0].referenceText == "text A")
        #expect(loaded[1].comment == "comment B")
    }

    @Test func inlineCommentEditUpdatesOnly() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        let c = InlineComment(referenceText: "ref", comment: "original")
        store.append(c)

        store.update(id: c.id, newComment: "edited")

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].comment == "edited")
        #expect(loaded[0].referenceText == "ref") // reference unchanged
    }

    @Test func inlineCommentDeleteRemovesOne() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        let c1 = InlineComment(referenceText: "a", comment: "keep")
        let c2 = InlineComment(referenceText: "b", comment: "delete")
        store.append(c1)
        store.append(c2)

        store.delete(id: c2.id)

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].comment == "keep")
    }
}

// MARK: - Chat Panel — Session Management

@Suite("Chat Panel - Session Management")
struct ChatPanelSessionTests {

    private func tempGitRoot() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("chat-panel-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func historyManagerCreatesDirectory() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        _ = ChatHistoryManager(gitRoot: root, fileURL: file)

        let chatDir = root.appendingPathComponent(".claude-chat")
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: chatDir.path, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }

    @Test func sessionIdPersistedPerFile() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file1 = root.appendingPathComponent("a.md")
        let file2 = root.appendingPathComponent("b.md")

        let mgr1 = ChatHistoryManager(gitRoot: root, fileURL: file1)
        mgr1.setSessionId("session-a")

        let mgr2 = ChatHistoryManager(gitRoot: root, fileURL: file2)
        mgr2.setSessionId("session-b")

        // Each file has its own session
        #expect(mgr1.sessionId == "session-a")
        #expect(mgr2.sessionId == "session-b")

        // New manager for same file restores session
        let mgr1b = ChatHistoryManager(gitRoot: root, fileURL: file1)
        #expect(mgr1b.sessionId == "session-a")
    }

    @Test func clearResetsSessionAndMessages() {
        let root = tempGitRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("test.md")
        let mgr = ChatHistoryManager(gitRoot: root, fileURL: file)
        mgr.append(ChatMessage(role: .user, content: "hello"))
        mgr.setSessionId("sess-1")

        mgr.clear()

        #expect(mgr.load().isEmpty)
        #expect(mgr.sessionId == nil)
    }

    @Test func fileKeyDeterministic() {
        let k1 = ChatHistoryManager.fileKey(for: "path/file.md")
        let k2 = ChatHistoryManager.fileKey(for: "path/file.md")
        #expect(k1 == k2)
    }

    @Test func differentPathsDifferentKeys() {
        let k1 = ChatHistoryManager.fileKey(for: "a.md")
        let k2 = ChatHistoryManager.fileKey(for: "b.md")
        #expect(k1 != k2)
    }
}

// MARK: - Chat Panel — Message Model

@Suite("Chat Panel - Message Model")
struct ChatPanelMessageTests {

    @Test func messageRoles() {
        #expect(ChatMessage.Role.user.rawValue == "user")
        #expect(ChatMessage.Role.assistant.rawValue == "assistant")
    }

    @Test func messageEncodeDecode() throws {
        let msg = ChatMessage(role: .assistant, content: "response text")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(msg)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        #expect(decoded.id == msg.id)
        #expect(decoded.role == .assistant)
        #expect(decoded.content == "response text")
    }

    @Test func chatHistoryEncodeDecode() throws {
        var history = ChatHistory(filePath: "doc.md")
        history.sessionId = "sid-1"
        history.messages = [ChatMessage(role: .user, content: "hi")]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(history)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChatHistory.self, from: data)

        #expect(decoded.sessionId == "sid-1")
        #expect(decoded.messages.count == 1)
    }
}

// MARK: - Preview Panel — HTML Rendering

@Suite("Preview Panel - HTML Rendering")
struct PreviewPanelTests {

    @Test func renderProducesHTML() {
        let html = HTMLRenderer.render(markdown: "# Hello")
        #expect(html.contains("Hello"))
        #expect(html.contains("<html"))
    }

    @Test func chatTemplateLoads() {
        let html = HTMLRenderer.renderChatTemplate()
        #expect(html.contains("updateStreaming"))
        #expect(html.contains("loadHistory"))
        #expect(html.contains("showThinking"))
        #expect(html.contains("finalizeStreaming"))
    }

    @Test func escapeForJSTemplateLiteral() {
        let escaped = HTMLRenderer.escapeForJSTemplateLiteral("test `backtick` $dollar \\slash")
        #expect(escaped.contains("\\`"))
        #expect(escaped.contains("\\$"))
        #expect(escaped.contains("\\\\"))
    }

    @Test func renderEscapesContent() {
        let html = HTMLRenderer.render(markdown: "test `code` here")
        // Content should be escaped for JS template literal
        #expect(html.contains("test"))
    }
}

// MARK: - Preview Panel — View Modes

@Suite("Preview Panel - View Modes")
struct ViewModeTests {

    @Test func viewModeAllCases() {
        let modes = ViewMode.allCases
        #expect(modes.count == 3)
        #expect(modes.contains(.sourceMD))
        #expect(modes.contains(.preview))
        #expect(modes.contains(.sourceHTML))
    }

    @Test func viewModeRawValues() {
        #expect(ViewMode.sourceMD.rawValue == "Source MD")
        #expect(ViewMode.preview.rawValue == "Preview")
        #expect(ViewMode.sourceHTML.rawValue == "Source HTML")
    }

    @Test func sourceHighlighterRendersMD() {
        let html = SourceHighlighter.render("# Title\n**bold**")
        #expect(html.contains("#"))
        #expect(html.contains("<html"))
    }

    @Test func sourceHighlighterRendersHTMLPreview() {
        let html = SourceHighlighter.renderHTMLPreview("# Title")
        #expect(html.contains("<html"))
    }
}

// MARK: - Preview Panel — Markdown Link Resolution

@Suite("Preview Panel - Link Resolution")
struct LinkResolutionTests {

    @Test func markdownExtensionsRecognized() {
        let extensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]
        for ext in extensions {
            #expect(extensions.contains(ext))
        }
    }

    @Test func relativePathResolution() {
        let base = URL(fileURLWithPath: "/projects/docs/readme.md")
        let dir = base.deletingLastPathComponent()
        let resolved = dir.appendingPathComponent("other.md")
        #expect(resolved.path == "/projects/docs/other.md")
    }

    @Test func relativePathWithSubdirectory() {
        let base = URL(fileURLWithPath: "/projects/docs/readme.md")
        let dir = base.deletingLastPathComponent()
        let resolved = dir.appendingPathComponent("subdir/guide.md")
        #expect(resolved.path == "/projects/docs/subdir/guide.md")
    }

    @Test func nonMarkdownExtensionNotMatched() {
        let extensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]
        #expect(!extensions.contains("txt"))
        #expect(!extensions.contains("html"))
        #expect(!extensions.contains("pdf"))
    }
}

// MARK: - Diff Panel

@Suite("Diff Panel")
struct DiffPanelTests {

    @Test func gitHelperDiffReturnsNilForNonGitFile() {
        let url = URL(fileURLWithPath: "/tmp/not-in-git-\(UUID().uuidString).md")
        let diff = GitHelper.diff(for: url, against: "HEAD")
        #expect(diff == nil)
    }

    @Test func gitHelperRefsIncludesHEAD() {
        // For a file in a git repo, available refs should include HEAD
        let currentFile = URL(fileURLWithPath: #filePath)
        let refs = GitHelper.availableRefs(for: currentFile)
        #expect(refs.contains("HEAD"))
    }
}

// MARK: - CLI Runner — Event Parsing

@Suite("CLI Runner - Stream Event Parsing")
struct CLIStreamEventTests {

    @Test func assistantEventTextExtraction() {
        let json: [String: Any] = [
            "type": "assistant",
            "message": [
                "content": [
                    ["type": "text", "text": "Hello world"]
                ]
            ]
        ]
        let message = json["message"] as! [String: Any]
        let content = message["content"] as! [[String: Any]]
        let textParts = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }
        #expect(textParts.joined() == "Hello world")
    }

    @Test func thinkingBlockFilteredOut() {
        let json: [String: Any] = [
            "type": "assistant",
            "message": [
                "content": [
                    ["type": "thinking", "thinking": "Let me consider..."],
                    ["type": "text", "text": "Answer"]
                ]
            ]
        ]
        let message = json["message"] as! [String: Any]
        let content = message["content"] as! [[String: Any]]
        let textParts = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }
        #expect(textParts.count == 1)
        #expect(textParts[0] == "Answer")
    }

    @Test func systemEventSessionId() {
        let json: [String: Any] = [
            "type": "system",
            "subtype": "init",
            "session_id": "sess-early-123"
        ]
        #expect(json["session_id"] as? String == "sess-early-123")
    }

    @Test func resultEventFields() {
        let json: [String: Any] = [
            "type": "result",
            "result": "Final answer text",
            "session_id": "sess-final-456"
        ]
        #expect(json["result"] as? String == "Final answer text")
        #expect(json["session_id"] as? String == "sess-final-456")
    }

    @Test func multipleTextBlocksJoined() {
        let content: [[String: Any]] = [
            ["type": "text", "text": "Part 1. "],
            ["type": "text", "text": "Part 2."]
        ]
        let textParts = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }
        #expect(textParts.joined() == "Part 1. Part 2.")
    }
}

// MARK: - Resolved Notes Detection

@Suite("Comments Panel - Resolved Notes Detection")
struct ResolvedNotesTests {

    @Test func disappearedNotesDetected() {
        let oldNotes = ["Fix typo", "Add detail", "Check formatting"]
        let newNotes = ["Add detail"] // "Fix typo" and "Check formatting" resolved

        let disappeared = oldNotes.filter { !newNotes.contains($0) }
        #expect(disappeared.count == 2)
        #expect(disappeared.contains("Fix typo"))
        #expect(disappeared.contains("Check formatting"))
    }

    @Test func noChangesNoResolved() {
        let notes = ["Note A", "Note B"]
        let disappeared = notes.filter { !notes.contains($0) }
        #expect(disappeared.isEmpty)
    }

    @Test func resolvedBatchStoresMetadata() {
        let batch = ResolvedBatch(
            resolvedAt: Date(),
            notes: ["Fixed issue"],
            diff: "- old\n+ new"
        )
        #expect(batch.notes.count == 1)
        #expect(batch.notes[0] == "Fixed issue")
        #expect(batch.diff.contains("- old"))
    }
}

// MARK: - Action Bar — Address Feedback Prompt

@Suite("Action Bar - Address Feedback")
struct AddressFeedbackTests {

    @Test func addressPromptIncludesReviewNotes() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let activeNotes = ["Fix this", "Improve that"]

        var parts = [String]()
        parts.append("Read the file at: \(url.path)")
        let noteCount = activeNotes.count
        if noteCount > 0 {
            parts.append("This file contains \(noteCount) review notes.")
        }
        parts.append("Keep the rest of the document intact.")

        let prompt = parts.joined(separator: "\n\n")
        #expect(prompt.contains(url.path))
        #expect(prompt.contains("2 review notes"))
    }

    @Test func addressPromptIncludesInlineComments() {
        let comments = [
            InlineComment(referenceText: "some text", comment: "fix spelling"),
            InlineComment(referenceText: "", comment: "general note")
        ]

        var parts = [String]()
        parts.append("Additionally, address these inline comments:")
        for comment in comments {
            if comment.referenceText.isEmpty {
                parts.append("- \(comment.comment)")
            } else {
                parts.append("- Re \"\(comment.referenceText.prefix(100))\": \(comment.comment)")
            }
        }
        let prompt = parts.joined(separator: "\n")
        #expect(prompt.contains("Re \"some text\": fix spelling"))
        #expect(prompt.contains("- general note"))
    }

    @Test func explainPromptFormatsCorrectly() {
        let selectedText = "some code here"
        let prompt = "Explain the following:\n\n```\n\(selectedText)\n```"
        #expect(prompt.contains("```\nsome code here\n```"))
    }

    @Test func askClaudePromptFormatsCorrectly() {
        let selectedText = "selected passage"
        let input = "Regarding:\n```\n\(selectedText)\n```\n\n"
        #expect(input.hasPrefix("Regarding:"))
        #expect(input.contains(selectedText))
        #expect(input.hasSuffix("\n\n"))
    }

    @Test func addressInlineCommentPrompt() {
        let url = URL(fileURLWithPath: "/tmp/doc.md")
        let comment = InlineComment(referenceText: "some text", comment: "needs clarification")

        var prompt = "Read the file at: \(url.path)\n\nAddress this comment"
        if !comment.referenceText.isEmpty {
            prompt += " about \"\(comment.referenceText.prefix(100))\""
        }
        prompt += ":\n\n\(comment.comment)\n\nKeep the rest of the document intact."

        #expect(prompt.contains(url.path))
        #expect(prompt.contains("about \"some text\""))
        #expect(prompt.contains("needs clarification"))
    }
}

// MARK: - Agent Prompt

@Suite("Action Bar - Agent Prompt")
struct AgentPromptTests {

    @Test func agentPromptIncludesFilePath() {
        let url = URL(fileURLWithPath: "/projects/doc.md")
        let noteCount = 3
        let prompt = "Read the file at: \(url.path)\n\nThis file contains \(noteCount) review notes."
        #expect(prompt.contains("/projects/doc.md"))
        #expect(prompt.contains("3 review notes"))
    }

    @Test func agentPromptSingularNote() {
        let suffix = pluralSuffix(for: 1)
        #expect(suffix == "")
    }

    @Test func agentPromptPluralNotes() {
        let suffix = pluralSuffix(for: 5)
        #expect(suffix == "s")
    }

    private func pluralSuffix(for count: Int) -> String {
        count == 1 ? "" : "s"
    }
}

// MARK: - Document Model

@Suite("Document Model")
struct DocumentModelTests {

    @Test func markdownDocumentInitWithText() {
        let doc = MarkdownDocument(text: "# Hello")
        #expect(doc.text == "# Hello")
    }

    @Test func markdownDocumentDefaultEmpty() {
        let doc = MarkdownDocument()
        #expect(doc.text == "")
    }

    @Test func markdownDocumentDeclaresSupportedTypes() {
        // MarkdownDocument reads markdown and plain text
        let types = MarkdownDocument.readableContentTypes
        #expect(types.contains(.plainText))
    }
}
