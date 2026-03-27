# AutoClip

A tiny macOS app that watches folders for new files and automatically copies them to the clipboard — both the **file** (for pasting into Finder, Slack, etc.) and the **full path** (for `pbpaste` in the terminal).

By default it watches your screenshot folder. Zero CPU usage between events.

## How it works

- Uses `DispatchSource` (kqueue) to watch one or more directories
- The process sleeps until the OS signals a new file — no polling
- When a matching file appears, it puts the file URL + text path on the clipboard and shows a notification
- Runs as an `LSUIElement` — no Dock icon, no window, just a background process

## Install

### From source

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/jspiro/AutoClip.git
cd AutoClip
make install
```

Then open `~/Applications/AutoClip.app` and approve the Desktop access prompt if shown.

To start on login: **System Settings > General > Login Items > "+" > select AutoClip.app**

### From release

Download the latest `.app` from [Releases](https://github.com/jspiro/AutoClip/releases), move it to `~/Applications/`, and open it.

## Usage

Take a screenshot (`Cmd+Shift+3`, `Cmd+Shift+4`, or `Cmd+Shift+5`), or drop a file into a watched folder. AutoClip handles the rest:

- **`pbpaste`** in terminal returns the full file path
- **`Cmd+V` in Finder** pastes a copy of the file
- **`Cmd+V` in Slack, Notes, etc.** pastes the image

## Configuration

### Watch directories

By default, AutoClip watches your macOS screenshot save location (from `com.apple.screencapture`, usually `~/Desktop`).

To watch custom directories:

```sh
defaults write net.lostinrecursion.AutoClip WatchDirectories -array \
  ~/Desktop/Screenshots \
  ~/Downloads
```

### File extensions

By default: `png`, `jpg`, `jpeg`, `tiff`, `heic`, `gif`, `webp`, `pdf`, `mov`, `mp4`.

To customize:

```sh
defaults write net.lostinrecursion.AutoClip Extensions -array png jpg pdf
```

### Reset to defaults

```sh
defaults delete net.lostinrecursion.AutoClip
```

## Uninstall

```sh
make uninstall
```

Or manually:

1. Remove from Login Items in System Settings
2. Delete `~/Applications/AutoClip.app`

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools (to build from source)

## License

MIT
