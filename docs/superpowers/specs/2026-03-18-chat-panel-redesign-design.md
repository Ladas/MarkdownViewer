# Chat Panel Redesign: Markdown Rendering, Resizable Panel, Per-File Sessions

**Date:** 2026-03-18
**Status:** Draft

## Problem

The chat panel displays Claude's responses as plain text, ignoring markdown formatting (headers, code blocks, lists, bold/italic). This looks poor in a native app that otherwise renders markdown beautifully. Additionally, each message is independent with no conversation continuity, and the panel has a fixed height.

## Goals

1. Render both user and assistant messages as formatted markdown in the chat panel
2. Maintain a persistent Claude CLI session per markdown file, surviving app restarts
3. Make the chat panel resizable via a drag handle

## Non-Goals

- Interactive permission prompts (continue using `--dangerously-skip-permissions` toggle)
- Mermaid diagram rendering inside chat messages (could add later)
- Syntax highlighting in code blocks (future enhancement)
- Conversation branching or message editing
- Persisting panel height across sessions

## Design

### 1. Chat Message Rendering (Single WKWebView)

Replace the current `ScrollView` of `MessageBubble` SwiftUI views with a single `WKWebView` that renders the entire conversation as formatted HTML. The WKWebView scrolls internally (not sized to content).

**New component: `ChatWebView`**
- `NSViewRepresentable` wrapping a `WKWebView`
- Loads the chat template HTML (composed by `HTMLRenderer`) on appear
- Must implement `dismantleNSView` to remove script message handlers (same pattern as `MarkdownWebView`) to avoid retain cycles

**New resource: `chat-template.html`**
- Contains HTML structure, CSS for message layout, and JS API
- Uses placeholder markers (`/* {{MARKED_JS}} */`, `/* {{PURIFY_JS}} */`, `/* {{VENDOR_CSS}} */`) for vendor lib inlining — same pattern as `template.html`
- CSS for message layout:
  - User messages: blue-tinted background (`rgba(0, 122, 255, 0.05)`), "You" label
  - Assistant messages: purple-tinted background (`rgba(175, 82, 222, 0.05)`), "Claude" label
  - Timestamps in subtle gray below each message
  - Dark mode via `@media (prefers-color-scheme: dark)`
  - Messages rendered inside `.markdown-body` class (github-markdown-css)

**Vendor lib inlining via `HTMLRenderer`:**
- Add `static func renderChatTemplate() -> String` to `HTMLRenderer`
- Loads `chat-template.html` from `Bundle.module` and substitutes vendor lib placeholders
- Uses the same `preparedTemplate` caching pattern as the main renderer
- This ensures vendor JS/CSS is inlined into the HTML string (required because `loadHTMLString` has no base URL)

**JavaScript API** (called from Swift via `evaluateJavaScript`):
- `addMessage(role, markdownContent, timestamp)` — renders markdown via `marked.parse()` then `DOMPurify.sanitize()`, appends to message list, auto-scrolls to bottom
- `updateStreaming(markdownContent)` — re-renders partial response in place during streaming
- `finalizeStreaming(timestamp)` — converts streaming block to permanent message
- `clearMessages()` — empties the message list
- `loadHistory(messagesJSON)` — bulk-loads saved messages on panel open

**JS content escaping:**
- When calling `evaluateJavaScript`, markdown content must be JSON-encoded (via `JSONEncoder`) before interpolation, not raw string interpolation — same approach as `MarkdownWebView.Coordinator.performSearch`

**Streaming behavior:**
- During streaming, `updateStreaming()` is called on each output chunk with the accumulated response so far
- The partial response is re-parsed through `marked.parse()` on each update (marked.js is fast enough for this)
- On completion, `finalizeStreaming()` stamps the timestamp and converts to a permanent message block
- Auto-scroll to bottom on all content changes

**SwiftUI structure of `ChatPanelView`:**
```
VStack(spacing: 0) {
    Header bar (unchanged: title, allow-editing toggle, clear button)
    Divider
    ChatWebView (replaces ScrollView + MessageBubble)
    Divider
    Input bar (unchanged: text field, send/cancel button)
}
```

### 2. Conversation Continuity — Per-File Sessions

Each opened markdown file maintains its own persistent Claude CLI session.

**Session ID generation:**
- Compute from the file's path relative to git root (or absolute path if no git root)
- Use a deterministic hash: first 16 characters of SHA-256 of the relative path
- Example: `README.md` -> `sha256("README.md")[:16]` -> `"e3b0c44298fc1c14"`

**Validation note:** The `--resume` flag combined with `-p` (print mode) needs to be validated against the Claude CLI before implementation. If `--resume` does not work with `-p`, fallback options:
- Use `--continue` (continues most recent session in that directory, less precise)
- Pass conversation history as context in the prompt prefix

**Claude CLI invocation:**
- Every message uses `--resume <session-id>`:
  ```
  claude -p '<prompt>' --resume <session-id>
  ```
- If the session exists, Claude continues with full prior context
- If the session doesn't exist (first message, or after clear), Claude starts a new session under that ID
- `--dangerously-skip-permissions` appended when allow-editing is on (unchanged)

**History storage (per-file JSON files):**

Each file gets its own history file at `<git-root>/.claude-chat/<session-id>.json`:

```json
{
  "sessionId": "e3b0c44298fc1c14",
  "filePath": "docs/README.md",
  "messages": [
    {
      "id": "uuid",
      "role": "user",
      "content": "What does this file do?",
      "timestamp": "2026-03-18T10:30:00Z"
    }
  ]
}
```

- `ChatHistoryManager` is initialized with a file-specific path: `<git-root>/.claude-chat/<session-id>.json`
- Display history is loaded from this file when the panel opens -> fed to `ChatWebView.loadHistory()`

**When `fileURL` is nil** (untitled/unsaved documents): chat is disabled — the input field shows "Save the file to enable chat" and the send button is disabled.

**Clear history behavior:**
- Clears the display messages array
- Sets `sessionId` to `nil`
- On the next message, a new deterministic session ID is generated (same hash, but with a counter suffix: `<hash>-1`, `<hash>-2`, etc., stored in the history file)
- Old CLI session is abandoned

### 3. Resizable Chat Panel

Replace the fixed-height `frame` with a draggable divider.

**State:** `@State private var chatPanelHeight: CGFloat = 250` in `ContentView`

**`ChatDividerView`** (defined as a private struct inside `ContentView.swift`):
- 6pt tall invisible hit area for easy grabbing
- 1pt visual divider line centered within it
- Cursor changes to `NSCursor.resizeUpDown` on hover
- `DragGesture` adjusts `chatPanelHeight`, clamped to `100...600`

**Layout in ContentView body:**
```swift
// Inside the main VStack, after MarkdownWebView:
if showChat {
    ChatDividerView(height: $chatPanelHeight)  // draggable
    ChatPanelView(fileURL: fileURL)
        .frame(height: chatPanelHeight)
}
```

`chatPanelHeight` is not persisted — resets to 250 on each app launch.

## File Changes

### New Files

| File | Purpose |
|------|---------|
| `Resources/chat-template.html` | HTML + CSS + JS for chat message rendering. Placeholder markers for vendor lib inlining. Message styling, dark mode, JS API (`addMessage`, `updateStreaming`, `finalizeStreaming`, `clearMessages`, `loadHistory`). |

### Modified Files

| File | Change |
|------|--------|
| `ChatPanelView.swift` | Replace `ScrollView` + `MessageBubble` with new `ChatWebView` (single WKWebView). Keep SwiftUI header and input bar. Add session ID management. Add `ChatWebView` as `NSViewRepresentable` with `dismantleNSView` cleanup. Remove `MessageBubble` and `streamingBubble`. |
| `ChatMessage.swift` | Update `ChatHistoryManager` to use per-file JSON files (`<session-id>.json`). New JSON structure with `sessionId` and `filePath`. Add `generateSessionId(for:relativeTo:)` method. Handle nil-fileURL case. |
| `ClaudeCLIRunner.swift` | Add `sessionId: String?` parameter to `run()`. When provided, append `--resume <id>` to the claude command. |
| `ContentView.swift` | Replace fixed chat `frame` with `chatPanelHeight` state + `ChatDividerView` (private struct with drag gesture). Deployment target stays macOS 13 (use existing `onChange` form). |
| `HTMLRenderer.swift` | Add `static func renderChatTemplate() -> String` that loads `chat-template.html` and inlines vendor JS/CSS using the same placeholder substitution pattern as `preparedTemplate`. |

### Deleted Code

| Item | Reason |
|------|--------|
| `MessageBubble` struct in `ChatPanelView.swift` | Replaced by WKWebView rendering |
| `streamingBubble` computed property | Streaming now handled by `ChatWebView.updateStreaming()` |

## Security Considerations

- All chat message content is sanitized through `DOMPurify` before injection into the web view (same as main view)
- Content passed to `evaluateJavaScript` is JSON-encoded, not raw-interpolated, preventing injection
- `chat-template.html` uses the same CSP as `template.html`: `default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: https:`
- Session IDs are deterministic hashes — no sensitive data in the ID itself
- File paths in prompts use relative paths (no absolute paths leaked to Claude)

## Testing

- `ChatHistoryManager`: test new per-file JSON format read/write, session ID generation, clear behavior, nil-fileURL handling
- `ClaudeCLIRunner`: test `--resume` flag is correctly appended to command
- `HTMLRenderer`: test `renderChatTemplate()` produces valid HTML with inlined vendor libs
- Manual: verify markdown rendering quality, streaming display, dark mode, panel resizing, session persistence across app restarts
- Manual: validate `claude -p --resume` works correctly before relying on it
