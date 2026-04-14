import AppKit
import WebKit

/// Exports SVGs to PNG (via resvg) or animated GIF (via hidden WKWebView snapshots)
public final class SVGExporter: NSObject, WKNavigationDelegate {

    public enum ExportResult {
        case png(Data)
        case gif(Data)
        case error(String)
    }

    private var webView: WKWebView?
    private var completion: ((ExportResult) -> Void)?
    private var frameCount: Int = 12
    private var fps: Double = 6
    private var capturedFrames: [CGImage] = []
    private var svgSize: CGSize = .zero

    /// Export SVG to the best available format
    /// - Static SVGs: uses resvg (high quality) with canvas fallback
    /// - Animated SVGs: uses hidden WKWebView frame capture → GIF
    private static let maxDimension = 4096

    public func export(svgString: String, animated: Bool, width: Int = 600, completion: @escaping (ExportResult) -> Void) {
        let cappedWidth = min(width, Self.maxDimension)
        self.completion = completion

        if !animated {
            // Static: resvg
            if ResvgRenderer.isAvailable {
                if let data = ResvgRenderer.renderToPNG(svgString: svgString, width: cappedWidth) {
                    completion(.png(data))
                    self.completion = nil
                    return
                }
            }
            completion(.error("resvg not installed. Run: brew install resvg"))
            self.completion = nil
            return
        } else {
            // Animated: capture frames via hidden WKWebView
            captureAnimatedFrames(svgString: svgString, width: cappedWidth)
        }
    }

    // MARK: - Animated capture (multiple frames via hidden WKWebView)

    private func captureAnimatedFrames(svgString: String, width: Int) {
        let html = wrapSVGInHTML(svgString)
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: 400), configuration: config)
        wv.navigationDelegate = self
        self.webView = wv
        self.svgSize = CGSize(width: width, height: 400)
        self.capturedFrames = []
        wv.loadHTMLString(html, baseURL: URL(string: "about:blank"))
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Get actual SVG dimensions from the rendered page
        webView.evaluateJavaScript("var svg = document.querySelector('svg'); svg ? JSON.stringify({w: svg.getBoundingClientRect().width, h: svg.getBoundingClientRect().height}) : '{}'") { [weak self] result, _ in
            guard let self = self else { return }
            if let json = result as? String, let data = json.data(using: .utf8),
               let dims = try? JSONSerialization.jsonObject(with: data) as? [String: Double],
               let w = dims["w"], let h = dims["h"], w > 0, h > 0 {
                self.svgSize = CGSize(width: w, height: h)
                webView.frame = NSRect(x: 0, y: 0, width: Int(w), height: Int(h))
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.captureFrame(index: 0)
            }
        }
    }

    private func captureFrame(index: Int) {
        guard let wv = webView else { return }
        if index >= frameCount {
            encodeGIF()
            return
        }

        let config = WKSnapshotConfiguration()
        config.rect = CGRect(origin: .zero, size: svgSize)

        wv.takeSnapshot(with: config) { [weak self] image, error in
            guard let self = self else { return }
            guard let image = image,
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                // Skip failed frame
                DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / self.fps)) {
                    self.captureFrame(index: index + 1)
                }
                return
            }

            self.capturedFrames.append(cgImage)

            DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / self.fps)) {
                self.captureFrame(index: index + 1)
            }
        }
    }

    private func encodeGIF() {
        guard !capturedFrames.isEmpty else {
            completion?(.error("No frames captured"))
            cleanup()
            return
        }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, "com.compuserve.gif" as CFString, capturedFrames.count, nil) else {
            completion?(.error("GIF destination failed"))
            cleanup()
            return
        }

        let gifProps: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(dest, gifProps as CFDictionary)

        let delay = 1.0 / fps
        for frame in capturedFrames {
            let frameProps: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: delay
                ]
            ]
            CGImageDestinationAddImage(dest, frame, frameProps as CFDictionary)
        }

        CGImageDestinationFinalize(dest)
        completion?(.gif(data as Data))
        cleanup()
    }

    private func cleanup() {
        webView?.navigationDelegate = nil
        webView = nil
        capturedFrames = []
    }

    private func wrapSVGInHTML(_ svg: String) -> String {
        // Sanitize: strip script tags and event handlers from SVG
        let sanitized = svg
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "\\son\\w+\\s*=\\s*\"[^\"]*\"", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "\\son\\w+\\s*=\\s*'[^']*'", with: "", options: [.regularExpression, .caseInsensitive])
        return """
        <!DOCTYPE html>
        <html><head>
        <meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data:;">
        <style>body{margin:0;padding:0;background:#fff;overflow:hidden}svg{display:block}</style>
        </head><body>\(sanitized)</body></html>
        """
    }
}
