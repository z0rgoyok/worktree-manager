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
            // When repositories load, expand all and sync selection
            for repo in repos {
                expandedRepositories.insert(repo.id)
            }
            if selection == nil, let repo = store.selectedRepository {
                selection = .repository(repo)
            }
        }
        .onChange(of: store.selectedRepository) { _, repo in
            // Sync external selection changes
            if let repo = repo, selection?.repository.id != repo.id {
                selection = .repository(repo)
                expandedRepositories.insert(repo.id)
            }
        }
        .onChange(of: store.worktrees) { _, worktrees in
            // Sync worktrees cache for selected repository
            if let repo = store.selectedRepository {
                worktreesCache[repo.id] = worktrees
            }
        }
        .onChange(of: selection) { _, newSelection in
            // Auto-expand when selecting a worktree
            if let sel = newSelection {
                expandedRepositories.insert(sel.repository.id)
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
                // Already selected — use store's worktrees
                worktreesCache[repo.id] = store.worktrees
            } else {
                // Load independently without changing selection
                let loadedWorktrees = await store.loadWorktreesOnly(for: repo)
                worktreesCache[repo.id] = loadedWorktrees
            }
            loadingRepositories.remove(repo.id)
        }
    }

    private func initializeSelection() {
        // Auto-expand selected repository
        if let sel = selection {
            expandedRepositories.insert(sel.repository.id)
        }
        // Expand all by default for better UX
        for repo in store.repositories {
            expandedRepositories.insert(repo.id)
        }
        // Sync selection with store
        if selection == nil, let repo = store.selectedRepository {
            selection = .repository(repo)
        }
    }
}

// MARK: - Project Tree Node

struct ProjectTreeNode: View {
    @EnvironmentObject var store: AppStore
    let repository: Repository
    @Binding var selection: SidebarSelection?
    @Binding var isExpanded: Bool
    let worktrees: [Worktree]
    let isLoadingWorktrees: Bool
    let onCopySettings: () -> Void

    @State private var isHovered = false

    private var isRepoSelected: Bool {
        if case .repository(let r) = selection, r.id == repository.id {
            return true
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Repository row
            HStack(spacing: DS.Spacing.xs) {
                // Disclosure indicator
                Button {
                    withAnimation(DS.Animation.quick) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .frame(width: DS.Sizes.treeIconSize, height: DS.Sizes.treeIconSize)
                }
                .buttonStyle(.plain)

                // Folder icon
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
                    .frame(width: DS.Sizes.treeIconSize)

                // Name and path
                VStack(alignment: .leading, spacing: 1) {
                    Text(repository.name)
                        .font(DS.Typography.treeItem)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .lineLimit(1)

                    Text(repository.path)
                        .font(DS.Typography.treeItemSecondary)
                        .foregroundStyle(DS.Colors.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // Worktree count badge
                if !worktrees.isEmpty {
                    Text("\(worktrees.count)")
                        .font(DS.Typography.badge)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .padding(.horizontal, DS.Spacing.xs)
                        .padding(.vertical, DS.Spacing.xxxs)
                        .background(DS.Colors.surfaceSecondary)
                        .cornerRadius(DS.Radius.xs)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .frame(height: DS.Sizes.treeRowHeight + 8)
            .background(
                isRepoSelected ? DS.Colors.sidebarSelected :
                isHovered ? DS.Colors.sidebarHover : Color.clear
            )
            .cornerRadius(DS.Radius.sm)
            .padding(.horizontal, DS.Spacing.xs)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture {
                selection = .repository(repository)
                Task { await store.selectRepository(repository) }
            }
            .contextMenu {
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repository.path)
                }

                Button {
                    onCopySettings()
                } label: {
                    Label("Copy Files Settings...", systemImage: "doc.on.doc")
                }

                Divider()

                Button("Remove from List", role: .destructive) {
                    Task { await store.removeRepository(repository) }
                }
            }

            // Worktrees (children)
            if isExpanded {
                if isLoadingWorktrees {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.6)
                        Spacer()
                    }
                    .padding(.vertical, DS.Spacing.sm)
                } else {
                    ForEach(sortedWorktrees) { worktree in
                        WorktreeTreeRow(
                            worktree: worktree,
                            repository: repository,
                            selection: $selection,
                            status: store.getStatus(for: worktree)
                        )
                    }
                }
            }
        }
    }

    private var sortedWorktrees: [Worktree] {
        // Main worktree first, then alphabetically
        worktrees.sorted { lhs, rhs in
            if lhs.isMain && !rhs.isMain { return true }
            if !lhs.isMain && rhs.isMain { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}

// MARK: - Worktree Tree Row

struct WorktreeTreeRow: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    let repository: Repository
    @Binding var selection: SidebarSelection?
    let status: WorktreeStatus?

    @State private var isHovered = false

    private var isSelected: Bool {
        if case .worktree(let wt, _) = selection, wt.id == worktree.id {
            return true
        }
        return false
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Indent space for tree hierarchy
            Color.clear
                .frame(width: DS.Sizes.treeIndent + DS.Sizes.treeIconSize)

            // Branch icon
            Image(systemName: worktree.isMain ? "house.fill" : "arrow.triangle.branch")
                .font(.system(size: 12))
                .foregroundStyle(worktree.isMain ? .orange : DS.Colors.textSecondary)
                .frame(width: DS.Sizes.treeIconSize)

            // Name and branch
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: DS.Spacing.xs) {
                    Text(worktree.name)
                        .font(DS.Typography.treeItem)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .lineLimit(1)

                    if worktree.isMain {
                        StatusBadge(text: "main", color: .blue)
                    }

                    if worktree.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: DS.Spacing.xs) {
                    Text(worktree.branch)
                        .font(DS.Typography.treeItemSecondary)
                        .foregroundStyle(DS.Colors.textTertiary)
                        .lineLimit(1)

                    // Status indicators
                    if let status = status {
                        WorktreeStatusIndicators(status: status)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .frame(minHeight: DS.Sizes.treeRowHeight)
        .background(
            isSelected ? DS.Colors.sidebarSelected :
            isHovered ? DS.Colors.sidebarHover : Color.clear
        )
        .cornerRadius(DS.Radius.sm)
        .padding(.horizontal, DS.Spacing.xs)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            selection = .worktree(worktree, inRepository: repository)
        }
        .contextMenu {
            Button("Open in Finder") {
                store.openInFinder(worktree)
            }

            Button("Open in Terminal") {
                store.openInTerminal(worktree)
            }

            if !worktree.isMain {
                Divider()

                if worktree.isLocked {
                    Button("Unlock") {
                        Task { await store.unlockWorktree(worktree) }
                    }
                } else {
                    Button("Lock") {
                        Task { await store.lockWorktree(worktree) }
                    }
                }
            }
        }
    }
}

// MARK: - Worktree Status Indicators

struct WorktreeStatusIndicators: View {
    let status: WorktreeStatus

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            if status.isDirty {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
                    .help("Uncommitted changes")
            }

            if status.ahead > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(status.ahead)")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.blue)
                .help("\(status.ahead) commits to push")
            }

            if status.behind > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(status.behind)")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.purple)
                .help("\(status.behind) commits behind")
            }

            if let pr = status.prStatus {
                Image(systemName: pr.isMerged ? "checkmark.circle.fill" : "arrow.triangle.pull")
                    .font(.system(size: 9))
                    .foregroundStyle(pr.isMerged ? .purple : .green)
                    .help(pr.isMerged ? "PR merged" : "PR #\(pr.number)")
            }
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DS.Typography.badge)
            .foregroundStyle(color)
            .padding(.horizontal, DS.Spacing.xxs)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .cornerRadius(DS.Radius.xs)
    }
}

#Preview {
    ProjectTreeSidebar(selection: .constant(nil))
        .environmentObject(AppStore())
        .frame(width: 280, height: 500)
}
