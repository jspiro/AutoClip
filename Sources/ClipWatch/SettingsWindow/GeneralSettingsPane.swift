import Cocoa
import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: GeneralViewModel

    init(preferences: PreferencesManager) {
        self.viewModel = GeneralViewModel(preferences: preferences)
    }

    var body: some View {
        Form {
            Section("Watched Folders") {
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
            }

            Section {
                Toggle("Start at Login", isOn: $viewModel.startAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 280)
    }
}

// MARK: - ViewModel

class GeneralViewModel: ObservableObject {
    @Published var directories: [String]
    @Published var startAtLogin: Bool {
        didSet { preferences.startAtLogin = startAtLogin }
    }

    private let preferences: PreferencesManager

    init(preferences: PreferencesManager) {
        self.preferences = preferences
        self.directories = preferences.watchDirectories
        self.startAtLogin = preferences.startAtLogin
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
