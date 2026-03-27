import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    let preferences = PreferencesManager()
    private var watcherManager: WatcherManager!
    private var statusBarController: StatusBarController!
    private var settingsWindowManager: SettingsWindowManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        watcherManager = WatcherManager(preferences: preferences)
        settingsWindowManager = SettingsWindowManager(preferences: preferences)
        statusBarController = StatusBarController(
            preferences: preferences,
            watcherManager: watcherManager,
            settingsWindowManager: settingsWindowManager
        )
    }
}
