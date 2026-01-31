import Foundation

// MARK: - Git Actions Use Cases

extension AppStore {
    func push(_ worktree: Worktree) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
            try await runIO { try self.git.push(at: worktree.path, setUpstream: !status.hasRemote) }
            await refreshWorktreeStatus(worktree)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func pull(_ worktree: Worktree) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await runIO { try self.git.pull(at: worktree.path) }
            await refreshWorktreeStatus(worktree)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func createPR(_ worktree: Worktree, title: String, body: String, baseBranch: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
            if status.hasUnpushedCommits || !status.hasRemote {
                try await runIO { try self.git.push(at: worktree.path, setUpstream: !status.hasRemote) }
            }

            let prUrl = try await runIO { try self.git.createPR(at: worktree.path, title: title, body: body, baseBranch: baseBranch) }
            await refreshWorktreeStatus(worktree)

            if let url = URL(string: prUrl) {
                system.openURL(url)
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func openPR(_ worktree: Worktree) {
        guard let prStatus = getStatus(for: worktree)?.prStatus,
              let url = URL(string: prStatus.url) else {
            return
        }
        system.openURL(url)
    }

    func mergeBranch(_ worktree: Worktree, into targetBranch: String) async {
        guard let repo = selectedRepository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await runIO { try self.git.mergeBranch(at: repo.path, source: worktree.branch, into: targetBranch) }
            await refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }
}
