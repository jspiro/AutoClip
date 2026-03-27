APP_NAME = AutoClip
BUNDLE = build/$(APP_NAME).app
CONTENTS = $(BUNDLE)/Contents
PLIST = AutoClip/Info.plist
INSTALL_DIR = $(HOME)/Applications

# SPM puts the release binary here
SPM_BIN = $(shell swift build -c release --show-bin-path 2>/dev/null)

.PHONY: build install uninstall run clean

build:
	swift build -c release
	@mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	@cp $(PLIST) $(CONTENTS)/
	@cp AutoClip/Resources/AppIcon.icns $(CONTENTS)/Resources/
	@cp $$(swift build -c release --show-bin-path)/$(APP_NAME) $(CONTENTS)/MacOS/
	@codesign -s - $(BUNDLE)
	@echo "Built $(BUNDLE)"

install: build
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Add to Login Items: System Settings > General > Login Items"

uninstall:
	-osascript -e 'tell application "$(APP_NAME)" to quit' 2>/dev/null
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled"

run: build
	open $(BUNDLE)

clean:
	rm -rf build
	swift package clean
