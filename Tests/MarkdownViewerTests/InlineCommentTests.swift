import Testing
import Foundation
@testable import MarkdownViewerLib

@Suite("InlineComment - Model")
struct InlineCommentModelTests {

    @Test func initSetsFields() {
        let comment = InlineComment(referenceText: "selected text", comment: "my note")
        #expect(comment.referenceText == "selected text")
        #expect(comment.comment == "my note")
        #expect(comment.id != UUID())
    }

    @Test func timestampIsRecent() {
        let before = Date()
        let comment = InlineComment(referenceText: "", comment: "test")
        let after = Date()
        #expect(comment.timestamp >= before)
        #expect(comment.timestamp <= after)
    }

    @Test func encodeDecode() throws {
        let comment = InlineComment(referenceText: "ref", comment: "note")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(comment)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(InlineComment.self, from: data)

        #expect(decoded.id == comment.id)
        #expect(decoded.referenceText == "ref")
        #expect(decoded.comment == "note")
    }
}

@Suite("InlineCommentStore")
struct InlineCommentStoreTests {

    private func tempFileURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("test-\(UUID().uuidString).md")
    }

    private func sidecarURL(for fileURL: URL) -> URL {
        let dir = fileURL.deletingLastPathComponent()
        return dir.appendingPathComponent(".\(fileURL.lastPathComponent).comments.json")
    }

    @Test func loadEmptyReturnsEmpty() {
        let url = tempFileURL()
        let store = InlineCommentStore(fileURL: url)
        #expect(store.load().isEmpty)
    }

    @Test func appendAndLoad() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        let comment = InlineComment(referenceText: "hello world", comment: "fix this")
        store.append(comment)

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].referenceText == "hello world")
        #expect(loaded[0].comment == "fix this")
    }

    @Test func appendMultiple() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        store.append(InlineComment(referenceText: "a", comment: "note 1"))
        store.append(InlineComment(referenceText: "b", comment: "note 2"))

        let loaded = store.load()
        #expect(loaded.count == 2)
        #expect(loaded[0].comment == "note 1")
        #expect(loaded[1].comment == "note 2")
    }

    @Test func deleteById() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        let c1 = InlineComment(referenceText: "a", comment: "keep")
        let c2 = InlineComment(referenceText: "b", comment: "delete")
        store.append(c1)
        store.append(c2)

        store.delete(id: c2.id)

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].comment == "keep")
    }

    @Test func updateById() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        let comment = InlineComment(referenceText: "ref", comment: "old")
        store.append(comment)

        store.update(id: comment.id, newComment: "new")

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].comment == "new")
        #expect(loaded[0].referenceText == "ref")
    }

    @Test func deleteNonexistentIdIsNoop() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        store.append(InlineComment(referenceText: "a", comment: "keep"))

        store.delete(id: UUID())

        #expect(store.load().count == 1)
    }

    @Test func saveOverwrites() {
        let url = tempFileURL()
        let sidecar = sidecarURL(for: url)
        defer { try? FileManager.default.removeItem(at: sidecar) }

        let store = InlineCommentStore(fileURL: url)
        store.append(InlineComment(referenceText: "a", comment: "one"))
        store.append(InlineComment(referenceText: "b", comment: "two"))

        store.save([InlineComment(referenceText: "c", comment: "only")])

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].comment == "only")
    }

    @Test func sidecarFilename() {
        let url = URL(fileURLWithPath: "/tmp/myfile.md")
        let sidecar = sidecarURL(for: url)
        #expect(sidecar.lastPathComponent == ".myfile.md.comments.json")
    }
}
