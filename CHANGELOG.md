# Changelog

## Unreleased

### New Features

#### Claude Chat Panel
- Integrated chat panel (Cmd+Shift+K) powered by Claude CLI (`claude -p`)
- **Typing animation** — response text is revealed progressively with a typing effect (Claude CLI buffers full responses; the app animates them for a smooth UX)
- **stream-json event parsing** — correctly handles Claude CLI `assistant` and `system` events for text extraction and early session ID capture
- **Model picker** — switch between Sonnet, Opus, Haiku, or enter a custom model ID; takes effect immediately
- Per-file chat sessions with automatic `--resume` for conversation continuity
- Responses rendered as markdown in a WKWebView
- **Automatic `claude` binary resolution** — finds the CLI in common install locations (`~/.npm-global/bin/`, `/usr/local/bin/`, `/opt/homebrew/bin/`) without relying on shell PATH
- "Allow editing" toggle — when enabled, Claude can edit files (`--dangerously-skip-permissions`); when disabled, write tools are blocked (`--disallowedTools`)
- Session ID displayed in the status bar (first 8 chars, full UUID on hover)
- Working directory shown in status bar with click-to-change via directory picker
- Per-directory session tracking — switching directories saves/restores session IDs
- Automatic retry when a saved session has expired ("No conversation found" error)
- Cancel button to stop in-progress requests
- Chat history persisted per file in `.claude-chat/` directory

#### Context Menu
- **Comment** — select text in the preview, right-click → Comment to add an inline comment anchored to that text
- **Claude > Explain** — select text, right-click → Claude → Explain to send it to chat with an explanation prompt
- **Claude > Ask...** — select text, right-click → Claude → Ask... to paste the selected text into the chat input for a custom question (cursor placed at end, text deselected)

#### Inline Comments
- Comments tied to specific text passages, stored in a sidecar `.comments.json` file alongside the markdown
- Comments panel shows inline comments with quoted reference text, separate from review notes
- Each inline comment has Edit, Address, and Delete actions
- "Address" sends a focused prompt to Claude chat referencing the specific comment and its context
- New inline comments are also inserted as `review` blocks in the markdown at the position of the referenced text

#### Address Feedback
- "Address" toolbar button (next to Agent) opens the chat panel with a prompt including all review notes and inline comments
- Prompt lets you review and edit before sending
- Per-comment "Address" button in the Comments panel for targeted feedback

#### Markdown Link Navigation
- Clicking `.md` file links in the rendered preview opens them as new tabs in the same window
- Supports relative paths resolved against the current file's directory
- Recognizes `.md`, `.markdown`, `.mdown`, `.mkd`, `.mkdn` extensions

### Improvements

- Larger default window size (1300×900) for better readability
- Larger default chat panel height (400px, expandable to 1200px)
- Chat input field expands up to 15 lines for longer prompts
- Comments panel count badge includes both review notes and inline comments
- `baseURL` set on WKWebView so relative links and images resolve correctly

### Tests

- `InlineCommentTests` — model encoding/decoding, store CRUD (append, delete, update, save), sidecar file naming
- `ChatMessageTests` — message model encoding/decoding, role raw values
- `ChatHistoryManagerTests` — file key determinism, session ID persistence and reset, append/load/save/clear, `.claude-chat/` directory creation
- `ClaudeCLIRunnerTests` — git root discovery, initialization, cancel when not running, claude path resolution
- `PanelFunctionalityTests` — 50+ tests covering all panels:
  - TOC panel: heading parsing, code block filtering, sequential IDs, level matching
  - Comments panel: review note extraction/replace/insert, inline comment CRUD, resolved note detection, button label logic
  - Chat panel: session management, per-file persistence, message encode/decode
  - Preview panel: HTML rendering, chat template functions, JS escaping, view modes, source highlighter
  - Link resolution: markdown extensions, relative path resolution, non-markdown filtering
  - Diff panel: non-git fallback, available refs
  - CLI stream events: assistant text extraction, thinking block filtering, session_id, multi-block join
  - Action bar: address feedback prompt, agent prompt, explain/ask formatting
