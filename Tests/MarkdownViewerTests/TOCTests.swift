import Testing
@testable import MarkdownViewerLib

@Suite("TOC - Heading Parsing")
struct TOCTests {

    @Test func simpleHeadings() {
        let md = """
        # Title
        ## Section 1
        ### Subsection
        ## Section 2
        """
        let entries = TOCEntry.parse(from: md)
        #expect(entries.count == 4)
        #expect(entries[0].level == 1)
        #expect(entries[0].title == "Title")
        #expect(entries[1].level == 2)
        #expect(entries[1].title == "Section 1")
        #expect(entries[2].level == 3)
        #expect(entries[2].title == "Subsection")
        #expect(entries[3].level == 2)
        #expect(entries[3].title == "Section 2")
    }

    @Test func headingIndices() {
        let md = "# A\n## B\n### C"
        let entries = TOCEntry.parse(from: md)
        #expect(entries[0].id == 0)
        #expect(entries[1].id == 1)
        #expect(entries[2].id == 2)
    }

    @Test func headingInsideCodeBlock() {
        let md = """
        # Real heading
        ```
        # Not a heading
        ## Also not
        ```
        ## Another real heading
        """
        let entries = TOCEntry.parse(from: md)
        #expect(entries.count == 2)
        #expect(entries[0].title == "Real heading")
        #expect(entries[1].title == "Another real heading")
    }

    @Test func emptyDocument() {
        #expect(TOCEntry.parse(from: "").isEmpty)
    }

    @Test func noHeadings() {
        #expect(TOCEntry.parse(from: "Just some text\nMore text").isEmpty)
    }

    @Test func trailingHashes() {
        let entries = TOCEntry.parse(from: "## Title ##")
        #expect(entries.count == 1)
        #expect(entries[0].title == "Title")
    }

    @Test func allLevels() {
        let md = "# H1\n## H2\n### H3\n#### H4\n##### H5\n###### H6"
        let entries = TOCEntry.parse(from: md)
        #expect(entries.count == 6)
        for i in 0..<6 {
            #expect(entries[i].level == i + 1)
        }
    }

    @Test func headingWithFormatting() {
        let entries = TOCEntry.parse(from: "## **Bold** and *italic*")
        #expect(entries.count == 1)
        #expect(entries[0].title == "**Bold** and *italic*")
    }

    @Test func noSpaceAfterHash() {
        // Per CommonMark spec, space after # is required
        let entries = TOCEntry.parse(from: "#NoSpace")
        #expect(entries.isEmpty)
    }

    @Test func fencedCodeBlockWithLanguage() {
        let md = """
        # Before
        ```python
        # comment in code
        ```
        # After
        """
        let entries = TOCEntry.parse(from: md)
        #expect(entries.count == 2)
    }
}
