import SwiftUI

struct RepositorySidebar: View {
    @EnvironmentObject var root: RootComponent
    @EnvironmentObject var workspace: WorkspaceComponent
    @State private var repositoryForCopySettings: Repository?
    @State private var isArchivedSectionExpanded: Bool = false

    private var activeRepositories: [Repository] {
        workspace.state.repositories.filter { !$0.isArchived }
    }

    private var archivedRepositories: [Repository] {
        workspace.state.repositories.filter { $0.isArchived }
    }

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
                ForEach(activeRepositories) { repo in
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

                            Button {
                                Task { await workspace.archiveRepository(repo) }
                            } label: {
                                Label("Archive Project", systemImage: "archivebox")
                            }

                            Divider()

                            Button("Remove from List", role: .destructive) {
                                Task { await workspace.removeRepository(repo) }
                            }
                        }
                }
            }

            if !archivedRepositories.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $isArchivedSectionExpanded) {
                        ForEach(archivedRepositories) { repo in
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

                                    Button {
                                        Task { await workspace.restoreRepository(repo) }
                                    } label: {
                                        Label("Restore Project", systemImage: "arrow.uturn.left")
                                    }

                                    Divider()

                                    Button("Remove from List", role: .destructive) {
                                        Task { await workspace.removeRepository(repo) }
                                    }
                                }
                        }
                    } label: {
                        Label("Archived", systemImage: "archivebox")
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
        .onAppear {
            syncArchivedSectionVisibility()
        }
        .onChange(of: workspace.state.selectedRepository) { _, _ in
            syncArchivedSectionVisibility()
        }
    }

    private func syncArchivedSectionVisibility() {
        guard let selected = workspace.state.selectedRepository else { return }
        if selected.isArchived {
            isArchivedSectionExpanded = true
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
