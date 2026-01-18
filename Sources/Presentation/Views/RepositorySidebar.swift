import SwiftUI

struct RepositorySidebar: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddRepo = false
    @State private var repositoryForCopySettings: Repository?

    var body: some View {
        List(selection: Binding(
            get: { store.selectedRepository },
            set: { repo in
                if let repo = repo {
                    Task { await store.selectRepository(repo) }
                }
            }
        )) {
            Section("Repositories") {
                ForEach(store.repositories) { repo in
                    RepositoryRow(repository: repo)
                        .tag(repo)
                        .contextMenu {
                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repo.path)
                            }

                            Button {
                                repositoryForCopySettings = repo
                            } label: {
                                Label("Copy Files Settings...", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Button("Remove from List", role: .destructive) {
                                Task { await store.removeRepository(repo) }
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddRepo = true
                } label: {
                    Label("Add Repository", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddRepo) {
            AddRepositorySheet()
        }
        .sheet(item: $repositoryForCopySettings) { repo in
            RepositoryCopyPatternsSheet(repository: repo, store: store)
        }
    }
}

struct RepositoryRow: View {
    let repository: Repository

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(repository.name)
                    .fontWeight(.medium)

                Text(repository.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddRepositorySheet: View {
    @EnvironmentObject var store: AppStore
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
                    Task { await store.addRepository(at: path) }
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

#Preview {
    RepositorySidebar()
        .environmentObject(AppStore())
}
