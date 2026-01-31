import Foundation

// MARK: - Repository Use Cases

extension AppStore {
    func loadRepositories() async {
        repositories = preferences.loadRepositories()
        // Auto-select first repository
        if selectedRepository == nil, let first = repositories.first {
            await selectRepository(first)
        }
    }

    func addRepository(at path: String) async {
        do {
            let rootPath = try await runIO { try self.git.getRepositoryRoot(at: path) }

            // Check if already added
            guard !repositories.contains(where: { $0.path == rootPath }) else {
                showError(message: "Repository already added")
                return
            }

            let repo = Repository(path: rootPath)
            repositories.append(repo)
            preferences.saveRepositories(repositories)

            await selectRepository(repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func removeRepository(_ repo: Repository) async {
        repositories.removeAll { $0.id == repo.id }
        preferences.saveRepositories(repositories)

        if selectedRepository?.id == repo.id {
            if let selected = repositories.first {
                await selectRepository(selected)
            } else {
                selectedRepository = nil
                worktrees = []
                branches = []
            }
        }
    }

    func selectRepository(_ repo: Repository) async {
        selectedRepository = repo
        await refreshWorktrees(for: repo)
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
