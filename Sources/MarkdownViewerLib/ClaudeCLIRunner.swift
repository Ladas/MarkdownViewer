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

    /// JSON response from `claude -p --output-format json`
    public struct CLIResponse {
        public let result: String
        public let sessionId: String?
    }

    /// Run claude CLI with a prompt using JSON output format.
    /// Returns the full response and session ID for --resume support.
    public func run(
        prompt: String,
        allowEditing: Bool = false,
        sessionId: String? = nil,
        onOutput: @escaping @Sendable (String) -> Void,
        onComplete: @escaping @Sendable (CLIResponse, Int32) -> Void
    ) {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        let escapedPrompt = prompt
            .replacingOccurrences(of: "'", with: "'\\''")
        var claudeCmd = "claude -p '\(escapedPrompt)' --output-format json --model claude-sonnet-4-6"
        if let sid = sessionId {
            claudeCmd += " --resume '\(sid)'"
        }
        if allowEditing {
            claudeCmd += " --dangerously-skip-permissions"
        } else {
            // Block write tools when editing is disabled
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

        // Accumulate all stdout data for JSON parsing
        var stdoutData = Data()
        let outHandle = stdoutPipe.fileHandleForReading
        outHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                outHandle.readabilityHandler = nil
                return
            }
            stdoutData.append(data)
            // Also stream raw chunks for a "thinking" indicator
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    onOutput(str)
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
            DispatchQueue.main.async {
                let response = Self.parseResponse(stdout: stdoutData, stderr: stderrData)
                onComplete(response, proc.terminationStatus)
            }
        }

        do {
            try process.run()
        } catch {
            let errorResponse = CLIResponse(result: "Error: Failed to launch shell: \(error.localizedDescription)", sessionId: nil)
            onComplete(errorResponse, 1)
        }
    }

    /// Parse the JSON response from claude CLI
    private static func parseResponse(stdout: Data, stderr: Data) -> CLIResponse {
        // Try parsing stdout as JSON first
        if let response = parseJSON(stdout) {
            return response
        }
        // Claude also outputs JSON to stderr with --output-format json
        if let response = parseJSON(stderr) {
            return response
        }
        // Fallback: treat stdout as plain text
        let text = String(data: stdout, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty {
            let errText = String(data: stderr, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return CLIResponse(result: errText.isEmpty ? "" : "Error: \(errText)", sessionId: nil)
        }
        return CLIResponse(result: text, sessionId: nil)
    }

    private static func parseJSON(_ data: Data) -> CLIResponse? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let result = json["result"] as? String ?? ""
        let sessionId = json["session_id"] as? String
        return CLIResponse(result: result, sessionId: sessionId)
    }

    public func cancel() {
        process?.terminate()
        process = nil
    }
}
