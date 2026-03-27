APP_NAME = ClipWatch
BUNDLE = build/$(APP_NAME).app
BINARY = $(BUNDLE)/Contents/MacOS/$(APP_NAME)
SRC = $(APP_NAME)/main.swift
PLIST = $(APP_NAME)/Info.plist
INSTALL_DIR = $(HOME)/Applications

.PHONY: build install uninstall run clean

build: $(BINARY)

$(BINARY): $(SRC) $(PLIST)
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@cp $(PLIST) $(BUNDLE)/Contents/
	swiftc -O -o $(BINARY) $(SRC) -framework Cocoa
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
