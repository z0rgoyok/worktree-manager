import SwiftUI
import AppKit

/// Native tree sidebar showing projects with worktrees nested inside
struct ProjectTreeSidebar: View {
    @EnvironmentObject var root: RootComponent
    @EnvironmentObject var workspace: WorkspaceComponent
    @Binding var selection: SidebarSelection?
    @State private var expandedRepositories: Set<UUID> = []
    @State private var pendingExpandedRepositoryIds: Set<UUID> = []
    @State private var repositoryForCopySettings: Repository?
    @State private var worktreesCache: [UUID: [Worktree]] = [:]  // repo.id -> worktrees
    @State private var loadingRepositories: Set<UUID> = []
    @FocusState private var isKeyboardFocused: Bool

    var body: some View {
        content
            .frame(minWidth: DS.Sizes.sidebarMinWidth)
            .background(DS.Colors.surfacePrimary)
            .background(
                KeyDownHandlerView(isActive: isKeyboardFocused, onKeyDown: handleKeyDown)
            )
            .focusable(true)
            .focused($isKeyboardFocused)
            .simultaneousGesture(
                TapGesture().onEnded {
                    isKeyboardFocused = true
                }
            )
            .toolbar { sidebarToolbar }
            .sheet(item: $repositoryForCopySettings) { repo in
                RepositoryCopyPatternsSheet(repository: repo)
            }
            .onAppear {
                if pendingExpandedRepositoryIds.isEmpty {
                    pendingExpandedRepositoryIds = workspace.loadExpandedRepositoryIds()
                }
                restoreExpandedRepositoriesIfNeeded()
                initializeSelection()
                isKeyboardFocused = true
            }
            .onChange(of: expandedRepositories) { _, expanded in
                workspace.setExpandedRepositoryIds(expanded)
            }
            .onChange(of: workspace.state.repositories) { _, repos in
                // Drop expansion state for repositories that no longer exist.
                let repoIds = Set(repos.map(\.id))
                let filtered = expandedRepositories.intersection(repoIds)
                if filtered != expandedRepositories {
                    expandedRepositories = filtered
                }
                restoreExpandedRepositoriesIfNeeded()

                if selection == nil, let repo = workspace.state.selectedRepository {
                    selection = .repository(repo)
                }
            }
            .onChange(of: workspace.state.selectedRepository) { _, repo in
                // Sync external selection changes
                if let repo = repo, selection?.repository.id != repo.id {
                    selection = .repository(repo)
                }
            }
            .onChange(of: workspace.state.worktrees) { _, worktrees in
                // Sync worktrees cache for selected repository
                if let repo = workspace.state.selectedRepository {
                    withAnimation(DS.Animation.quick) {
                        worktreesCache[repo.id] = worktrees
                        loadingRepositories.remove(repo.id)
                    }
                }
            }
            .onChange(of: selection) { _, newSelection in
                // Auto-expand only when selecting a worktree (so the selection is visible).
                if let sel = newSelection, SidebarAutoExpansionPolicy.shouldAutoExpandRepository(for: newSelection) {
                    expandedRepositories.insert(sel.repository.id)
                    pendingExpandedRepositoryIds.remove(sel.repository.id)
                    if worktreesCache[sel.repository.id] == nil {
                        loadWorktrees(for: sel.repository)
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            header

            Divider()

            // Tree content
            if workspace.state.repositories.isEmpty {
                emptyState
            } else {
                repositoriesTree
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Projects")
                .font(DS.Typography.sectionHeader)
                .foregroundStyle(DS.Colors.textSecondary)
                .textCase(.uppercase)

            Spacer()

            HeaderIconButton(
                systemImage: shouldCollapseAllRepositories ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                help: shouldCollapseAllRepositories ? "Collapse All Projects" : "Expand All Projects",
                isDisabled: workspace.state.repositories.isEmpty,
                action: toggleAllRepositoriesExpansion
            )

            HeaderIconButton(
                systemImage: "plus",
                help: "Add Repository",
                isDisabled: false
            ) {
                root.send(.presentSheet(.addRepository))
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }

    private struct HeaderIconButton: View {
        let systemImage: String
        let help: String
        let isDisabled: Bool
        let action: () -> Void

        @State private var isHovered = false

        var body: some View {
            Button {
                action()
            } label: {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(isHovered && !isDisabled ? DS.Colors.surfaceSecondary : Color.clear)
                    .cornerRadius(DS.Radius.sm)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .help(help)
            .onHover { isHovered = $0 }
        }
    }

    private var shouldCollapseAllRepositories: Bool {
        let repos = workspace.state.repositories
        guard !repos.isEmpty else { return false }
        return expandedRepositories.count == repos.count
    }

    private var emptyState: some View {
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
                root.send(.presentSheet(.addRepository))
            } label: {
                Label("Add Repository", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var repositoriesTree: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(workspace.state.repositories) { repo in
                        ProjectTreeNode(
                            repository: repo,
                            selection: $selection,
                            isExpanded: expansionBinding(for: repo),
                            worktrees: worktrees(for: repo),
                            isLoadingWorktrees: isLoading(repo: repo),
                            onCopySettings: { repositoryForCopySettings = repo }
                        )
                        .id(AnyHashable(repo.id))
                    }
                }
                .padding(.vertical, DS.Spacing.xs)
            }
            .onChange(of: selection) { _, newSelection in
                guard let newSelection else { return }
                proxy.scrollTo(scrollId(for: newSelection), anchor: .center)
            }
        }
    }

    private var sidebarToolbar: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button {
                root.send(.presentSheet(.help))
            } label: {
                Label("Help", systemImage: "questionmark.circle")
            }
            .help("Show help")
        }
    }

    private func expansionBinding(for repo: Repository) -> Binding<Bool> {
        Binding(
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
        )
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
            if workspace.state.selectedRepository?.id == repo.id {
                // Selected repository: rely on the store's selected worktrees (loaded elsewhere),
                // and keep a loading placeholder until they arrive.
                if !workspace.state.worktrees.isEmpty {
                    await MainActor.run {
                        withAnimation(DS.Animation.quick) {
                            worktreesCache[repo.id] = workspace.state.worktrees
                            loadingRepositories.remove(repo.id)
                        }
                    }
                }
            } else {
                // Load independently without changing selection
                let loadedWorktrees = await workspace.loadWorktreesOnly(for: repo)
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
        if let sel = selection, SidebarAutoExpansionPolicy.shouldAutoExpandRepository(for: selection) {
            expandedRepositories.insert(sel.repository.id)
            if worktreesCache[sel.repository.id] == nil {
                loadWorktrees(for: sel.repository)
            }
            return
        }

        if let repo = workspace.state.selectedRepository {
            selection = .repository(repo)
        }
    }

    private func restoreExpandedRepositories() {
        let repoIds = Set(workspace.state.repositories.map(\.id))
        let available = pendingExpandedRepositoryIds.intersection(repoIds)
        if !available.isEmpty {
            expandedRepositories.formUnion(available)
            pendingExpandedRepositoryIds.subtract(available)
        }

        ensureWorktreesLoadedForExpandedRepositories()
    }

    private func restoreExpandedRepositoriesIfNeeded() {
        guard !workspace.state.repositories.isEmpty else { return }
        restoreExpandedRepositories()
    }

    private func ensureWorktreesLoadedForExpandedRepositories() {
        let expandedIds = expandedRepositories

        for id in expandedIds {
            guard worktreesCache[id] == nil else { continue }
            guard !loadingRepositories.contains(id) else { continue }
            guard let repo = workspace.state.repositories.first(where: { $0.id == id }) else { continue }
            loadWorktrees(for: repo)
        }
    }

    private func toggleAllRepositoriesExpansion() {
        pendingExpandedRepositoryIds.removeAll()

        withAnimation(DS.Animation.quick) {
            if shouldCollapseAllRepositories {
                expandedRepositories.removeAll()
                return
            }

            expandedRepositories = Set(workspace.state.repositories.map(\.id))
        }

        ensureWorktreesLoadedForExpandedRepositories()
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let key = navigationKey(for: event) else { return false }

        let output = SidebarKeyboardNavigation.handle(
            key: key,
            selection: selection,
            repositories: workspace.state.repositories,
            expandedRepositoryIds: expandedRepositories,
            worktreesByRepositoryId: worktreesCache
        )

        if output.expandedRepositoryIds != expandedRepositories {
            expandedRepositories = output.expandedRepositoryIds
        }

        for repoId in output.repositoryIdsToLoadWorktrees {
            guard let repo = workspace.state.repositories.first(where: { $0.id == repoId }) else { continue }
            loadWorktrees(for: repo)
        }

        selection = output.selection
        return true
    }

    private func navigationKey(for event: NSEvent) -> SidebarKeyboardNavigation.Key? {
        switch event.keyCode {
        case 126: return .up
        case 125: return .down
        case 123: return .left
        case 124: return .right
        case 49: return .space
        default: return nil
        }
    }

    private func scrollId(for selection: SidebarSelection) -> AnyHashable {
        switch selection {
        case .repository(let repo):
            return AnyHashable(repo.id)
        case .worktree(let worktree, _):
            return AnyHashable(worktree.id)
        }
    }
}

#Preview {
    let root = RootComponent.makeDefault(loadOnInit: false)
    return ProjectTreeSidebar(selection: .constant(nil))
        .environmentObject(root)
        .environmentObject(root.workspace)
        .frame(width: 280, height: 500)
}
