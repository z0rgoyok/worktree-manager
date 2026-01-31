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
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(repo.path, forType: .string)
                            } label: {
                                Label("Copy Path", systemImage: "doc.on.doc")
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

#Preview {
    RepositorySidebar()
        .environmentObject(AppStore.makeDefault())
}
