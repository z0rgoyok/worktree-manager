import SwiftUI

struct RepositorySidebar: View {
    @EnvironmentObject var root: RootComponent
    @EnvironmentObject var workspace: WorkspaceComponent
    @State private var repositoryForCopySettings: Repository?

    var body: some View {
        List(selection: Binding(
            get: { workspace.state.selectedRepository },
            set: { repo in
                if let repo {
                    workspace.send(.setSidebarSelection(.repository(repo)), root: root)
                }
            }
        )) {
            Section("Repositories") {
                ForEach(workspace.state.repositories) { repo in
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
                                Task { await workspace.removeRepository(repo) }
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
                    root.send(.presentSheet(.addRepository))
                } label: {
                    Label("Add Repository", systemImage: "plus")
                }
            }
        }
        .sheet(item: $repositoryForCopySettings) { repo in
            RepositoryCopyPatternsSheet(repository: repo)
        }
    }
}

#Preview {
    let root = RootComponent.makeDefault(loadOnInit: false)
    return RepositorySidebar()
        .environmentObject(root)
        .environmentObject(root.workspace)
        .environmentObject(root.settings)
}
