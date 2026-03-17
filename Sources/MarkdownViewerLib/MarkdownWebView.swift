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
    var zoomLevel: Double = 1.0
    var scrollToHeadingTrigger: Int = 0
    var scrollToHeadingIndex: Int = -1
    var appearanceMode: String = "auto"
    var onSearchResult: ((Int, Int) -> Void)?
    var onCopyDone: (() -> Void)?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "copyImage")
        config.userContentController.add(context.coordinator, name: "copyRendered")
        let webView = WKWebView(frame: .zero, configuration: config)
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

        let contentChanged = coord.lastMarkdown != markdown || coord.lastOverrideHTML != overrideHTML
        if contentChanged {
            coord.lastMarkdown = markdown
            coord.lastOverrideHTML = overrideHTML
            coord.lastSearchText = nil
            coord.pageLoaded = false
            let html = overrideHTML ?? HTMLRenderer.render(markdown: markdown)
            webView.loadHTMLString(html, baseURL: nil)
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

        webView.pageZoom = zoomLevel

        if copyChanged {
            coord.lastCopyRenderedTrigger = copyRenderedTrigger
            guard coord.pageLoaded else { return }
            webView.evaluateJavaScript("copyRenderedContent()") { _, _ in }
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
        var lastScrollTrigger: Int = 0
        var lastAppearanceMode: String = "auto"
        var pageLoaded = false
        var pendingSearch: String?
        var pendingAppearance: String?
        var onSearchResult: ((Int, Int) -> Void)?
        var onCopyDone: (() -> Void)?

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "copyImage" {
                handleCopyImage(message)
            } else if message.name == "copyRendered" {
                handleCopyRendered(message)
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
            pasteboard.setString(html, forType: .html)
            onCopyDone?()
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
            if let search = pendingSearch {
                pendingSearch = nil
                performSearch(search, in: webView)
            }
            if let appearance = pendingAppearance {
                pendingAppearance = nil
                let escaped = appearance.replacingOccurrences(of: "'", with: "\\'")
                webView.evaluateJavaScript("setAppearance('\(escaped)')") { _, _ in }
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
