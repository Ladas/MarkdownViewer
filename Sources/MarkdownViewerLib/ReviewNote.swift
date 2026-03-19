import Foundation

public enum ReviewNote {

    private static let blockRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "```review\\n[\\s\\S]*?\\n```")
    }()

    private static let extractRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "```review\\n([\\s\\S]*?)\\n```")
    }()

    public static func sanitizeContent(_ content: String) -> String {
        content.replacingOccurrences(of: "```", with: "` ` `")
    }

    public static func extract(from markdown: String) -> [String] {
        let nsText = markdown as NSString
        let matches = extractRegex.matches(in: markdown, range: NSRange(location: 0, length: nsText.length))
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return nsText.substring(with: match.range(at: 1))
        }
    }

    public static func replace(at index: Int, with newContent: String?, in text: String) -> String {
        let nsText = text as NSString
        let matches = blockRegex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard index < matches.count else { return text }

        let match = matches[index]
        var result = text
        guard let range = Range(match.range, in: text) else { return text }

        if let newContent = newContent {
            result.replaceSubrange(range, with: "```review\n\(newContent)\n```")
        } else {
            var start = range.lowerBound
            var end = range.upperBound
            // Consume up to 2 trailing newlines
            for _ in 0..<2 {
                if end < text.endIndex && text[end] == "\n" {
                    end = text.index(after: end)
                }
            }
            // Consume up to 2 leading newlines
            for _ in 0..<2 {
                if start > text.startIndex {
                    let before = text.index(before: start)
                    if text[before] == "\n" {
                        start = before
                    } else {
                        break
                    }
                }
            }
            // Ensure we leave a blank line between surrounding content
            let hasBefore = start > text.startIndex
            let hasAfter = end < text.endIndex
            let separator = (hasBefore && hasAfter) ? "\n\n" : ""
            result.replaceSubrange(start..<end, with: separator)
        }
        return result
    }

    public static func insertAfterHeading(_ headingText: String, note: String, in text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var insertIndex = lines.count
        var inCodeBlock = false

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { inCodeBlock = !inCodeBlock; continue }
            if inCodeBlock { continue }

            if let match = trimmed.range(of: "^#{1,6}\\s+", options: .regularExpression) {
                var title = String(trimmed[match.upperBound...])
                if let trailing = title.range(of: "\\s+#+\\s*$", options: .regularExpression) {
                    title = String(title[..<trailing.lowerBound])
                }
                if title == headingText {
                    for j in (i + 1)..<lines.count {
                        let nextTrimmed = lines[j].trimmingCharacters(in: .whitespaces)
                        if nextTrimmed.range(of: "^#{1,6}\\s+", options: .regularExpression) != nil {
                            insertIndex = j
                            break
                        }
                    }
                    break
                }
            }
        }

        var result = lines
        result.insert(contentsOf: note.components(separatedBy: "\n"), at: insertIndex)
        return result.joined(separator: "\n")
    }
}
