import Foundation

/// Represents a selection target in the sidebar
enum SidebarSelection: Hashable {
    case repository(Repository)
    case worktree(Worktree, inRepository: Repository)

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

