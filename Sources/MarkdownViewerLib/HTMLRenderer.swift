import Foundation

public enum HTMLRenderer {

    // Static resources embedded once on first access (~2.6MB total, never changes at runtime)
    private static let preparedTemplate: String = {
        let css = loadResource("style", withExtension: "css") ?? ""
        let vendorCSS = loadResource("github-markdown", withExtension: "css", subdirectory: "Resources/vendor") ?? ""
        let faCSS = loadResource("fontawesome", withExtension: "css", subdirectory: "Resources/vendor") ?? ""
        let markedJS = loadResource("marked.min", withExtension: "js", subdirectory: "Resources/vendor") ?? ""
        let mermaidJS = loadResource("mermaid.min", withExtension: "js", subdirectory: "Resources/vendor") ?? ""
        let purifyJS = loadResource("purify.min", withExtension: "js", subdirectory: "Resources/vendor") ?? ""
        let template = loadResource("template", withExtension: "html") ?? fallbackTemplate()
        return template
            .replacingOccurrences(of: "/* {{VENDOR_CSS}} */", with: vendorCSS)
            .replacingOccurrences(of: "/* {{FA_CSS}} */", with: faCSS)
            .replacingOccurrences(of: "/* {{CSS}} */", with: css)
            .replacingOccurrences(of: "/* {{MARKED_JS}} */", with: markedJS)
            .replacingOccurrences(of: "/* {{MERMAID_JS}} */", with: mermaidJS)
            .replacingOccurrences(of: "/* {{PURIFY_JS}} */", with: purifyJS)
    }()

    private static let preparedChatTemplate: String = {
        let vendorCSS = loadResource("github-markdown", withExtension: "css", subdirectory: "Resources/vendor") ?? ""
        let faCSS = loadResource("fontawesome", withExtension: "css", subdirectory: "Resources/vendor") ?? ""
        let markedJS = loadResource("marked.min", withExtension: "js", subdirectory: "Resources/vendor") ?? ""
        let purifyJS = loadResource("purify.min", withExtension: "js", subdirectory: "Resources/vendor") ?? ""
        let template = loadResource("chat-template", withExtension: "html") ?? fallbackTemplate()
        return template
            .replacingOccurrences(of: "/* {{VENDOR_CSS}} */", with: vendorCSS)
            .replacingOccurrences(of: "/* {{FA_CSS}} */", with: faCSS)
            .replacingOccurrences(of: "/* {{MARKED_JS}} */", with: markedJS)
            .replacingOccurrences(of: "/* {{PURIFY_JS}} */", with: purifyJS)
    }()

    public static func renderChatTemplate() -> String {
        preparedChatTemplate
    }

    public static func render(markdown: String) -> String {
        let escaped = escapeForJSTemplateLiteral(markdown)
        return preparedTemplate.replacingOccurrences(of: "{{MARKDOWN_CONTENT}}", with: escaped)
    }

    public static func compose(
        template: String,
        markdown: String,
        css: String,
        vendorCSS: String,
        markedJS: String,
        mermaidJS: String,
        purifyJS: String = "",
        faCSS: String = ""
    ) -> String {
        let escaped = escapeForJSTemplateLiteral(markdown)
        return template
            .replacingOccurrences(of: "/* {{VENDOR_CSS}} */", with: vendorCSS)
            .replacingOccurrences(of: "/* {{FA_CSS}} */", with: faCSS)
            .replacingOccurrences(of: "/* {{CSS}} */", with: css)
            .replacingOccurrences(of: "/* {{MARKED_JS}} */", with: markedJS)
            .replacingOccurrences(of: "/* {{MERMAID_JS}} */", with: mermaidJS)
            .replacingOccurrences(of: "/* {{PURIFY_JS}} */", with: purifyJS)
            .replacingOccurrences(of: "{{MARKDOWN_CONTENT}}", with: escaped)
    }

    static func escapeForJSTemplateLiteral(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "</", with: "<\\/")
    }

    private static func loadResource(
        _ name: String,
        withExtension ext: String,
        subdirectory: String = "Resources"
    ) -> String? {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: subdirectory
        ) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func fallbackTemplate() -> String {
        """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"></head>
        <body><pre>Could not load template. Run 'make deps' first.</pre></body>
        </html>
        """
    }
}
