# Markdown Viewer

[![CI](https://github.com/Ladas/MarkdownViewer/actions/workflows/ci.yml/badge.svg)](https://github.com/Ladas/MarkdownViewer/actions/workflows/ci.yml)
[![CodeQL](https://github.com/Ladas/MarkdownViewer/actions/workflows/codeql.yml/badge.svg)](https://github.com/Ladas/MarkdownViewer/actions/workflows/codeql.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Ladas/MarkdownViewer/badge)](https://scorecard.dev/viewer/?uri=github.com/Ladas/MarkdownViewer)
[![Release](https://img.shields.io/github/v/release/Ladas/MarkdownViewer)](https://github.com/Ladas/MarkdownViewer/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)

A lightweight native macOS Markdown viewer with Mermaid diagram support.

## Why

As AI-assisted development tools like Claude Code become the primary way to write and review code, traditional IDEs are no longer the default workspace. But developers still need a fast, native way to preview Markdown documents — architecture diagrams, design docs, READMEs — without switching to a browser or a heavy editor. Set MarkdownViewer as your default `.md` handler and Cmd+click any file path in your terminal to instantly preview it, review rendered Mermaid diagrams, and copy formatted output for sharing.

## Features

- **Markdown rendering** with GitHub-flavored styling (tables, task lists, code blocks)
- **Mermaid diagrams** rendered inline (flowcharts, sequence diagrams, etc.)
- **Table of Contents** sidebar (Ctrl+Cmd+T) with heading navigation
- **Git diff view** (Cmd+D) to compare against HEAD or remote refs
- **File watcher** automatically reloads when the file changes externally
- **Light/Dark/System appearance** toggle (View > Appearance)
- **Search** (Cmd+F) with match highlighting and navigation
- **Zoom** (Cmd+/-, trackpad pinch, click-drag pan when zoomed)
- **Review notes** — add inline review feedback that Claude Code can read and act on (see [Review Workflow](#review-workflow))
- **Voice dictation** support — toggle Voice mode in the action bar, use native macOS dictation (Fn+Fn) to speak notes
- **Copy Markdown Source** (Cmd+Shift+C) copies raw markdown
- **Copy HTML** (Cmd+Option+C) copies standalone HTML with CSS and diagrams as PNG — pastes cleanly into Google Docs
- **Export HTML** (Cmd+E) saves a standalone `.html` file with everything embedded
- **Copy individual diagrams** — hover any Mermaid diagram for a copy-as-PNG button
- **App icon** — generated Markdown mark (M with down arrow)
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
| Table of Contents | Ctrl+Cmd+T |
| Git Diff | Cmd+D |
| Copy markdown source | Cmd+Shift+C |
| Copy HTML | Cmd+Option+C |
| Export HTML | Cmd+E |
| Add review note | Cmd+Shift+N |
| Add note at section | Cmd+double-click |

## Review Workflow

MarkdownViewer supports inline review notes designed for the AI-assisted development loop:

1. **Claude Code generates** a document (architecture diagram, design doc, etc.)
2. **You open it** in MarkdownViewer (Cmd+click the file path in your terminal)
3. **You add review notes** — click "Add Note" or Cmd+double-click near a section heading
4. **Use voice dictation** — toggle "Voice" in the action bar, then press Fn twice to dictate your feedback
5. **Notes are saved** as ` ```review ` code blocks directly in the `.md` file
6. **Tell Claude Code** to read your feedback: *"read my review notes in architecture.md and address them"*
7. **Claude Code finds** the ` ```review ` blocks and acts on your feedback

### Note format

Notes are stored as fenced code blocks with the `review` language tag:

````markdown
```review
This section needs error handling for the edge case where the API returns 404.
Consider adding a retry mechanism.
```
````

This format is:
- **Valid markdown** — renders as a code block in any viewer, GitHub, etc.
- **Non-destructive** — doesn't break document formatting
- **Machine-readable** — Claude Code and other tools can easily find and parse them
- **Rendered specially** — MarkdownViewer shows them as styled callout blocks with Edit/Delete buttons

## Architecture

```
Sources/
  MarkdownViewerLib/           # Library (testable)
    HTMLRenderer.swift          # Template composition, JS escaping, resource caching
    MarkdownDocument.swift      # Read-only FileDocument for .md files
    MarkdownWebView.swift       # WKWebView wrapper with search, zoom, panning
    ContentView.swift           # SwiftUI view with action bar, TOC sidebar, diff view
    FileWatcher.swift           # Polls file modification date for auto-reload
    GitHelper.swift             # Git diff operations and diff-to-HTML rendering
    Resources/
      template.html             # HTML template with rendering, search, copy, export JS
      style.css                 # GitHub-flavored CSS with dark mode + appearance overrides
      vendor/                   # Downloaded: marked.js, mermaid.js, DOMPurify, github-markdown.css
  MarkdownViewer/
    MarkdownViewerApp.swift     # @main entry point, menu commands
Tests/
  MarkdownViewerTests/          # 42 Swift Testing tests
scripts/
  generate-icon.swift           # Generates AppIcon.icns from code
```

### Bundled dependencies

Downloaded at build time via `make deps` (not included in repo):

| Library | Version | Size | Purpose |
|---------|---------|------|---------|
| [marked](https://github.com/markedjs/marked) | 15.0.8 | 39 KB | Markdown to HTML |
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

## Planned

- Print / export to PDF
- Drag-and-drop file opening
- Syntax highlighting in code blocks

## Uninstall

```bash
rm -rf /Applications/MarkdownViewer.app
```

## License

[MIT](LICENSE)
