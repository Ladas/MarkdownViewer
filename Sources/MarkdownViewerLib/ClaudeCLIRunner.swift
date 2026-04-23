import Foundation

public final class ClaudeCLIRunner: @unchecked Sendable {
    private var process: Process?
    private let workingDirectory: URL

    private static let loginShell: String = {
        if FileManager.default.isExecutableFile(atPath: "/bin/zsh") { return "/bin/zsh" }
        if FileManager.default.isExecutableFile(atPath: "/bin/bash") { return "/bin/bash" }
        return "/bin/sh"
    }()

    /// Capture the full login-shell environment once (includes ~/.zshrc, ~/.bash_profile, etc.)
    private static let shellEnvironment: [String: String] = {
        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: loginShell)
        proc.arguments = ["-l", "-i", "-c", "env"]
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        proc.standardInput = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return ProcessInfo.processInfo.environment
        }
        var env: [String: String] = [:]
        for line in output.components(separatedBy: "\n") {
            guard let eqIndex = line.firstIndex(of: "=") else { continue }
            let key = String(line[line.startIndex..<eqIndex])
            let value = String(line[line.index(after: eqIndex)...])
            if !key.isEmpty { env[key] = value }
        }
        return env.isEmpty ? ProcessInfo.processInfo.environment : env
    }()

    /// Resolve full path to `claude` binary once
    private static let claudePath: String = {
        let candidates = [
            "\(NSHomeDirectory())/.npm-global/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: loginShell)
        proc.arguments = ["-l", "-i", "-c", "which claude"]
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        proc.standardInput = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let resolved = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !resolved.isEmpty {
            return resolved
        }
        return "claude"
    }()

    public init(workingDirectory: URL) {
        self.workingDirectory = workingDirectory
    }

    public var isRunning: Bool {
        process?.isRunning ?? false
    }

    /// Find git root by walking up from the given directory
    public static func findGitRoot(from fileURL: URL) -> URL? {
        var dir = fileURL.deletingLastPathComponent()
        while dir.path != "/" {
            let gitDir = dir.appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: gitDir.path) {
                return dir
            }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }

    /// Response from claude CLI
    public struct CLIResponse {
        public let result: String
        public let sessionId: String?
    }

    /// Run claude CLI with streaming JSON output.
    /// `onOutput` is called with the accumulated text each time new content arrives.
    /// `onComplete` is called with the full response and session ID.
    public func run(
        prompt: String,
        allowEditing: Bool = false,
        sessionId: String? = nil,
        model: String = "claude-sonnet-4-6",
        onOutput: @escaping @Sendable (String) -> Void,
        onComplete: @escaping @Sendable (CLIResponse, Int32) -> Void
    ) {
        let escapedPrompt = prompt
            .replacingOccurrences(of: "'", with: "'\\''")

        var args = ["-p", escapedPrompt,
                    "--output-format", "stream-json",
                    "--verbose",
                    "--include-partial-messages",
                    "--model", model]
        if let sid = sessionId {
            args += ["--resume", sid]
        }
        if allowEditing {
            args += ["--dangerously-skip-permissions"]
        } else {
            args += ["--disallowedTools", "Edit", "Write", "Bash", "NotebookEdit"]
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.claudePath)
        process.arguments = args
        process.currentDirectoryURL = workingDirectory

        var env = Self.shellEnvironment
        env["TERM"] = "dumb"
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.nullDevice

        self.process = process

        // Buffer for incomplete lines (stream-json is newline-delimited)
        var lineBuffer = ""
        var resultText = ""
        var resultSessionId: String?

        let outHandle = stdoutPipe.fileHandleForReading
        outHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                outHandle.readabilityHandler = nil
                return
            }
            guard let chunk = String(data: data, encoding: .utf8) else { return }
            lineBuffer += chunk

            // Process complete lines
            while let newlineIndex = lineBuffer.firstIndex(of: "\n") {
                let line = String(lineBuffer[lineBuffer.startIndex..<newlineIndex])
                lineBuffer = String(lineBuffer[lineBuffer.index(after: newlineIndex)...])

                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty,
                      let lineData = trimmed.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                    continue
                }

                let type = json["type"] as? String ?? ""

                switch type {
                case "system":
                    // Capture session_id from init event (available early)
                    if let sid = json["session_id"] as? String {
                        resultSessionId = sid
                    }
                case "assistant":
                    // Extract text from assistant message content blocks
                    // Format: {"type":"assistant","message":{"content":[{"type":"text","text":"..."}]}}
                    if let message = json["message"] as? [String: Any],
                       let content = message["content"] as? [[String: Any]] {
                        var textParts: [String] = []
                        for block in content {
                            if let blockType = block["type"] as? String,
                               blockType == "text",
                               let text = block["text"] as? String {
                                textParts.append(text)
                            }
                        }
                        let text = textParts.joined()
                        if !text.isEmpty {
                            resultText = text
                            DispatchQueue.main.async {
                                onOutput(text)
                            }
                        }
                    }
                case "result":
                    // Final result with session_id
                    if let result = json["result"] as? String {
                        resultText = result
                    }
                    if let sid = json["session_id"] as? String {
                        resultSessionId = sid
                    }
                default:
                    break
                }
            }
        }

        // Capture stderr for error reporting
        var stderrData = Data()
        let errHandle = stderrPipe.fileHandleForReading
        errHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                errHandle.readabilityHandler = nil
                return
            }
            stderrData.append(data)
        }

        process.terminationHandler = { proc in
            outHandle.readabilityHandler = nil
            errHandle.readabilityHandler = nil

            // Process any remaining buffered data
            let remaining = lineBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !remaining.isEmpty,
               let lineData = remaining.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] {
                if let result = json["result"] as? String {
                    resultText = result
                }
                if let sid = json["session_id"] as? String {
                    resultSessionId = sid
                }
            }

            DispatchQueue.main.async {
                if resultText.isEmpty {
                    // Fallback: check stderr for errors
                    let errText = String(data: stderrData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let response = CLIResponse(
                        result: errText.isEmpty ? "" : "Error: \(errText)",
                        sessionId: resultSessionId
                    )
                    onComplete(response, proc.terminationStatus)
                } else {
                    let response = CLIResponse(result: resultText, sessionId: resultSessionId)
                    onComplete(response, proc.terminationStatus)
                }
            }
        }

        do {
            try process.run()
        } catch {
            let errorResponse = CLIResponse(result: "Error: Failed to launch shell: \(error.localizedDescription)", sessionId: nil)
            onComplete(errorResponse, 1)
        }
    }

    public func cancel() {
        process?.terminate()
        process = nil
    }
}
