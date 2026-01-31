import Foundation

/// Status information for a worktree
struct WorktreeStatus: Equatable {
    let isDirty: Bool
    let hasRemote: Bool
    let ahead: Int
    let behind: Int
    let prStatus: PRStatus?

    var hasUnpushedCommits: Bool {
        ahead > 0
    }

    var needsPull: Bool {
        behind > 0
    }

    var hasPR: Bool {
        prStatus != nil
    }
}
