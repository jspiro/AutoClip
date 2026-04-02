APP_NAME = AutoClip
BUNDLE = build/$(APP_NAME).app
CONTENTS = $(BUNDLE)/Contents
PLIST = AutoClip/Info.plist
INSTALL_DIR = /Applications

# SPM puts the release binary here
SPM_BIN = $(shell swift build -c release --show-bin-path 2>/dev/null)

ICON_SOURCE = $(shell python3 -c "import json; d=json.load(open('AutoClip.icon/icon.json')); print(d['groups'][0]['layers'][0]['image-name'])" 2>/dev/null)

CODESIGN_IDENTITY = Developer ID Application: Jono Spiro (QZEHRZT694)

.PHONY: build install uninstall run clean icon secrets

build:
	swift build -c release
	@mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	@cp $(PLIST) $(CONTENTS)/
	@# AppIcon loaded from Assets.car (compiled by 'icon' target)
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

dev: icon
	-@pkill -x $(APP_NAME) 2>/dev/null; sleep 0.5
	open $(BUNDLE)

install: icon
	-@pkill -x $(APP_NAME) 2>/dev/null; sleep 0.5
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"
	open $(INSTALL_DIR)/$(APP_NAME).app

uninstall:
	-osascript -e 'tell application "$(APP_NAME)" to quit' 2>/dev/null
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled"

run: build
	open $(BUNDLE)

icon: build
	@# Compile .icon package into Assets.car using Xcode's actool
	@xcrun actool --compile $(CONTENTS)/Resources \
	  --platform macosx --minimum-deployment-target 13.0 \
	  AutoClip.icon >/dev/null
	@echo "Compiled AutoClip.icon → Assets.car"

secrets:
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

clean:
	rm -rf build
	swift package clean
