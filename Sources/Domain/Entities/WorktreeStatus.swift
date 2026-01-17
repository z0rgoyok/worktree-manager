import Foundation

/// Status information for a worktree
struct WorktreeStatus {
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

    var statusSummary: String {
        var parts: [String] = []

        if isDirty {
            parts.append("uncommitted changes")
        }

        if ahead > 0 {
            parts.append("\(ahead) unpushed")
        }

        if behind > 0 {
            parts.append("\(behind) behind")
        }

        if let pr = prStatus {
            parts.append("PR #\(pr.number) \(pr.state.lowercased())")
        }

        return parts.isEmpty ? "Clean" : parts.joined(separator: " · ")
    }
}

/// Pull request status
struct PRStatus {
    let number: Int
    let state: String  // OPEN, CLOSED, MERGED
    let url: String
    let title: String?

    var isOpen: Bool {
        state.uppercased() == "OPEN"
    }

    var isMerged: Bool {
        state.uppercased() == "MERGED"
    }
}
