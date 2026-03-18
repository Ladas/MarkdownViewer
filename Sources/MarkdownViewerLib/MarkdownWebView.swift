import SwiftUI
import WebKit
import AppKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    var overrideHTML: String?
    var searchText: String = ""
    var navigationTrigger: Int = 0
    var navigationForward: Bool = true
    var copyRenderedTrigger: Int = 0
    var exportHTMLTrigger: Int = 0
    var zoomLevel: Double = 1.0
    var scrollToHeadingTrigger: Int = 0
    var scrollToHeadingIndex: Int = -1
    var appearanceMode: String = "auto"
    var contentWidth: Double = 980
    var onSearchResult: ((Int, Int) -> Void)?
    var onCopyDone: (() -> Void)?
    var onExportHTML: ((String) -> Void)?
    var onEditNote: ((Int, String) -> Void)?
    var onAddNoteAtHeading: ((String) -> Void)?
    var onExplainWithClaude: ((String) -> Void)?
    var onAskClaude: ((String) -> Void)?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "copyImage")
        config.userContentController.add(context.coordinator, name: "copyRendered")
        config.userContentController.add(context.coordinator, name: "exportHTML")
        config.userContentController.add(context.coordinator, name: "editNote")
        config.userContentController.add(context.coordinator, name: "addNoteAtHeading")
        let webView = MarkdownWKWebView(frame: .zero, configuration: config)
        webView.coordinator = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = true
        context.coordinator.lastMarkdown = markdown
        context.coordinator.lastOverrideHTML = overrideHTML

        let html = overrideHTML ?? HTMLRenderer.render(markdown: markdown)
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coord = context.coordinator
        coord.onSearchResult = onSearchResult
        coord.onCopyDone = onCopyDone
        coord.onExportHTML = onExportHTML
        coord.onEditNote = onEditNote
        coord.onAddNoteAtHeading = onAddNoteAtHeading
        coord.onExplainWithClaude = onExplainWithClaude
        coord.onAskClaude = onAskClaude

        let contentChanged = coord.lastMarkdown != markdown || coord.lastOverrideHTML != overrideHTML
        if contentChanged {
            coord.lastMarkdown = markdown
            coord.lastOverrideHTML = overrideHTML
            coord.lastSearchText = nil
            coord.pageLoaded = false
            let htmlToLoad = overrideHTML ?? HTMLRenderer.render(markdown: markdown)
            // Save scroll position before reload, restore in didFinish
            webView.evaluateJavaScript("window.scrollY") { result, _ in
                coord.savedScrollY = result as? Double ?? 0
                webView.loadHTMLString(htmlToLoad, baseURL: nil)
            }
            return
        }

        let searchChanged = coord.lastSearchText != searchText
        let navChanged = coord.lastNavTrigger != navigationTrigger
        let copyChanged = coord.lastCopyRenderedTrigger != copyRenderedTrigger
        let scrollChanged = coord.lastScrollTrigger != scrollToHeadingTrigger

        if searchChanged {
            coord.lastSearchText = searchText
            coord.lastNavTrigger = navigationTrigger
            coord.performSearch(searchText, in: webView)
        } else if navChanged {
            coord.lastNavTrigger = navigationTrigger
            coord.navigateSearch(navigationForward ? "next" : "prev", in: webView)
        }

        if coord.lastZoomLevel != zoomLevel {
            coord.lastZoomLevel = zoomLevel
            webView.pageZoom = zoomLevel
        }

        if copyChanged {
            coord.lastCopyRenderedTrigger = copyRenderedTrigger
            guard coord.pageLoaded else { return }
            webView.evaluateJavaScript("copyRenderedContent()") { _, _ in }
        }

        let exportChanged = coord.lastExportHTMLTrigger != exportHTMLTrigger
        if exportChanged {
            coord.lastExportHTMLTrigger = exportHTMLTrigger
            guard coord.pageLoaded else { return }
            webView.evaluateJavaScript("exportHTMLContent()") { _, _ in }
        }

        if scrollChanged {
            coord.lastScrollTrigger = scrollToHeadingTrigger
            if scrollToHeadingIndex >= 0 && coord.pageLoaded {
                webView.evaluateJavaScript("scrollToHeading(\(scrollToHeadingIndex))") { _, _ in }
            }
        }

        if coord.lastAppearanceMode != appearanceMode {
            coord.lastAppearanceMode = appearanceMode
            if coord.pageLoaded {
                let escaped = appearanceMode.replacingOccurrences(of: "'", with: "\\'")
                webView.evaluateJavaScript("setAppearance('\(escaped)')") { _, _ in }
            }
        }

        if coord.lastContentWidth != contentWidth {
            coord.lastContentWidth = contentWidth
            if coord.pageLoaded {
                webView.evaluateJavaScript("setContentWidth(\(Int(contentWidth)))") { _, _ in }
            }
        }
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        let controller = webView.configuration.userContentController
        for name in ["copyImage", "copyRendered", "exportHTML", "editNote", "addNoteAtHeading"] {
            controller.removeScriptMessageHandler(forName: name)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private static let allowedSchemes: Set<String> = ["http", "https", "mailto"]

        var lastMarkdown: String?
        var lastOverrideHTML: String?
        var lastSearchText: String?
        var lastNavTrigger: Int = 0
        var lastCopyRenderedTrigger: Int = 0
        var lastExportHTMLTrigger: Int = 0
        var lastScrollTrigger: Int = 0
        var lastZoomLevel: Double = 1.0
        var lastAppearanceMode: String = "auto"
        var lastContentWidth: Double = 980
        var pageLoaded = false
        var savedScrollY: Double = 0
        var pendingSearch: String?
        var onSearchResult: ((Int, Int) -> Void)?
        var onCopyDone: (() -> Void)?
        var onExportHTML: ((String) -> Void)?
        var onEditNote: ((Int, String) -> Void)?
        var onAddNoteAtHeading: ((String) -> Void)?
        var onExplainWithClaude: ((String) -> Void)?
        var onAskClaude: ((String) -> Void)?

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "copyImage" {
                handleCopyImage(message)
            } else if message.name == "copyRendered" {
                handleCopyRendered(message)
            } else if message.name == "exportHTML" {
                handleExportHTML(message)
            } else if message.name == "editNote" {
                if let dict = message.body as? [String: Any],
                   let index = dict["index"] as? Int,
                   let content = dict["content"] as? String {
                    onEditNote?(index, content)
                }
            } else if message.name == "addNoteAtHeading" {
                if let dict = message.body as? [String: Any],
                   let heading = dict["heading"] as? String {
                    onAddNoteAtHeading?(heading)
                }
            }
        }

        private func handleCopyImage(_ message: WKScriptMessage) {
            guard let dataUrl = message.body as? String,
                  let commaIndex = dataUrl.firstIndex(of: ",") else { return }

            let base64 = String(dataUrl[dataUrl.index(after: commaIndex)...])
            guard let imageData = Data(base64Encoded: base64),
                  let image = NSImage(data: imageData) else { return }

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
            onCopyDone?()
        }

        private func handleCopyRendered(_ message: WKScriptMessage) {
            guard let html = message.body as? String else { return }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            // .html for rich paste (Google Docs), .string for plain text paste
            pasteboard.setString(html, forType: .html)
            pasteboard.setString(html, forType: .string)
            onCopyDone?()
        }

        private func handleExportHTML(_ message: WKScriptMessage) {
            guard let html = message.body as? String else { return }
            onExportHTML?(html)
        }

        // MARK: - Search

        func performSearch(_ query: String, in webView: WKWebView) {
            if !pageLoaded {
                pendingSearch = query
                return
            }

            if query.isEmpty {
                webView.evaluateJavaScript("clearSearch()") { [weak self] _, _ in
                    self?.onSearchResult?(0, 0)
                }
                return
            }

            guard let jsonData = try? JSONEncoder().encode(query),
                  let jsonString = String(data: jsonData, encoding: .utf8) else { return }

            webView.evaluateJavaScript("performSearch(\(jsonString))") { [weak self] result, _ in
                self?.handleSearchResult(result)
            }
        }

        func navigateSearch(_ direction: String, in webView: WKWebView) {
            guard pageLoaded else { return }
            webView.evaluateJavaScript("navigateSearch('\(direction)')") { [weak self] result, _ in
                self?.handleSearchResult(result)
            }
        }

        private func handleSearchResult(_ result: Any?) {
            if let dict = result as? [String: Any],
               let total = dict["total"] as? Int,
               let current = dict["current"] as? Int {
                onSearchResult?(total, current)
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pageLoaded = true
            if savedScrollY > 0 {
                let y = savedScrollY
                savedScrollY = 0
                webView.evaluateJavaScript("window.scrollTo(0, \(y))") { _, _ in }
            }
            if let search = pendingSearch {
                pendingSearch = nil
                performSearch(search, in: webView)
            }
            if lastAppearanceMode != "auto" {
                let escaped = lastAppearanceMode.replacingOccurrences(of: "'", with: "\\'")
                webView.evaluateJavaScript("setAppearance('\(escaped)')") { _, _ in }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                if let scheme = url.scheme?.lowercased(),
                   Self.allowedSchemes.contains(scheme) {
                    NSWorkspace.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - WKWebView subclass for context menu

class MarkdownWKWebView: WKWebView {
    weak var coordinator: MarkdownWebView.Coordinator?

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        menu.addItem(NSMenuItem.separator())

        let claudeMenu = NSMenu(title: "Claude")

        let explainItem = NSMenuItem(
            title: "Explain",
            action: #selector(explainWithClaude(_:)),
            keyEquivalent: ""
        )
        explainItem.target = self
        claudeMenu.addItem(explainItem)

        let askItem = NSMenuItem(
            title: "Ask...",
            action: #selector(askClaude(_:)),
            keyEquivalent: ""
        )
        askItem.target = self
        claudeMenu.addItem(askItem)

        let claudeItem = NSMenuItem(title: "Claude", action: nil, keyEquivalent: "")
        claudeItem.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "Claude")
        claudeItem.submenu = claudeMenu
        menu.addItem(claudeItem)

        super.willOpenMenu(menu, with: event)
    }

    @objc private func explainWithClaude(_ sender: Any?) {
        evaluateJavaScript("window.getSelection().toString()") { [weak self] result, _ in
            guard let text = result as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            self?.coordinator?.onExplainWithClaude?(text)
        }
    }

    @objc private func askClaude(_ sender: Any?) {
        evaluateJavaScript("window.getSelection().toString()") { [weak self] result, _ in
            guard let text = result as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            self?.coordinator?.onAskClaude?(text)
        }
    }
}
