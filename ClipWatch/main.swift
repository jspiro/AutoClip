import Cocoa

/// ClipWatch — watches folders for new files and copies them to the clipboard.
///
/// Uses DispatchSource (kqueue) per directory. The process sleeps with zero
/// CPU usage until the OS signals a change in a watched directory.

// MARK: - Configuration

/// File extensions to watch for (case-insensitive).
let defaultExtensions: Set<String> = [
    "png", "jpg", "jpeg", "tiff", "heic", "gif", "webp",
    "pdf", "mov", "mp4",
]

/// Returns the list of directories to watch.
///
/// Configure with:
///   defaults write net.lostinrecursion.ClipWatch WatchDirectories \
///     -array ~/Desktop/Screenshots ~/Downloads
///
/// Default: whatever macOS is configured to save screenshots to.
func watchDirectories() -> [String] {
    let defaults = UserDefaults.standard

    if let custom = defaults.stringArray(forKey: "WatchDirectories"), !custom.isEmpty {
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

/// Returns the set of file extensions to watch for.
///
/// Configure with:
///   defaults write net.lostinrecursion.ClipWatch Extensions -array png jpg pdf
///
/// Default: common image/video/document extensions.
func watchExtensions() -> Set<String> {
    let defaults = UserDefaults.standard
    if let custom = defaults.stringArray(forKey: "Extensions"), !custom.isEmpty {
        return Set(custom.map { $0.lowercased() })
    }
    return defaultExtensions
}

// MARK: - Watcher

class DirectoryWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var lastProcessed = ""
    private let directory: String
    private let extensions: Set<String>

    init(directory: String, extensions: Set<String>) {
        self.directory = directory
        self.extensions = extensions
    }

    func start() {
        let fd = open(directory, O_EVTONLY)
        guard fd >= 0 else {
            NSLog("ClipWatch: cannot open %@", directory)
            return
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            // Delay to let the OS finish writing the file
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.processNewest()
            }
        }

        source?.setCancelHandler { close(fd) }
        source?.resume()
        NSLog("ClipWatch: watching %@", directory)
    }

    private func processNewest() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: directory) else {
            return
        }

        // Find the newest matching file by modification date
        let newest = files
            .filter {
                extensions.contains(
                    ($0 as NSString).pathExtension.lowercased())
            }
            .compactMap { name -> (String, Date)? in
                let path = (directory as NSString)
                    .appendingPathComponent(name)
                guard let attrs = try? fm.attributesOfItem(atPath: path),
                    let mod = attrs[.modificationDate] as? Date
                else { return nil }
                return (path, mod)
            }
            .max { $0.1 < $1.1 }

        guard let (fullPath, modDate) = newest else { return }

        let age = Date().timeIntervalSince(modDate)
        if fullPath == lastProcessed || age > 5 { return }
        lastProcessed = fullPath

        copyToClipboard(path: fullPath)

        let filename = URL(fileURLWithPath: fullPath).lastPathComponent
        showNotification(filename: filename)
        NSLog("ClipWatch: copied %@", filename)
    }

    /// Puts the file on the clipboard (like Finder's Cmd+C) and adds the
    /// full POSIX path as plain text so `pbpaste` returns the path.
    private func copyToClipboard(path: String) {
        let url = URL(fileURLWithPath: path)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([url as NSURL])
        pb.addTypes([.string], owner: nil)
        pb.setString(path, forType: .string)
    }

    private func showNotification(filename: String) {
        let script = "display notification \"\(filename)\" "
            + "with title \"Copied to clipboard\""
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        try? proc.run()
    }
}

// MARK: - Entry point

let dirs = watchDirectories()
let exts = watchExtensions()

if dirs.isEmpty {
    NSLog("ClipWatch: no directories to watch")
    exit(1)
}

for dir in dirs {
    let watcher = DirectoryWatcher(directory: dir, extensions: exts)
    watcher.start()
}

// LSUIElement app — no dock icon, just runs in background
NSApplication.shared.run()
