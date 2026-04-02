import Cocoa
import Sparkle
import SwiftUI

struct AboutSettingsView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        as? String ?? "1.0.0"
    private let repoURL = "https://github.com/jspiro/AutoClip"
    private let updaterController: SPUStandardUpdaterController

    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
    }

    var body: some View {
        VStack(spacing: 20) {
            // App info
            VStack(spacing: 8) {
                // App icon from bundle
                if let nsImage = NSApp.applicationIconImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                }

                Text("AutoClip")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version \(version)")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)

            Divider()

            // Actions
            HStack(spacing: 12) {
                Button("Quit AutoClip") {
                    NSApplication.shared.terminate(nil)
                }
                Spacer()
                Button("Check for Updates") {
                    updaterController.checkForUpdates(nil)
                }
                Button("Contribute") {
                    NSWorkspace.shared.open(
                        URL(string: repoURL)!)
                }
                Button("Report a Bug") {
                    NSWorkspace.shared.open(
                        URL(string: "\(repoURL)/issues/new")!)
                }
            }
        }
        .padding(20)
        .frame(width: 580, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
    }
}
