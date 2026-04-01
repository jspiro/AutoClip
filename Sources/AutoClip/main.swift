import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Status item must be created at top level — survives the full app lifecycle
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
if let button = statusItem.button {
    // Custom menu bar icon (SVG template image)
    let iconPath = Bundle.main.resourcePath.map { $0 + "/MenuBarIcon.svg" }
    if let path = iconPath, let image = NSImage(contentsOfFile: path) {
        image.isTemplate = true
        image.size = NSSize(width: 22, height: 22)
        button.image = image
    } else if let image = NSImage(
        systemSymbolName: "doc.on.clipboard",
        accessibilityDescription: "AutoClip")
    {
        // Fallback to SF Symbol if resource missing
        image.isTemplate = true
        button.image = image
    }
}

let delegate = AppDelegate()
delegate.statusItem = statusItem
app.delegate = delegate
app.run()
