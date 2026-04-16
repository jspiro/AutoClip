import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate,
    UNUserNotificationCenterDelegate
{
    let preferences = PreferencesManager()
    var statusItem: NSStatusItem!
    private var updaterManager: UpdaterManager!
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

        updaterManager = UpdaterManager()
        watcherManager = WatcherManager(preferences: preferences)
        settingsWindowManager = SettingsWindowManager(
            preferences: preferences, updaterManager: updaterManager)
        statusBarController = StatusBarController(
            statusItem: statusItem,
            preferences: preferences,
            watcherManager: watcherManager,
            settingsWindowManager: settingsWindowManager,
            updaterManager: updaterManager
        )

        // Mark launch complete so applicationShouldHandleReopen knows
        // the next reopen is user-initiated, not the initial open.
        DispatchQueue.main.async { self.hasFinishedFirstLaunch = true }
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
    // Suppress settings window when app activates from notification click
    private var handlingNotification = false

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows flag: Bool
    ) -> Bool {
        guard hasFinishedFirstLaunch else { return false }
        // Delay so didReceive can set handlingNotification first
        DispatchQueue.main.async {
            guard !self.handlingNotification else { return }
            self.settingsWindowManager.show()
        }
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handlingNotification = true
        defer {
            DispatchQueue.main.async { self.handlingNotification = false }
        }
        let userInfo = response.notification.request.content.userInfo
        if let path = userInfo["filePath"] as? String {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        completionHandler()
    }
}
