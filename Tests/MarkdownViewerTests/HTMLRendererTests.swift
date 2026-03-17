import Testing
@testable import MarkdownViewerLib

@Suite("HTMLRenderer - JS Template Literal Escaping")
struct EscapeTests {

    @Test func backslash() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("a\\b") == "a\\\\b")
    }

    @Test func backtick() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("a`b") == "a\\`b")
    }

    @Test func dollarSign() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("$x") == "\\$x")
    }

    @Test func templateInterpolation() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("${value}") == "\\${value}")
    }

    @Test func scriptClosingTag() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("</script>") == "<\\/script>")
    }

    @Test func allClosingTags() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("</div></span>") == "<\\/div><\\/span>")
    }

    @Test func emptyString() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("") == "")
    }

    @Test func noSpecialChars() {
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("Hello, world!") == "Hello, world!")
    }

    @Test func combinedSpecialChars() {
        // \`$ -> \\\`\$
        #expect(HTMLRenderer.escapeForJSTemplateLiteral("\\`$") == "\\\\\\`\\$")
    }

    @Test func multilineWithCodeFence() {
        let input = "line1\nline2\n```\ncode\n```"
        let result = HTMLRenderer.escapeForJSTemplateLiteral(input)
        #expect(result.contains("\\`\\`\\`"))
        #expect(result.contains("line1\nline2"))
    }
}

@Suite("HTMLRenderer - Template Composition")
struct ComposeTests {

    @Test func insertsEscapedMarkdown() {
        let result = HTMLRenderer.compose(
            template: "const md = `{{MARKDOWN_CONTENT}}`;",
            markdown: "# Hello",
            css: "", vendorCSS: "", markedJS: "", mermaidJS: ""
        )
        #expect(result == "const md = `# Hello`;")
    }

    @Test func insertsCSS() {
        let result = HTMLRenderer.compose(
            template: "<style>/* {{CSS}} */</style>",
            markdown: "",
            css: "body{color:red}", vendorCSS: "", markedJS: "", mermaidJS: ""
        )
        #expect(result.contains("body{color:red}"))
    }

    @Test func insertsVendorCSS() {
        let result = HTMLRenderer.compose(
            template: "<style>/* {{VENDOR_CSS}} */</style>",
            markdown: "",
            css: "", vendorCSS: ".markdown-body{}", markedJS: "", mermaidJS: ""
        )
        #expect(result.contains(".markdown-body{}"))
    }

    @Test func insertsMarkedJS() {
        let result = HTMLRenderer.compose(
            template: "<script>/* {{MARKED_JS}} */</script>",
            markdown: "",
            css: "", vendorCSS: "", markedJS: "var marked={};", mermaidJS: ""
        )
        #expect(result.contains("var marked={};"))
    }

    @Test func insertsMermaidJS() {
        let result = HTMLRenderer.compose(
            template: "<script>/* {{MERMAID_JS}} */</script>",
            markdown: "",
            css: "", vendorCSS: "", markedJS: "", mermaidJS: "var mermaid={};"
        )
        #expect(result.contains("var mermaid={};"))
    }

    @Test func escapesMarkdownContent() {
        let result = HTMLRenderer.compose(
            template: "`{{MARKDOWN_CONTENT}}`",
            markdown: "has `backtick` and $dollar",
            css: "", vendorCSS: "", markedJS: "", mermaidJS: ""
        )
        #expect(result.contains("has \\`backtick\\` and \\$dollar"))
    }

    @Test func fullTemplate() {
        let template = """
        <style>/* {{VENDOR_CSS}} */</style>
        <style>/* {{CSS}} */</style>
        <script>/* {{MARKED_JS}} */</script>
        <script>/* {{MERMAID_JS}} */</script>
        <body>`{{MARKDOWN_CONTENT}}`</body>
        """
        let result = HTMLRenderer.compose(
            template: template, markdown: "# Test",
            css: "body{}", vendorCSS: ".md{}", markedJS: "marked()", mermaidJS: "mermaid()"
        )
        #expect(result.contains("<style>.md{}</style>"))
        #expect(result.contains("<style>body{}</style>"))
        #expect(result.contains("<script>marked()</script>"))
        #expect(result.contains("<script>mermaid()</script>"))
        #expect(result.contains("# Test"))
    }
}
