import Cocoa

/// Owns the NSStatusItem (menu bar icon) and builds the dropdown menu.
class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let preferences: PreferencesManager
    private let watcherManager: WatcherManager
    private let settingsWindowManager: SettingsWindowManager

    init(
        preferences: PreferencesManager,
        watcherManager: WatcherManager,
        settingsWindowManager: SettingsWindowManager
    ) {
        self.preferences = preferences
        self.watcherManager = watcherManager
        self.settingsWindowManager = settingsWindowManager
        super.init()

        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "ClipWatch")
            {
                image.isTemplate = true
                button.image = image
            }
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    /// Rebuild the menu each time it opens so it reflects current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Title
        let title = NSMenuItem(title: "ClipWatch", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        // Watched directories
        for dir in preferences.watchDirectories {
            let displayPath = abbreviatePath(dir)
            let item = NSMenuItem(
                title: displayPath, action: nil, keyEquivalent: "")
            item.state = .on
            item.isEnabled = false
            menu.addItem(item)
        }
        menu.addItem(.separator())

        // Recently copied
        let recent = preferences.recentlyCopied
        if !recent.isEmpty {
            let header = NSMenuItem(
                title: "Recently Copied:", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            for path in recent {
                let filename = URL(fileURLWithPath: path).lastPathComponent
                let item = NSMenuItem(
                    title: "  \(filename)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }

        // Actions
        menu.addItem(
            NSMenuItem(
                title: "Preferences\u{2026}",
                action: #selector(openPreferences),
                keyEquivalent: ","))

        menu.addItem(
            NSMenuItem(
                title: "Check for Updates\u{2026}",
                action: #selector(checkForUpdates),
                keyEquivalent: ""))

        menu.addItem(.separator())

        menu.addItem(
            NSMenuItem(
                title: "Quit ClipWatch",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))
    }

    // MARK: - Actions

    @objc private func openPreferences() {
        settingsWindowManager.show()
    }

    @objc private func checkForUpdates() {
        // TODO: wire to UpdaterManager in step 5
        NSLog("ClipWatch: check for updates not yet implemented")
    }

    // MARK: - Helpers

    /// Replace home directory prefix with ~ for display.
    private func abbreviatePath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
