import Testing
@testable import MarkdownViewerLib

@Suite("MarkdownDocument")
struct MarkdownDocumentTests {

    @Test func defaultText() {
        let doc = MarkdownDocument()
        #expect(doc.text == "")
    }

    @Test func initWithText() {
        let doc = MarkdownDocument(text: "# Hello World")
        #expect(doc.text == "# Hello World")
    }

    @Test func multilineMarkdown() {
        let markdown = """
        # Title

        Some paragraph with **bold** and *italic*.

        ```mermaid
        graph TD
            A --> B
        ```
        """
        let doc = MarkdownDocument(text: markdown)
        #expect(doc.text.contains("# Title"))
        #expect(doc.text.contains("```mermaid"))
    }

    @Test func emoji() {
        let doc = MarkdownDocument(text: "Hello 🌍")
        #expect(doc.text == "Hello 🌍")
    }

    @Test func preservesWhitespace() {
        let text = "  indented\n\ttabbed\n\nblank line above"
        let doc = MarkdownDocument(text: text)
        #expect(doc.text == text)
    }
}
