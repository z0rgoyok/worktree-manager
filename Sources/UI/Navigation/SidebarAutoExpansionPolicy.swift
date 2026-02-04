import Foundation

/// UI policy for when the sidebar should auto-expand a repository node.
///
/// Goal: keep user-controlled expand/collapse state stable on app start, while still ensuring
/// that a selected worktree is visible (its parent repository must be expanded).
struct SidebarAutoExpansionPolicy {
    static func shouldAutoExpandRepository(for selection: SidebarSelection?) -> Bool {
        switch selection {
        case .worktree:
            return true
        case .repository, .none:
            return false
        }
    }
}

