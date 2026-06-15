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

    // MARK: - classifyLink: Path traversal prevention

    @Test func classifyTraversalAboveBaseIsCancelled() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/current.md")
        let relativeURL = URL(string: "../../etc/passwd.md")!
        let result = MarkdownWebView.classifyLink(url: relativeURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    @Test func classifyTraversalToSiblingDirectoryIsCancelled() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/current.md")
        let relativeURL = URL(string: "../other-project/secret.md")!
        let result = MarkdownWebView.classifyLink(url: relativeURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    @Test func classifyAbsoluteFileURLOutsideBaseIsCancelled() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/current.md")
        let absoluteURL = URL(fileURLWithPath: "/etc/secret.md")
        let result = MarkdownWebView.classifyLink(url: absoluteURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    @Test func classifyTraversalThenBackIntoBaseIsAllowed() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/current.md")
        let relativeURL = URL(string: "subdir/../sibling.md")!
        let result = MarkdownWebView.classifyLink(url: relativeURL, fileURL: fileURL)
        let expected = URL(fileURLWithPath: "/Users/test/docs/sibling.md")
        #expect(result == .openMarkdownTab(expected))
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

// MARK: - resolveInDirectory

@Suite("Link Navigation - Safe Path Resolution")
struct ResolveInDirectoryTests {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resolve-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func resolvesFileInSameDirectory() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("readme.md")
        FileManager.default.createFile(atPath: file.path, contents: nil)

        let result = MarkdownWebView.resolveInDirectory(relativePath: "readme.md", baseDir: dir)
        #expect(result == file)
    }

    @Test func resolvesFileInSubdirectory() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sub = dir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("nested.md")
        FileManager.default.createFile(atPath: file.path, contents: nil)

        let result = MarkdownWebView.resolveInDirectory(relativePath: "sub/nested.md", baseDir: dir)
        #expect(result == file)
    }

    @Test func rejectsTraversalWithDotDot() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = MarkdownWebView.resolveInDirectory(relativePath: "../escape.md", baseDir: dir)
        #expect(result == nil)
    }

    @Test func rejectsCurrentDirDot() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = MarkdownWebView.resolveInDirectory(relativePath: "./file.md", baseDir: dir)
        #expect(result == nil)
    }

    @Test func returnsNilForMissingFile() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = MarkdownWebView.resolveInDirectory(relativePath: "nonexistent.md", baseDir: dir)
        #expect(result == nil)
    }

    @Test func returnsNilForEmptyPath() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = MarkdownWebView.resolveInDirectory(relativePath: "", baseDir: dir)
        #expect(result == nil)
    }

    @Test func returnsNilWhenIntermediateIsNotDirectory() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        // Create a file named "sub" (not a directory)
        let notADir = dir.appendingPathComponent("sub")
        FileManager.default.createFile(atPath: notADir.path, contents: nil)

        let result = MarkdownWebView.resolveInDirectory(relativePath: "sub/file.md", baseDir: dir)
        #expect(result == nil)
    }
}
