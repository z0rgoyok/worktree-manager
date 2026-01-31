import Foundation

// MARK: - Git Actions Use Cases

extension AppStore {
    func push(_ worktree: Worktree) async throws {
        var capturedError: Error?
        await withWorktreeActivity(worktreePath: worktree.path, kind: .push, message: "Pushing \(worktree.name)…") {
            isLoading = true
            defer { isLoading = false }

            do {
                let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
                try await runIO { try self.git.push(at: worktree.path, setUpstream: !status.hasRemote) }
                await refreshWorktreeStatus(worktree)
            } catch {
                capturedError = error
            }
        }
        if let capturedError {
            throw capturedError
        }
    }

    func pull(_ worktree: Worktree) async throws {
        var capturedError: Error?
        await withWorktreeActivity(worktreePath: worktree.path, kind: .pull, message: "Pulling \(worktree.name)…") {
            isLoading = true
            defer { isLoading = false }

            do {
                try await runIO { try self.git.pull(at: worktree.path) }
                await refreshWorktreeStatus(worktree)
            } catch {
                capturedError = error
            }
        }
        if let capturedError {
            throw capturedError
        }
    }

    func createPR(_ worktree: Worktree, title: String, body: String, baseBranch: String?) async throws -> URL {
        var prURL: URL?
        var prURLString: String?
        var capturedError: Error?

        await withWorktreeActivity(worktreePath: worktree.path, kind: .createPR, message: "Creating PR for \(worktree.name)…") {
            isLoading = true
            defer { isLoading = false }

            do {
                let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
                if status.hasUnpushedCommits || !status.hasRemote {
                    try await runIO { try self.git.push(at: worktree.path, setUpstream: !status.hasRemote) }
                }

                let prUrl = try await runIO { try self.git.createPR(at: worktree.path, title: title, body: body, baseBranch: baseBranch) }
                await refreshWorktreeStatus(worktree)

                prURLString = prUrl
                prURL = URL(string: prUrl)
            } catch {
                capturedError = error
            }
        }

        if let capturedError {
            throw capturedError
        }
        guard let prURL else {
            throw AppStoreError.invalidURL(urlString: prURLString ?? "")
        }
        return prURL
    }

    func openPRURL(_ worktree: Worktree) -> URL? {
        guard let prStatus = getStatus(for: worktree)?.prStatus else { return nil }
        return URL(string: prStatus.url)
    }

    func mergeBranch(_ worktree: Worktree, into targetBranch: String) async throws {
        guard let repo = selectedRepository else { return }

        var capturedError: Error?

        await withWorktreeActivity(worktreePath: worktree.path, kind: .merge, message: "Merging \(worktree.name)…") {
            isLoading = true
            defer { isLoading = false }

            do {
                try await runIO { try self.git.mergeBranch(at: repo.path, source: worktree.branch, into: targetBranch) }
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
