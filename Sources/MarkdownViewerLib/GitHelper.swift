import Foundation

public enum GitHelper {

    public static func isGitRepo(at fileURL: URL) -> Bool {
        run(["rev-parse", "--git-dir"], in: fileURL.deletingLastPathComponent()) != nil
    }

    public static func diff(for fileURL: URL, against ref: String = "HEAD") -> String? {
        run(["diff", ref, "--", fileURL.path], in: fileURL.deletingLastPathComponent())
    }

    public static func availableRefs(for fileURL: URL) -> [String] {
        let dir = fileURL.deletingLastPathComponent()
        var refs = ["HEAD"]
        for remote in ["origin/main", "origin/master", "upstream/main", "upstream/master"] {
            if run(["rev-parse", "--verify", remote], in: dir) != nil {
                refs.append(remote)
            }
        }
        return refs
    }

    public static func diffToHTML(_ diff: String) -> String {
        var lines = [String]()
        lines.append("""
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        body { margin: 0; padding: 16px 32px; font-family: SF Mono, Menlo, monospace; font-size: 13px; background: #ffffff; color: #1f2328; }
        @media (prefers-color-scheme: dark) { body { background: #0d1117; color: #e6edf3; } }
        .diff-line { white-space: pre-wrap; padding: 1px 8px; margin: 0; line-height: 1.5; }
        .diff-add { background: rgba(46, 160, 67, 0.15); color: #1a7f37; }
        .diff-del { background: rgba(248, 81, 73, 0.15); color: #cf222e; }
        .diff-hunk { color: #656d76; background: rgba(84, 174, 255, 0.1); font-weight: 600; margin-top: 8px; }
        .diff-header { color: #656d76; font-weight: 600; }
        .diff-empty { text-align: center; padding: 48px; color: #656d76; font-family: -apple-system, sans-serif; font-size: 15px; }
        @media (prefers-color-scheme: dark) {
            .diff-add { background: rgba(46, 160, 67, 0.15); color: #3fb950; }
            .diff-del { background: rgba(248, 81, 73, 0.15); color: #f85149; }
            .diff-hunk { color: #8b949e; background: rgba(56, 139, 253, 0.1); }
            .diff-header { color: #8b949e; }
            .diff-empty { color: #8b949e; }
        }
        </style>
        </head>
        <body>
        """)

        for line in diff.components(separatedBy: "\n") {
            let escaped = line
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")

            let cls: String
            if line.hasPrefix("+++") || line.hasPrefix("---") {
                cls = "diff-header"
            } else if line.hasPrefix("+") {
                cls = "diff-add"
            } else if line.hasPrefix("-") {
                cls = "diff-del"
            } else if line.hasPrefix("@@") {
                cls = "diff-hunk"
            } else if line.hasPrefix("diff ") || line.hasPrefix("index ") {
                cls = "diff-header"
            } else {
                cls = ""
            }

            lines.append("<div class=\"diff-line \(cls)\">\(escaped)</div>")
        }

        lines.append("</body></html>")
        return lines.joined(separator: "\n")
    }

    private static func run(_ arguments: [String], in directory: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
