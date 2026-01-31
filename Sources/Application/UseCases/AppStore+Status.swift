import Foundation

// MARK: - Status Use Cases

extension AppStore {
    func refreshWorktreeStatus(_ worktree: Worktree) async {
        guard !worktree.isPrunable else {
            worktreeStatuses[worktree.path] = nil
            return
        }

        let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
        if let existing = worktreeStatuses[worktree.path], existing == status {
            return
        }
        worktreeStatuses[worktree.path] = status
    }

    func refreshAllStatuses() async {
        await withTaskGroup(of: Void.self) { group in
            for worktree in worktrees where !worktree.isPrunable {
                group.addTask { [weak self] in
                    await self?.refreshWorktreeStatus(worktree)
                }
            }
        }
    }

    func getStatus(for worktree: Worktree) -> WorktreeStatus? {
        worktreeStatuses[worktree.path]
    }
}
