import Cocoa

/// Watches a single directory for new files using DispatchSource (kqueue).
/// The process sleeps with zero CPU until the OS signals a directory change.
class DirectoryWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var lastProcessed = ""
    private let directory: String
    private let preferences: PreferencesManager

    /// Called on the main queue when a new file is copied to the clipboard.
    var onFileCopied: ((String) -> Void)?

    init(directory: String, preferences: PreferencesManager) {
        self.directory = directory
        self.preferences = preferences
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

    func stop() {
        source?.cancel()
        source = nil
    }

    private func processNewest() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: directory) else {
            return
        }

        let extensions = preferences.activeExtensions

        // Find the newest matching file by modification date
        let newest = files
            .filter { name in
                // When watchAllFiles is true, extensions is nil — accept everything
                guard let exts = extensions else { return true }
                return exts.contains(
                    (name as NSString).pathExtension.lowercased())
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

        onFileCopied?(fullPath)
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
