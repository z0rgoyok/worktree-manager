import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddWorktree = false
    @State private var showAddRepository = false
    @State private var showCreatePR = false
    @State private var showFinishWorktree = false
    @State private var showHelp = false
    @State private var sidebarSelection: SidebarSelection?

    var body: some View {
        NavigationSplitView {
            ProjectTreeSidebar(selection: $sidebarSelection)
                .frame(minWidth: DS.Sizes.sidebarMinWidth)
                .navigationSplitViewColumnWidth(
                    min: DS.Sizes.sidebarMinWidth,
                    ideal: DS.Sizes.sidebarIdealWidth,
                    max: DS.Sizes.sidebarMaxWidth
                )
        } detail: {
            KanbanBoard(selection: sidebarSelection)
                .frame(minWidth: 600)
        }
        .frame(minWidth: 900, minHeight: 550)
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if store.selectedRepository != nil {
                    Button {
                        showAddWorktree = true
                    } label: {
                        Label("New Worktree", systemImage: "plus.square.on.square")
                    }
                    .help("New Worktree... (⌘N)")

                    if store.selectedWorktree != nil {
                        Button {
                            if let wt = store.selectedWorktree {
                                store.openInFinder(wt)
                            }
                        } label: {
                            Label("Finder", systemImage: "folder")
                        }
                        .help("Show in Finder (⇧⌘F)")

                        Button {
                            if let wt = store.selectedWorktree {
                                store.openInTerminal(wt)
                            }
                        } label: {
                            Label("Terminal", systemImage: "terminal")
                        }
                        .help("Open in Terminal (⇧⌘T)")
                    }

                    Button {
                        Task { await store.refreshWorktrees() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Refresh (⌘R)")
                }
            }
        }
        // Sheets
        .sheet(isPresented: $showAddWorktree) {
            AddWorktreeSheet()
        }
        .sheet(isPresented: $showAddRepository) {
            AddRepositorySheet()
        }
        .sheet(isPresented: $showCreatePR) {
            if let worktree = store.selectedWorktree {
                CreatePRSheet(worktree: worktree)
            }
        }
        .sheet(isPresented: $showFinishWorktree) {
            if let worktree = store.selectedWorktree {
                CompleteWorktreeSheet(
                    worktree: worktree,
                    statusCell: store.statusStore.cell(forWorktreePath: worktree.path)
                )
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .alert("Error", isPresented: $store.showError) {
            Button("OK") {
                store.clearError()
            }
        } message: {
            Text(store.error ?? "Unknown error")
        }
        // Sync selection with store
        .onChange(of: sidebarSelection) { _, newSelection in
            if let selection = newSelection {
                Task {
                    if store.selectedRepository?.id != selection.repository.id {
                        await store.selectRepository(selection.repository)
                    }
                    // Sync selected worktree
                    if case .worktree(let wt, _) = selection {
                        store.selectedWorktree = wt
                    } else {
                        store.selectedWorktree = nil
                    }
                }
            } else {
                store.selectedWorktree = nil
            }
        }
        .onAppear {
            if let repo = store.selectedRepository {
                sidebarSelection = .repository(repo)
            }
        }
        // Handle notifications from menu commands
        .onReceive(NotificationCenter.default.publisher(for: .showAddWorktree)) { _ in
            showAddWorktree = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddRepository)) { _ in
            showAddRepository = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showCreatePR)) { _ in
            showCreatePR = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFinishWorktree)) { _ in
            showFinishWorktree = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showHelp)) { _ in
            showHelp = true
        }
    }

    private var navigationTitle: String {
        if let worktree = store.selectedWorktree {
            return worktree.name
        } else if let repo = store.selectedRepository {
            return repo.name
        }
        return "Worktree Manager"
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Repository Selected")
                .font(.title2)
                .fontWeight(.medium)

            Text("Add a repository from the sidebar to manage its worktrees")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore.makeDefault())
}
