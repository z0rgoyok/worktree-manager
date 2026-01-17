import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("worktreeBasePath") private var worktreeBasePath = ""
    @AppStorage("defaultEditorId") private var defaultEditorId = ""

    var body: some View {
        TabView {
            GeneralSettingsView(
                worktreeBasePath: $worktreeBasePath,
                defaultEditorId: $defaultEditorId,
                availableEditors: store.availableEditors()
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
        }
        .frame(width: 450, height: 300)
        .onAppear {
            if worktreeBasePath.isEmpty {
                worktreeBasePath = StorageService.shared.worktreeBasePath
            }
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var worktreeBasePath: String
    @Binding var defaultEditorId: String
    let availableEditors: [Editor]

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

            Section {
                Picker("Default Editor", selection: $defaultEditorId) {
                    Text("Always Ask").tag("")

                    ForEach(availableEditors) { editor in
                        Text(editor.name).tag(editor.id)
                    }
                }

                Text("The editor to open worktrees with by default")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: worktreeBasePath) { _, newValue in
            StorageService.shared.worktreeBasePath = newValue
        }
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

#Preview {
    SettingsView()
        .environmentObject(AppStore())
}
