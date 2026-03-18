import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - TOC Entry

public struct TOCEntry: Identifiable {
    public let id: Int
    public let level: Int
    public let title: String

    public static func parse(from markdown: String) -> [TOCEntry] {
        var entries = [TOCEntry]()
        var index = 0
        var inCodeBlock = false

        for line in markdown.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                inCodeBlock = !inCodeBlock
                continue
            }
            if inCodeBlock { continue }

            if let match = trimmed.range(of: "^#{1,6}\\s+", options: .regularExpression) {
                let level = trimmed[match].filter { $0 == "#" }.count
                var title = String(trimmed[match.upperBound...])
                // Remove trailing hashes
                if let trailing = title.range(of: "\\s+#+\\s*$", options: .regularExpression) {
                    title = String(title[..<trailing.lowerBound])
                }
                entries.append(TOCEntry(id: index, level: level, title: title))
                index += 1
            }
        }
        return entries
    }
}

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
struct ToggleTOCKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct ToggleDiffKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct ExportHTMLKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct AddNoteKey: FocusedValueKey {
    typealias Value = () -> Void
}
struct SetAppearanceKey: FocusedValueKey {
    typealias Value = (String) -> Void
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
    var toggleTOC: (() -> Void)? {
        get { self[ToggleTOCKey.self] }
        set { self[ToggleTOCKey.self] = newValue }
    }
    var toggleDiff: (() -> Void)? {
        get { self[ToggleDiffKey.self] }
        set { self[ToggleDiffKey.self] = newValue }
    }
    var exportHTML: (() -> Void)? {
        get { self[ExportHTMLKey.self] }
        set { self[ExportHTMLKey.self] = newValue }
    }
    var addNote: (() -> Void)? {
        get { self[AddNoteKey.self] }
        set { self[AddNoteKey.self] = newValue }
    }
    var setAppearance: ((String) -> Void)? {
        get { self[SetAppearanceKey.self] }
        set { self[SetAppearanceKey.self] = newValue }
    }
}

// MARK: - ContentView

public struct ContentView: View {
    let document: MarkdownDocument
    let fileURL: URL?

    @State private var currentText: String
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var matchTotal = 0
    @State private var matchCurrent = 0
    @State private var navigationTrigger = 0
    @State private var navigationForward = true
    @State private var copyRenderedTrigger = 0
    @State private var exportHTMLTrigger = 0
    @State private var zoomLevel: Double = 1.0
    @State private var showCopied = false
    @State private var showTOC = false
    @State private var showDiff = false
    @State private var diffRef = "HEAD"
    @State private var diffHTML: String?
    @State private var availableRefs: [String] = ["HEAD"]
    @State private var isGitRepo = false
    @State private var scrollToHeadingTrigger = 0
    @State private var scrollToHeadingIndex = -1
    @State private var fileWatcher: FileWatcher?
    @State private var appearanceMode = "auto"
    @State private var contentWidth: Double = 980
    @State private var showNoteEditor = false
    @State private var noteContent = ""
    @State private var editingNoteIndex: Int?
    @State private var insertAfterHeading: String?
    @State private var voiceInputEnabled = false
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isNoteFocused: Bool

    public init(document: MarkdownDocument, fileURL: URL? = nil) {
        self.document = document
        self.fileURL = fileURL
        self._currentText = State(initialValue: document.text)
    }

    private var tocEntries: [TOCEntry] {
        TOCEntry.parse(from: currentText)
    }

    public var body: some View {
        HStack(spacing: 0) {
            if showTOC {
                tocSidebar
                Divider()
            }
            VStack(spacing: 0) {
                actionBar
                Divider()
                if showSearch {
                    searchBar
                    Divider()
                }
                if showDiff {
                    diffToolbar
                    Divider()
                }
                MarkdownWebView(
                    markdown: currentText,
                    overrideHTML: showDiff ? diffHTML : nil,
                    searchText: showSearch ? searchText : "",
                    navigationTrigger: navigationTrigger,
                    navigationForward: navigationForward,
                    copyRenderedTrigger: copyRenderedTrigger,
                    exportHTMLTrigger: exportHTMLTrigger,
                    zoomLevel: zoomLevel,
                    scrollToHeadingTrigger: scrollToHeadingTrigger,
                    scrollToHeadingIndex: scrollToHeadingIndex,
                    appearanceMode: appearanceMode,
                    contentWidth: contentWidth,
                    onSearchResult: { total, current in
                        matchTotal = total
                        matchCurrent = current
                    },
                    onCopyDone: { showCopiedToast() },
                    onExportHTML: { html in saveHTMLFile(html) },
                    onEditNote: { index, content in openNoteEditor(index: index, content: content) },
                    onAddNoteAtHeading: { heading in openNoteEditor(afterHeading: heading) }
                )
            }
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
        .focusedValue(\.toggleSearch, toggleSearch)
        .focusedValue(\.findNext, findNext)
        .focusedValue(\.findPrevious, findPrevious)
        .focusedValue(\.copySource, copySource)
        .focusedValue(\.copyRendered, copyRendered)
        .focusedValue(\.exportHTML, exportHTML)
        .focusedValue(\.addNote, { openNoteEditor() })
        .focusedValue(\.zoomIn, { zoomLevel = min(zoomLevel + 0.1, 3.0) })
        .focusedValue(\.zoomOut, { zoomLevel = max(zoomLevel - 0.1, 0.5) })
        .focusedValue(\.zoomReset, { zoomLevel = 1.0 })
        .focusedValue(\.toggleTOC, { showTOC.toggle() })
        .focusedValue(\.toggleDiff, toggleDiff)
        .focusedValue(\.setAppearance, { mode in appearanceMode = mode })
        .onExitCommand {
            if showSearch { dismissSearch() }
        }
        .onAppear {
            startFileWatcher()
            checkGitRepo()
        }
        .onDisappear {
            fileWatcher?.stop()
            fileWatcher = nil
        }
        .onChange(of: currentText) { _ in
            if showDiff { updateDiff() }
        }
        .sheet(isPresented: $showNoteEditor) {
            noteEditorSheet
        }
    }

    // MARK: - Note Editor Sheet

    private var noteEditorSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(editingNoteIndex != nil ? "Edit Review Note" : "New Review Note")
                    .font(.headline)
                Spacer()
                if voiceInputEnabled {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text("Voice input enabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let heading = insertAfterHeading, !heading.isEmpty {
                Text("After: \(heading)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $noteContent)
                .font(.body)
                .frame(minHeight: 120)
                .focused($isNoteFocused)

            Text("Tip: Press Fn twice or the microphone key to start voice dictation")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack {
                Button("Cancel") {
                    showNoteEditor = false
                    noteContent = ""
                    editingNoteIndex = nil
                    insertAfterHeading = nil
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Delete Note") {
                    deleteNote()
                }
                .foregroundStyle(.red)
                .opacity(editingNoteIndex != nil ? 1 : 0)
                .disabled(editingNoteIndex == nil)

                Button("Save") {
                    saveNote()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 250)
        .onAppear {
            isNoteFocused = true
        }
    }

    // MARK: - TOC Sidebar

    private var tocSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Contents")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(tocEntries) { entry in
                        Button(action: { scrollToHeading(entry.id) }) {
                            Text(entry.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, CGFloat(entry.level - 1) * 12)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .frame(width: 220)
        .background(.background)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 4) {
            actionButton("Contents", icon: "list.bullet.indent", active: showTOC) {
                showTOC.toggle()
            }
            if isGitRepo {
                actionButton("Git Diff", icon: "arrow.left.arrow.right", active: showDiff) {
                    toggleDiff()
                }
            }

            actionButton("Add Note", icon: "plus.bubble") {
                openNoteEditor()
            }
            actionButton("Voice", icon: voiceInputEnabled ? "mic.fill" : "mic", active: voiceInputEnabled) {
                voiceInputEnabled.toggle()
            }

            Spacer()

            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Slider(value: $contentWidth, in: 400...2400, step: 20)
                .frame(width: 80)
                .controlSize(.mini)
                .help("Content width: \(Int(contentWidth))px")
            Text("\(Int(contentWidth))")
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            actionButton("Copy MD", icon: "doc.on.doc") {
                copySource()
            }
            actionButton("Copy HTML", icon: "doc.richtext") {
                copyRendered()
            }
            actionButton("Export HTML", icon: "square.and.arrow.up") {
                exportHTML()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private func actionButton(_ title: String, icon: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 11))
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(active ? .accentColor : nil)
    }

    // MARK: - Search Bar

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

    // MARK: - Diff Toolbar

    private var diffToolbar: some View {
        HStack(spacing: 8) {
            Text("Diff against:")
                .foregroundStyle(.secondary)
                .font(.system(size: 12))

            Picker("", selection: $diffRef) {
                ForEach(availableRefs, id: \.self) { ref in
                    Text(ref).tag(ref)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            .onChange(of: diffRef) { _ in
                updateDiff()
            }

            Spacer()

            if diffHTML == nil {
                Text("No changes")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                    .italic()
            }

            Button(action: { showDiff = false; diffHTML = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Actions

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
        NSPasteboard.general.setString(currentText, forType: .string)
        showCopiedToast()
    }

    private func copyRendered() {
        copyRenderedTrigger += 1
    }

    private func exportHTML() {
        exportHTMLTrigger += 1
    }

    private func saveHTMLFile(_ html: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.canCreateDirectories = true
        if let url = fileURL {
            panel.directoryURL = url.deletingLastPathComponent()
            panel.nameFieldStringValue = url.deletingPathExtension().lastPathComponent + ".html"
        } else {
            panel.nameFieldStringValue = "export.html"
        }
        panel.begin { response in
            guard response == .OK, let saveURL = panel.url else { return }
            do {
                try html.write(to: saveURL, atomically: true, encoding: .utf8)
                showCopiedToast()
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    private func showCopiedToast() {
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopied = false }
        }
    }

    private func scrollToHeading(_ index: Int) {
        scrollToHeadingIndex = index
        scrollToHeadingTrigger += 1
    }

    private func toggleDiff() {
        showDiff.toggle()
        if showDiff {
            updateDiff()
        } else {
            diffHTML = nil
        }
    }

    private func updateDiff() {
        guard let url = fileURL else { diffHTML = nil; return }
        let diff = GitHelper.diff(for: url, against: diffRef)
        if let d = diff, !d.isEmpty {
            diffHTML = GitHelper.diffToHTML(d)
        } else {
            diffHTML = nil
        }
    }

    // MARK: - Review Notes

    private func openNoteEditor(index: Int? = nil, content: String = "", afterHeading: String? = nil) {
        editingNoteIndex = index
        noteContent = content
        insertAfterHeading = afterHeading
        showNoteEditor = true
    }

    private func saveNote() {
        guard let url = fileURL else { return }
        let trimmed = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var content = currentText
        let noteBlock = "\n\n```review\n\(trimmed)\n```\n"

        if let index = editingNoteIndex {
            content = replaceReviewBlock(at: index, with: trimmed, in: content)
        } else if let heading = insertAfterHeading, !heading.isEmpty {
            content = insertAfterHeadingText(heading, note: noteBlock, in: content)
        } else {
            content += noteBlock
        }

        try? content.write(to: url, atomically: true, encoding: .utf8)

        showNoteEditor = false
        noteContent = ""
        editingNoteIndex = nil
        insertAfterHeading = nil
    }

    private func deleteNote() {
        guard let url = fileURL, let index = editingNoteIndex else { return }
        let content = replaceReviewBlock(at: index, with: nil, in: currentText)
        try? content.write(to: url, atomically: true, encoding: .utf8)

        showNoteEditor = false
        noteContent = ""
        editingNoteIndex = nil
        insertAfterHeading = nil
    }

    private func replaceReviewBlock(at index: Int, with newContent: String?, in text: String) -> String {
        let pattern = "```review\\n[\\s\\S]*?\\n```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard index < matches.count else { return text }

        let match = matches[index]
        var result = text
        let range = Range(match.range, in: text)!
        if let newContent = newContent {
            result.replaceSubrange(range, with: "```review\n\(newContent)\n```")
        } else {
            // Delete: also remove surrounding blank lines
            let start = text.index(range.lowerBound, offsetBy: 0)
            var end = range.upperBound
            // Consume trailing newlines
            while end < text.endIndex && text[end] == "\n" {
                end = text.index(after: end)
            }
            // Consume leading newlines
            var actualStart = start
            if actualStart > text.startIndex {
                let before = text.index(before: actualStart)
                if text[before] == "\n" {
                    actualStart = before
                    if actualStart > text.startIndex {
                        let before2 = text.index(before: actualStart)
                        if text[before2] == "\n" {
                            actualStart = before2
                        }
                    }
                }
            }
            result.replaceSubrange(actualStart..<end, with: "")
        }
        return result
    }

    private func insertAfterHeadingText(_ headingText: String, note: String, in text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var insertIndex = lines.count
        var inCodeBlock = false

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { inCodeBlock = !inCodeBlock; continue }
            if inCodeBlock { continue }

            if let match = trimmed.range(of: "^#{1,6}\\s+", options: .regularExpression) {
                var title = String(trimmed[match.upperBound...])
                if let trailing = title.range(of: "\\s+#+\\s*$", options: .regularExpression) {
                    title = String(title[..<trailing.lowerBound])
                }
                if title == headingText {
                    // Find the end of this section (next heading or end)
                    for j in (i + 1)..<lines.count {
                        let nextTrimmed = lines[j].trimmingCharacters(in: .whitespaces)
                        if nextTrimmed.range(of: "^#{1,6}\\s+", options: .regularExpression) != nil {
                            insertIndex = j
                            break
                        }
                    }
                    if insertIndex == lines.count { insertIndex = lines.count }
                    break
                }
            }
        }

        var result = lines
        result.insert(contentsOf: note.components(separatedBy: "\n"), at: insertIndex)
        return result.joined(separator: "\n")
    }

    // MARK: - File Watcher

    private func startFileWatcher() {
        guard let url = fileURL else { return }
        fileWatcher = FileWatcher(url: url) { newText in
            currentText = newText
        }
    }

    // MARK: - Git

    private func checkGitRepo() {
        guard let url = fileURL else { return }
        isGitRepo = GitHelper.isGitRepo(at: url)
        if isGitRepo {
            availableRefs = GitHelper.availableRefs(for: url)
        }
    }
}
