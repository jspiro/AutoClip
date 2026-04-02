import Cocoa
import Settings

extension Settings.PaneIdentifier {
    static let general = Self("general")
    static let fileTypes = Self("fileTypes")
    static let about = Self("about")
}

/// Manages the preferences window lifecycle and the activation policy dance
/// required for LSUIElement apps to show focused windows.
class SettingsWindowManager {
    private lazy var settingsWindowController: SettingsWindowController = {
        let generalPane = Settings.Pane(
            identifier: .general,
            title: "General",
            toolbarIcon: NSImage(
                systemSymbolName: "gear",
                accessibilityDescription: "General")!
        ) { [preferences] in
            GeneralSettingsView(preferences: preferences)
        }

        let fileTypesPane = Settings.Pane(
            identifier: .fileTypes,
            title: "File Types",
            toolbarIcon: NSImage(
                systemSymbolName: "doc.badge.gearshape",
                accessibilityDescription: "File Types")!
        ) { [preferences] in
            FileTypesSettingsView(preferences: preferences)
        }

        let aboutPane = Settings.Pane(
            identifier: .about,
            title: "About",
            toolbarIcon: NSImage(
                systemSymbolName: "info.circle",
                accessibilityDescription: "About")!
        ) { [updaterManager] in
            AboutSettingsView(
                updaterController: updaterManager!.controller)
        }

        return SettingsWindowController(
            panes: [
                generalPane.asSettingsPane(),
                fileTypesPane.asSettingsPane(),
                aboutPane.asSettingsPane(),
            ],
            style: .toolbarItems
        )
    }()

    private let preferences: PreferencesManager
    private let updaterManager: UpdaterManager?
    private var windowCloseObserver: NSObjectProtocol?

    init(preferences: PreferencesManager, updaterManager: UpdaterManager? = nil) {
        self.preferences = preferences
        self.updaterManager = updaterManager
    }

    func show() {
        // Temporarily become a regular app so the window can receive focus
        NSApp.setActivationPolicy(.regular)
        ensureMainMenu()
        settingsWindowController.show()
        NSApp.activate(ignoringOtherApps: true)

        // Observe window close to revert activation policy
        if windowCloseObserver == nil {
            windowCloseObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: settingsWindowController.window,
                queue: .main
            ) { [weak self] _ in
                // Defer by one run loop tick so the window finishes closing
                DispatchQueue.main.async {
                    self?.revertActivationPolicy()
                }
            }
        }
    }

    private func revertActivationPolicy() {
        NSApp.setActivationPolicy(.accessory)
    }

    /// LSUIElement apps have no menu bar — add one so Cmd+W works
    private func ensureMainMenu() {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(
            NSMenuItem(
                title: "Quit AutoClip",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(
            NSMenuItem(
                title: "Close",
                action: #selector(NSWindow.performClose(_:)),
                keyEquivalent: "w"))
        let windowItem = NSMenuItem()
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)

        NSApp.mainMenu = mainMenu
        // Keep menu bar hidden — Cmd+W still works via responder chain
        NSApp.mainMenu?.items.forEach { $0.isHidden = true }
    }
}
