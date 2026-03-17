# Markdown Viewer

[![CI](https://github.com/Ladas/MarkdownViewer/actions/workflows/ci.yml/badge.svg)](https://github.com/Ladas/MarkdownViewer/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)

A lightweight native macOS app for viewing Markdown files with full Mermaid diagram support. Designed to be your default `.md` file viewer.

## Features

- **Markdown rendering** with GitHub-flavored styling (tables, task lists, code blocks)
- **Mermaid diagrams** rendered inline (flowcharts, sequence diagrams, etc.)
- **Dark mode** automatic switching
- **Search** (Cmd+F) with match highlighting and navigation
- **Zoom** (Cmd+/-, trackpad pinch, click-drag pan when zoomed)
- **Copy Source** (Cmd+Shift+C) copies raw markdown to clipboard
- **Copy Rendered** (Cmd+Option+C) copies formatted HTML with diagrams as images, ready to paste into Google Docs
- **Copy individual diagrams** hover over any mermaid diagram for a copy button (copies as PNG)
- **macOS native** document app with tabs, multiple windows, recent files
- **Set as default** `.md` viewer via Finder

## Install

### From source (recommended)

Requires Swift 5.9+ (Xcode Command Line Tools or Xcode).

```bash
git clone https://github.com/Ladas/MarkdownViewer.git
cd MarkdownViewer
make install
```

This downloads JS dependencies, builds a release binary, creates the `.app` bundle, and copies it to `/Applications`.

### From release

Download the latest `.zip` from [Releases](https://github.com/Ladas/MarkdownViewer/releases), unzip, and drag `MarkdownViewer.app` to `/Applications`.

### First launch

The app is ad-hoc signed (not notarized). On first launch:

1. Right-click `MarkdownViewer.app` in `/Applications`
2. Click **Open**
3. Click **Open** in the dialog

This is only needed once.

## Set as default viewer for `.md` files

### Option A: Finder (GUI)

1. Right-click any `.md` file in Finder
2. **Get Info** (Cmd+I)
3. Under **Open with**, select **Markdown Viewer**
4. Click **Change All...**

### Option B: Command line

```bash
brew install duti
duti -s com.local.MarkdownViewer .md viewer
```

Verify: `duti -x md` should show `MarkdownViewer.app`.

### Option C: Open from terminal

```bash
open -a "Markdown Viewer" README.md
```

## Keyboard shortcuts

| Action | Shortcut |
|--------|----------|
| Find | Cmd+F |
| Find Next | Cmd+G |
| Find Previous | Cmd+Shift+G |
| Close search | Escape |
| Zoom in | Cmd+= |
| Zoom out | Cmd+- |
| Actual size | Cmd+0 |
| Copy markdown source | Cmd+Shift+C |
| Copy rendered (for Google Docs) | Cmd+Option+C |

## Architecture

```
Sources/
  MarkdownViewerLib/           # Library (testable)
    HTMLRenderer.swift          # Template composition, JS escaping, resource caching
    MarkdownDocument.swift      # Read-only FileDocument for .md files
    MarkdownWebView.swift       # WKWebView wrapper with search, zoom, panning
    ContentView.swift           # SwiftUI view with toolbar and search bar
    Resources/
      template.html             # HTML template with rendering + search + panning JS
      style.css                 # GitHub-flavored CSS with dark mode
      vendor/                   # Downloaded: marked.js, mermaid.js, DOMPurify, github-markdown.css
  MarkdownViewer/
    MarkdownViewerApp.swift     # @main entry point, menu commands
Tests/
  MarkdownViewerTests/          # Swift Testing tests for HTMLRenderer + MarkdownDocument
```

### Bundled dependencies

Downloaded at build time via `make deps` (not included in repo):

| Library | Version | Size | Purpose |
|---------|---------|------|---------|
| [marked](https://github.com/markedjs/marked) | 15.0.7 | 39 KB | Markdown to HTML |
| [mermaid](https://github.com/mermaid-js/mermaid) | 11.4.1 | 2.5 MB | Diagram rendering |
| [DOMPurify](https://github.com/cure53/DOMPurify) | 3.2.4 | 22 KB | HTML sanitization (XSS prevention) |
| [github-markdown-css](https://github.com/sindresorhus/github-markdown-css) | 5.8.1 | 29 KB | GitHub-flavored styling |

All resources are bundled in the app. **No network access at runtime.**

### Security

- HTML output sanitized by DOMPurify before rendering
- Content-Security-Policy blocks external resource loading
- Mermaid runs in `securityLevel: 'strict'`
- Only `http://`, `https://`, `mailto:` links open in browser
- JS template literal escaping prevents content injection
- Read-only: the app cannot modify any file

## Build commands

| Command | Description |
|---------|-------------|
| `make deps` | Download JS vendor dependencies |
| `make build` | Build release binary |
| `make test` | Run unit tests |
| `make app` | Create `.app` bundle |
| `make install` | Build + install to `/Applications` |
| `make clean` | Remove build artifacts |

## Uninstall

```bash
rm -rf /Applications/MarkdownViewer.app
```

## License

[MIT](LICENSE)
