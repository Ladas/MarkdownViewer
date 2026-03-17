import SwiftUI
import MarkdownViewerLib

@main
struct MarkdownViewerApp: App {
    @FocusedValue(\.toggleSearch) var toggleSearch
    @FocusedValue(\.findNext) var findNext
    @FocusedValue(\.findPrevious) var findPrevious
    @FocusedValue(\.copySource) var copySource
    @FocusedValue(\.copyRendered) var copyRendered
    @FocusedValue(\.zoomIn) var zoomIn
    @FocusedValue(\.zoomOut) var zoomOut
    @FocusedValue(\.zoomReset) var zoomReset
    @FocusedValue(\.toggleTOC) var toggleTOC
    @FocusedValue(\.toggleDiff) var toggleDiff
    @FocusedValue(\.setAppearance) var setAppearance

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { config in
            ContentView(document: config.document, fileURL: config.fileURL)
                .navigationSubtitle(config.fileURL?.path ?? "")
        }
        .commands {
            CommandGroup(replacing: .textEditing) {
                Button("Find...") {
                    toggleSearch?()
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find Next") {
                    findNext?()
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    findPrevious?()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()

                Button("Copy Markdown Source") {
                    copySource?()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Copy Rendered (for Google Docs)") {
                    copyRendered?()
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
            }

            CommandGroup(after: .toolbar) {
                Divider()

                Button("Zoom In") {
                    zoomIn?()
                }
                .keyboardShortcut("=", modifiers: .command)

                Button("Zoom Out") {
                    zoomOut?()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Actual Size") {
                    zoomReset?()
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()

                Button("Table of Contents") {
                    toggleTOC?()
                }
                .keyboardShortcut("t", modifiers: [.control, .command])

                Button("Git Diff") {
                    toggleDiff?()
                }
                .keyboardShortcut("d", modifiers: .command)

                Divider()

                Menu("Appearance") {
                    Button("System") {
                        setAppearance?("auto")
                    }
                    Button("Light") {
                        setAppearance?("light")
                    }
                    Button("Dark") {
                        setAppearance?("dark")
                    }
                }
            }
        }
    }
}
