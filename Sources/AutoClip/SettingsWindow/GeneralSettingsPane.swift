import Cocoa
import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: GeneralViewModel

    init(preferences: PreferencesManager) {
        self.viewModel = GeneralViewModel(preferences: preferences)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watched Folders")
                .font(.headline)

            List(viewModel.directories, id: \.self) { dir in
                HStack {
                    Image(systemName: "folder")
                    Text(viewModel.abbreviatePath(dir))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(height: 120)

            HStack {
                Button(action: viewModel.addDirectory) {
                    Image(systemName: "plus")
                }
                Button(action: viewModel.removeSelected) {
                    Image(systemName: "minus")
                }
                .disabled(viewModel.directories.count <= 1)
            }

            Divider()

            Toggle("Start at Login", isOn: $viewModel.startAtLogin)

            Divider()

            HStack {
                Text("Notifications")
                    .font(.headline)
                Spacer()
                Button("Open in System Settings\u{2026}") {
                    // Deep link to notification settings for this app
                    let bundleId = Bundle.main.bundleIdentifier ?? ""
                    let url = URL(
                        string:
                            "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleId)"
                    )!
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()

            HStack {
                Text("Recent files to show")
                Spacer()
                Picker("", selection: $viewModel.maxRecentFiles) {
                    Text("3").tag(3)
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("20").tag(20)
                }
                .labelsHidden()
                .frame(width: 70)
            }
        }
        .padding(20)
        .frame(width: 450, height: 380, alignment: .topLeading)
    }
}

// MARK: - ViewModel

class GeneralViewModel: ObservableObject {
    @Published var directories: [String]
    @Published var startAtLogin: Bool {
        didSet { preferences.startAtLogin = startAtLogin }
    }
    @Published var maxRecentFiles: Int {
        didSet { preferences.maxRecentFiles = maxRecentFiles }
    }

    private let preferences: PreferencesManager

    init(preferences: PreferencesManager) {
        self.preferences = preferences
        self.directories = preferences.watchDirectories
        self.startAtLogin = preferences.startAtLogin
        self.maxRecentFiles = preferences.maxRecentFiles
    }

    func addDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to watch"

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            if !directories.contains(path) {
                directories.append(path)
                preferences.watchDirectories = directories
            }
        }
    }

    func removeSelected() {
        guard directories.count > 1 else { return }
        directories.removeLast()
        preferences.watchDirectories = directories
    }

    func abbreviatePath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
