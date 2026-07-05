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

// MARK: - Temp file location

@Suite("Link Navigation - Temp File Location")
struct TempFileLocationTests {

    // The temp file MUST be in the same directory as the markdown file.
    // When it was in the parent directory, WKWebView resolved relative links one
    // level too high (e.g. "other.md" → "evals/other.md" instead of
    // "evals/2026-06-19/other.md"), causing classifyLink to cancel every link.

    @Test func tempFileIsInsideFileDirectory() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let baseDir = fileURL.deletingLastPathComponent()
        let tempURL = MarkdownWebView.tempFileURL(inDirectory: baseDir)

        #expect(tempURL.deletingLastPathComponent().standardizedFileURL == baseDir.standardizedFileURL)
    }

    @Test func tempFileIsNotInParentDirectory() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let baseDir = fileURL.deletingLastPathComponent()
        let tempURL = MarkdownWebView.tempFileURL(inDirectory: baseDir)
        let parentDir = baseDir.deletingLastPathComponent()

        #expect(tempURL.deletingLastPathComponent().standardizedFileURL != parentDir.standardizedFileURL)
    }

    @Test func tempFileNameIsHidden() {
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let tempURL = MarkdownWebView.tempFileURL(inDirectory: baseDir)
        #expect(tempURL.lastPathComponent.hasPrefix("."))
    }

    // Simulate exactly what WKWebView does: when loaded with tempURL as the base,
    // a relative link "other.md" resolves to tempURL's directory + "other.md".
    // classifyLink must accept this resolved URL.
    @Test func relativeLinkFromTempFileResolvesIntoSameDirectory() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let baseDir = fileURL.deletingLastPathComponent()
        let tempURL = MarkdownWebView.tempFileURL(inDirectory: baseDir)

        // WKWebView resolves "other.md" against tempURL → same directory as fileURL
        let navigationURL = tempURL.deletingLastPathComponent()
            .appendingPathComponent("other.md")

        let result = MarkdownWebView.classifyLink(url: navigationURL, fileURL: fileURL)
        #expect(result == .openMarkdownTab(navigationURL.standardizedFileURL))
    }

    // Regression: with the old code tempURL was in the PARENT directory, so
    // WKWebView resolved relative links one level too high and classifyLink
    // cancelled them because they were outside the file's directory.
    @Test func regressionTempFileInParentDirectoryBreaksLinks() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let baseDir = fileURL.deletingLastPathComponent()

        // Simulate the OLD (broken) temp file location: parent of baseDir
        let brokenTempURL = baseDir.deletingLastPathComponent()
            .appendingPathComponent(".markdown-viewer-temp.html")

        // WKWebView would have resolved "other.md" against the parent dir
        let navigationURL = brokenTempURL.deletingLastPathComponent()
            .appendingPathComponent("other.md")

        // classifyLink must CANCEL this — the resolved URL is outside baseDir
        let result = MarkdownWebView.classifyLink(url: navigationURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    // Full chain with real files: correct temp file location → relative link
    // resolves correctly → resolveInDirectory finds the file.
    @Test func fullChainWithCorrectTempFileLocation() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("temp-loc-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fileURL = dir.appendingPathComponent("report.md")
        let targetFile = dir.appendingPathComponent("other.md")
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        FileManager.default.createFile(atPath: targetFile.path, contents: nil)

        let baseDir = fileURL.deletingLastPathComponent()
        let tempURL = MarkdownWebView.tempFileURL(inDirectory: baseDir)

        // WKWebView resolves "other.md" from tempURL → should land in same dir
        let navigationURL = tempURL.deletingLastPathComponent()
            .appendingPathComponent("other.md")

        let action = MarkdownWebView.classifyLink(url: navigationURL, fileURL: fileURL)
        guard case .openMarkdownTab(let resolvedURL) = action else {
            Issue.record("Expected openMarkdownTab, got \(action)")
            return
        }

        let relPath = MarkdownWebView.relativePathInDirectory(
            resolvedURL: resolvedURL, baseDir: baseDir)
        #expect(relPath == "other.md")

        let safeURL = MarkdownWebView.resolveInDirectory(
            relativePath: relPath!, baseDir: baseDir)
        #expect(safeURL == targetFile)
    }
}

// MARK: - classifyLink with fully-resolved file:// URLs (as WKWebView provides)

@Suite("Link Navigation - classifyLink with file:// URLs")
struct ClassifyLinkFileURLTests {

    // WKWebView always hands decidePolicyFor a fully-resolved file:// URL,
    // even when the original link was a bare relative path like "other.md".

    @Test func sameDirectoryFileURL() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        // WKWebView resolves "other.md" → file:///Users/test/docs/other.md
        let clickedURL = URL(fileURLWithPath: "/Users/test/docs/other.md")
        let result = MarkdownWebView.classifyLink(url: clickedURL, fileURL: fileURL)
        #expect(result == .openMarkdownTab(clickedURL.standardizedFileURL))
    }

    @Test func subdirectoryFileURL() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let clickedURL = URL(fileURLWithPath: "/Users/test/docs/subdir/nested.md")
        let result = MarkdownWebView.classifyLink(url: clickedURL, fileURL: fileURL)
        #expect(result == .openMarkdownTab(clickedURL.standardizedFileURL))
    }

    @Test func parentDirectoryFileURLIsCancelled() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        // WKWebView resolves "../secret.md" → file:///Users/test/secret.md
        let clickedURL = URL(fileURLWithPath: "/Users/test/secret.md")
        let result = MarkdownWebView.classifyLink(url: clickedURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    @Test func siblingDirectoryFileURLIsCancelled() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let clickedURL = URL(fileURLWithPath: "/Users/test/other-project/file.md")
        let result = MarkdownWebView.classifyLink(url: clickedURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    @Test func nonMarkdownFileURLIsCancelled() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let clickedURL = URL(fileURLWithPath: "/Users/test/docs/image.png")
        let result = MarkdownWebView.classifyLink(url: clickedURL, fileURL: fileURL)
        #expect(result == .cancel)
    }
}

// MARK: - relativePathInDirectory

@Suite("Link Navigation - relativePathInDirectory")
struct RelativePathInDirectoryTests {

    @Test func sameDirectoryFile() {
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let resolved = URL(fileURLWithPath: "/Users/test/docs/other.md")
        let result = MarkdownWebView.relativePathInDirectory(resolvedURL: resolved, baseDir: baseDir)
        #expect(result == "other.md")
    }

    @Test func fileInSubdirectory() {
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let resolved = URL(fileURLWithPath: "/Users/test/docs/subdir/nested.md")
        let result = MarkdownWebView.relativePathInDirectory(resolvedURL: resolved, baseDir: baseDir)
        #expect(result == "subdir/nested.md")
    }

    @Test func fileInDeeplyNestedSubdirectory() {
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let resolved = URL(fileURLWithPath: "/Users/test/docs/a/b/c/file.md")
        let result = MarkdownWebView.relativePathInDirectory(resolvedURL: resolved, baseDir: baseDir)
        #expect(result == "a/b/c/file.md")
    }

    @Test func fileOutsideBaseDirReturnsNil() {
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let resolved = URL(fileURLWithPath: "/Users/test/secret.md")
        let result = MarkdownWebView.relativePathInDirectory(resolvedURL: resolved, baseDir: baseDir)
        #expect(result == nil)
    }

    @Test func fileinSiblingDirectoryReturnsNil() {
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let resolved = URL(fileURLWithPath: "/Users/test/other-project/file.md")
        let result = MarkdownWebView.relativePathInDirectory(resolvedURL: resolved, baseDir: baseDir)
        #expect(result == nil)
    }

    @Test func prefixAmbiguityRejected() {
        // /Users/test/docs-extra/file.md must NOT match base /Users/test/docs
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let resolved = URL(fileURLWithPath: "/Users/test/docs-extra/file.md")
        let result = MarkdownWebView.relativePathInDirectory(resolvedURL: resolved, baseDir: baseDir)
        #expect(result == nil)
    }

    @Test func baseDirItselfReturnsNil() {
        let baseDir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let result = MarkdownWebView.relativePathInDirectory(resolvedURL: baseDir, baseDir: baseDir)
        #expect(result == nil)
    }
}

// MARK: - Full pipeline: classifyLink → relativePathInDirectory → resolveInDirectory

@Suite("Link Navigation - Full pipeline")
struct LinkPipelineTests {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // This is the exact scenario that was broken: WKWebView gives a file:// URL
    // for a same-directory link; the old code passed url.relativePath (an absolute
    // path) to resolveInDirectory which then failed to find any component.
    @Test func sameDirectoryLinkOpens() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let currentFile = dir.appendingPathComponent("report.md")
        let targetFile  = dir.appendingPathComponent("other.md")
        FileManager.default.createFile(atPath: currentFile.path, contents: nil)
        FileManager.default.createFile(atPath: targetFile.path, contents: nil)

        // classifyLink step — use the fully-resolved file:// URL as WKWebView would
        let action = MarkdownWebView.classifyLink(url: targetFile, fileURL: currentFile)
        guard case .openMarkdownTab(let resolvedURL) = action else {
            Issue.record("Expected openMarkdownTab, got \(action)")
            return
        }

        // relativePathInDirectory step
        let baseDir = currentFile.deletingLastPathComponent()
        let relPath = MarkdownWebView.relativePathInDirectory(resolvedURL: resolvedURL, baseDir: baseDir)
        #expect(relPath == "other.md")

        // resolveInDirectory step
        let safeURL = MarkdownWebView.resolveInDirectory(relativePath: relPath!, baseDir: baseDir)
        #expect(safeURL == targetFile)
    }

    @Test func subdirectoryLinkOpens() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sub = dir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let currentFile = dir.appendingPathComponent("index.md")
        let targetFile  = sub.appendingPathComponent("chapter.md")
        FileManager.default.createFile(atPath: currentFile.path, contents: nil)
        FileManager.default.createFile(atPath: targetFile.path, contents: nil)

        let action = MarkdownWebView.classifyLink(url: targetFile, fileURL: currentFile)
        guard case .openMarkdownTab(let resolvedURL) = action else {
            Issue.record("Expected openMarkdownTab, got \(action)")
            return
        }

        let baseDir = currentFile.deletingLastPathComponent()
        let relPath = MarkdownWebView.relativePathInDirectory(resolvedURL: resolvedURL, baseDir: baseDir)
        #expect(relPath == "sub/chapter.md")

        let safeURL = MarkdownWebView.resolveInDirectory(relativePath: relPath!, baseDir: baseDir)
        #expect(safeURL == targetFile)
    }

    @Test func parentDirectoryLinkBlocked() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sub = dir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let currentFile = sub.appendingPathComponent("report.md")
        // Target is ../escape.md — one level above sub, inside dir
        let targetFile  = dir.appendingPathComponent("escape.md")
        FileManager.default.createFile(atPath: currentFile.path, contents: nil)
        FileManager.default.createFile(atPath: targetFile.path, contents: nil)

        // classifyLink should block this (outside the file's directory)
        let action = MarkdownWebView.classifyLink(url: targetFile, fileURL: currentFile)
        #expect(action == .cancel)
    }

    @Test func missingTargetFileReturnsNilFromResolve() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let currentFile = dir.appendingPathComponent("report.md")
        let targetFile  = dir.appendingPathComponent("nonexistent.md")
        FileManager.default.createFile(atPath: currentFile.path, contents: nil)
        // targetFile is NOT created on disk

        let action = MarkdownWebView.classifyLink(url: targetFile, fileURL: currentFile)
        guard case .openMarkdownTab(let resolvedURL) = action else {
            Issue.record("Expected openMarkdownTab, got \(action)")
            return
        }

        let baseDir = currentFile.deletingLastPathComponent()
        let relPath = MarkdownWebView.relativePathInDirectory(resolvedURL: resolvedURL, baseDir: baseDir)
        #expect(relPath == "nonexistent.md")

        // resolveInDirectory must return nil — file doesn't exist
        let safeURL = MarkdownWebView.resolveInDirectory(relativePath: relPath!, baseDir: baseDir)
        #expect(safeURL == nil)
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

// MARK: - extractLocalPaths

@Suite("Link Navigation - extractLocalPaths")
struct ExtractLocalPathsTests {

    @Test func extractsImagePath() {
        let md = "![diagram](../diagrams/arch.svg)"
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths == ["../diagrams/arch.svg"])
    }

    @Test func extractsLinkPath() {
        let md = "[see docs](other.md)"
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths == ["other.md"])
    }

    @Test func extractsBothImagesAndLinks() {
        let md = """
        ![img](images/photo.png)
        Some text [link](../docs/readme.md) more text
        ![another](sub/diagram.svg)
        """
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths == ["images/photo.png", "../docs/readme.md", "sub/diagram.svg"])
    }

    @Test func ignoresHTTPLinks() {
        let md = "[example](https://example.com)"
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths.isEmpty)
    }

    @Test func ignoresMailtoLinks() {
        let md = "[email](mailto:user@example.com)"
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths.isEmpty)
    }

    @Test func ignoresAnchorLinks() {
        let md = "[section](#overview)"
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths.isEmpty)
    }

    @Test func ignoresDataURIs() {
        let md = "![icon](data:image/png;base64,abc)"
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths.isEmpty)
    }

    @Test func handlesImageWithTitle() {
        let md = """
        ![alt](image.png "my title")
        """
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths == ["image.png"])
    }

    @Test func returnsEmptyForNoLinks() {
        let md = "Just plain text with no links at all."
        let paths = MarkdownWebView.extractLocalPaths(from: md)
        #expect(paths.isEmpty)
    }
}

// MARK: - commonAncestorDirectory

@Suite("Link Navigation - commonAncestorDirectory")
struct CommonAncestorDirectoryTests {

    @Test func sameDirectoryReturnsSelf() {
        let dir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let result = MarkdownWebView.commonAncestorDirectory(of: [dir, dir])
        #expect(result?.path == dir.path)
    }

    @Test func siblingDirectoriesReturnParent() {
        let a = URL(fileURLWithPath: "/Users/test/docs/dev", isDirectory: true)
        let b = URL(fileURLWithPath: "/Users/test/docs/diagrams", isDirectory: true)
        let result = MarkdownWebView.commonAncestorDirectory(of: [a, b])
        #expect(result?.path == "/Users/test/docs")
    }

    @Test func nestedDirectoryReturnsParent() {
        let parent = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let child = URL(fileURLWithPath: "/Users/test/docs/sub/deep", isDirectory: true)
        let result = MarkdownWebView.commonAncestorDirectory(of: [parent, child])
        #expect(result?.path == "/Users/test/docs")
    }

    @Test func distantDirectoriesReturnRoot() {
        let a = URL(fileURLWithPath: "/Users/alice/project", isDirectory: true)
        let b = URL(fileURLWithPath: "/var/log", isDirectory: true)
        let result = MarkdownWebView.commonAncestorDirectory(of: [a, b])
        #expect(result?.path == "/")
    }

    @Test func singleURLReturnsSelf() {
        let dir = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let result = MarkdownWebView.commonAncestorDirectory(of: [dir])
        #expect(result?.path == dir.path)
    }

    @Test func emptyArrayReturnsNil() {
        let result = MarkdownWebView.commonAncestorDirectory(of: [])
        #expect(result == nil)
    }

    @Test func threeDirectories() {
        let a = URL(fileURLWithPath: "/project/docs/dev", isDirectory: true)
        let b = URL(fileURLWithPath: "/project/docs/diagrams", isDirectory: true)
        let c = URL(fileURLWithPath: "/project/src", isDirectory: true)
        let result = MarkdownWebView.commonAncestorDirectory(of: [a, b, c])
        #expect(result?.path == "/project")
    }
}

// MARK: - accessScope

@Suite("Link Navigation - accessScope")
struct AccessScopeTests {

    @Test func noFileURLReturnsNil() {
        let result = MarkdownWebView.accessScope(markdown: "![img](a.png)", fileURL: nil)
        #expect(result == nil)
    }

    @Test func noLocalPathsReturnsFileDirectory() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let md = "Just text, no links."
        let result = MarkdownWebView.accessScope(markdown: md, fileURL: fileURL)
        #expect(result?.path == "/Users/test/docs")
    }

    @Test func sameDirectoryImageReturnsFileDirectory() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let md = "![img](photo.png)"
        let result = MarkdownWebView.accessScope(markdown: md, fileURL: fileURL)
        #expect(result?.path == "/Users/test/docs")
    }

    @Test func parentDirectoryImageWidensScope() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/dev/report.md")
        let md = "![img](../diagrams/arch.svg)"
        let result = MarkdownWebView.accessScope(markdown: md, fileURL: fileURL)
        #expect(result?.path == "/Users/test/docs")
    }

    @Test func multipleParentReferencesWidenToCommonAncestor() {
        let fileURL = URL(fileURLWithPath: "/project/docs/dev/report.md")
        let md = """
        ![a](../diagrams/a.svg)
        [b](../../src/main.md)
        """
        let result = MarkdownWebView.accessScope(markdown: md, fileURL: fileURL)
        #expect(result?.path == "/project")
    }

    @Test func httpLinksDoNotAffectScope() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let md = "[link](https://example.com) ![img](photo.png)"
        let result = MarkdownWebView.accessScope(markdown: md, fileURL: fileURL)
        #expect(result?.path == "/Users/test/docs")
    }
}

// MARK: - classifyLink with accessScope

@Suite("Link Navigation - classifyLink with accessScope")
struct ClassifyLinkWithAccessScopeTests {

    @Test func siblingDirectoryAllowedWithWiderScope() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/dev/report.md")
        let targetURL = URL(fileURLWithPath: "/Users/test/docs/other/notes.md")
        let scope = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let result = MarkdownWebView.classifyLink(url: targetURL, fileURL: fileURL, accessScope: scope)
        #expect(result == .openMarkdownTab(targetURL.standardizedFileURL))
    }

    @Test func outsideScopeStillBlocked() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/dev/report.md")
        let targetURL = URL(fileURLWithPath: "/Users/test/secret.md")
        let scope = URL(fileURLWithPath: "/Users/test/docs", isDirectory: true)
        let result = MarkdownWebView.classifyLink(url: targetURL, fileURL: fileURL, accessScope: scope)
        #expect(result == .cancel)
    }

    @Test func defaultScopeFallsBackToFileDirectory() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let targetURL = URL(fileURLWithPath: "/Users/test/secret.md")
        let result = MarkdownWebView.classifyLink(url: targetURL, fileURL: fileURL)
        #expect(result == .cancel)
    }

    @Test func sameDirectoryStillWorksWithScope() {
        let fileURL = URL(fileURLWithPath: "/Users/test/docs/report.md")
        let targetURL = URL(fileURLWithPath: "/Users/test/docs/other.md")
        let scope = URL(fileURLWithPath: "/Users/test", isDirectory: true)
        let result = MarkdownWebView.classifyLink(url: targetURL, fileURL: fileURL, accessScope: scope)
        #expect(result == .openMarkdownTab(targetURL.standardizedFileURL))
    }
}
