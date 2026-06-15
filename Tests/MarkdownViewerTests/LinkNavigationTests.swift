import Testing
import Foundation
@testable import MarkdownViewerLib

@Suite("Link Navigation")
struct LinkNavigationTests {

    // MARK: - Markdown extensions

    @Test func markdownExtensionsContainsStandardTypes() {
        let expected: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]
        #expect(MarkdownWebView.markdownExtensions == expected)
    }

    // MARK: - Allowed schemes

    @Test func allowedSchemesContainsExpectedProtocols() {
        #expect(MarkdownWebView.allowedSchemes.contains("http"))
        #expect(MarkdownWebView.allowedSchemes.contains("https"))
        #expect(MarkdownWebView.allowedSchemes.contains("mailto"))
    }

    @Test func allowedSchemesDoesNotContainDangerousProtocols() {
        #expect(!MarkdownWebView.allowedSchemes.contains("javascript"))
        #expect(!MarkdownWebView.allowedSchemes.contains("data"))
        #expect(!MarkdownWebView.allowedSchemes.contains("ftp"))
    }

    // MARK: - classifyLink: HTTP/HTTPS links

    @Test func classifyHttpLinkOpensExternal() {
        let url = URL(string: "https://example.com")!
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .openExternal(url))
    }

    @Test func classifyHttpLinkCaseInsensitive() {
        let url = URL(string: "HTTP://example.com")!
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .openExternal(url))
    }

    @Test func classifyMailtoOpensExternal() {
        let url = URL(string: "mailto:user@example.com")!
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .openExternal(url))
    }

    // MARK: - classifyLink: Unknown schemes

    @Test func classifyJavascriptSchemeIsCancelled() {
        let url = URL(string: "javascript:alert(1)")!
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .cancel)
    }

    @Test func classifyFtpSchemeIsCancelled() {
        let url = URL(string: "ftp://files.example.com/doc.md")!
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .cancel)
    }

    // MARK: - classifyLink: File scheme markdown links

    @Test func classifyFileSchemeMarkdownOpensTab() {
        let url = URL(fileURLWithPath: "/docs/README.md")
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .openMarkdownTab(url))
    }

    @Test func classifyFileSchemeMarkdownAllExtensions() {
        let extensions = ["md", "markdown", "mdown", "mkd", "mkdn"]
        for ext in extensions {
            let url = URL(fileURLWithPath: "/docs/file.\(ext)")
            let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
            #expect(result == .openMarkdownTab(url), "Extension .\(ext) should be classified as markdown")
        }
    }

    @Test func classifyFileSchemeNonMarkdownIsCancelled() {
        let url = URL(fileURLWithPath: "/docs/image.png")
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .cancel)
    }

    @Test func classifyFileSchemeTxtIsCancelled() {
        let url = URL(fileURLWithPath: "/docs/notes.txt")
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .cancel)
    }

    // MARK: - classifyLink: Relative paths

    @Test func classifyRelativeMarkdownResolvesAgainstFileURL() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/current.md")
        let relativeURL = URL(string: "other.md")!
        let result = MarkdownWebView.classifyLink(url: relativeURL, fileURL: fileURL)
        let expected = URL(fileURLWithPath: "/Users/test/docs/other.md")
        #expect(result == .openMarkdownTab(expected))
    }

    @Test func classifyRelativePathInSubdirectory() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/current.md")
        let relativeURL = URL(string: "subdir/nested.md")!
        let result = MarkdownWebView.classifyLink(url: relativeURL, fileURL: fileURL)
        let expected = URL(fileURLWithPath: "/Users/test/docs/subdir/nested.md")
        #expect(result == .openMarkdownTab(expected))
    }

    @Test func classifyRelativeNonMarkdownIsCancelled() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/current.md")
        let relativeURL = URL(string: "image.png")!
        let result = MarkdownWebView.classifyLink(url: relativeURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    @Test func classifyRelativeWithoutFileURLIsCancelled() {
        let relativeURL = URL(string: "other.md")!
        let result = MarkdownWebView.classifyLink(url: relativeURL, fileURL: nil)
        #expect(result == .cancel)
    }

    // MARK: - classifyLink: Case insensitivity

    @Test func classifyMarkdownExtensionCaseInsensitive() {
        let url = URL(fileURLWithPath: "/docs/README.MD")
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .openMarkdownTab(url))
    }

    @Test func classifyMixedCaseExtension() {
        let url = URL(fileURLWithPath: "/docs/file.Markdown")
        let result = MarkdownWebView.classifyLink(url: url, fileURL: nil)
        #expect(result == .openMarkdownTab(url))
    }

    // MARK: - LinkAction equatable

    @Test func linkActionEquality() {
        let url1 = URL(fileURLWithPath: "/a.md")
        let url2 = URL(fileURLWithPath: "/b.md")
        #expect(MarkdownWebView.LinkAction.openMarkdownTab(url1) == .openMarkdownTab(url1))
        #expect(MarkdownWebView.LinkAction.openMarkdownTab(url1) != .openMarkdownTab(url2))
        #expect(MarkdownWebView.LinkAction.cancel == .cancel)
        #expect(MarkdownWebView.LinkAction.cancel != .openExternal(url1))
    }
}
