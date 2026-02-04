import Foundation

// MARK: - Repository Use Cases

extension AppStore {
    func loadRepositories() async throws {
        let snapshotLastSelectedRepositoryId = preferences.lastSelectedRepositoryId
        let snapshotLastSelectedWorktreePath = preferences.lastSelectedWorktreePath

        repositories = preferences.loadRepositories()
        guard selectedRepository == nil else { return }

        if let lastId = snapshotLastSelectedRepositoryId,
           let repo = repositories.first(where: { $0.id == lastId }) {
            try await selectRepository(repo)
        } else if let first = repositories.first {
            try await selectRepository(first)
        }

        // Restore last selected worktree (if still present) after worktrees are loaded.
        if let repo = selectedRepository,
           snapshotLastSelectedRepositoryId == repo.id,
           let path = snapshotLastSelectedWorktreePath,
           let worktree = worktrees.first(where: { $0.path == path }) {
            selectedWorktree = worktree
        }
    }

    func addRepository(at path: String) async throws {
        let rootPath = try await runIO { try self.git.getRepositoryRoot(at: path) }

        // Check if already added
        guard !repositories.contains(where: { $0.path == rootPath }) else {
            throw AppStoreError.repositoryAlreadyAdded
        }

        let repo = Repository(path: rootPath)
        repositories.append(repo)
        preferences.saveRepositories(repositories)

        try await selectRepository(repo)
    }

    func removeRepository(_ repo: Repository) async {
        repositories.removeAll { $0.id == repo.id }
        preferences.saveRepositories(repositories)

        if selectedRepository?.id == repo.id {
            if let selected = repositories.first {
                try? await selectRepository(selected)
            } else {
                selectedRepository = nil
                worktrees = []
                branches = []
            }
        }
    }

    func archiveRepository(_ repo: Repository) async {
        await setRepositoryArchived(repo, isArchived: true)
    }

    func restoreRepository(_ repo: Repository) async {
        await setRepositoryArchived(repo, isArchived: false)
    }

    private func setRepositoryArchived(_ repo: Repository, isArchived: Bool) async {
        guard let index = repositories.firstIndex(where: { $0.id == repo.id }) else { return }
        guard repositories[index].isArchived != isArchived else { return }

        var updated = repositories[index]
        updated.isArchived = isArchived
        repositories[index] = updated
        preferences.saveRepositories(repositories)

        if selectedRepository?.id == repo.id {
            if isArchived {
                if let nextActive = repositories.first(where: { !$0.isArchived }) {
                    try? await selectRepository(nextActive)
                } else {
                    selectedRepository = updated
                }
            } else {
                selectedRepository = updated
            }
        }
    }

    func selectRepository(_ repo: Repository) async throws {
        selectedRepository = repo
        selectedWorktree = nil
        try await refreshWorktrees(for: repo)
        await loadBranches(for: repo)
    }

    /// Load worktrees for a repository without changing selection
    /// Returns the loaded worktrees directly
    func loadWorktreesOnly(for repo: Repository) async -> [Worktree] {
        do {
            let listedWorktrees = try await runIO { try self.git.listWorktrees(at: repo.path) }
            let enrichedWorktrees = listedWorktrees.map { worktree in
                let baseBranch = preferences.worktreeBaseBranch(forWorktreePath: worktree.path)
                return worktree.withBaseBranch(baseBranch)
            }
            return enrichedWorktrees
        } catch {
            return []
        }
    }
}
