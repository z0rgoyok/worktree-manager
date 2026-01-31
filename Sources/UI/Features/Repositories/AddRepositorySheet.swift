import SwiftUI

struct AddRepositorySheet: View {
    @EnvironmentObject var workspace: WorkspaceComponent
    @Environment(\.dismiss) var dismiss
    @State private var path = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Repository")
                .font(.headline)

            HStack {
                TextField("Repository Path", text: $path)
                    .textFieldStyle(.roundedBorder)

                Button("Browse...") {
                    selectFolder()
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    Task { await workspace.addRepository(at: path) }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(path.isEmpty)
            }
        }
        .padding()
        .frame(width: 450)
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a git repository"

        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
        }
    }
}
