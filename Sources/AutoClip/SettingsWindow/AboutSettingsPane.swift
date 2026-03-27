import Cocoa
import SwiftUI

struct AboutSettingsView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        as? String ?? "1.0.0"
    private let repoURL = "https://github.com/jspiro/AutoClip"

    var body: some View {
        VStack(spacing: 20) {
            // App info
            VStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("AutoClip")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version \(version)")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)

            Divider()

            // Links
            HStack(spacing: 20) {
                Button("Quit AutoClip") {
                    NSApplication.shared.terminate(nil)
                }
                Spacer()
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
        .frame(width: 450, height: 250, alignment: .top)
    }
}
