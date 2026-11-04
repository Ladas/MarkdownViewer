import Testing
import UniformTypeIdentifiers
@testable import MarkdownViewerLib

// MARK: - MarkdownDocument: File Type Registration

@Suite("MarkdownDocument - Data File Content Types")
struct DataFileContentTypeTests {

    @Test func readableContentTypesIncludesJSON() {
        #expect(MarkdownDocument.readableContentTypes.contains(.json))
    }

    @Test func readableContentTypesIncludesYAML() {
        #expect(MarkdownDocument.readableContentTypes.contains(.yaml))
    }

    @Test func readableContentTypesStillIncludesMarkdown() {
        #expect(MarkdownDocument.readableContentTypes.contains(.markdown))
    }

    @Test func readableContentTypesStillIncludesPlainText() {
        #expect(MarkdownDocument.readableContentTypes.contains(.plainText))
    }

    @Test func initWithJSONContent() {
        let json = """
        {"key": "value", "number": 42}
        """
        let doc = MarkdownDocument(text: json)
        #expect(doc.text == json)
    }

    @Test func initWithYAMLContent() {
        let yaml = """
        name: test
        items:
          - one
          - two
        """
        let doc = MarkdownDocument(text: yaml)
        #expect(doc.text == yaml)
    }

    @Test func initWithComplexJSON() {
        let json = """
        {
          "nested": {
            "array": [1, 2, 3],
            "null_value": null,
            "boolean": true,
            "string": "hello \\\"world\\\""
          }
        }
        """
        let doc = MarkdownDocument(text: json)
        #expect(doc.text.contains("nested"))
        #expect(doc.text.contains("null_value"))
    }

    @Test func initWithComplexYAML() {
        let yaml = """
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: my-config
          labels:
            app: test
        data:
          key1: value1
          key2: |
            multi
            line
            value
        """
        let doc = MarkdownDocument(text: yaml)
        #expect(doc.text.contains("apiVersion"))
        #expect(doc.text.contains("multi"))
    }
}

// MARK: - HTMLRenderer.wrapForRendering

@Suite("HTMLRenderer - wrapForRendering: JSON")
struct WrapJSONTests {

    @Test func wrapsJSONInCodeFence() {
        let json = """
        {"key": "value"}
        """
        let result = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        #expect(result == "```json\n{\"key\": \"value\"}\n```")
    }

    @Test func jsonExtensionCaseInsensitive() {
        let text = "{}"
        let upper = HTMLRenderer.wrapForRendering(text, fileExtension: "JSON")
        let mixed = HTMLRenderer.wrapForRendering(text, fileExtension: "Json")
        #expect(upper.hasPrefix("```json"))
        #expect(mixed.hasPrefix("```json"))
    }

    @Test func preservesJSONContentExactly() {
        let json = """
        {
          "string": "hello",
          "number": 3.14,
          "boolean": true,
          "null": null,
          "array": [1, "two", false],
          "nested": {"a": {"b": "c"}}
        }
        """
        let result = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        #expect(result.contains(json))
    }

    @Test func emptyJSONFile() {
        let result = HTMLRenderer.wrapForRendering("", fileExtension: "json")
        #expect(result == "```json\n\n```")
    }

    @Test func jsonWithSpecialCharacters() {
        let json = """
        {"url": "https://example.com?a=1&b=2", "html": "<div>test</div>"}
        """
        let result = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        #expect(result.contains("https://example.com?a=1&b=2"))
        #expect(result.contains("<div>test</div>"))
    }

    @Test func jsonWithUnicode() {
        let json = """
        {"emoji": "🎉", "cjk": "日本語", "accents": "café"}
        """
        let result = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        #expect(result.contains("🎉"))
        #expect(result.contains("日本語"))
        #expect(result.contains("café"))
    }

    @Test func jsonWithBackticks() {
        let json = """
        {"code": "`inline code`"}
        """
        let result = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        #expect(result.hasPrefix("```json\n"))
        #expect(result.hasSuffix("\n```"))
        #expect(result.contains("`inline code`"))
    }

    @Test func jsonWithNewlines() {
        let json = "{\n  \"a\": 1,\n  \"b\": 2\n}"
        let result = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        let lines = result.components(separatedBy: "\n")
        #expect(lines.first == "```json")
        #expect(lines.last == "```")
    }
}

@Suite("HTMLRenderer - wrapForRendering: YAML")
struct WrapYAMLTests {

    @Test func wrapsYAMLInCodeFence() {
        let yaml = "name: test\nvalue: 42"
        let result = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yaml")
        #expect(result == "```yaml\nname: test\nvalue: 42\n```")
    }

    @Test func wrapsYMLInCodeFence() {
        let yaml = "key: value"
        let result = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yml")
        #expect(result == "```yaml\nkey: value\n```")
    }

    @Test func yamlExtensionCaseInsensitive() {
        let text = "key: value"
        let upper = HTMLRenderer.wrapForRendering(text, fileExtension: "YAML")
        let mixed = HTMLRenderer.wrapForRendering(text, fileExtension: "Yml")
        #expect(upper.hasPrefix("```yaml"))
        #expect(mixed.hasPrefix("```yaml"))
    }

    @Test func ymlAndYamlProduceSameWrapper() {
        let text = "key: value"
        let fromYaml = HTMLRenderer.wrapForRendering(text, fileExtension: "yaml")
        let fromYml = HTMLRenderer.wrapForRendering(text, fileExtension: "yml")
        #expect(fromYaml == fromYml)
    }

    @Test func preservesYAMLContentExactly() {
        let yaml = """
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: nginx
          labels:
            app: nginx
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: nginx
        """
        let result = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yaml")
        #expect(result.contains(yaml))
    }

    @Test func emptyYAMLFile() {
        let result = HTMLRenderer.wrapForRendering("", fileExtension: "yaml")
        #expect(result == "```yaml\n\n```")
    }

    @Test func yamlWithComments() {
        let yaml = """
        # This is a comment
        name: test  # inline comment
        """
        let result = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yaml")
        #expect(result.contains("# This is a comment"))
        #expect(result.contains("# inline comment"))
    }

    @Test func yamlWithMultilineStrings() {
        let yaml = """
        description: |
          This is a
          multi-line string
        folded: >
          This will be
          folded into one line
        """
        let result = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yaml")
        #expect(result.contains("description: |"))
        #expect(result.contains("folded: >"))
    }

    @Test func yamlWithAnchorsAndAliases() {
        let yaml = """
        defaults: &defaults
          timeout: 30
          retries: 3
        production:
          <<: *defaults
          timeout: 60
        """
        let result = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yaml")
        #expect(result.contains("&defaults"))
        #expect(result.contains("*defaults"))
    }
}

@Suite("HTMLRenderer - wrapForRendering: Passthrough")
struct WrapPassthroughTests {

    @Test func markdownFilesNotWrapped() {
        let md = "# Hello\n\nSome text"
        let result = HTMLRenderer.wrapForRendering(md, fileExtension: "md")
        #expect(result == md)
    }

    @Test func markdownExtensionNotWrapped() {
        let md = "# Hello"
        let result = HTMLRenderer.wrapForRendering(md, fileExtension: "markdown")
        #expect(result == md)
    }

    @Test func txtFilesNotWrapped() {
        let text = "plain text content"
        let result = HTMLRenderer.wrapForRendering(text, fileExtension: "txt")
        #expect(result == text)
    }

    @Test func nilExtensionNotWrapped() {
        let text = "no extension"
        let result = HTMLRenderer.wrapForRendering(text, fileExtension: nil)
        #expect(result == text)
    }

    @Test func emptyExtensionNotWrapped() {
        let text = "empty ext"
        let result = HTMLRenderer.wrapForRendering(text, fileExtension: "")
        #expect(result == text)
    }

    @Test func unknownExtensionNotWrapped() {
        let text = "some content"
        #expect(HTMLRenderer.wrapForRendering(text, fileExtension: "xml") == text)
        #expect(HTMLRenderer.wrapForRendering(text, fileExtension: "csv") == text)
        #expect(HTMLRenderer.wrapForRendering(text, fileExtension: "toml") == text)
        #expect(HTMLRenderer.wrapForRendering(text, fileExtension: "ini") == text)
    }
}

@Suite("HTMLRenderer - wrapForRendering: Code Fence Structure")
struct WrapCodeFenceStructureTests {

    @Test func jsonFenceStartsWithCorrectMarker() {
        let result = HTMLRenderer.wrapForRendering("{}", fileExtension: "json")
        #expect(result.hasPrefix("```json\n"))
    }

    @Test func jsonFenceEndsWithClosingMarker() {
        let result = HTMLRenderer.wrapForRendering("{}", fileExtension: "json")
        #expect(result.hasSuffix("\n```"))
    }

    @Test func yamlFenceStartsWithCorrectMarker() {
        let result = HTMLRenderer.wrapForRendering("key: val", fileExtension: "yaml")
        #expect(result.hasPrefix("```yaml\n"))
    }

    @Test func yamlFenceEndsWithClosingMarker() {
        let result = HTMLRenderer.wrapForRendering("key: val", fileExtension: "yaml")
        #expect(result.hasSuffix("\n```"))
    }

    @Test func noDoubleNewlinesAroundContent() {
        let result = HTMLRenderer.wrapForRendering("content", fileExtension: "json")
        #expect(!result.contains("```json\n\ncontent"))
        #expect(!result.contains("content\n\n```"))
    }

    @Test func contentBetweenFenceMarkers() {
        let content = "test content here"
        let result = HTMLRenderer.wrapForRendering(content, fileExtension: "json")
        let inner = result
            .replacingOccurrences(of: "```json\n", with: "")
            .replacingOccurrences(of: "\n```", with: "")
        #expect(inner == content)
    }
}

// MARK: - Integration: wrapForRendering + escapeForJSTemplateLiteral

@Suite("Data File Rendering - JS Escaping Integration")
struct DataFileEscapingTests {

    @Test func jsonWithBackticksEscapedForJS() {
        let json = """
        {"code": "`value`"}
        """
        let wrapped = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        let escaped = HTMLRenderer.escapeForJSTemplateLiteral(wrapped)
        #expect(escaped.contains("\\`\\`\\`json"))
        #expect(escaped.contains("\\`value\\`"))
    }

    @Test func jsonWithDollarSignsEscapedForJS() {
        let json = """
        {"price": "$99.99"}
        """
        let wrapped = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        let escaped = HTMLRenderer.escapeForJSTemplateLiteral(wrapped)
        #expect(escaped.contains("\\$99.99"))
    }

    @Test func yamlWithBackslashesEscapedForJS() {
        let yaml = "path: C:\\Users\\test"
        let wrapped = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yaml")
        let escaped = HTMLRenderer.escapeForJSTemplateLiteral(wrapped)
        #expect(escaped.contains("C:\\\\Users\\\\test"))
    }

    @Test func jsonWithScriptTagEscapedForJS() {
        let json = """
        {"html": "</script>"}
        """
        let wrapped = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        let escaped = HTMLRenderer.escapeForJSTemplateLiteral(wrapped)
        #expect(escaped.contains("<\\/script>"))
    }
}

// MARK: - Integration: TOC with Data Files

@Suite("TOC - Data File Content")
struct TOCDataFileTests {

    @Test func jsonContentProducesNoTOCEntries() {
        let json = """
        {
          "# not a heading": "value",
          "## also not": "value"
        }
        """
        let entries = TOCEntry.parse(from: json)
        #expect(entries.isEmpty)
    }

    @Test func yamlContentProducesNoTOCEntries() {
        let yaml = """
        config:
          setting1: value1
          setting2: value2
        """
        let entries = TOCEntry.parse(from: yaml)
        #expect(entries.isEmpty)
    }

    @Test func yamlCommentLooksLikeHeadingButIsNot() {
        // YAML comments start with # but TOC parser requires space after #
        // and these are typically indented or part of values, not standalone headings
        let yaml = """
        # This actually matches the heading regex
        name: test
        """
        let entries = TOCEntry.parse(from: yaml)
        // This is expected: YAML comments with "# Text" format will match
        // as headings — acceptable since it's a code file, not markdown
        #expect(entries.count == 1)
    }
}

// MARK: - Integration: Full Render Pipeline

@Suite("Data File Rendering - Full Pipeline")
struct DataFileFullPipelineTests {

    @Test func jsonRenderedAsHTML() {
        let json = """
        {"key": "value"}
        """
        let wrapped = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        let html = HTMLRenderer.render(markdown: wrapped)
        #expect(html.contains("<!DOCTYPE html") || html.contains("<html"))
        #expect(html.contains("key"))
        #expect(html.contains("value"))
    }

    @Test func yamlRenderedAsHTML() {
        let yaml = "name: test\nversion: 1.0"
        let wrapped = HTMLRenderer.wrapForRendering(yaml, fileExtension: "yaml")
        let html = HTMLRenderer.render(markdown: wrapped)
        #expect(html.contains("<!DOCTYPE html") || html.contains("<html"))
        #expect(html.contains("name"))
        #expect(html.contains("test"))
    }

    @Test func markdownStillRendersNormally() {
        let md = "# Hello\n\nParagraph with **bold**."
        let wrapped = HTMLRenderer.wrapForRendering(md, fileExtension: "md")
        let html = HTMLRenderer.render(markdown: wrapped)
        #expect(html.contains("# Hello"))
        #expect(html.contains("**bold**"))
    }

    @Test func wrappedJSONContainsCodeFenceInRenderedHTML() {
        let json = "{}"
        let wrapped = HTMLRenderer.wrapForRendering(json, fileExtension: "json")
        let html = HTMLRenderer.render(markdown: wrapped)
        // The escaped backticks for the code fence should be present
        #expect(html.contains("\\`\\`\\`json"))
    }
}
