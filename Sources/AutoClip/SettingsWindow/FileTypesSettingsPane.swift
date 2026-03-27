import Cocoa
import SwiftUI

struct FileTypesSettingsView: View {
    @ObservedObject var viewModel: FileTypesViewModel

    init(preferences: PreferencesManager) {
        self.viewModel = FileTypesViewModel(preferences: preferences)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch for")
                .font(.headline)

            Picker("", selection: $viewModel.watchAllFiles) {
                Text("All files").tag(true)
                Text("Only specific extensions").tag(false)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            if !viewModel.watchAllFiles {
                FlowLayout(spacing: 6) {
                    ForEach(viewModel.sortedExtensions, id: \.self) {
                        ext in
                        ExtensionChip(
                            ext: ext,
                            onRemove: {
                                viewModel.removeExtension(ext)
                            })
                    }
                }
                .frame(minHeight: 30)

                HStack {
                    TextField("e.g. png", text: $viewModel.newExtension)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onSubmit { viewModel.addExtension() }

                    Button("Add") { viewModel.addExtension() }
                        .disabled(
                            viewModel.newExtension
                                .trimmingCharacters(in: .whitespaces)
                                .isEmpty)

                    Spacer()

                    Button("Reset to Defaults") {
                        viewModel.resetExtensions()
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 450, height: 250, alignment: .topLeading)
    }
}

// MARK: - Extension Chip

private struct ExtensionChip: View {
    let ext: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(".\(ext)")
                .font(.system(.body, design: .monospaced))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(6)
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y),
                proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews)
        -> (size: CGSize, positions: [CGPoint])
    {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (
            size: CGSize(width: maxWidth, height: y + rowHeight),
            positions: positions
        )
    }
}

// MARK: - ViewModel

class FileTypesViewModel: ObservableObject {
    @Published var watchAllFiles: Bool {
        didSet { preferences.watchAllFiles = watchAllFiles }
    }
    @Published var extensionSet: Set<String>
    @Published var newExtension = ""

    var sortedExtensions: [String] {
        extensionSet.sorted()
    }

    private let preferences: PreferencesManager

    init(preferences: PreferencesManager) {
        self.preferences = preferences
        self.watchAllFiles = preferences.watchAllFiles
        self.extensionSet = preferences.extensions
    }

    func addExtension() {
        let ext = newExtension
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
        guard !ext.isEmpty else { return }
        extensionSet.insert(ext)
        preferences.extensions = extensionSet
        newExtension = ""
    }

    func removeExtension(_ ext: String) {
        extensionSet.remove(ext)
        preferences.extensions = extensionSet
    }

    func resetExtensions() {
        extensionSet = PreferencesManager.defaultExtensions
        preferences.extensions = extensionSet
    }
}
