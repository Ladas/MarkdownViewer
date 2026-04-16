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

## Git Rebase Procedure (/git:rebase)

**CRITICAL: Never use `git checkout --theirs` or `git checkout --ours` on conflicting files. Always manually merge.**

### Steps:

1. **Stash uncommitted changes**: `git stash` (if any)

2. **Fetch latest main**: `git fetch origin main`

3. **Inventory our changes BEFORE rebase** (save this list):
   ```bash
   git diff origin/main --stat  # files we changed
   git diff origin/main -- <each file> | head -100  # key changes per file
   ```

4. **Inventory main's new changes**:
   ```bash
   git log --oneline origin/main..HEAD  # our commits
   git log --oneline HEAD..origin/main  # their new commits
   ```

5. **Start rebase**: `git rebase origin/main`

6. **On EACH conflict**:
   - Read the FULL conflict markers in the file (both sides)
   - Understand what EACH side changed and WHY
   - Manually edit to KEEP BOTH sets of changes
   - If ContentView.swift conflicts: check for new @State vars, focused values, action bar buttons, message handlers — ALL must survive
   - `git add <file>` then `git rebase --continue`

7. **After rebase — VERIFY nothing was lost**:
   ```bash
   # Check key feature counts (adjust grep patterns per project)
   grep -c "showChat\|ChatPanel\|chatPanel" Sources/MarkdownViewerLib/ContentView.swift
   grep -c "showComments\|commentsPanel" Sources/MarkdownViewerLib/ContentView.swift
   grep -c "cycleAppearance\|appearanceIcon" Sources/MarkdownViewerLib/ContentView.swift
   grep -c "mermaidTheme\|MermaidTheme" Sources/MarkdownViewerLib/ContentView.swift
   grep -c "copyGDocs\|GDoc" Sources/MarkdownViewerLib/ContentView.swift
   ```

8. **Build and test**: `swift build && swift test`

9. **Pop stash**: `git stash pop` (if stashed)

10. **Force push**: `git push --force-with-lease`

### Common pitfalls:
- ContentView.swift has 1300+ lines with many independent features — conflicts here are dangerous
- MarkdownWebView.swift has message handlers that must match template.html JS functions
- template.html has JS functions called from Swift — renaming breaks silently
- Theme files in Resources/themes/ are gitignored — won't conflict but won't transfer

## Security

- DOMPurify sanitizes all rendered HTML
- CSP: `default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: https:`
- Mermaid runs in `securityLevel: 'strict'`
- URL scheme whitelist: only http, https, mailto
- JS template literal escaping prevents content injection
- Read-only: cannot modify files
