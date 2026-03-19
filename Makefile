.PHONY: deps verify-deps build test icon app install clean

APP_NAME = MarkdownViewer
VENDOR_DIR = Sources/MarkdownViewerLib/Resources/vendor

# Pinned versions
MARKED_VERSION = 15.0.8
MERMAID_VERSION = 11.13.0
DOMPURIFY_VERSION = 3.2.4
GH_MARKDOWN_CSS_VERSION = 5.8.1
FA_VERSION = 6.7.2

deps:
	@mkdir -p $(VENDOR_DIR)
	@echo "Downloading marked.js@$(MARKED_VERSION)..."
	@curl -sL "https://cdn.jsdelivr.net/npm/marked@$(MARKED_VERSION)/marked.min.js" -o $(VENDOR_DIR)/marked.min.js
	@echo "Downloading mermaid.js@$(MERMAID_VERSION)..."
	@curl -sL "https://cdn.jsdelivr.net/npm/mermaid@$(MERMAID_VERSION)/dist/mermaid.min.js" -o $(VENDOR_DIR)/mermaid.min.js
	@echo "Downloading DOMPurify@$(DOMPURIFY_VERSION)..."
	@curl -sL "https://cdn.jsdelivr.net/npm/dompurify@$(DOMPURIFY_VERSION)/dist/purify.min.js" -o $(VENDOR_DIR)/purify.min.js
	@echo "Downloading github-markdown-css@$(GH_MARKDOWN_CSS_VERSION)..."
	@curl -sL "https://cdn.jsdelivr.net/npm/github-markdown-css@$(GH_MARKDOWN_CSS_VERSION)/github-markdown.css" -o $(VENDOR_DIR)/github-markdown.css
	@echo "Downloading Font Awesome@$(FA_VERSION)..."
	@curl -sL "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/$(FA_VERSION)/css/all.min.css" -o $(VENDOR_DIR)/fontawesome-raw.css
	@curl -sL "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/$(FA_VERSION)/webfonts/fa-solid-900.woff2" -o $(VENDOR_DIR)/fa-solid-900.woff2
	@curl -sL "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/$(FA_VERSION)/webfonts/fa-regular-400.woff2" -o $(VENDOR_DIR)/fa-regular-400.woff2
	@curl -sL "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/$(FA_VERSION)/webfonts/fa-brands-400.woff2" -o $(VENDOR_DIR)/fa-brands-400.woff2
	@echo "Inlining Font Awesome fonts..."
	@cd $(VENDOR_DIR) && \
		SOLID=$$(base64 -i fa-solid-900.woff2) && \
		REGULAR=$$(base64 -i fa-regular-400.woff2) && \
		BRANDS=$$(base64 -i fa-brands-400.woff2) && \
		sed \
			-e "s|../webfonts/fa-solid-900.woff2|data:font/woff2;base64,$$SOLID|g" \
			-e "s|../webfonts/fa-regular-400.woff2|data:font/woff2;base64,$$REGULAR|g" \
			-e "s|../webfonts/fa-brands-400.woff2|data:font/woff2;base64,$$BRANDS|g" \
			fontawesome-raw.css > fontawesome.css && \
		rm -f fontawesome-raw.css fa-solid-900.woff2 fa-regular-400.woff2 fa-brands-400.woff2
	@echo "Done."

verify-deps:
	@echo "Verifying vendor dependency checksums..."
	@cd $(VENDOR_DIR) && shasum -a 256 -c ../../../../vendor-checksums.sha256
	@echo "All checksums verified."

build: deps
	swift build -c release

test:
	swift test

icon:
	swift scripts/generate-icon.swift

app: build icon
	@rm -rf $(APP_NAME).app
	@mkdir -p $(APP_NAME).app/Contents/MacOS
	@mkdir -p $(APP_NAME).app/Contents/Resources
	@BIN_PATH=$$(swift build -c release --show-bin-path) && \
		cp "$$BIN_PATH/$(APP_NAME)" $(APP_NAME).app/Contents/MacOS/ && \
		cp -r "$$BIN_PATH/MarkdownViewer_MarkdownViewerLib.bundle" $(APP_NAME).app/Contents/Resources/ 2>/dev/null || true
	@cp Info.plist $(APP_NAME).app/Contents/
	@cp AppIcon.icns $(APP_NAME).app/Contents/Resources/ 2>/dev/null || true
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
