import Testing
@testable import MarkdownViewerLib

@Suite("ReviewNote - Extract")
struct ExtractTests {

    @Test func extractSingle() {
        let md = "# Title\n\n```review\nFix this\n```\n"
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 1)
        #expect(notes[0] == "Fix this")
    }

    @Test func extractMultiple() {
        let md = """
        # A
        ```review
        Note one
        ```
        ## B
        ```review
        Note two
        ```
        """
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 2)
        #expect(notes[0] == "Note one")
        #expect(notes[1] == "Note two")
    }

    @Test func extractMultiline() {
        let md = "```review\nLine 1\nLine 2\nLine 3\n```"
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 1)
        #expect(notes[0] == "Line 1\nLine 2\nLine 3")
    }

    @Test func extractNone() {
        let md = "# Just a heading\n\nSome text"
        #expect(ReviewNote.extract(from: md).isEmpty)
    }

    @Test func extractIgnoresMermaid() {
        let md = "```mermaid\ngraph TD\n```\n\n```review\nNote\n```"
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 1)
        #expect(notes[0] == "Note")
    }

    @Test func extractIgnoresCodeBlocks() {
        let md = "```python\nprint('hello')\n```\n\n```review\nFeedback\n```"
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 1)
        #expect(notes[0] == "Feedback")
    }
}

@Suite("ReviewNote - Replace")
struct ReplaceTests {

    @Test func replaceContent() {
        let md = "Before\n\n```review\nOld\n```\n\nAfter"
        let result = ReviewNote.replace(at: 0, with: "New", in: md)
        #expect(result.contains("```review\nNew\n```"))
        #expect(!result.contains("Old"))
        #expect(result.contains("Before"))
        #expect(result.contains("After"))
    }

    @Test func replaceSecondNote() {
        let md = "```review\nFirst\n```\n\n```review\nSecond\n```"
        let result = ReviewNote.replace(at: 1, with: "Updated", in: md)
        #expect(result.contains("```review\nFirst\n```"))
        #expect(result.contains("```review\nUpdated\n```"))
        #expect(!result.contains("Second"))
    }

    @Test func replaceOutOfBounds() {
        let md = "```review\nOnly\n```"
        let result = ReviewNote.replace(at: 5, with: "New", in: md)
        #expect(result == md)
    }

    @Test func deleteNote() {
        let md = "Before\n\n```review\nDelete me\n```\n\nAfter"
        let result = ReviewNote.replace(at: 0, with: nil, in: md)
        #expect(!result.contains("review"))
        #expect(!result.contains("Delete me"))
        #expect(result.contains("Before"))
        #expect(result.contains("After"))
    }

    @Test func deleteFirstOfTwo() {
        let md = "```review\nFirst\n```\n\n```review\nSecond\n```"
        let result = ReviewNote.replace(at: 0, with: nil, in: md)
        #expect(!result.contains("First"))
        #expect(result.contains("```review\nSecond\n```"))
    }

    @Test func deleteLastOfTwo() {
        let md = "```review\nFirst\n```\n\n```review\nSecond\n```"
        let result = ReviewNote.replace(at: 1, with: nil, in: md)
        #expect(result.contains("```review\nFirst\n```"))
        #expect(!result.contains("Second"))
    }

    @Test func deleteOnlyNote() {
        let md = "# Title\n\n```review\nDelete\n```\n\n## Next"
        let result = ReviewNote.replace(at: 0, with: nil, in: md)
        #expect(!result.contains("review"))
        #expect(result.contains("# Title"))
        #expect(result.contains("## Next"))
    }

    @Test func replacePreservesMultiline() {
        let md = "```review\nOld\n```"
        let result = ReviewNote.replace(at: 0, with: "Line 1\nLine 2", in: md)
        #expect(result == "```review\nLine 1\nLine 2\n```")
    }
}

@Suite("ReviewNote - Insert After Heading")
struct InsertTests {

    @Test func insertAfterFirstHeading() {
        let md = "# Introduction\n\nSome text\n\n## Methods\n\nMore text"
        let result = ReviewNote.insertAfterHeading(
            "Introduction",
            note: "\n```review\nNote\n```\n",
            in: md
        )
        let lines = result.components(separatedBy: "\n")
        let introIdx = lines.firstIndex { $0.contains("# Introduction") }!
        let methodsIdx = lines.firstIndex { $0.contains("## Methods") }!
        let noteIdx = lines.firstIndex { $0.contains("```review") }!
        #expect(noteIdx > introIdx)
        #expect(noteIdx < methodsIdx)
    }

    @Test func insertAfterLastHeading() {
        let md = "# Title\n\nText\n\n## Last Section\n\nContent here"
        let result = ReviewNote.insertAfterHeading(
            "Last Section",
            note: "\n```review\nFeedback\n```\n",
            in: md
        )
        #expect(result.contains("Content here"))
        #expect(result.hasSuffix("```\n"))
    }

    @Test func insertHeadingNotFound() {
        let md = "# Title\n\nText"
        let result = ReviewNote.insertAfterHeading(
            "Nonexistent",
            note: "\n```review\nNote\n```\n",
            in: md
        )
        // Should append at end when heading not found
        #expect(result.contains("```review\nNote\n```"))
    }

    @Test func insertIgnoresCodeBlockHeadings() {
        let md = "# Real\n\nText\n\n```python\n# Not a heading\n```\n\n## Next"
        let result = ReviewNote.insertAfterHeading(
            "Real",
            note: "\n```review\nNote\n```\n",
            in: md
        )
        let lines = result.components(separatedBy: "\n")
        let realIdx = lines.firstIndex { $0 == "# Real" }!
        let nextIdx = lines.firstIndex { $0 == "## Next" }!
        let noteIdx = lines.firstIndex { $0 == "```review" }!
        #expect(noteIdx > realIdx)
        #expect(noteIdx < nextIdx)
    }

    @Test func insertWithTrailingHashes() {
        let md = "## Title ##\n\nContent\n\n## Next"
        let result = ReviewNote.insertAfterHeading(
            "Title",
            note: "\n```review\nNote\n```\n",
            in: md
        )
        #expect(result.contains("```review"))
    }
}

@Suite("ReviewNote - Sanitize")
struct SanitizeTests {

    @Test func sanitizesBackticks() {
        let content = "Has ``` backticks"
        let sanitized = ReviewNote.sanitizeContent(content)
        #expect(!sanitized.contains("```"))
        #expect(sanitized.contains("` ` `"))
    }

    @Test func noChangeWithoutBackticks() {
        let content = "Normal review content"
        #expect(ReviewNote.sanitizeContent(content) == content)
    }

    @Test func multipleBacktickSequences() {
        let content = "Before ``` middle ``` after"
        let sanitized = ReviewNote.sanitizeContent(content)
        #expect(!sanitized.contains("```"))
    }
}

@Suite("ReviewNote - Roundtrip")
struct RoundtripTests {

    @Test func addThenExtract() {
        var md = "# Doc\n\nContent"
        md += "\n\n```review\nMy feedback\n```\n"
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 1)
        #expect(notes[0] == "My feedback")
    }

    @Test func addEditExtract() {
        var md = "# Doc\n\n```review\nOriginal\n```\n"
        md = ReviewNote.replace(at: 0, with: "Edited", in: md)
        let notes = ReviewNote.extract(from: md)
        #expect(notes.count == 1)
        #expect(notes[0] == "Edited")
    }

    @Test func addDeleteExtract() {
        var md = "# Doc\n\n```review\nTo delete\n```\n"
        md = ReviewNote.replace(at: 0, with: nil, in: md)
        let notes = ReviewNote.extract(from: md)
        #expect(notes.isEmpty)
    }

    @Test func insertEditDelete() {
        var md = "# Title\n\nContent\n\n## Section\n\nMore"
        md = ReviewNote.insertAfterHeading(
            "Title",
            note: "\n```review\nNote 1\n```\n",
            in: md
        )
        #expect(ReviewNote.extract(from: md).count == 1)

        md = ReviewNote.replace(at: 0, with: "Updated note", in: md)
        #expect(ReviewNote.extract(from: md) == ["Updated note"])

        md = ReviewNote.replace(at: 0, with: nil, in: md)
        #expect(ReviewNote.extract(from: md).isEmpty)
        #expect(md.contains("# Title"))
        #expect(md.contains("## Section"))
    }
}
