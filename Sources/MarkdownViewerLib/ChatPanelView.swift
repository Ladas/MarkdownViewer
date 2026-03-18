import SwiftUI
import WebKit

// MARK: - ChatWebView

struct ChatWebView: NSViewRepresentable {
    let messages: [ChatMessage]
    let streamingText: String
    let isStreaming: Bool
    let statusText: String

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
            webView.evaluateJavaScript("showThinking()") { _, _ in }
        } else if isStreaming && !streamingText.isEmpty {
            coord.updateStreaming(streamingText, in: webView)
        } else if !isStreaming && coord.wasStreaming {
            coord.finalizeStreaming(in: webView)
        }
        coord.wasStreaming = isStreaming

        // Show status text (stderr) if changed
        if !statusText.isEmpty && statusText != coord.lastStatusText {
            coord.lastStatusText = statusText
            coord.showStatus(statusText, in: webView)
        }
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
        var lastStatusText = ""
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

        func showStatus(_ text: String, in webView: WKWebView) {
            guard let data = try? JSONEncoder().encode(text),
                  let json = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("showStatus(\(json))") { _, _ in }
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
    @State private var stderrBuffer = ""
    @State private var lastShownStderr = ""
    @State private var pendingApproval: String? = nil
    @State private var historyManager: ChatHistoryManager?
    @State private var cliRunner: ClaudeCLIRunner?
    @State private var gitRoot: URL?
    @State private var allowEditing = false
    @FocusState private var isInputFocused: Bool

    /// Patterns in stderr that indicate Claude is asking for tool approval
    private static let approvalPatterns = [
        "allow", "Allow", "permission", "approve",
        "(y/n)", "(Y/n)", "(yes/no)", "yes/no",
        "Do you want", "Would you like"
    ]

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
                isStreaming: isLoading,
                statusText: lastShownStderr
            )

            // Approval bar — shown when Claude asks for permission
            if let approval = pendingApproval {
                Divider()
                approvalBar(approval)
            }

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

    // MARK: - Approval Bar

    private func approvalBar(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                    .padding(.top, 1)

                Text(cleanApprovalText(text))
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                Button(action: { respondToApproval("y\n") }) {
                    Label("Allow", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)

                Button(action: { respondToApproval("n\n") }) {
                    Label("Deny", systemImage: "xmark.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)

                Spacer()

                Button(action: { respondToApproval("y\n") }) {
                    Text("Always allow")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Allow this and future tool uses in this session")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.08))
    }

    /// Strip ANSI escape codes and clean up the approval text for display
    private func cleanApprovalText(_ text: String) -> String {
        // Remove ANSI escape sequences
        var cleaned = text.replacingOccurrences(
            of: "\\x1B\\[[0-9;]*[a-zA-Z]|\\x1B\\([a-zA-Z]",
            with: "",
            options: .regularExpression
        )
        // Also remove raw ESC characters
        cleaned = cleaned.replacingOccurrences(
            of: "\u{1B}\\[[0-9;]*[a-zA-Z]|\u{1B}\\([a-zA-Z]",
            with: "",
            options: .regularExpression
        )
        // Remove box-drawing characters
        cleaned = cleaned.replacingOccurrences(
            of: "[╭╮╰╯│─┌┐└┘├┤┬┴┼]+",
            with: "",
            options: .regularExpression
        )
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func respondToApproval(_ response: String) {
        cliRunner?.sendInput(response)
        pendingApproval = nil
        stderrBuffer = ""
    }

    // MARK: - Setup & Actions

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
        stderrBuffer = ""
        lastShownStderr = ""
        pendingApproval = nil

        cliRunner?.run(
            prompt: buildPrompt(prompt),
            allowEditing: allowEditing,
            sessionId: historyManager?.sessionId,
            onOutput: { [self] chunk in
                MainActor.assumeIsolated {
                    streamingResponse += chunk
                }
            },
            onStderr: { [self] chunk in
                MainActor.assumeIsolated {
                    stderrBuffer += chunk
                    handleStderr()
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
                    // Show any remaining stderr as status if no response was received
                    if response.isEmpty && !stderrBuffer.isEmpty && pendingApproval == nil {
                        lastShownStderr = stderrBuffer
                    }
                    streamingResponse = ""
                    stderrBuffer = ""
                    isLoading = false
                    pendingApproval = nil
                }
            }
        )
    }

    /// Analyze stderr buffer for approval prompts or error messages
    private func handleStderr() {
        let buffer = stderrBuffer

        // Check if this looks like an approval prompt
        let looksLikeApproval = Self.approvalPatterns.contains { buffer.contains($0) }
        if looksLikeApproval {
            pendingApproval = buffer
            return
        }

        // For non-approval stderr, show it as a status message if it's substantial
        // (skip tiny fragments that are part of ongoing output)
        if buffer.count > 20 && buffer.contains("\n") {
            lastShownStderr = buffer
        }
    }

    private func cancelRequest() {
        cliRunner?.cancel()
        if !streamingResponse.isEmpty {
            let partial = ChatMessage(role: .assistant, content: streamingResponse + "\n\n[cancelled]")
            messages.append(partial)
            historyManager?.append(partial)
        }
        streamingResponse = ""
        stderrBuffer = ""
        isLoading = false
        pendingApproval = nil
    }

    private func clearHistory() {
        messages = []
        historyManager?.clear()
        lastShownStderr = ""
    }
}
