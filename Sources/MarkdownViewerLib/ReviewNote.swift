import Foundation

public enum ReviewNote {

    public static func extract(from markdown: String) -> [String] {
        let pattern = "```review\\n([\\s\\S]*?)\\n```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = markdown as NSString
        let matches = regex.matches(in: markdown, range: NSRange(location: 0, length: nsText.length))
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return nsText.substring(with: match.range(at: 1))
        }
    }

    public static func replace(at index: Int, with newContent: String?, in text: String) -> String {
        let pattern = "```review\\n[\\s\\S]*?\\n```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard index < matches.count else { return text }

        let match = matches[index]
        var result = text
        guard let range = Range(match.range, in: text) else { return text }

        if let newContent = newContent {
            result.replaceSubrange(range, with: "```review\n\(newContent)\n```")
        } else {
            var start = range.lowerBound
            var end = range.upperBound
            // Consume trailing newlines
            while end < text.endIndex && text[end] == "\n" {
                end = text.index(after: end)
            }
            // Consume up to 2 leading newlines
            if start > text.startIndex {
                let before = text.index(before: start)
                if text[before] == "\n" {
                    start = before
                    if start > text.startIndex {
                        let before2 = text.index(before: start)
                        if text[before2] == "\n" {
                            start = before2
                        }
                    }
                }
            }
            result.replaceSubrange(start..<end, with: "")
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
