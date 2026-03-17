# Contributing to MarkdownViewer

## Development Setup

### Prerequisites

- macOS 13+ (Ventura or later)
- Swift 5.9+ (Xcode Command Line Tools or Xcode)
- `pre-commit` (`brew install pre-commit`)

### Getting Started

```bash
git clone https://github.com/Ladas/MarkdownViewer.git
cd MarkdownViewer
pre-commit install --hook-type pre-commit --hook-type commit-msg
make deps
make build
```

### Running Tests

```bash
make test
```

> **Note:** If you only have Command Line Tools (no Xcode), you need to point to an Xcode installation:
> ```bash
> DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer swift test
> ```

### Testing the App

```bash
make app
open MarkdownViewer.app /path/to/test.md
```

## Making Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make your changes
4. Run tests (`make test`)
5. Build the app (`make app`) and verify manually
6. Commit with a descriptive message
7. Push and open a Pull Request

## Commit Messages

Use conventional commit format:

```
feat: add table of contents sidebar
fix: handle empty mermaid blocks without crash
chore: bump mermaid.js to 11.5.0
docs: update install instructions for Sequoia
```

The `commit-msg` hook automatically converts AI `Co-Authored-By` trailers to `Assisted-By`.

## Code Style

- Swift follows standard conventions (no tabs, 4-space indent)
- Keep the app lightweight — avoid adding Swift package dependencies
- Security-sensitive code (escaping, sanitization) must have tests

## Architecture

- **MarkdownViewerLib** — all logic, testable without @main
- **MarkdownViewer** — just the app entry point and menu commands
- **Resources** — HTML template with embedded JS, CSS
- **Vendor JS** — downloaded by `make deps`, gitignored

## Reporting Issues

- **Bugs:** Open a [GitHub issue](https://github.com/Ladas/MarkdownViewer/issues)
- **Security:** See [SECURITY.md](SECURITY.md) — do not open public issues for vulnerabilities
