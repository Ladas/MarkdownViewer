.PHONY: deps build test app install clean

APP_NAME = MarkdownViewer
VENDOR_DIR = Sources/MarkdownViewerLib/Resources/vendor

deps:
	@mkdir -p $(VENDOR_DIR)
	@echo "Downloading marked.js..."
	@curl -sL "https://cdn.jsdelivr.net/npm/marked@15.0.7/marked.min.js" -o $(VENDOR_DIR)/marked.min.js
	@echo "Downloading mermaid.js..."
	@curl -sL "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js" -o $(VENDOR_DIR)/mermaid.min.js
	@echo "Downloading DOMPurify..."
	@curl -sL "https://cdn.jsdelivr.net/npm/dompurify@3.2.4/dist/purify.min.js" -o $(VENDOR_DIR)/purify.min.js
	@echo "Downloading github-markdown.css..."
	@curl -sL "https://cdn.jsdelivr.net/npm/github-markdown-css@5.8.1/github-markdown.css" -o $(VENDOR_DIR)/github-markdown.css
	@echo "Done."

build: deps
	swift build -c release

test: deps
	DEVELOPER_DIR=/Users/lsmola/Downloads/Xcode.app/Contents/Developer swift test

app: build
	@rm -rf $(APP_NAME).app
	@mkdir -p $(APP_NAME).app/Contents/MacOS
	@mkdir -p $(APP_NAME).app/Contents/Resources
	@BIN_PATH=$$(swift build -c release --show-bin-path) && \
		cp "$$BIN_PATH/$(APP_NAME)" $(APP_NAME).app/Contents/MacOS/ && \
		cp -r "$$BIN_PATH/MarkdownViewer_MarkdownViewerLib.bundle" $(APP_NAME).app/Contents/Resources/ 2>/dev/null || true
	@cp Info.plist $(APP_NAME).app/Contents/
	@echo -n "APPL????" > $(APP_NAME).app/Contents/PkgInfo
	@codesign --force --sign - $(APP_NAME).app
	@echo "Built $(APP_NAME).app"

install: app
	@cp -r $(APP_NAME).app /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"
	@echo "To set as default for .md files:"
	@echo "  1. Right-click any .md file in Finder"
	@echo "  2. Get Info (Cmd+I)"
	@echo "  3. Open with -> Markdown Viewer -> Change All"

clean:
	swift package clean
	rm -rf $(APP_NAME).app
