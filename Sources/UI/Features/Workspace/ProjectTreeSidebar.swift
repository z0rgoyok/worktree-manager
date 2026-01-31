import SwiftUI

/// Native tree sidebar showing projects with worktrees nested inside
struct ProjectTreeSidebar: View {
    @EnvironmentObject var store: AppStore
    @Binding var selection: SidebarSelection?
    @State private var showAddRepo = false
    @State private var expandedRepositories: Set<UUID> = []
    @State private var repositoryForCopySettings: Repository?
    @State private var worktreesCache: [UUID: [Worktree]] = [:]  // repo.id -> worktrees
    @State private var loadingRepositories: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Projects")
                    .font(DS.Typography.sectionHeader)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    showAddRepo = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Add Repository")
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)

            Divider()

            // Tree content
            if store.repositories.isEmpty {
                // Empty state
                VStack(spacing: DS.Spacing.lg) {
                    Spacer()

                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(DS.Colors.textQuaternary)

                    VStack(spacing: DS.Spacing.sm) {
                        Text("No Projects")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textSecondary)

                        Text("Add a git repository to get started")
                            .font(.subheadline)
                            .foregroundStyle(DS.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        showAddRepo = true
                    } label: {
                        Label("Add Repository", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.repositories) { repo in
                            ProjectTreeNode(
                                repository: repo,
                                selection: $selection,
                                isExpanded: Binding(
                                    get: { expandedRepositories.contains(repo.id) },
                                    set: { expanded in
                                        if expanded {
                                            expandedRepositories.insert(repo.id)
                                            // Load worktrees when expanding
                                            if worktreesCache[repo.id] == nil {
                                                loadWorktrees(for: repo)
                                            }
                                        } else {
                                            expandedRepositories.remove(repo.id)
                                        }
                                    }
                                ),
                                worktrees: worktrees(for: repo),
                                isLoadingWorktrees: isLoading(repo: repo),
                                onCopySettings: { repositoryForCopySettings = repo }
                            )
                        }
                    }
                    .padding(.vertical, DS.Spacing.xs)
                }
            }
        }
        .frame(minWidth: DS.Sizes.sidebarMinWidth)
        .background(DS.Colors.surfacePrimary)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    NotificationCenter.default.post(name: .showHelp, object: nil)
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .help("Show help")
            }
        }
        .sheet(isPresented: $showAddRepo) {
            AddRepositorySheet()
        }
        .sheet(item: $repositoryForCopySettings) { repo in
            RepositoryCopyPatternsSheet(repository: repo, store: store)
        }
        .onAppear {
            initializeSelection()
        }
        .onChange(of: store.repositories) { _, repos in
            // Drop expansion state for repositories that no longer exist.
            expandedRepositories = expandedRepositories.intersection(Set(repos.map(\.id)))

            if selection == nil, let repo = store.selectedRepository {
                selection = .repository(repo)
            }
        }
        .onChange(of: store.selectedRepository) { _, repo in
            // Sync external selection changes
            if let repo = repo, selection?.repository.id != repo.id {
                selection = .repository(repo)
                expandedRepositories.insert(repo.id)
                if worktreesCache[repo.id] == nil {
                    loadWorktrees(for: repo)
                }
            }
        }
        .onChange(of: store.worktrees) { _, worktrees in
            // Sync worktrees cache for selected repository
            if let repo = store.selectedRepository {
                withAnimation(DS.Animation.quick) {
                    worktreesCache[repo.id] = worktrees
                    loadingRepositories.remove(repo.id)
                }
            }
        }
        .onChange(of: selection) { _, newSelection in
            // Auto-expand when selecting a worktree
            if let sel = newSelection {
                expandedRepositories.insert(sel.repository.id)
                if worktreesCache[sel.repository.id] == nil {
                    loadWorktrees(for: sel.repository)
                }
            }
        }
    }

    private func worktrees(for repo: Repository) -> [Worktree] {
        // Return cached worktrees for this repo
        return worktreesCache[repo.id] ?? []
    }

    private func isLoading(repo: Repository) -> Bool {
        loadingRepositories.contains(repo.id)
    }

    private func loadWorktrees(for repo: Repository) {
        guard !loadingRepositories.contains(repo.id) else { return }

        loadingRepositories.insert(repo.id)

        Task {
            // Use store's git client to load worktrees without changing selection
            if store.selectedRepository?.id == repo.id {
                // Selected repository: rely on the store's selected worktrees (loaded elsewhere),
                // and keep a loading placeholder until they arrive.
                if !store.worktrees.isEmpty {
                    await MainActor.run {
                        withAnimation(DS.Animation.quick) {
                            worktreesCache[repo.id] = store.worktrees
                            loadingRepositories.remove(repo.id)
                        }
                    }
                }
            } else {
                // Load independently without changing selection
                let loadedWorktrees = await store.loadWorktreesOnly(for: repo)
                await MainActor.run {
                    withAnimation(DS.Animation.quick) {
                        worktreesCache[repo.id] = loadedWorktrees
                        loadingRepositories.remove(repo.id)
                    }
                }
            }
        }
    }

    private func initializeSelection() {
        if let sel = selection {
            expandedRepositories.insert(sel.repository.id)
            if worktreesCache[sel.repository.id] == nil {
                loadWorktrees(for: sel.repository)
            }
            return
        }

        if let repo = store.selectedRepository {
            selection = .repository(repo)
            expandedRepositories.insert(repo.id)
            if worktreesCache[repo.id] == nil {
                loadWorktrees(for: repo)
            }
        }
    }
}

#Preview {
    ProjectTreeSidebar(selection: .constant(nil))
        .environmentObject(AppStore.makeDefault())
        .frame(width: 280, height: 500)
}
