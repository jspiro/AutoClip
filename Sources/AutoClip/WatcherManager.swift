import Foundation

/// Owns the set of active DirectoryWatcher instances.
/// Rebuilds watchers when preferences change.
class WatcherManager {
    let preferences: PreferencesManager
    private var watchers: [DirectoryWatcher] = []

    init(preferences: PreferencesManager) {
        self.preferences = preferences

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: PreferencesManager.didChange,
            object: preferences
        )

        rebuildWatchers()
    }

    @objc private func preferencesDidChange() {
        rebuildWatchers()
    }

    private func rebuildWatchers() {
        // Stop existing watchers
        for watcher in watchers {
            watcher.stop()
        }
        watchers.removeAll()

        // Create new watchers for each directory
        let dirs = preferences.watchDirectories
        for dir in dirs {
            let watcher = DirectoryWatcher(
                directory: dir, preferences: preferences)
            watcher.onFileCopied = { [weak self] path in
                self?.preferences.addRecentFile(path)
            }
            watcher.start()
            watchers.append(watcher)
        }
    }
}
