# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in MarkdownViewer, please report it responsibly.

**Do not open a public issue for security vulnerabilities.**

Instead, please email: **lsmola@github.com** (replace with your preferred contact)

Or use [GitHub's private vulnerability reporting](https://github.com/Ladas/MarkdownViewer/security/advisories/new).

### What to include

- Description of the vulnerability
- Steps to reproduce
- Affected versions
- Potential impact

### Response timeline

- **Acknowledgment:** within 48 hours
- **Assessment:** within 1 week
- **Fix:** depends on severity (critical: ASAP, others: next release)

## Security Model

MarkdownViewer is a read-only document viewer. It:

- **Cannot modify files** — read-only FileDocument
- **Has no network access** at runtime — all resources are bundled
- **Sanitizes HTML** via DOMPurify before rendering
- **Restricts content loading** via Content-Security-Policy
- **Limits link navigation** to http, https, and mailto schemes
- **Runs Mermaid in strict mode** — disables unsafe diagram features

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest  | Yes       |

## Dependencies

JavaScript libraries are bundled at build time (not loaded at runtime):

| Library | Purpose | Security role |
|---------|---------|---------------|
| [DOMPurify](https://github.com/cure53/DOMPurify) | HTML sanitization | Prevents XSS from markdown content |
| [marked](https://github.com/markedjs/marked) | Markdown parsing | Converts markdown to HTML |
| [mermaid](https://github.com/mermaid-js/mermaid) | Diagram rendering | Runs in strict security mode |
| [github-markdown-css](https://github.com/sindresorhus/github-markdown-css) | Styling | CSS only, no code execution |
