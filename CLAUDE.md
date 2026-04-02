## Architecture

- **Build**: SPM (`Package.swift`) + `Makefile` for app bundle assembly
- **Entry point**: `Sources/AutoClip/main.swift` — creates NSApplication,
  status item, and AppDelegate manually (no storyboard/SwiftUI App)
- **Menu bar only**: `LSUIElement = true` in `Info.plist`, no Dock icon
- **File watching**: kqueue via `DispatchSource.makeFileSystemObjectSource`
  in `DirectoryWatcher.swift` — zero CPU while idle
- **Settings UI**: `sindresorhus/Settings` library (SwiftUI panes)
- **Auto-update**: Sparkle framework, appcast at GitHub Pages
- **Signing**: ad-hoc locally (`codesign -f -s -`), Developer ID + notarization in CI

## Workflow

- Open GitHub issues for larger pieces of work before starting
- Use draft PRs (`gh pr create --draft`) for all changes

## Dev Commands

See `Makefile` for available targets.
