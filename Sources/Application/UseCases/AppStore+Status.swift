import Foundation

// MARK: - Status Use Cases

extension AppStore {
    private static let statusRefreshSuppressionInterval: TimeInterval = 0.75

    private var now: Date { Date() }

    func refreshWorktreeStatus(_ worktree: Worktree) async {
        guard !worktree.isPrunable else {
            statusStore.set(nil, forWorktreePath: worktree.path)
            return
        }

        statusRefreshSuppressionUntilByWorktreePath[worktree.path] = now.addingTimeInterval(Self.statusRefreshSuppressionInterval)

        let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
        if let existing = statusStore.value(forWorktreePath: worktree.path), existing == status {
            return
        }
        statusStore.set(status, forWorktreePath: worktree.path)
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

    func refreshStatuses(for worktrees: [Worktree]) async {
        let unique = Dictionary(grouping: worktrees, by: \.path).compactMap { $0.value.first }
        await withTaskGroup(of: Void.self) { group in
            for worktree in unique where !worktree.isPrunable {
                group.addTask { [weak self] in
                    await self?.refreshWorktreeStatus(worktree)
                }
            }
        }
    }

    func getStatus(for worktree: Worktree) -> WorktreeStatus? {
        statusStore.value(forWorktreePath: worktree.path)
    }

    func shouldSuppressStatusRefresh(forWorktreePath path: String) -> Bool {
        let suppression = statusRefreshSuppressionUntilByWorktreePath[path]
        guard let suppression else { return false }
        return suppression > now
    }
}
