APP_NAME = AutoClip
BUNDLE = build/$(APP_NAME).app
CONTENTS = $(BUNDLE)/Contents
PLIST = AutoClip/Info.plist
INSTALL_DIR = /Applications

# SPM puts the release binary here
SPM_BIN = $(shell swift build -c release --show-bin-path 2>/dev/null)

ICON_SOURCE = $(shell python3 -c "import json; d=json.load(open('AutoClip.icon/icon.json')); print(d['groups'][0]['layers'][0]['image-name'])" 2>/dev/null)

.PHONY: build dev install uninstall run clean icon secrets

build: ## SPM release build + assemble .app bundle
	swift build -c release
	@mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	@cp $(PLIST) $(CONTENTS)/
	@# Local dev: suffix bundle ID so TCC grants (and Sparkle auto-updates)
	@# don't collide with the installed release. CI keeps production ID.
	@if [ -z "$(CI)" ]; then \
		/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier net.lostinrecursion.AutoClip.dev" $(CONTENTS)/Info.plist; \
		/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName AutoClip Dev" $(CONTENTS)/Info.plist; \
		echo "Local build: using bundle ID net.lostinrecursion.AutoClip.dev"; \
	fi
	@# Pre-built .icns committed to repo; actool can't compile .icon
	@# packages in GitHub Actions CI (silently produces empty output)
	@cp AutoClip/Resources/AppIcon.icns $(CONTENTS)/Resources/
	@cp AutoClip/Resources/MenuBarIcon.svg $(CONTENTS)/Resources/
	@cp $$(swift build -c release --show-bin-path)/$(APP_NAME) $(CONTENTS)/MacOS/
	@# Embed Sparkle.framework
	@mkdir -p $(CONTENTS)/Frameworks
	@cp -R $$(swift build -c release --show-bin-path)/Sparkle.framework $(CONTENTS)/Frameworks/
	@rm -rf $(CONTENTS)/Frameworks/Sparkle.framework/Versions/B/XPCServices
	@install_name_tool -add_rpath @loader_path/../Frameworks $(CONTENTS)/MacOS/$(APP_NAME) 2>/dev/null || true
	@# Sign inside-out: framework internals → framework → bundle
	@codesign -f -s - $(CONTENTS)/Frameworks/Sparkle.framework/Versions/B/Autoupdate
	@codesign -f -s - $(CONTENTS)/Frameworks/Sparkle.framework/Versions/B/Updater.app
	@codesign -f -s - $(CONTENTS)/Frameworks/Sparkle.framework
	@codesign -f -s - $(BUNDLE)
	@echo "Built $(BUNDLE)"

dev: icon ## Build + icon + relaunch app
	-@pkill -x $(APP_NAME) 2>/dev/null; sleep 0.5
	open $(BUNDLE)

install: icon ## Copy to /Applications and launch
	-@pkill -x $(APP_NAME) 2>/dev/null; sleep 0.5
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"
	open $(INSTALL_DIR)/$(APP_NAME).app

uninstall: ## Remove from /Applications
	-osascript -e 'tell application "$(APP_NAME)" to quit' 2>/dev/null
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled"

run: build ## Build and open from build/
	open $(BUNDLE)

# Regenerate committed .icns when .icon source changes
AutoClip/Resources/AppIcon.icns: AutoClip.icon/icon.json AutoClip.icon/Assets/$(ICON_SOURCE)
	@xcrun actool --compile /tmp/autoclip-icon-out \
	  --platform macosx --minimum-deployment-target 13.0 \
	  --app-icon AutoClip \
	  --output-partial-info-plist /dev/null \
	  AutoClip.icon >/dev/null
	@cp /tmp/autoclip-icon-out/AutoClip.icns $@
	@rm -rf /tmp/autoclip-icon-out
	@echo "Regenerated $@ from AutoClip.icon"

icon: build AutoClip/Resources/AppIcon.icns ## Compile .icon → Assets.car (local only)
	@# actool compiles the .icon package into Assets.car with dynamic
	@# effects (glass, shadows). Only works locally — CI uses the
	@# pre-built .icns from AutoClip/Resources/ instead.
	@xcrun actool --compile $(CONTENTS)/Resources \
	  --platform macosx --minimum-deployment-target 13.0 \
	  --app-icon AutoClip \
	  --output-partial-info-plist /dev/null \
	  AutoClip.icon >/dev/null
	@codesign -f -s - $(BUNDLE)
	@echo "Compiled AutoClip.icon → Assets.car"

secrets: ## Export Developer ID cert to GitHub Actions secrets
	@# Export Developer ID cert and set all GitHub Actions secrets
	@P12=$$(mktemp /tmp/devid.XXXX.p12); \
	PASS=$$(openssl rand -base64 24); \
	security export -t identities -f pkcs12 -k login.keychain \
	  -P "$$PASS" -o "$$P12"; \
	base64 -i "$$P12" | gh secret set DEVELOPER_ID_CERT_BASE64; \
	echo "$$PASS" | gh secret set DEVELOPER_ID_CERT_PASSWORD; \
	rm -f "$$P12"; \
	echo "Set DEVELOPER_ID_CERT_BASE64 and DEVELOPER_ID_CERT_PASSWORD"
	@echo "Now set the remaining secrets manually:"
	@echo "  gh secret set NOTARIZATION_APPLE_ID"
	@echo "  gh secret set NOTARIZATION_TEAM_ID"
	@echo "  gh secret set NOTARIZATION_PASSWORD"

clean: ## Remove build/ and SPM cache
	rm -rf build
	swift package clean
