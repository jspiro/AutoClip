# AutoClip

**Screenshot → clipboard → paste into AI tools in one step.**

AutoClip is a macOS menu bar app that watches folders for new files and
automatically copies them to the clipboard — both the **file** (for pasting
into Finder, Slack, etc.) and the **full path** (for `pbpaste` in the terminal).

Take a screenshot of your app, and it's instantly on your clipboard — ready to
paste into Claude Code (or any AI tool) for feedback, debugging, and iteration.
No manual file-finding, no drag-and-drop, no extra steps.

By default it watches your screenshot folder.

## Why

When you're iterating on a UI with an AI coding assistant, the loop is:

1. Make a change
2. Screenshot the result
3. **Find the screenshot file and get it to the AI**
4. Get feedback, repeat

Step 3 is friction. AutoClip eliminates it — your screenshot is on the
clipboard the instant it's saved. Just paste.

**Why not Cmd+Ctrl+Shift+4 (screenshot to clipboard)?** That gives you
image data, not a file — AI tools like Claude Code need a file path, and
you lose the screenshot after pasting. AutoClip saves the file *and* puts
it on the clipboard, so you keep a copy and can paste anywhere.

It's also great for your **Downloads folder** — drop a file in and
Cmd+Shift+V it into a conversation instantly.

## Install

### From release (recommended)

Download the latest `.zip` from
[Releases](https://github.com/jspiro/AutoClip/releases), unzip, move
`AutoClip.app` to `/Applications/`, and open it. Signed and notarized.

### From source

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/jspiro/AutoClip.git
cd AutoClip
make install
```

To start on login: toggle "Start at Login" in AutoClip's preferences, or add
it via **System Settings > General > Login Items**.

## How it works

- Uses `DispatchSource` (kqueue) to watch one or more directories
- The process sleeps until the OS signals a new file — no polling
- When a matching file appears, copies it to the clipboard and shows a
  notification
- Menu bar icon with recent files, preferences, and quick re-copy
- Automatic updates via Sparkle
- Runs as a background app — no Dock icon, no Cmd+Tab

## Usage

Take a screenshot (`Cmd+Shift+3`, `Cmd+Shift+4`, or `Cmd+Shift+5`), or add a
file to a watched folder. AutoClip handles the rest:

- **Paste into Claude Code** — screenshot is ready immediately
- **`pbpaste`** in terminal returns the full file path
- **`Cmd+V` in Finder** pastes a copy of the file
- **`Cmd+V` in Slack, Notes, etc.** pastes the image
- Click the menu bar icon to see recent files and re-copy any of them

## Preferences

Click the menu bar icon > **Preferences** (or reopen AutoClip while running):

- **General** — watched folders (+/-), start at login, notification settings,
  recent file count
- **File Types** — watch all files, or only specific extensions
- **About** — version, check for updates, contribute, report a bug

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools (to build from source)

## License

[PolyForm Shield 1.0.0](LICENSE) — free to use, modify, and share;
no competitive use.
