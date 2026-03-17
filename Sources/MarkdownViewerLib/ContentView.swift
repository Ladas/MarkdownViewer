import SwiftUI
import AppKit

// MARK: - FocusedValue keys for menu commands

struct ToggleSearchKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct FindNextKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct FindPreviousKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct CopySourceKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct CopyRenderedKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct ZoomInKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct ZoomOutKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct ZoomResetKey: FocusedValueKey {
    typealias Value = () -> Void
}

public extension FocusedValues {
    var toggleSearch: (() -> Void)? {
        get { self[ToggleSearchKey.self] }
        set { self[ToggleSearchKey.self] = newValue }
    }
    var findNext: (() -> Void)? {
        get { self[FindNextKey.self] }
        set { self[FindNextKey.self] = newValue }
    }
    var findPrevious: (() -> Void)? {
        get { self[FindPreviousKey.self] }
        set { self[FindPreviousKey.self] = newValue }
    }
    var copySource: (() -> Void)? {
        get { self[CopySourceKey.self] }
        set { self[CopySourceKey.self] = newValue }
    }
    var copyRendered: (() -> Void)? {
        get { self[CopyRenderedKey.self] }
        set { self[CopyRenderedKey.self] = newValue }
    }
    var zoomIn: (() -> Void)? {
        get { self[ZoomInKey.self] }
        set { self[ZoomInKey.self] = newValue }
    }
    var zoomOut: (() -> Void)? {
        get { self[ZoomOutKey.self] }
        set { self[ZoomOutKey.self] = newValue }
    }
    var zoomReset: (() -> Void)? {
        get { self[ZoomResetKey.self] }
        set { self[ZoomResetKey.self] = newValue }
    }
}

// MARK: - ContentView

public struct ContentView: View {
    let document: MarkdownDocument
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var matchTotal = 0
    @State private var matchCurrent = 0
    @State private var navigationTrigger = 0
    @State private var navigationForward = true
    @State private var copyRenderedTrigger = 0
    @State private var zoomLevel: Double = 1.0
    @State private var showCopied = false
    @FocusState private var isSearchFocused: Bool

    public init(document: MarkdownDocument) {
        self.document = document
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showSearch {
                searchBar
                Divider()
            }
            MarkdownWebView(
                markdown: document.text,
                searchText: showSearch ? searchText : "",
                navigationTrigger: navigationTrigger,
                navigationForward: navigationForward,
                copyRenderedTrigger: copyRenderedTrigger,
                zoomLevel: zoomLevel,
                onSearchResult: { total, current in
                    matchTotal = total
                    matchCurrent = current
                },
                onCopyDone: { showCopiedToast() }
            )
        }
        .frame(minWidth: 600, minHeight: 400)
        .overlay(alignment: .topTrailing) {
            if showCopied {
                Text("Copied!")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .padding(12)
                    .transition(.opacity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: copySource) {
                    Image(systemName: "doc.on.doc")
                }
                .help("Copy Markdown Source (Cmd+Shift+C)")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: copyRendered) {
                    Image(systemName: "doc.richtext")
                }
                .help("Copy Rendered for Google Docs (Cmd+Option+C)")
            }
        }
        .focusedValue(\.toggleSearch, toggleSearch)
        .focusedValue(\.findNext, findNext)
        .focusedValue(\.findPrevious, findPrevious)
        .focusedValue(\.copySource, copySource)
        .focusedValue(\.copyRendered, copyRendered)
        .focusedValue(\.zoomIn, { zoomLevel = min(zoomLevel + 0.1, 3.0) })
        .focusedValue(\.zoomOut, { zoomLevel = max(zoomLevel - 0.1, 0.5) })
        .focusedValue(\.zoomReset, { zoomLevel = 1.0 })
        .onExitCommand {
            if showSearch { dismissSearch() }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit { findNext() }

            if !searchText.isEmpty {
                Text("\(matchCurrent) of \(matchTotal)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .fixedSize()
            }

            Button(action: findPrevious) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(matchTotal == 0)

            Button(action: findNext) {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .disabled(matchTotal == 0)

            Button(action: dismissSearch) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
        .onAppear { isSearchFocused = true }
    }

    private func toggleSearch() {
        showSearch.toggle()
        if showSearch {
            isSearchFocused = true
        } else {
            dismissSearch()
        }
    }

    private func dismissSearch() {
        showSearch = false
        searchText = ""
        matchTotal = 0
        matchCurrent = 0
    }

    private func findNext() {
        if !showSearch { showSearch = true; isSearchFocused = true; return }
        navigationForward = true
        navigationTrigger += 1
    }

    private func findPrevious() {
        if !showSearch { showSearch = true; isSearchFocused = true; return }
        navigationForward = false
        navigationTrigger += 1
    }

    private func copySource() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(document.text, forType: .string)
        showCopiedToast()
    }

    private func copyRendered() {
        copyRenderedTrigger += 1
    }

    private func showCopiedToast() {
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopied = false }
        }
    }
}
