# AutoClip

A macOS menu bar app that watches folders for new files and automatically copies them to the clipboard — both the **file** (for pasting into Finder, Slack, etc.) and the **full path** (for `pbpaste` in the terminal).

By default it watches your screenshot folder. Zero CPU usage between events.

## How it works

- Uses `DispatchSource` (kqueue) to watch one or more directories
- The process sleeps until the OS signals a new file — no polling
- When a matching file appears, copies it to the clipboard and shows a notification
- Menu bar icon with recent files, preferences, and quick re-copy
- Runs as a background app — no Dock icon, no Cmd+Tab

## Install

### From source

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/jspiro/AutoClip.git
cd AutoClip
make install
```

Then open `~/Applications/AutoClip.app`.

To start on login: **System Settings > General > Login Items > "+" > select AutoClip.app**, or toggle "Start at Login" in AutoClip's preferences.

### From release

Download the latest `.app` from [Releases](https://github.com/jspiro/AutoClip/releases), move it to `~/Applications/`, and open it.

## Usage

Take a screenshot (`Cmd+Shift+3`, `Cmd+Shift+4`, or `Cmd+Shift+5`), or add a file to a watched folder. AutoClip handles the rest:

- **`pbpaste`** in terminal returns the full file path
- **`Cmd+V` in Finder** pastes a copy of the file
- **`Cmd+V` in Slack, Notes, etc.** pastes the image
- Click the menu bar icon to see recent files and re-copy any of them

## Preferences

Click the menu bar icon > **Preferences** (or double-click AutoClip.app while running):

- **General** — watched folders (+/-), start at login, notification settings, recent file count
- **File Types** — watch all files, or only specific extensions
- **About** — version, contribute, report a bug

Settings can also be configured via `defaults write`:

```sh
# Custom directories
defaults write net.lostinrecursion.AutoClip WatchDirectories -array \
  ~/Pictures/Screenshots \
  ~/Downloads

# Custom extensions (when not using "All files")
defaults write net.lostinrecursion.AutoClip Extensions -array png jpg pdf

# Reset everything
defaults delete net.lostinrecursion.AutoClip
```

## Uninstall

```sh
make uninstall
```

Or manually: remove from Login Items, then delete `~/Applications/AutoClip.app`.

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools (to build from source)

## License

MIT
