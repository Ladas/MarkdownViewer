import Foundation

public final class ClaudeCLIRunner: @unchecked Sendable {
    private var process: Process?
    private var stdinPipe: Pipe?
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

    /// Send text to the running process's stdin (e.g. approval responses)
    public func sendInput(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        stdinPipe?.fileHandleForWriting.write(data)
    }

    /// Run claude CLI with a prompt, streaming output line by line.
    /// Executes via the user's login shell so PATH resolution works correctly
    /// even when launched from a GUI app (which has a minimal PATH).
    public func run(
        prompt: String,
        allowEditing: Bool = false,
        sessionId: String? = nil,
        onOutput: @escaping @Sendable (String) -> Void,
        onStderr: @escaping @Sendable (String) -> Void = { _ in },
        onComplete: @escaping @Sendable (Int32) -> Void
    ) {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        // Build the claude command with proper escaping
        let escapedPrompt = prompt
            .replacingOccurrences(of: "'", with: "'\\''")
        var claudeCmd = "claude -p '\(escapedPrompt)'"
        if let sid = sessionId {
            claudeCmd += " --resume '\(sid)'"
        }
        if allowEditing {
            claudeCmd += " --dangerously-skip-permissions"
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        // -l: login shell (sources .zprofile), -i: interactive (sources .zshrc)
        // Together they ensure the user's full PATH is available
        process.arguments = ["-l", "-i", "-c", claudeCmd]
        process.currentDirectoryURL = workingDirectory

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "dumb"
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        // Use nullDevice so claude -p doesn't block waiting for stdin.
        // The -p flag is non-interactive — approvals are handled via
        // --dangerously-skip-permissions toggle, not stdin interaction.
        process.standardInput = FileHandle.nullDevice

        self.process = process
        self.stdinPipe = nil

        let outHandle = stdoutPipe.fileHandleForReading
        outHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                outHandle.readabilityHandler = nil
                return
            }
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    onOutput(str)
                }
            }
        }

        let errHandle = stderrPipe.fileHandleForReading
        errHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                errHandle.readabilityHandler = nil
                return
            }
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    onStderr(str)
                }
            }
        }

        process.terminationHandler = { proc in
            outHandle.readabilityHandler = nil
            errHandle.readabilityHandler = nil
            DispatchQueue.main.async {
                onComplete(proc.terminationStatus)
            }
        }

        do {
            try process.run()
        } catch {
            onOutput("Error: Failed to launch shell: \(error.localizedDescription)")
            onComplete(1)
        }
    }

    public func cancel() {
        process?.terminate()
        process = nil
        stdinPipe = nil
    }
}
