# Chat Panel Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the chat panel to render messages as formatted markdown via WKWebView, add per-file Claude CLI session persistence, and make the panel resizable.

**Architecture:** Replace the SwiftUI `ScrollView` + plain `Text` message bubbles with a single `WKWebView` that uses the same marked.js/DOMPurify/github-markdown-css pipeline as the main view. Claude CLI sessions are tied to each markdown file via `--resume <session-id>`. A draggable divider replaces the fixed-height panel frame.

**Tech Stack:** Swift/SwiftUI, WKWebView, WebKit, marked.js, DOMPurify, github-markdown-css

**Spec:** `docs/superpowers/specs/2026-03-18-chat-panel-redesign-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `Sources/MarkdownViewerLib/Resources/chat-template.html` | Create | HTML + CSS + JS for chat rendering with message layout, dark mode, JS API |
| `Sources/MarkdownViewerLib/HTMLRenderer.swift` | Modify | Add `renderChatTemplate()` static method |
| `Sources/MarkdownViewerLib/ChatMessage.swift` | Modify | Per-file JSON history, session ID generation |
| `Sources/MarkdownViewerLib/ClaudeCLIRunner.swift` | Modify | Add `sessionId` parameter, `--resume` flag |
| `Sources/MarkdownViewerLib/ChatPanelView.swift` | Rewrite | Replace ScrollView with ChatWebView, session management |
| `Sources/MarkdownViewerLib/ContentView.swift` | Modify | Draggable divider, `chatPanelHeight` state |

---

### Task 1: Create `chat-template.html`

**Files:**
- Create: `Sources/MarkdownViewerLib/Resources/chat-template.html`

- [ ] **Step 1: Create the chat template HTML file**

This file follows the same placeholder pattern as `template.html`. It includes vendor CSS/JS via placeholders, defines message styling, and exposes a JS API.

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="Content-Security-Policy"
          content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; img-src data: https:; font-src data:;">
    <style>/* {{VENDOR_CSS}} */</style>
    <style>/* {{FA_CSS}} */</style>
    <script>/* {{PURIFY_JS}} */</script>
    <script>/* {{MARKED_JS}} */</script>
    <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
        font-size: 13px;
        padding: 8px;
        background: #ffffff;
        color: #1f2328;
        overflow-y: auto;
    }
    @media (prefers-color-scheme: dark) {
        body { background: #1e1e1e; color: #e6edf3; }
    }
    .message {
        margin-bottom: 8px;
        padding: 8px 10px;
        border-radius: 8px;
        overflow-wrap: break-word;
    }
    .message-user {
        background: rgba(0, 122, 255, 0.05);
        border-left: 3px solid rgba(0, 122, 255, 0.3);
    }
    .message-assistant {
        background: rgba(175, 82, 222, 0.05);
        border-left: 3px solid rgba(175, 82, 222, 0.3);
    }
    @media (prefers-color-scheme: dark) {
        .message-user {
            background: rgba(0, 122, 255, 0.1);
            border-left-color: rgba(0, 122, 255, 0.4);
        }
        .message-assistant {
            background: rgba(175, 82, 222, 0.1);
            border-left-color: rgba(175, 82, 222, 0.4);
        }
    }
    .message-label {
        font-size: 10px;
        font-weight: 600;
        margin-bottom: 4px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    .message-user .message-label { color: rgba(0, 122, 255, 0.7); }
    .message-assistant .message-label { color: rgba(175, 82, 222, 0.7); }
    .message-timestamp {
        font-size: 9px;
        color: #8b949e;
        margin-top: 4px;
    }
    .message .markdown-body {
        font-size: 12px;
        background: transparent !important;
        padding: 0 !important;
    }
    .message .markdown-body pre {
        font-size: 11px;
    }
    .streaming-cursor::after {
        content: '▌';
        animation: blink 1s step-end infinite;
        color: rgba(175, 82, 222, 0.5);
    }
    @keyframes blink { 50% { opacity: 0; } }
    #empty-state {
        text-align: center;
        padding: 32px 16px;
        color: #8b949e;
    }
    #empty-state .icon { font-size: 24px; margin-bottom: 8px; opacity: 0.3; }
    #empty-state .title { font-size: 12px; margin-bottom: 4px; }
    #empty-state .subtitle { font-size: 10px; opacity: 0.7; }
    </style>
</head>
<body>
    <div id="messages"></div>
    <div id="empty-state">
        <div class="icon">💬</div>
        <div class="title">Ask Claude about this project</div>
        <div class="subtitle">Toggle "Allow editing" to let Claude modify files</div>
    </div>

    <script>
    var messagesEl = document.getElementById('messages');
    var emptyState = document.getElementById('empty-state');
    var streamingEl = null;

    function renderMarkdown(text) {
        if (typeof marked !== 'undefined') {
            var html = marked.parse(text);
            if (typeof DOMPurify !== 'undefined') {
                return DOMPurify.sanitize(html);
            }
        }
        // Fallback: escape and wrap in pre
        var div = document.createElement('div');
        div.textContent = text;
        return '<pre>' + div.innerHTML + '</pre>';
    }

    function formatTimestamp(ts) {
        try {
            var d = new Date(ts);
            return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        } catch(e) { return ''; }
    }

    function createMessageEl(role, htmlContent, timestamp) {
        var div = document.createElement('div');
        div.className = 'message message-' + role;

        var label = document.createElement('div');
        label.className = 'message-label';
        label.textContent = role === 'user' ? 'You' : 'Claude';
        div.appendChild(label);

        var body = document.createElement('div');
        body.className = 'markdown-body';
        body.innerHTML = htmlContent;
        div.appendChild(body);

        if (timestamp) {
            var ts = document.createElement('div');
            ts.className = 'message-timestamp';
            ts.textContent = formatTimestamp(timestamp);
            div.appendChild(ts);
        }

        return div;
    }

    function scrollToBottom() {
        window.scrollTo(0, document.body.scrollHeight);
    }

    function addMessage(role, markdownContent, timestamp) {
        emptyState.style.display = 'none';
        var html = renderMarkdown(markdownContent);
        var el = createMessageEl(role, html, timestamp);
        messagesEl.appendChild(el);
        scrollToBottom();
    }

    function updateStreaming(markdownContent) {
        if (!streamingEl) {
            emptyState.style.display = 'none';
            streamingEl = document.createElement('div');
            streamingEl.className = 'message message-assistant';

            var label = document.createElement('div');
            label.className = 'message-label';
            label.textContent = 'Claude';
            streamingEl.appendChild(label);

            var body = document.createElement('div');
            body.className = 'markdown-body streaming-cursor';
            streamingEl.appendChild(body);

            messagesEl.appendChild(streamingEl);
        }
        var body = streamingEl.querySelector('.markdown-body');
        body.innerHTML = renderMarkdown(markdownContent);
        scrollToBottom();
    }

    function finalizeStreaming(timestamp) {
        if (streamingEl) {
            var body = streamingEl.querySelector('.markdown-body');
            body.classList.remove('streaming-cursor');
            if (timestamp) {
                var ts = document.createElement('div');
                ts.className = 'message-timestamp';
                ts.textContent = formatTimestamp(timestamp);
                streamingEl.appendChild(ts);
            }
            streamingEl = null;
        }
    }

    function clearMessages() {
        messagesEl.innerHTML = '';
        streamingEl = null;
        emptyState.style.display = 'block';
    }

    function showThinking() {
        emptyState.style.display = 'none';
        if (!streamingEl) {
            streamingEl = document.createElement('div');
            streamingEl.className = 'message message-assistant';

            var label = document.createElement('div');
            label.className = 'message-label';
            label.textContent = 'Claude';
            streamingEl.appendChild(label);

            var body = document.createElement('div');
            body.className = 'markdown-body streaming-cursor';
            body.innerHTML = '<em style="color:#8b949e">Thinking...</em>';
            streamingEl.appendChild(body);

            messagesEl.appendChild(streamingEl);
            scrollToBottom();
        }
    }

    function loadHistory(messages) {
        clearMessages();
        if (!messages || messages.length === 0) {
            emptyState.style.display = 'block';
            return;
        }
        emptyState.style.display = 'none';
        messages.forEach(function(msg) {
            var html = renderMarkdown(msg.content);
            var el = createMessageEl(msg.role, html, msg.timestamp);
            messagesEl.appendChild(el);
        });
        scrollToBottom();
    }
    </script>
</body>
</html>
```

- [ ] **Step 2: Verify the file is in the right location**

Run: `ls -la Sources/MarkdownViewerLib/Resources/chat-template.html`
Expected: file exists

- [ ] **Step 3: Commit**

```bash
git add Sources/MarkdownViewerLib/Resources/chat-template.html
git commit -m "feat: add chat-template.html for markdown-rendered chat messages"
```

---

### Task 2: Add `renderChatTemplate()` to `HTMLRenderer.swift`

**Files:**
- Modify: `Sources/MarkdownViewerLib/HTMLRenderer.swift`

- [ ] **Step 1: Add the chat template static property and method**

Add after the existing `preparedTemplate` (around line 21):

```swift
private static let preparedChatTemplate: String = {
    let vendorCSS = loadResource("github-markdown", withExtension: "css", subdirectory: "Resources/vendor") ?? ""
    let faCSS = loadResource("fontawesome", withExtension: "css", subdirectory: "Resources/vendor") ?? ""
    let markedJS = loadResource("marked.min", withExtension: "js", subdirectory: "Resources/vendor") ?? ""
    let purifyJS = loadResource("purify.min", withExtension: "js", subdirectory: "Resources/vendor") ?? ""
    let template = loadResource("chat-template", withExtension: "html") ?? fallbackTemplate()
    return template
        .replacingOccurrences(of: "/* {{VENDOR_CSS}} */", with: vendorCSS)
        .replacingOccurrences(of: "/* {{FA_CSS}} */", with: faCSS)
        .replacingOccurrences(of: "/* {{MARKED_JS}} */", with: markedJS)
        .replacingOccurrences(of: "/* {{PURIFY_JS}} */", with: purifyJS)
}()

public static func renderChatTemplate() -> String {
    preparedChatTemplate
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1`
Expected: Build complete with no errors

- [ ] **Step 3: Commit**

```bash
git add Sources/MarkdownViewerLib/HTMLRenderer.swift
git commit -m "feat: add renderChatTemplate() to HTMLRenderer"
```

---

### Task 3: Update `ChatMessage.swift` — per-file history and session IDs

**Files:**
- Modify: `Sources/MarkdownViewerLib/ChatMessage.swift`

- [ ] **Step 1: Rewrite ChatMessage.swift with session-aware history**

Replace the entire file with:

```swift
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
```

- [ ] **Step 2: Do NOT build or commit yet**

This task changes the `ChatHistoryManager` initializer signature which breaks `ChatPanelView`. Continue directly to Task 4 and Task 5 — they will be committed together to keep the build green.

---

### Task 4: Update `ClaudeCLIRunner.swift` — add `--resume` support

**Files:**
- Modify: `Sources/MarkdownViewerLib/ClaudeCLIRunner.swift`

- [ ] **Step 1: Add `sessionId` parameter to `run()`**

In `ClaudeCLIRunner.swift`, update the `run` method signature and command building:

```swift
public func run(
    prompt: String,
    allowEditing: Bool = false,
    sessionId: String? = nil,
    onOutput: @escaping @Sendable (String) -> Void,
    onComplete: @escaping @Sendable (Int32) -> Void
) {
    let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

    let escapedPrompt = prompt
        .replacingOccurrences(of: "'", with: "'\\''")
    var claudeCmd = "claude -p '\(escapedPrompt)'"
    if let sid = sessionId {
        claudeCmd += " --resume '\(sid)'"
    }
    if allowEditing {
        claudeCmd += " --dangerously-skip-permissions"
    }

    // ... rest of the method unchanged
```

- [ ] **Step 2: Do NOT build or commit yet**

Continue to Task 5. Tasks 3, 4, and 5 will be built and committed together.

---

### Task 5: Rewrite `ChatPanelView.swift` — ChatWebView + session management

**Files:**
- Rewrite: `Sources/MarkdownViewerLib/ChatPanelView.swift`

- [ ] **Step 1: Rewrite ChatPanelView.swift**

Replace the entire file. Key changes:
- `ChatWebView`: new `NSViewRepresentable` wrapping WKWebView, loads `HTMLRenderer.renderChatTemplate()`
- `ChatPanelView`: uses `ChatWebView` instead of `ScrollView` + `MessageBubble`
- Session ID passed to `ClaudeCLIRunner.run()`
- Messages serialized as JSON for `loadHistory()` JS call
- `dismantleNSView` cleans up script message handlers

```swift
import SwiftUI
import WebKit

// MARK: - ChatWebView

struct ChatWebView: NSViewRepresentable {
    let messages: [ChatMessage]
    let streamingText: String
    let isStreaming: Bool

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        let html = HTMLRenderer.renderChatTemplate()
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coord = context.coordinator
        guard coord.pageLoaded else {
            coord.pendingMessages = messages
            coord.pendingStreaming = isStreaming ? streamingText : nil
            return
        }

        if coord.lastMessageCount != messages.count {
            coord.lastMessageCount = messages.count
            coord.loadAllMessages(messages, in: webView)
        }

        if isStreaming && streamingText.isEmpty && !coord.wasStreaming {
            // Show "Thinking..." before first chunk arrives
            webView.evaluateJavaScript("showThinking()") { _, _ in }
        } else if isStreaming && !streamingText.isEmpty {
            coord.updateStreaming(streamingText, in: webView)
        } else if !isStreaming && coord.wasStreaming {
            coord.finalizeStreaming(in: webView)
        }
        coord.wasStreaming = isStreaming
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.webView = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var pageLoaded = false
        var lastMessageCount = 0
        var wasStreaming = false
        var pendingMessages: [ChatMessage]?
        var pendingStreaming: String?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pageLoaded = true
            if let msgs = pendingMessages {
                pendingMessages = nil
                loadAllMessages(msgs, in: webView)
            }
            if let streaming = pendingStreaming {
                pendingStreaming = nil
                updateStreaming(streaming, in: webView)
            }
        }

        func loadAllMessages(_ messages: [ChatMessage], in webView: WKWebView) {
            struct MessageDTO: Encodable {
                let role: String
                let content: String
                let timestamp: Date
            }
            let dtos = messages.map { MessageDTO(role: $0.role.rawValue, content: $0.content, timestamp: $0.timestamp) }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(dtos),
                  let json = String(data: data, encoding: .utf8) else { return }
            // Pass JSON array directly — loadHistory() accepts an object, not a string
            webView.evaluateJavaScript("loadHistory(\(json))") { _, _ in }
        }

        func updateStreaming(_ text: String, in webView: WKWebView) {
            guard let data = try? JSONEncoder().encode(text),
                  let json = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("updateStreaming(\(json))") { _, _ in }
        }

        func finalizeStreaming(in webView: WKWebView) {
            let ts = ISO8601DateFormatter().string(from: Date())
            webView.evaluateJavaScript("finalizeStreaming('\(ts)')") { _, _ in }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                let allowed: Set<String> = ["http", "https", "mailto"]
                if let scheme = url.scheme?.lowercased(), allowed.contains(scheme) {
                    NSWorkspace.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - ChatPanelView

struct ChatPanelView: View {
    let fileURL: URL?

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var streamingResponse = ""
    @State private var historyManager: ChatHistoryManager?
    @State private var cliRunner: ClaudeCLIRunner?
    @State private var gitRoot: URL?
    @State private var allowEditing = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundStyle(.secondary)
                Text("Claude Chat")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Toggle(isOn: $allowEditing) {
                    Label("Allow editing", systemImage: allowEditing ? "pencil.circle.fill" : "pencil.circle")
                        .font(.system(size: 10))
                }
                .toggleStyle(.button)
                .buttonStyle(.borderless)
                .tint(allowEditing ? .orange : nil)
                .help(allowEditing ? "Claude can edit files (click to disable)" : "Claude is read-only (click to allow editing)")

                if !messages.isEmpty {
                    Button(action: clearHistory) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Clear chat history")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // Chat messages (WKWebView)
            ChatWebView(
                messages: messages,
                streamingText: streamingResponse,
                isStreaming: isLoading
            )

            Divider()

            // Input
            HStack(spacing: 8) {
                if fileURL != nil {
                    TextField("Ask Claude...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .onSubmit {
                            if !NSEvent.modifierFlags.contains(.shift) {
                                sendMessage()
                            }
                        }
                } else {
                    Text("Save the file to enable chat")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLoading {
                    Button(action: cancelRequest) {
                        Image(systemName: "stop.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Cancel")
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                    }
                    .buttonStyle(.borderless)
                    .disabled(fileURL == nil || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Send (Enter)")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .onAppear { setupChat() }
    }

    private func setupChat() {
        guard let url = fileURL else { return }

        let root: URL
        if let gitRoot = ClaudeCLIRunner.findGitRoot(from: url) {
            root = gitRoot
        } else {
            root = url.deletingLastPathComponent()
        }

        self.gitRoot = root
        historyManager = ChatHistoryManager(gitRoot: root, fileURL: url)
        cliRunner = ClaudeCLIRunner(workingDirectory: root)
        messages = historyManager?.load() ?? []
    }

    private func buildPrompt(_ userPrompt: String) -> String {
        guard let url = fileURL else { return userPrompt }
        let filePath: String
        if let root = gitRoot {
            let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
            if url.path.hasPrefix(rootPath) {
                filePath = String(url.path.dropFirst(rootPath.count))
            } else {
                filePath = url.path
            }
        } else {
            filePath = url.path
        }
        return "Context: The user is viewing the file `\(filePath)`. Read it first before answering.\n\n\(userPrompt)"
    }

    private func sendMessage() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: .user, content: prompt)
        messages.append(userMessage)
        historyManager?.append(userMessage)
        inputText = ""
        isLoading = true
        streamingResponse = ""

        cliRunner?.run(
            prompt: buildPrompt(prompt),
            allowEditing: allowEditing,
            sessionId: historyManager?.sessionId,
            onOutput: { [self] chunk in
                MainActor.assumeIsolated {
                    streamingResponse += chunk
                }
            },
            onComplete: { [self] _ in
                MainActor.assumeIsolated {
                    let response = streamingResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !response.isEmpty {
                        let assistantMessage = ChatMessage(role: .assistant, content: response)
                        messages.append(assistantMessage)
                        historyManager?.append(assistantMessage)
                    }
                    streamingResponse = ""
                    isLoading = false
                }
            }
        )
    }

    private func cancelRequest() {
        cliRunner?.cancel()
        if !streamingResponse.isEmpty {
            let partial = ChatMessage(role: .assistant, content: streamingResponse + "\n\n[cancelled]")
            messages.append(partial)
            historyManager?.append(partial)
        }
        streamingResponse = ""
        isLoading = false
    }

    private func clearHistory() {
        messages = []
        historyManager?.clear()
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1`
Expected: Build complete with no errors

- [ ] **Step 3: Commit Tasks 3, 4, and 5 together**

```bash
git add Sources/MarkdownViewerLib/ChatMessage.swift Sources/MarkdownViewerLib/ClaudeCLIRunner.swift Sources/MarkdownViewerLib/ChatPanelView.swift
git commit -m "feat: rewrite chat panel with WKWebView rendering, per-file sessions, --resume support"
```

---

### Task 6: Update `ContentView.swift` — draggable divider

**Files:**
- Modify: `Sources/MarkdownViewerLib/ContentView.swift`

- [ ] **Step 1: Add `chatPanelHeight` state and drag tracking**

Find `@State private var showChat = false` and add after it:

```swift
@State private var chatPanelHeight: CGFloat = 250
@State private var chatDragStartHeight: CGFloat? = nil
```

- [ ] **Step 2: Replace the fixed chat frame with draggable divider**

Find the current chat panel section in the body (the `if showChat` block with `Divider()` and `ChatPanelView`). Replace it with:

```swift
if showChat {
    chatDivider
    ChatPanelView(fileURL: fileURL)
        .frame(height: chatPanelHeight)
}
```

- [ ] **Step 3: Add the chatDivider computed property**

Add this after the existing `tocSidebar` or `diffToolbar` section in `ContentView`:

```swift
// MARK: - Chat Divider

private var chatDivider: some View {
    Rectangle()
        .fill(Color.clear)
        .frame(height: 6)
        .overlay(
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if chatDragStartHeight == nil {
                        chatDragStartHeight = chatPanelHeight
                    }
                    chatPanelHeight = max(100, min(600, (chatDragStartHeight ?? 250) - value.translation.height))
                }
                .onEnded { _ in
                    chatDragStartHeight = nil
                }
        )
}
```

- [ ] **Step 4: Build to verify**

Run: `swift build 2>&1`
Expected: Build complete with no errors

- [ ] **Step 5: Build the app and test**

Run: `make app 2>&1`
Expected: Built MarkdownViewer.app

- [ ] **Step 6: Commit**

```bash
git add Sources/MarkdownViewerLib/ContentView.swift
git commit -m "feat: add resizable chat panel with draggable divider"
```

---

### Task 7: Integration test and final build

- [ ] **Step 1: Clean build**

Run: `swift package clean && make app 2>&1`
Expected: Full clean build succeeds

- [ ] **Step 2: Manual verification checklist**

Test the following after launching `./MarkdownViewer.app`:
1. Open a .md file
2. Toggle chat panel (Cmd+Shift+K or Chat button)
3. Send a message — verify markdown rendering (code blocks, headers, lists)
4. Verify streaming shows live with cursor animation
5. Send a follow-up message — verify Claude remembers prior context (--resume)
6. Drag the divider to resize panel
7. Toggle dark mode (View > Appearance > Dark) — verify chat styling adapts
8. Clear history — verify new session starts
9. Close and reopen the same file — verify chat history persists
10. Open a different .md file — verify separate chat session

- [ ] **Step 3: Install**

Run: `make install 2>&1`

- [ ] **Step 4: Final commit with all remaining changes**

```bash
git add -A
git commit -m "feat: chat panel redesign with markdown rendering, per-file sessions, resizable panel"
```
