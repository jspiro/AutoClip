import Foundation
import ServiceManagement

/// Centralized UserDefaults wrapper for all AutoClip settings.
/// Posts `PreferencesManager.didChange` when settings are modified.
class PreferencesManager {
    static let didChange = Notification.Name("AutoClipPreferencesDidChange")

    static let defaultExtensions: Set<String> = [
        "png", "jpg", "jpeg", "tiff", "heic", "gif", "webp",
        "pdf", "mov", "mp4",
    ]

    private let defaults = UserDefaults.standard

    var maxRecentFiles: Int {
        get {
            let val = defaults.integer(forKey: "MaxRecentFiles")
            return val > 0 ? val : 5
        }
        set { defaults.set(newValue, forKey: "MaxRecentFiles") }
    }

    // MARK: - Watch Directories

    var watchDirectories: [String] {
        get {
            if let custom = defaults.stringArray(forKey: "WatchDirectories"),
                !custom.isEmpty
            {
                return custom.map { ($0 as NSString).expandingTildeInPath }
            }
            // Default to macOS screenshot location
            if let loc = UserDefaults(suiteName: "com.apple.screencapture")?
                .string(forKey: "location")
            {
                return [(loc as NSString).expandingTildeInPath]
            }
            return [("~/Desktop" as NSString).expandingTildeInPath]
        }
        set {
            defaults.set(newValue, forKey: "WatchDirectories")
            NotificationCenter.default.post(name: Self.didChange, object: self)
        }
    }

    // MARK: - File Types

    /// When true, watch all files regardless of extension.
    var watchAllFiles: Bool {
        get { defaults.bool(forKey: "WatchAllFiles") }
        set {
            defaults.set(newValue, forKey: "WatchAllFiles")
            NotificationCenter.default.post(name: Self.didChange, object: self)
        }
    }

    /// Extensions to filter by when watchAllFiles is false.
    var extensions: Set<String> {
        get {
            if let custom = defaults.stringArray(forKey: "Extensions"),
                !custom.isEmpty
            {
                return Set(custom.map { $0.lowercased() })
            }
            return Self.defaultExtensions
        }
        set {
            defaults.set(Array(newValue), forKey: "Extensions")
            NotificationCenter.default.post(name: Self.didChange, object: self)
        }
    }

    /// Returns nil when watching all files, or the extension set when filtering.
    var activeExtensions: Set<String>? {
        watchAllFiles ? nil : extensions
    }

    // MARK: - Recently Copied

    var recentlyCopied: [String] {
        get { defaults.stringArray(forKey: "RecentlyCopied") ?? [] }
        set {
            let trimmed = Array(newValue.prefix(maxRecentFiles))
            defaults.set(trimmed, forKey: "RecentlyCopied")
        }
    }

    func addRecentFile(_ path: String) {
        var recent = recentlyCopied
        // Remove if already present, then prepend
        recent.removeAll { $0 == path }
        recent.insert(path, at: 0)
        recentlyCopied = recent
    }

    // MARK: - Login Item

    var startAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog(
                    "AutoClip: login item error: %@",
                    error.localizedDescription)
            }
        }
    }
}
