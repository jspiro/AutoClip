APP_NAME = AutoClip
BUNDLE = build/$(APP_NAME).app
CONTENTS = $(BUNDLE)/Contents
PLIST = AutoClip/Info.plist
INSTALL_DIR = $(HOME)/Applications

# SPM puts the release binary here
SPM_BIN = $(shell swift build -c release --show-bin-path 2>/dev/null)

ICON_SOURCE = $(shell python3 -c "import json; d=json.load(open('AutoClip.icon/icon.json')); print(d['groups'][0]['layers'][0]['image-name'])" 2>/dev/null)

.PHONY: build install uninstall run clean icon

build: icon
	swift build -c release
	@mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	@cp $(PLIST) $(CONTENTS)/
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

install: build
	-@pkill -x $(APP_NAME) 2>/dev/null; sleep 0.5
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"
	open $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Add to Login Items: System Settings > General > Login Items"

uninstall:
	-osascript -e 'tell application "$(APP_NAME)" to quit' 2>/dev/null
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled"

run: build
	open $(BUNDLE)

icon:
	@rm -rf /tmp/autoclip-iconset.iconset && mkdir /tmp/autoclip-iconset.iconset
	@SRC="AutoClip.icon/Assets/$(ICON_SOURCE)"; \
	for s in 16 32 128 256 512; do \
	  s2=$$((s*2)); \
	  sips -z $$s $$s "$$SRC" --out "/tmp/autoclip-iconset.iconset/icon_$${s}x$${s}.png" >/dev/null; \
	  sips -z $$s2 $$s2 "$$SRC" --out "/tmp/autoclip-iconset.iconset/icon_$${s}x$${s}@2x.png" >/dev/null; \
	done
	@iconutil -c icns /tmp/autoclip-iconset.iconset -o AutoClip/Resources/AppIcon.icns
	@echo "Generated AppIcon.icns from AutoClip.icon/Assets/$(ICON_SOURCE)"

clean:
	rm -rf build
	swift package clean
