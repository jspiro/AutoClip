import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Status item must be created at top level — survives the full app lifecycle
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
if let button = statusItem.button {
    if let image = NSImage(
        systemSymbolName: "doc.on.clipboard",
        accessibilityDescription: "AutoClip")
    {
        image.isTemplate = true
        button.image = image
    } else {
        button.title = "CW"
    }
}

let delegate = AppDelegate()
delegate.statusItem = statusItem
app.delegate = delegate
app.run()
