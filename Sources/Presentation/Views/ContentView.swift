import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddWorktree = false
    @State private var showHelp = false
    @State private var sidebarSelection: SidebarSelection?
    @State private var sidebarWidth: CGFloat = DS.Sizes.sidebarIdealWidth

    var body: some View {
        HSplitView {
            // Left: Project tree sidebar
            ProjectTreeSidebar(selection: $sidebarSelection)
                .frame(minWidth: DS.Sizes.sidebarMinWidth, maxWidth: DS.Sizes.sidebarMaxWidth)

            // Right: Kanban board
            KanbanBoard(selection: sidebarSelection)
                .frame(minWidth: 600)
        }
        .frame(minWidth: 900, minHeight: 550)
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
                        Label("New Worktree", systemImage: "plus.square.on.square")
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
        .onChange(of: sidebarSelection) { _, newSelection in
            // Sync selection with store
            if let selection = newSelection {
                Task {
                    if store.selectedRepository?.id != selection.repository.id {
                        await store.selectRepository(selection.repository)
                    }
                }
            }
        }
        .onAppear {
            // Initialize selection from store
            if let repo = store.selectedRepository {
                sidebarSelection = .repository(repo)
            }
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
