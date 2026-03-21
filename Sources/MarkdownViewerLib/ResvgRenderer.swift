import Foundation
import AppKit

public enum ResvgRenderer {

    /// Check if resvg is available on the system
    public static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: resvgPath)
    }

    /// Render SVG string to PNG data using resvg CLI
    /// Returns nil if resvg is not installed or rendering fails
    public static func renderToPNG(svgString: String, width: Int? = nil) -> Data? {
        guard isAvailable else { return nil }

        // Write SVG to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let svgFile = tempDir.appendingPathComponent("mdviewer-\(UUID().uuidString).svg")
        let pngFile = tempDir.appendingPathComponent("mdviewer-\(UUID().uuidString).png")

        defer {
            try? FileManager.default.removeItem(at: svgFile)
            try? FileManager.default.removeItem(at: pngFile)
        }

        guard let svgData = svgString.data(using: .utf8) else { return nil }
        do {
            try svgData.write(to: svgFile)
        } catch {
            return nil
        }

        // Run resvg
        var args = [svgFile.path, pngFile.path]
        if let w = width {
            args.insert(contentsOf: ["--width", String(w)], at: 0)
        }

        let result = run(args)
        guard result else { return nil }

        return try? Data(contentsOf: pngFile)
    }

    // MARK: - Private

    private static let resvgPath: String = {
        // Check common locations
        for path in ["/opt/homebrew/bin/resvg", "/usr/local/bin/resvg", "/usr/bin/resvg"] {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        // Try which
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["resvg"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                return path
            }
        }
        return "/opt/homebrew/bin/resvg" // default, will fail gracefully
    }()

    private static func run(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: resvgPath)
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
