SCHEME       = LifeTrack
PROJECT_DIR  = lifeTrackIos
XCODEPROJ    = $(PROJECT_DIR)/LifeTrack.xcodeproj
ARCHIVE_PATH = $(PROJECT_DIR)/build/LifeTrack.xcarchive
EXPORT_PATH  = $(PROJECT_DIR)/build/export

SIMULATOR    = "iPhone 16 Pro"

# ─────────────────────────────────────────────
# Dev
# ─────────────────────────────────────────────

.PHONY: run
run:
	@echo "▶ Building and running on simulator..."
	xcodebuild \
		-project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-destination "platform=iOS Simulator,name=$(SIMULATOR)" \
		-configuration Debug \
		build

.PHONY: open
open:
	@echo "▶ Opening in Xcode..."
	open $(XCODEPROJ)

# ─────────────────────────────────────────────
# Release
# ─────────────────────────────────────────────

.PHONY: archive
archive:
	@echo "▶ Archiving for App Store..."
	xcodebuild \
		-project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination "generic/platform=iOS" \
		archive \
		-archivePath $(ARCHIVE_PATH)
	@echo "✓ Archive saved to $(ARCHIVE_PATH)"

.PHONY: export
export: archive
	@echo "▶ Exporting .ipa..."
	xcodebuild \
		-exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist $(PROJECT_DIR)/ExportOptions.plist
	@echo "✓ IPA saved to $(EXPORT_PATH)"

.PHONY: submit
submit: archive
	@echo "▶ Uploading to App Store Connect..."
	xcrun altool \
		--upload-app \
		--type ios \
		--file "$(ARCHIVE_PATH)" \
		--apiKey $$APP_STORE_API_KEY \
		--apiIssuer $$APP_STORE_ISSUER_ID
	@echo "✓ Submitted to App Store Connect"

.PHONY: release
release: archive submit
	@echo "✓ Release complete"

# ─────────────────────────────────────────────
# Misc
# ─────────────────────────────────────────────

.PHONY: clean
clean:
	@echo "▶ Cleaning build artifacts..."
	xcodebuild -project $(XCODEPROJ) -scheme $(SCHEME) clean
	rm -rf $(PROJECT_DIR)/build
	@echo "✓ Clean done"

.PHONY: help
help:
	@echo ""
	@echo "LifeTrack iOS — Makefile commands:"
	@echo ""
	@echo "  make open      — открыть проект в Xcode"
	@echo "  make run       — собрать и запустить на симуляторе"
	@echo ""
	@echo "  make archive   — создать архив для App Store"
	@echo "  make submit    — загрузить в App Store Connect"
	@echo "  make release   — archive + submit одной командой"
	@echo ""
	@echo "  make clean     — очистить build артефакты"
	@echo ""
	@echo "  Env vars для submit:"
	@echo "    APP_STORE_API_KEY   — App Store Connect API Key ID"
	@echo "    APP_STORE_ISSUER_ID — App Store Connect Issuer ID"
	@echo ""
