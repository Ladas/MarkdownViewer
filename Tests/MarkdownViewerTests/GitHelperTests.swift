import Testing
import Foundation
@testable import MarkdownViewerLib

@Suite("GitHelper - Diff HTML Rendering")
struct DiffHTMLTests {

    @Test func addedLine() {
        let html = GitHelper.diffToHTML("+added line")
        #expect(html.contains("diff-add"))
        #expect(html.contains("+added line"))
    }

    @Test func removedLine() {
        let html = GitHelper.diffToHTML("-removed line")
        #expect(html.contains("diff-del"))
        #expect(html.contains("-removed line"))
    }

    @Test func contextLine() {
        let html = GitHelper.diffToHTML(" context line")
        // The div for a context line should not have diff-add or diff-del class
        #expect(html.contains("<div class=\"diff-line \"> context line</div>"))
    }

    @Test func hunkHeader() {
        let html = GitHelper.diffToHTML("@@ -1,3 +1,4 @@")
        #expect(html.contains("diff-hunk"))
    }

    @Test func diffHeader() {
        let html = GitHelper.diffToHTML("diff --git a/file b/file")
        #expect(html.contains("diff-header"))
    }

    @Test func fileHeaders() {
        let html = GitHelper.diffToHTML("--- a/file\n+++ b/file")
        #expect(html.contains("diff-header"))
    }

    @Test func htmlEscaping() {
        let html = GitHelper.diffToHTML("+<script>alert('xss')</script>")
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>alert"))
    }

    @Test func ampersandEscaping() {
        let html = GitHelper.diffToHTML("+a & b")
        #expect(html.contains("a &amp; b"))
    }

    @Test func emptyDiff() {
        let html = GitHelper.diffToHTML("")
        #expect(html.contains("<body>"))
        #expect(html.contains("</body>"))
    }

    @Test func multipleLines() {
        let diff = """
        diff --git a/f b/f
        --- a/f
        +++ b/f
        @@ -1,2 +1,3 @@
         unchanged
        -old
        +new
        +added
        """
        let html = GitHelper.diffToHTML(diff)
        #expect(html.contains("diff-header"))
        #expect(html.contains("diff-hunk"))
        #expect(html.contains("diff-del"))
        #expect(html.contains("diff-add"))
    }

    @Test func indexLine() {
        let html = GitHelper.diffToHTML("index abc1234..def5678 100644")
        #expect(html.contains("diff-header"))
    }

    @Test func producesValidHTML() {
        let html = GitHelper.diffToHTML("+line")
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("</html>"))
    }

    @Test func greaterThanEscaping() {
        let html = GitHelper.diffToHTML("+if a > b")
        #expect(html.contains("a &gt; b"))
    }
}

@Suite("GitHelper - Git Operations")
struct GitOperationTests {

    @Test func isGitRepoInRepo() {
        // This test file is inside the MarkdownViewer git repo
        let url = URL(fileURLWithPath: #filePath)
        #expect(GitHelper.isGitRepo(at: url))
    }

    @Test func isGitRepoOutsideRepo() {
        let url = URL(fileURLWithPath: "/tmp/not-a-repo-file.txt")
        #expect(!GitHelper.isGitRepo(at: url))
    }

    @Test func availableRefsInRepo() {
        let url = URL(fileURLWithPath: #filePath)
        let refs = GitHelper.availableRefs(for: url)
        #expect(refs.contains("HEAD"))
    }

    @Test func diffReturnsNilOutsideRepo() {
        let url = URL(fileURLWithPath: "/tmp/not-a-repo-file.txt")
        #expect(GitHelper.diff(for: url) == nil)
    }
}
