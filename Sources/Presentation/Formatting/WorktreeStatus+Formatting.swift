import Foundation

extension WorktreeStatus {
    /// Presentation-friendly summary of a worktree's status.
    ///
    /// Kept out of `Domain` to avoid mixing UI string formatting with the domain model.
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

        if let prStatus {
            parts.append("PR #\(prStatus.number) \(prStatus.state.lowercased())")
        }

        return parts.isEmpty ? "Clean" : parts.joined(separator: " · ")
    }
}
