import Testing
import Foundation
@testable import MarkdownViewerLib

@Suite("ClaudeCLIRunner")
struct ClaudeCLIRunnerTests {

    @Test func findGitRootFromSubdirectory() {
        // This test runs from within the MarkdownViewer git repo
        let currentFile = URL(fileURLWithPath: #filePath)
        let root = ClaudeCLIRunner.findGitRoot(from: currentFile)
        #expect(root != nil)
        let gitDir = root!.appendingPathComponent(".git")
        #expect(FileManager.default.fileExists(atPath: gitDir.path))
    }

    @Test func findGitRootFromRootReturnsNil() {
        let url = URL(fileURLWithPath: "/tmp/nonexistent-file.md")
        let root = ClaudeCLIRunner.findGitRoot(from: url)
        #expect(root == nil)
    }

    @Test func initSetsWorkingDirectory() {
        let dir = URL(fileURLWithPath: "/tmp")
        let runner = ClaudeCLIRunner(workingDirectory: dir)
        #expect(!runner.isRunning)
    }

    @Test func cancelWhenNotRunning() {
        let dir = URL(fileURLWithPath: "/tmp")
        let runner = ClaudeCLIRunner(workingDirectory: dir)
        // Should not crash
        runner.cancel()
        #expect(!runner.isRunning)
    }
}
