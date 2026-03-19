import Foundation
import JavaScriptCore

public enum SourceHighlighter {

    // MARK: - Markdown Source View

    public static func render(_ markdown: String) -> String {
        let escaped = markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let highlighted = highlightMarkdown(escaped)

        return wrapInPage(highlighted)
    }

    // MARK: - HTML Preview

    public static func renderHTMLPreview(_ markdown: String) -> String {
        let html = renderMarkdownToHTML(markdown)
        let formatted = formatHTML(html)
        let escaped = formatted
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let highlighted = highlightHTML(escaped)

        return wrapInPage(highlighted)
    }

    // MARK: - Markdown Syntax Highlighting

    private static func highlightMarkdown(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var inCodeBlock = false

        for i in 0..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if !inCodeBlock {
                    inCodeBlock = true
                    lines[i] = "<span class=\"sh-fence\">\(lines[i])</span>"
                } else {
                    inCodeBlock = false
                    lines[i] = "<span class=\"sh-fence\">\(lines[i])</span>"
                }
                continue
            }

            if inCodeBlock {
                lines[i] = "<span class=\"sh-code\">\(lines[i])</span>"
                continue
            }

            // Headings
            if trimmed.range(of: "^#{1,6}\\s", options: .regularExpression) != nil {
                lines[i] = "<span class=\"sh-heading\">\(lines[i])</span>"
                continue
            }

            // Blockquotes
            if trimmed.hasPrefix("&gt;") {
                lines[i] = "<span class=\"sh-quote\">\(lines[i])</span>"
                continue
            }

            // Horizontal rules
            if trimmed.range(of: "^(---+|\\*\\*\\*+|___+)$", options: .regularExpression) != nil {
                lines[i] = "<span class=\"sh-hr\">\(lines[i])</span>"
                continue
            }

            // List items
            if trimmed.range(of: "^[-*+]\\s|^\\d+\\.\\s", options: .regularExpression) != nil {
                lines[i] = highlightInline(lines[i], cls: "sh-list-marker", outerCls: nil)
                continue
            }

            // Table separator
            if trimmed.range(of: "^\\|?[\\s:]*-{3,}", options: .regularExpression) != nil {
                lines[i] = "<span class=\"sh-table-sep\">\(lines[i])</span>"
                continue
            }

            // Table rows
            if trimmed.hasPrefix("|") {
                lines[i] = "<span class=\"sh-table\">\(lines[i])</span>"
                continue
            }

            // Inline highlighting for normal text
            lines[i] = highlightInline(lines[i], cls: nil, outerCls: nil)
        }

        return lines.joined(separator: "\n")
    }

    private static func highlightInline(_ line: String, cls: String?, outerCls: String?) -> String {
        var result = line

        // Bold
        result = result.replacingOccurrences(
            of: "(\\*\\*|__)(.+?)(\\*\\*|__)",
            with: "<span class=\"sh-bold\">$1$2$3</span>",
            options: .regularExpression
        )

        // Italic
        result = result.replacingOccurrences(
            of: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)",
            with: "<span class=\"sh-italic\">*$1*</span>",
            options: .regularExpression
        )

        // Inline code
        result = result.replacingOccurrences(
            of: "`([^`]+)`",
            with: "<span class=\"sh-inline-code\">`$1`</span>",
            options: .regularExpression
        )

        // Links
        result = result.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^)]+)\\)",
            with: "<span class=\"sh-link\">[$1]($2)</span>",
            options: .regularExpression
        )

        // Images
        result = result.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^)]+)\\)",
            with: "<span class=\"sh-image\">![$1]($2)</span>",
            options: .regularExpression
        )

        return result
    }

    // MARK: - HTML Syntax Highlighting

    private static func highlightHTML(_ text: String) -> String {
        var result = text

        // Tags
        result = result.replacingOccurrences(
            of: "(&lt;/?)(\\w+)(.*?)(&gt;)",
            with: "<span class=\"sh-tag\">$1</span><span class=\"sh-tag-name\">$2</span><span class=\"sh-attr\">$3</span><span class=\"sh-tag\">$4</span>",
            options: .regularExpression
        )

        // Attribute values
        result = result.replacingOccurrences(
            of: "(&quot;[^&]*&quot;|\"[^\"]*\")",
            with: "<span class=\"sh-attr-val\">$1</span>",
            options: .regularExpression
        )

        return result
    }

    // MARK: - Markdown to HTML via JavaScriptCore

    private static let jsContext: JSContext? = {
        guard let ctx = JSContext() else { return nil }
        if let markedJS = loadVendorResource("marked.min", ext: "js") {
            ctx.evaluateScript(markedJS)
        }
        return ctx
    }()

    private static func renderMarkdownToHTML(_ markdown: String) -> String {
        guard let ctx = jsContext else { return markdown }

        let escaped = HTMLRenderer.escapeForJSTemplateLiteral(markdown)
        let result = ctx.evaluateScript("typeof marked !== 'undefined' ? marked.parse(`\(escaped)`) : ''")
        return result?.toString() ?? ""
    }

    private static func loadVendorResource(_ name: String, ext: String) -> String? {
        guard let url = Bundle.module.url(
            forResource: name, withExtension: ext, subdirectory: "Resources/vendor"
        ) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Simple HTML Formatting

    private static func formatHTML(_ html: String) -> String {
        var result = html
        // Add newlines after closing tags for readability
        result = result.replacingOccurrences(of: "><", with: ">\n<")
        // Trim empty lines
        let lines = result.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var indented = [String]()
        var level = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("</") {
                level = max(0, level - 1)
            }
            indented.append(String(repeating: "  ", count: level) + trimmed)
            if trimmed.hasPrefix("<") && !trimmed.hasPrefix("</") && !trimmed.hasPrefix("<!") &&
               !trimmed.contains("/>") && !trimmed.contains("</") {
                level += 1
            }
        }
        return indented.joined(separator: "\n")
    }

    // MARK: - Page Wrapper

    private static func wrapInPage(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        body {
            margin: 0;
            padding: 16px 32px;
            background: #ffffff;
            color: #1f2328;
            font-family: SF Mono, Menlo, monospace;
            font-size: 13px;
            line-height: 1.6;
            -webkit-font-smoothing: antialiased;
        }
        @media (prefers-color-scheme: dark) {
            body { background: #0d1117; color: #e6edf3; }
        }
        pre {
            margin: 0;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        /* Markdown syntax highlighting */
        .sh-heading { color: #0550ae; font-weight: 600; }
        .sh-bold { color: #cf222e; }
        .sh-italic { color: #8250df; }
        .sh-inline-code { color: #0550ae; background: rgba(175, 184, 193, 0.2); border-radius: 3px; padding: 1px 4px; }
        .sh-fence { color: #656d76; }
        .sh-code { color: #0550ae; background: rgba(175, 184, 193, 0.1); }
        .sh-link { color: #0969da; }
        .sh-image { color: #8250df; }
        .sh-quote { color: #57606a; border-left: 3px solid #d0d7de; padding-left: 8px; }
        .sh-hr { color: #d0d7de; }
        .sh-table { color: #1f2328; }
        .sh-table-sep { color: #656d76; }
        .sh-list-marker { color: #cf222e; }
        /* HTML syntax highlighting */
        .sh-tag { color: #656d76; }
        .sh-tag-name { color: #116329; font-weight: 600; }
        .sh-attr { color: #0550ae; }
        .sh-attr-val { color: #0a3069; }
        @media (prefers-color-scheme: dark) {
            .sh-heading { color: #79c0ff; }
            .sh-bold { color: #ff7b72; }
            .sh-italic { color: #d2a8ff; }
            .sh-inline-code { color: #79c0ff; background: rgba(110, 118, 129, 0.2); }
            .sh-code { color: #79c0ff; background: rgba(110, 118, 129, 0.1); }
            .sh-link { color: #58a6ff; }
            .sh-image { color: #d2a8ff; }
            .sh-quote { color: #8b949e; border-left-color: #30363d; }
            .sh-hr { color: #30363d; }
            .sh-table { color: #e6edf3; }
            .sh-table-sep { color: #8b949e; }
            .sh-list-marker { color: #ff7b72; }
            .sh-tag { color: #8b949e; }
            .sh-tag-name { color: #7ee787; }
            .sh-attr { color: #79c0ff; }
            .sh-attr-val { color: #a5d6ff; }
        }
        </style>
        </head>
        <body><pre>\(content)</pre></body>
        </html>
        """
    }
}
