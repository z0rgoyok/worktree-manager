import Foundation

// MARK: - Worktree Use Cases

extension AppStore {
    func refreshWorktrees(for repo: Repository? = nil) async throws {
        guard let repo = repo ?? selectedRepository else {
            worktrees = []
            return
        }

        let requestId = nextRefreshWorktreesRequestToken()
        let repoId = repo.id

        var capturedError: Error?

        await withGlobalActivity(kind: .refresh, message: "Refreshing worktrees…") {
            isLoading = true
            defer { isLoading = false }

            do {
                let listedWorktrees = try await runIO { try self.git.listWorktrees(at: repo.path) }
                guard !Task.isCancelled else { return }
                guard isLatestRefreshWorktreesRequestToken(requestId) else { return }
                guard selectedRepository?.id == repoId else { return }

                let enrichedWorktrees = listedWorktrees.map { worktree in
                    let baseBranch = preferences.worktreeBaseBranch(forWorktreePath: worktree.path)
                    return worktree.withBaseBranch(baseBranch)
                }
                if enrichedWorktrees != worktrees {
                    worktrees = enrichedWorktrees
                }
            } catch {
                // Ignore cancellations and stale results to avoid leaking worktrees across repositories.
                if error is CancellationError || Task.isCancelled { return }
                guard isLatestRefreshWorktreesRequestToken(requestId) else { return }
                guard selectedRepository?.id == repoId else { return }

                worktrees = []
                capturedError = error
            }

            guard !Task.isCancelled else { return }
            guard isLatestRefreshWorktreesRequestToken(requestId) else { return }
            guard selectedRepository?.id == repoId else { return }

            updateWatchedPaths()
            await refreshAllStatuses()
        }

        if let capturedError,
           isLatestRefreshWorktreesRequestToken(requestId),
           selectedRepository?.id == repoId {
            throw capturedError
        }
    }

    func loadBranches(for repo: Repository? = nil) async {
        guard let repo = repo ?? selectedRepository else {
            branches = []
            return
        }

        let requestId = nextLoadBranchesRequestToken()
        let repoId = repo.id

        await withGlobalActivity(kind: .refresh, message: "Loading branches…") {
            do {
                let loadedBranches = try await runIO { try self.git.listBranches(at: repo.path) }
                guard !Task.isCancelled else { return }
                guard isLatestLoadBranchesRequestToken(requestId) else { return }
                guard selectedRepository?.id == repoId else { return }

                branches = loadedBranches
            } catch {
                if error is CancellationError || Task.isCancelled { return }
                guard isLatestLoadBranchesRequestToken(requestId) else { return }
                guard selectedRepository?.id == repoId else { return }

                branches = []
            }
        }
    }

    func createWorktree(
        name: String,
        branch: String,
        createNewBranch: Bool,
        baseBranch: String?,
        copyPatterns: [CopyPattern]? = nil
    ) async throws {
        guard let repo = selectedRepository else { return }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppStoreError.validation(message: "Worktree name is required")
        }
        guard !branch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppStoreError.validation(message: "Branch name is required")
        }

        let basePath = worktreeBasePath
        let repoName = repo.name
        let parentPath = "\(basePath)/\(repoName)"
        let worktreePath = "\(parentPath)/\(name)"

        var capturedError: Error?

        await withWorktreeActivity(
            worktreePath: worktreePath,
            kind: .createWorktree,
            message: "Creating \(name)…"
        ) {
            isLoading = true
            defer { isLoading = false }

            do {
                try await runIO { try self.fileSystem.createDirectory(atPath: parentPath, withIntermediateDirectories: true) }
                try await runIO {
                    try self.git.createWorktree(
                        at: repo.path,
                        worktreePath: worktreePath,
                        branch: branch,
                        createBranch: createNewBranch,
                        baseBranch: baseBranch
                    )
                }

                if let baseBranch {
                    preferences.setWorktreeBaseBranch(baseBranch, forWorktreePath: worktreePath)
                }

                // Copy files from main worktree
                let patterns = copyPatterns ?? effectiveCopyPatterns(for: repo)
                if !patterns.isEmpty {
                    _ = await copyFiles(patterns: patterns, from: repo.path, to: worktreePath)
                }

                try await refreshWorktrees(for: repo)
                await loadBranches(for: repo)
            } catch {
                capturedError = error
            }
        }

        if let capturedError {
            throw capturedError
        }
    }

    func branchExists(_ branch: String) -> Bool {
        guard let repo = selectedRepository else { return false }
        return git.branchExists(at: repo.path, branch: branch)
    }

    func recreateBranchAndWorktree(name: String, branch: String, baseBranch: String, copyPatterns: [CopyPattern]? = nil) async throws {
        guard let repo = selectedRepository else { return }
        let basePath = worktreeBasePath
        let repoName = repo.name
        let parentPath = "\(basePath)/\(repoName)"
        let worktreePath = "\(parentPath)/\(name)"

        var capturedError: Error?

        await withWorktreeActivity(
            worktreePath: worktreePath,
            kind: .createWorktree,
            message: "Recreating \(name)…"
        ) {
            isLoading = true
            defer { isLoading = false }

            do {
                try await runIO { try self.git.deleteBranch(at: repo.path, branch: branch, force: true) }

                try await runIO { try self.fileSystem.createDirectory(atPath: parentPath, withIntermediateDirectories: true) }
                try await runIO {
                    try self.git.createWorktree(
                        at: repo.path,
                        worktreePath: worktreePath,
                        branch: branch,
                        createBranch: true,
                        baseBranch: baseBranch
                    )
                }

                preferences.setWorktreeBaseBranch(baseBranch, forWorktreePath: worktreePath)

                // Copy files from main worktree
                let patterns = copyPatterns ?? effectiveCopyPatterns(for: repo)
                if !patterns.isEmpty {
                    _ = await copyFiles(patterns: patterns, from: repo.path, to: worktreePath)
                }

                try await refreshWorktrees(for: repo)
                await loadBranches(for: repo)
            } catch {
                capturedError = error
            }
        }

        if let capturedError {
            throw capturedError
        }
    }

    func removeWorktree(_ worktree: Worktree, force: Bool = false, deleteBranch: Bool = false) async throws {
        guard let repo = selectedRepository else { return }
        guard !worktree.isMain else {
            throw AppStoreError.cannotRemoveMainWorktree
        }

        isLoading = true
        let branchToDelete = deleteBranch ? worktree.branch : nil
        defer { isLoading = false }

        do {
            try await runIO { try self.git.removeWorktree(at: repo.path, worktreePath: worktree.path, force: force) }

            preferences.removeWorktreeBaseBranch(forWorktreePath: worktree.path)

            if let branch = branchToDelete, !branch.isEmpty && branch != "detached HEAD" {
                try? await runIO { try self.git.deleteBranch(at: repo.path, branch: branch, force: force) }
            }

            try await refreshWorktrees(for: repo)
            await loadBranches(for: repo)
        } catch {
            throw error
        }
    }

    /// Complete worktree with all cleanup options
    func completeWorktree(_ worktree: Worktree, options: CompleteWorktreeOptions) async throws {
        guard let repo = selectedRepository else { return }
        guard !worktree.isMain else {
            throw AppStoreError.cannotRemoveMainWorktree
        }

        var capturedError: Error?

        await withWorktreeActivity(
            worktreePath: worktree.path,
            kind: .completeWorktree,
            message: "Completing \(worktree.name)…"
        ) {
            isLoading = true
            defer { isLoading = false }

            do {
                // Step 1: Merge into target branch if requested
                if options.mergeIntoTarget {
                    try await runIO { try self.git.mergeBranch(at: repo.path, source: worktree.branch, into: options.targetBranch) }
                }

                // Step 2: Pull latest changes to target branch if requested
                if options.pullTargetFirst {
                    // Find worktree for target branch to pull there
                    let worktrees = try await runIO { try self.git.listWorktrees(at: repo.path) }
                    if let targetWorktree = worktrees.first(where: { $0.branch == options.targetBranch }) {
                        try await runIO { try self.git.pull(at: targetWorktree.path) }
                    }
                }

                // Step 3: Remove the worktree directory
                try await runIO { try self.git.removeWorktree(at: repo.path, worktreePath: worktree.path, force: options.force) }

                preferences.removeWorktreeBaseBranch(forWorktreePath: worktree.path)

                // Step 4: Delete local branch if requested
                if options.deleteLocalBranch && !worktree.branch.isEmpty && worktree.branch != "detached HEAD" {
                    try? await runIO { try self.git.deleteBranch(at: repo.path, branch: worktree.branch, force: options.force) }
                }

                // Step 5: Delete remote branch if requested
                if options.deleteRemoteBranch && !worktree.branch.isEmpty {
                    try? await runIO { try self.git.deleteRemoteBranch(at: repo.path, branch: worktree.branch) }
                }

                try await refreshWorktrees(for: repo)
                await loadBranches(for: repo)
            } catch {
                capturedError = error
            }
        }

        if let capturedError {
            throw capturedError
        }
    }

    func loadHasRemoteBranch(for worktree: Worktree) async -> Bool {
        guard let repo = selectedRepository else { return false }
        return await runIO {
            self.git.hasRemoteBranch(at: repo.path, branch: worktree.branch)
        }
    }

    /// Check if remote branch exists for a worktree
    func hasRemoteBranch(for worktree: Worktree) -> Bool {
        guard let repo = selectedRepository else { return false }
        return git.hasRemoteBranch(at: repo.path, branch: worktree.branch)
    }

    func lockWorktree(_ worktree: Worktree) async throws {
        guard let repo = selectedRepository else { return }
        var capturedError: Error?
        await withWorktreeActivity(worktreePath: worktree.path, kind: .lock, message: "Locking \(worktree.name)…") {
            do {
                try await runIO { try self.git.lockWorktree(at: repo.path, worktreePath: worktree.path, reason: nil) }
                try await refreshWorktrees(for: repo)
            } catch {
                capturedError = error
            }
        }
        if let capturedError {
            throw capturedError
        }
    }

    func unlockWorktree(_ worktree: Worktree) async throws {
        guard let repo = selectedRepository else { return }
        var capturedError: Error?
        await withWorktreeActivity(worktreePath: worktree.path, kind: .unlock, message: "Unlocking \(worktree.name)…") {
            do {
                try await runIO { try self.git.unlockWorktree(at: repo.path, worktreePath: worktree.path) }
                try await refreshWorktrees(for: repo)
            } catch {
                capturedError = error
            }
        }
        if let capturedError {
            throw capturedError
        }
    }

    func pruneWorktrees() async throws {
        guard let repo = selectedRepository else { return }
        var capturedError: Error?
        await withGlobalActivity(kind: .prune, message: "Pruning worktrees…") {
            do {
                try await runIO { try self.git.pruneWorktrees(at: repo.path) }
                try await refreshWorktrees(for: repo)
            } catch {
                capturedError = error
            }
        }
        if let capturedError {
            throw capturedError
        }
    }
}
