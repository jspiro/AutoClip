import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate,
    UNUserNotificationCenterDelegate
{
    let preferences = PreferencesManager()
    private var watcherManager: WatcherManager!
    private var statusBarController: StatusBarController!
    private var settingsWindowManager: SettingsWindowManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission at launch
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            NSLog("ClipWatch: notifications %@", granted ? "granted" : "denied")
            if granted {
                self.sendWelcomeNotificationIfNeeded(center)
            }
        }

        watcherManager = WatcherManager(preferences: preferences)
        settingsWindowManager = SettingsWindowManager(preferences: preferences)
        statusBarController = StatusBarController(
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
        content.title = "ClipWatch is running"
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

    // Show notifications even when the app is running
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }
}
