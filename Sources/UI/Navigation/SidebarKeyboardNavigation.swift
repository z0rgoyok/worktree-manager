import Foundation

struct SidebarKeyboardNavigation {
    enum Key: Equatable {
        case up
        case down
        case left
        case right
        case space
    }

    struct Output: Equatable {
        var selection: SidebarSelection?
        var expandedRepositoryIds: Set<UUID>
        var repositoryIdsToLoadWorktrees: Set<UUID>
    }

    static func handle(
        key: Key,
        selection: SidebarSelection?,
        repositories: [Repository],
        expandedRepositoryIds: Set<UUID>,
        worktreesByRepositoryId: [UUID: [Worktree]]
    ) -> Output {
        var expanded = expandedRepositoryIds
        var selection = selection
        var repositoryIdsToLoadWorktrees: Set<UUID> = []

        switch key {
        case .up, .down:
            let visible = visibleSelections(
                repositories: repositories,
                expandedRepositoryIds: expanded,
                worktreesByRepositoryId: worktreesByRepositoryId
            )

            guard !visible.isEmpty else {
                return Output(selection: selection, expandedRepositoryIds: expanded, repositoryIdsToLoadWorktrees: [])
            }

            let currentIndex = selection.flatMap { indexOf(selection: $0, in: visible) }

            if key == .down {
                if let currentIndex, visible.indices.contains(currentIndex + 1) {
                    selection = visible[currentIndex + 1]
                } else {
                    selection = visible.first
                }
            } else {
                if let currentIndex, visible.indices.contains(currentIndex - 1) {
                    selection = visible[currentIndex - 1]
                } else {
                    selection = visible.last
                }
            }

        case .right:
            switch selection {
            case .repository(let repo):
                if expanded.contains(repo.id) {
                    let worktrees = sortedWorktrees(worktreesByRepositoryId[repo.id] ?? [])
                    if let first = worktrees.first {
                        selection = .worktree(first, inRepository: repo)
                    }
                } else {
                    expanded.insert(repo.id)
                    if worktreesByRepositoryId[repo.id] == nil {
                        repositoryIdsToLoadWorktrees.insert(repo.id)
                    }
                }
            case .worktree, .none:
                break
            }

        case .left:
            switch selection {
            case .worktree(_, let repo):
                selection = .repository(repo)
            case .repository(let repo):
                if expanded.contains(repo.id) {
                    expanded.remove(repo.id)
                }
            case .none:
                break
            }

        case .space:
            switch selection {
            case .repository(let repo):
                if expanded.contains(repo.id) {
                    expanded.remove(repo.id)
                } else {
                    expanded.insert(repo.id)
                    if worktreesByRepositoryId[repo.id] == nil {
                        repositoryIdsToLoadWorktrees.insert(repo.id)
                    }
                }
            case .worktree, .none:
                break
            }
        }

        return Output(
            selection: selection,
            expandedRepositoryIds: expanded,
            repositoryIdsToLoadWorktrees: repositoryIdsToLoadWorktrees
        )
    }

    private static func visibleSelections(
        repositories: [Repository],
        expandedRepositoryIds: Set<UUID>,
        worktreesByRepositoryId: [UUID: [Worktree]]
    ) -> [SidebarSelection] {
        var visible: [SidebarSelection] = []
        visible.reserveCapacity(repositories.count)

        for repo in repositories {
            visible.append(.repository(repo))

            guard expandedRepositoryIds.contains(repo.id) else { continue }
            let worktrees = sortedWorktrees(worktreesByRepositoryId[repo.id] ?? [])
            for worktree in worktrees {
                visible.append(.worktree(worktree, inRepository: repo))
            }
        }

        return visible
    }

    private static func indexOf(selection: SidebarSelection, in visible: [SidebarSelection]) -> Int? {
        // Prefer an exact match (repo+worktree). If not found (e.g. worktree disappeared),
        // fall back to the repository row to keep navigation stable.
        for (index, item) in visible.enumerated() {
            if isSameSelection(lhs: item, rhs: selection) {
                return index
            }
        }

        if case .worktree(_, let repo) = selection {
            for (index, item) in visible.enumerated() {
                if case .repository(let rowRepo) = item, rowRepo.id == repo.id {
                    return index
                }
            }
        }

        return nil
    }

    private static func isSameSelection(lhs: SidebarSelection, rhs: SidebarSelection) -> Bool {
        switch (lhs, rhs) {
        case (.repository(let a), .repository(let b)):
            return a.id == b.id
        case (.worktree(let a, let aRepo), .worktree(let b, let bRepo)):
            return a.id == b.id && aRepo.id == bRepo.id
        case (.repository, .worktree), (.worktree, .repository):
            return false
        }
    }

    private static func sortedWorktrees(_ worktrees: [Worktree]) -> [Worktree] {
        worktrees.sorted { lhs, rhs in
            if lhs.isMain && !rhs.isMain { return true }
            if !lhs.isMain && rhs.isMain { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
