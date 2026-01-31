import SwiftUI

struct GeneralSettingsView: View {
    @Binding var worktreeBasePath: String

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Worktrees Location", text: $worktreeBasePath)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        selectFolder()
                    }
                }

                Text("New worktrees will be created in subdirectories here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select worktrees location"

        if panel.runModal() == .OK, let url = panel.url {
            worktreeBasePath = url.path
        }
    }
}

