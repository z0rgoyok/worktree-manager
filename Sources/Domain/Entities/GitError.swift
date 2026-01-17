import Foundation

/// Domain errors for git operations
enum GitError: LocalizedError {
    case notARepository(path: String)
    case worktreeAlreadyExists(name: String)
    case worktreeNotFound(path: String)
    case branchAlreadyExists(name: String)
    case branchNotFound(name: String)
    case cannotRemoveMainWorktree
    case commandFailed(message: String)
    case invalidPath(path: String)

    var errorDescription: String? {
        switch self {
        case .notARepository(let path):
            return "'\(path)' is not a git repository"
        case .worktreeAlreadyExists(let name):
            return "Worktree '\(name)' already exists"
        case .worktreeNotFound(let path):
            return "Worktree not found at '\(path)'"
        case .branchAlreadyExists(let name):
            return "Branch '\(name)' already exists"
        case .branchNotFound(let name):
            return "Branch '\(name)' not found"
        case .cannotRemoveMainWorktree:
            return "Cannot remove the main worktree"
        case .commandFailed(let message):
            return "Git command failed: \(message)"
        case .invalidPath(let path):
            return "Invalid path: '\(path)'"
        }
    }
}
