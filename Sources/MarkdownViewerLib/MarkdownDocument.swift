import SwiftUI
import UniformTypeIdentifiers

public extension UTType {
    static let markdown = UTType(importedAs: "net.daringfireball.markdown")
}

public struct MarkdownDocument: FileDocument {
    public static var readableContentTypes: [UTType] = [.markdown, .plainText]

    public var text: String

    public init(text: String = "") {
        self.text = text
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }
}
