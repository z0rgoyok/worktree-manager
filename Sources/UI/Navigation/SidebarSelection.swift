import Foundation

/// Represents a selection target in the sidebar
enum SidebarSelection: Hashable {
    case repository(Repository)
    case worktree(Worktree, inRepository: Repository)

    static func == (lhs: SidebarSelection, rhs: SidebarSelection) -> Bool {
        switch (lhs, rhs) {
        case (.repository(let a), .repository(let b)):
            return a.id == b.id
        case (.worktree(let aWt, let aRepo), .worktree(let bWt, let bRepo)):
            return aRepo.id == bRepo.id && aWt.id == bWt.id
        case (.repository, .worktree), (.worktree, .repository):
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .repository(let repo):
            hasher.combine(0)
            hasher.combine(repo.id)
        case .worktree(let worktree, let repo):
            hasher.combine(1)
            hasher.combine(repo.id)
            hasher.combine(worktree.id)
        }
    }

    var repository: Repository {
        switch self {
        case .repository(let repo): return repo
        case .worktree(_, let repo): return repo
        }
    }

    var worktree: Worktree? {
        switch self {
        case .repository: return nil
        case .worktree(let wt, _): return wt
        }
    }

    var displayName: String {
        switch self {
        case .repository(let repo): return repo.name
        case .worktree(let wt, _): return wt.name
        }
    }
}
