import Foundation

public final class ClaudeCLIRunner: @unchecked Sendable {
    private var process: Process?
    private let workingDirectory: URL

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
    /// `onOutput` is called with incremental text as it arrives.
    /// `onComplete` is called with the full response and session ID.
    public func run(
        prompt: String,
        allowEditing: Bool = false,
        sessionId: String? = nil,
        model: String = "claude-sonnet-4-6",
        onOutput: @escaping @Sendable (String) -> Void,
        onComplete: @escaping @Sendable (CLIResponse, Int32) -> Void
    ) {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        let escapedPrompt = prompt
            .replacingOccurrences(of: "'", with: "'\\''")
        var claudeCmd = "claude -p '\(escapedPrompt)' --output-format stream-json --verbose --model \(model)"
        if let sid = sessionId {
            claudeCmd += " --resume '\(sid)'"
        }
        if allowEditing {
            claudeCmd += " --dangerously-skip-permissions"
        } else {
            claudeCmd += " --disallowedTools Edit Write Bash NotebookEdit"
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-i", "-c", claudeCmd]
        process.currentDirectoryURL = workingDirectory

        var env = ProcessInfo.processInfo.environment
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
                case "content_block_delta":
                    // Extract streamed text delta
                    if let delta = json["delta"] as? [String: Any],
                       let text = delta["text"] as? String {
                        resultText += text
                        DispatchQueue.main.async {
                            onOutput(text)
                        }
                    }
                case "result":
                    // Final result with session_id
                    if let result = json["result"] as? String {
                        resultText = result
                    }
                    resultSessionId = json["session_id"] as? String
                case "message_start":
                    // Message started — could show thinking indicator
                    break
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
