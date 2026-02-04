import SwiftUI
import AppKit

/// Native tree sidebar showing projects with worktrees nested inside
struct ProjectTreeSidebar: View {
    @EnvironmentObject var root: RootComponent
    @EnvironmentObject var workspace: WorkspaceComponent
    @Binding var selection: SidebarSelection?
    @State private var expandedRepositories: Set<UUID> = []
    @State private var pendingExpandedRepositoryIds: Set<UUID> = []
    @State private var isArchivedSectionExpanded: Bool = false
    @State private var repositoryForCopySettings: Repository?
    @State private var worktreesCache: [UUID: [Worktree]] = [:]  // repo.id -> worktrees
    @State private var loadingRepositories: Set<UUID> = []
    @State private var loadWorktreesRequestIdByRepositoryId: [UUID: UInt64] = [:]
    @State private var loadWorktreesTaskByRepositoryId: [UUID: Task<Void, Never>] = [:]
    @State private var backgroundPrefetchTask: Task<Void, Never>?
    @State private var backgroundPrefetchRequestId: UInt64 = 0
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
                scheduleBackgroundPrefetch(for: activeRepositories)
            }
            .onChange(of: expandedRepositories) { _, expanded in
                workspace.setExpandedRepositoryIds(expanded)
                cancelWorktreeLoadsForCollapsedRepositories()
            }
            .onChange(of: workspace.state.repositories) { _, repos in
                // Drop expansion state for repositories that no longer exist.
                let repoIds = Set(repos.map(\.id))
                let filtered = expandedRepositories.intersection(repoIds)
                if filtered != expandedRepositories {
                    expandedRepositories = filtered
                }
                restoreExpandedRepositoriesIfNeeded()
                scheduleBackgroundPrefetch(for: activeRepositories)

                if selection == nil, let repo = workspace.state.selectedRepository {
                    selection = .repository(repo)
                }
            }
            .onChange(of: workspace.state.selectedRepository) { _, repo in
                // Sync external selection changes
                if let repo = repo, selection?.repository.id != repo.id {
                    selection = .repository(repo)
                }
                ensureArchivedSectionVisibility(for: selection)
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
                ensureArchivedSectionVisibility(for: newSelection)
            }
    }

    private var activeRepositories: [Repository] {
        workspace.state.repositories.filter { !$0.isArchived }
    }

    private var archivedRepositories: [Repository] {
        workspace.state.repositories.filter { $0.isArchived }
    }

    private var visibleRepositories: [Repository] {
        if isArchivedSectionExpanded {
            return activeRepositories + archivedRepositories
        }
        return activeRepositories
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
        let repos = visibleRepositories
        guard !repos.isEmpty else { return false }
        let visibleIds = Set(repos.map(\.id))
        return expandedRepositories.intersection(visibleIds).count == visibleIds.count
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
                    ForEach(activeRepositories) { repo in
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

                    if !archivedRepositories.isEmpty {
                        archivedSectionHeader

                        if isArchivedSectionExpanded {
                            ForEach(archivedRepositories) { repo in
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

    private var archivedSectionHeader: some View {
        Button {
            if isArchivedSectionExpanded, isSelectionWithinArchivedSection {
                return
            }
            withAnimation(DS.Animation.quick) {
                isArchivedSectionExpanded.toggle()
            }
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: isArchivedSectionExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .frame(width: DS.Sizes.treeIconSize, height: DS.Sizes.treeIconSize)

                Image(systemName: "archivebox")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .frame(width: DS.Sizes.treeIconSize)

                Text("Archived")
                    .font(DS.Typography.sectionHeader)
                    .foregroundStyle(DS.Colors.textSecondary)

                Spacer()

                Text("\(archivedRepositories.count)")
                    .font(DS.Typography.badge)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, DS.Spacing.xxxs)
                    .background(DS.Colors.surfaceSecondary)
                    .cornerRadius(DS.Radius.xs)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .frame(height: DS.Sizes.treeRowHeight)
            .background(DS.Colors.surfacePrimary)
            .cornerRadius(DS.Radius.sm)
            .padding(.horizontal, DS.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isArchivedSectionExpanded ? "Hide archived projects" : "Show archived projects")
        .padding(.top, DS.Spacing.xs)
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
                    cancelWorktreeLoad(forRepositoryId: repo.id)
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
        guard expandedRepositories.contains(repo.id) else { return }
        guard !loadingRepositories.contains(repo.id) else { return }

        let nextRequestId = (loadWorktreesRequestIdByRepositoryId[repo.id] ?? 0) &+ 1
        loadWorktreesRequestIdByRepositoryId[repo.id] = nextRequestId
        let requestId = nextRequestId

        loadingRepositories.insert(repo.id)

        let repoId = repo.id
        let task = Task {
            // Use store's git client to load worktrees without changing selection
            if workspace.state.selectedRepository?.id == repoId {
                // Selected repository: rely on the store's selected worktrees (loaded elsewhere),
                // and keep a loading placeholder until they arrive.
                if workspace.state.worktrees.isEmpty {
                    await MainActor.run {
                        guard expandedRepositories.contains(repoId) else { return }
                        guard loadWorktreesRequestIdByRepositoryId[repoId] == requestId else { return }
                        loadWorktreesTaskByRepositoryId.removeValue(forKey: repoId)
                    }
                    return
                }

                await MainActor.run {
                    withAnimation(DS.Animation.quick) {
                        guard expandedRepositories.contains(repoId) else { return }
                        guard loadWorktreesRequestIdByRepositoryId[repoId] == requestId else { return }

                        worktreesCache[repoId] = workspace.state.worktrees
                        loadingRepositories.remove(repoId)
                        loadWorktreesTaskByRepositoryId.removeValue(forKey: repoId)
                    }
                }
            } else {
                // Load independently without changing selection
                let loadedWorktrees = await workspace.loadWorktreesOnly(for: repo)
                await MainActor.run {
                    withAnimation(DS.Animation.quick) {
                        guard expandedRepositories.contains(repoId) else { return }
                        guard loadWorktreesRequestIdByRepositoryId[repoId] == requestId else { return }

                        worktreesCache[repoId] = loadedWorktrees
                        loadingRepositories.remove(repoId)
                        loadWorktreesTaskByRepositoryId.removeValue(forKey: repoId)
                    }
                }
            }
        }

        loadWorktreesTaskByRepositoryId[repo.id] = task
    }

    private func cancelWorktreeLoad(forRepositoryId id: UUID) {
        loadWorktreesRequestIdByRepositoryId[id] = (loadWorktreesRequestIdByRepositoryId[id] ?? 0) &+ 1
        loadWorktreesTaskByRepositoryId[id]?.cancel()
        loadWorktreesTaskByRepositoryId.removeValue(forKey: id)
        loadingRepositories.remove(id)
    }

    private func cancelWorktreeLoadsForCollapsedRepositories() {
        let expanded = expandedRepositories
        let idsToCancel = Set(loadWorktreesTaskByRepositoryId.keys).subtracting(expanded)
        for id in idsToCancel {
            cancelWorktreeLoad(forRepositoryId: id)
        }
    }

    private func initializeSelection() {
        if let sel = selection, SidebarAutoExpansionPolicy.shouldAutoExpandRepository(for: selection) {
            expandedRepositories.insert(sel.repository.id)
            if worktreesCache[sel.repository.id] == nil {
                loadWorktrees(for: sel.repository)
            }
            ensureArchivedSectionVisibility(for: sel)
            return
        }

        if let repo = workspace.state.selectedRepository {
            selection = .repository(repo)
        }

        ensureArchivedSectionVisibility(for: selection)
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

            expandedRepositories = Set(visibleRepositories.map(\.id))
        }

        ensureWorktreesLoadedForExpandedRepositories()
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let key = navigationKey(for: event) else { return false }

        let output = SidebarKeyboardNavigation.handle(
            key: key,
            selection: selection,
            repositories: visibleRepositories,
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

    private func scheduleBackgroundPrefetch(for repositories: [Repository]) {
        guard !repositories.isEmpty else {
            backgroundPrefetchTask?.cancel()
            backgroundPrefetchTask = nil
            return
        }

        backgroundPrefetchRequestId &+= 1
        let requestId = backgroundPrefetchRequestId

        backgroundPrefetchTask?.cancel()
        backgroundPrefetchTask = Task { @MainActor in
            // Allow the initial repository selection load to start first.
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard requestId == backgroundPrefetchRequestId else { return }

            for repo in repositories {
                if Task.isCancelled { return }
                guard requestId == backgroundPrefetchRequestId else { return }
                guard worktreesCache[repo.id] == nil else { continue }
                guard !loadingRepositories.contains(repo.id) else { continue }
                guard workspace.state.selectedRepository?.id != repo.id else { continue }

                let loadedWorktrees = await workspace.loadWorktreesOnly(for: repo)
                guard !Task.isCancelled else { return }
                guard requestId == backgroundPrefetchRequestId else { return }
                guard workspace.state.repositories.contains(where: { $0.id == repo.id }) else { continue }
                guard worktreesCache[repo.id] == nil else { continue }
                guard !loadedWorktrees.isEmpty else { continue }

                withAnimation(DS.Animation.quick) {
                    worktreesCache[repo.id] = loadedWorktrees
                }

                await Task.yield()
            }
        }
    }

    private func ensureArchivedSectionVisibility(for selection: SidebarSelection?) {
        guard let selection else { return }
        guard let repo = workspace.state.repositories.first(where: { $0.id == selection.repository.id }) else { return }
        if repo.isArchived, !isArchivedSectionExpanded {
            isArchivedSectionExpanded = true
        }
    }

    private var isSelectionWithinArchivedSection: Bool {
        guard let selection else { return false }
        guard let repo = workspace.state.repositories.first(where: { $0.id == selection.repository.id }) else { return false }
        return repo.isArchived
    }
}

#Preview {
    let root = RootComponent.makeDefault(loadOnInit: false)
    return ProjectTreeSidebar(selection: .constant(nil))
        .environmentObject(root)
        .environmentObject(root.workspace)
        .frame(width: 280, height: 500)
}
