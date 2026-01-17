import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddWorktree = false
    @State private var showHelp = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: Repository list
            RepositorySidebar()
        } detail: {
            // Main content: Worktree list
            if store.selectedRepository != nil {
                WorktreeList()
            } else {
                EmptyStateView()
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showHelp = true
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .help("Show help")

                if store.selectedRepository != nil {
                    Button {
                        showAddWorktree = true
                    } label: {
                        Label("New Worktree", systemImage: "plus")
                    }
                    .help("Create new worktree")

                    Button {
                        Task { await store.refreshWorktrees() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Refresh worktree list")
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
        }
        .sheet(isPresented: $showAddWorktree) {
            AddWorktreeSheet()
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
        .environmentObject(AppStore())
}
