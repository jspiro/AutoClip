import Cocoa

/// Owns the NSStatusItem (menu bar icon) and builds the dropdown menu.
class StatusBarController: NSObject, NSMenuDelegate {
    deinit { NSLog("AutoClip: StatusBarController DEALLOCATED") }

    // Status item is created in main.swift and passed in
    private var statusItem: NSStatusItem
    private let preferences: PreferencesManager
    private let watcherManager: WatcherManager
    private let settingsWindowManager: SettingsWindowManager

    init(
        statusItem: NSStatusItem,
        preferences: PreferencesManager,
        watcherManager: WatcherManager,
        settingsWindowManager: SettingsWindowManager
    ) {
        self.statusItem = statusItem
        self.preferences = preferences
        self.watcherManager = watcherManager
        self.settingsWindowManager = settingsWindowManager
        super.init()

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    /// Rebuild the menu each time it opens so it reflects current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Recently copied files with their source folder
        let recent = preferences.recentlyCopied
        if !recent.isEmpty {
            for path in recent {
                let url = URL(fileURLWithPath: path)
                let filename = url.lastPathComponent
                let folder = abbreviatePath(
                    url.deletingLastPathComponent().path)
                let item = NSMenuItem(
                    title: filename,
                    action: #selector(recopyFile(_:)),
                    keyEquivalent: "")
                item.target = self
                item.representedObject = path
                // Show source folder as subtitle (indented, smaller)
                let attrTitle = NSMutableAttributedString(string: filename)
                attrTitle.append(NSAttributedString(
                    string: "\n\(folder)",
                    attributes: [
                        .font: NSFont.systemFont(
                            ofSize: NSFont.smallSystemFontSize),
                        .foregroundColor: NSColor.secondaryLabelColor,
                    ]))
                item.attributedTitle = attrTitle
                menu.addItem(item)
            }
            menu.addItem(.separator())
        } else {
            let empty = NSMenuItem(
                title: "No recent files", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            menu.addItem(.separator())
        }

        // Actions
        let prefsItem = NSMenuItem(
            title: "Preferences\u{2026}",
            action: #selector(openPreferences),
            keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let updateItem = NSMenuItem(
            title: "Check for Updates\u{2026}",
            action: #selector(checkForUpdates),
            keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        menu.addItem(
            NSMenuItem(
                title: "Quit AutoClip",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))
    }

    // MARK: - Actions

    @objc private func recopyFile(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        let url = URL(fileURLWithPath: path)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([url as NSURL])
        pb.addTypes([.string], owner: nil)
        pb.setString(path, forType: .string)
    }

    @objc private func openPreferences() {
        settingsWindowManager.show()
    }

    @objc private func checkForUpdates() {
        // TODO: wire to UpdaterManager in step 5
        NSLog("AutoClip: check for updates not yet implemented")
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
