import Testing
@testable import MarkdownViewerLib

@Suite("SourceHighlighter - Markdown Source")
struct MarkdownSourceTests {

    @Test func rendersHeading() {
        let html = SourceHighlighter.render("# Title")
        #expect(html.contains("sh-heading"))
        #expect(html.contains("# Title"))
    }

    @Test func rendersMultipleLevelHeadings() {
        let html = SourceHighlighter.render("## H2\n### H3\n#### H4")
        #expect(html.contains("sh-heading"))
    }

    @Test func rendersBold() {
        let html = SourceHighlighter.render("**bold text**")
        #expect(html.contains("sh-bold"))
        #expect(html.contains("bold text"))
    }

    @Test func rendersItalic() {
        let html = SourceHighlighter.render("*italic text*")
        #expect(html.contains("sh-italic"))
    }

    @Test func rendersInlineCode() {
        let html = SourceHighlighter.render("`code here`")
        #expect(html.contains("sh-inline-code"))
        #expect(html.contains("code here"))
    }

    @Test func rendersCodeBlock() {
        let html = SourceHighlighter.render("```python\nprint('hi')\n```")
        #expect(html.contains("sh-fence"))
        #expect(html.contains("sh-code"))
        #expect(html.contains("print"))
    }

    @Test func rendersLink() {
        let html = SourceHighlighter.render("[text](https://example.com)")
        #expect(html.contains("sh-link"))
        #expect(html.contains("example.com"))
    }

    @Test func rendersBlockquote() {
        let html = SourceHighlighter.render("> quoted text")
        #expect(html.contains("sh-quote"))
    }

    @Test func rendersTable() {
        let html = SourceHighlighter.render("| A | B |\n|---|---|\n| 1 | 2 |")
        #expect(html.contains("sh-table"))
        #expect(html.contains("sh-table-sep"))
    }

    @Test func escapesHTML() {
        let html = SourceHighlighter.render("<script>alert('xss')</script>")
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>alert"))
    }

    @Test func producesValidPage() {
        let html = SourceHighlighter.render("# Test")
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<pre>"))
        #expect(html.contains("</html>"))
    }

    @Test func emptyInput() {
        let html = SourceHighlighter.render("")
        #expect(html.contains("<pre>"))
    }
}

@Suite("SourceHighlighter - HTML Preview")
struct HTMLPreviewTests {

    @Test func rendersHTMLTags() {
        let html = SourceHighlighter.renderHTMLPreview("# Hello")
        #expect(html.contains("sh-tag-name"))
        #expect(html.contains("h1"))
    }

    @Test func rendersParagraph() {
        let html = SourceHighlighter.renderHTMLPreview("Some text")
        #expect(html.contains("sh-tag-name"))
        #expect(html.contains("p"))
    }

    @Test func escapesHTMLInOutput() {
        let html = SourceHighlighter.renderHTMLPreview("**bold**")
        // The rendered HTML source should show <strong> as escaped text
        #expect(html.contains("&lt;"))
        #expect(html.contains("strong"))
    }

    @Test func producesValidPage() {
        let html = SourceHighlighter.renderHTMLPreview("test")
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("</html>"))
    }

    @Test func emptyInput() {
        let html = SourceHighlighter.renderHTMLPreview("")
        #expect(html.contains("<pre>"))
    }
}
