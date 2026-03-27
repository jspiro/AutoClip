import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate,
    UNUserNotificationCenterDelegate
{
    let preferences = PreferencesManager()
    var statusItem: NSStatusItem!
    private var watcherManager: WatcherManager!
    private var statusBarController: StatusBarController!
    private var settingsWindowManager: SettingsWindowManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        if Bundle.main.bundleIdentifier != nil {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound]) {
                granted, _ in
                NSLog(
                    "AutoClip: notifications %@",
                    granted ? "granted" : "denied")
                if granted {
                    self.sendWelcomeNotificationIfNeeded(center)
                }
            }
        }

        watcherManager = WatcherManager(preferences: preferences)
        settingsWindowManager = SettingsWindowManager(preferences: preferences)
        statusBarController = StatusBarController(
            statusItem: statusItem,
            preferences: preferences,
            watcherManager: watcherManager,
            settingsWindowManager: settingsWindowManager
        )
    }

    private func sendWelcomeNotificationIfNeeded(
        _ center: UNUserNotificationCenter
    ) {
        let key = "HasShownWelcomeNotification"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let content = UNMutableNotificationContent()
        content.title = "AutoClip is running"
        let dirs = preferences.watchDirectories
            .map { ($0 as NSString).lastPathComponent }
            .joined(separator: ", ")
        content.body = "Watching: \(dirs)"

        let request = UNNotificationRequest(
            identifier: "welcome",
            content: content,
            trigger: nil)
        center.add(request)
    }

    private var hasFinishedFirstLaunch = false

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows flag: Bool
    ) -> Bool {
        guard hasFinishedFirstLaunch else {
            hasFinishedFirstLaunch = true
            return false
        }
        settingsWindowManager.show()
        return false
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }
}
