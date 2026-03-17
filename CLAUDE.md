# CLAUDE.md - MarkdownViewer

## Project Overview

Native macOS Markdown viewer with Mermaid diagram support. SwiftUI app using WKWebView for rendering with bundled JavaScript libraries. Read-only, no network access at runtime.

## Build Commands

| Command | Description |
|---------|-------------|
| `make deps` | Download JS vendor libs (marked, mermaid, DOMPurify, github-markdown-css) |
| `make build` | Build release binary (runs `deps` first) |
| `make test` | Run unit tests (needs Xcode for Swift Testing framework) |
| `make app` | Create `.app` bundle with ad-hoc signing |
| `make install` | Build + install to `/Applications` |
| `make clean` | Remove build artifacts |

If only CommandLineTools are installed (no Xcode), tests need:
```bash
DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer swift test
```

## Architecture

```
Sources/
  MarkdownViewerLib/           # Library target (testable)
    HTMLRenderer.swift          # Template composition, JS escaping, resource caching
    MarkdownDocument.swift      # Read-only FileDocument for .md files
    MarkdownWebView.swift       # WKWebView wrapper: search, zoom, panning, copy
    ContentView.swift           # SwiftUI view, toolbar, search bar, focused values
    Resources/
      template.html             # HTML + JS: rendering, search, panning, diagram copy
      style.css                 # GitHub-flavored CSS, dark mode, highlights
      vendor/                   # Downloaded at build time, gitignored
  MarkdownViewer/
    MarkdownViewerApp.swift     # @main, DocumentGroup, menu commands
Tests/
  MarkdownViewerTests/          # Swift Testing: HTMLRenderer + MarkdownDocument
```

## Key Design Decisions

- **No Swift dependencies** — only Apple frameworks (SwiftUI, WebKit, AppKit)
- **JS libs bundled** — marked.js, mermaid.js, DOMPurify downloaded at build time, embedded in app
- **Library + executable split** — MarkdownViewerLib is testable, MarkdownViewer has @main
- **DOMPurify for XSS** — sanitizes marked.js HTML output before innerHTML
- **CSP header** — blocks external resource loading
- **pageZoom for keyboard zoom** — content overflows, enables JS click-drag panning
- **allowsMagnification for trackpad** — native pinch-to-zoom

## Security

- DOMPurify sanitizes all rendered HTML
- CSP: `default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: https:`
- Mermaid runs in `securityLevel: 'strict'`
- URL scheme whitelist: only http, https, mailto
- JS template literal escaping prevents content injection
- Read-only: cannot modify files
