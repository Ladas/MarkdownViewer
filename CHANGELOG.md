# Changelog

## Unreleased

### New Features

#### Claude Chat Panel
- Integrated chat panel (Cmd+Shift+K) powered by Claude CLI (`claude -p`)
- Per-file chat sessions with automatic `--resume` for conversation continuity
- Streaming responses rendered as markdown in a WKWebView
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

### Improvements

- Larger default window size (1300×900) for better readability
- Larger default chat panel height (400px, expandable to 1200px)
- Chat input field expands up to 15 lines for longer prompts
- Comments panel count badge includes both review notes and inline comments
