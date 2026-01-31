import Foundation
import Combine

/// Application state store: status cells keyed by worktree path.
/// Cells are stable (same instance per path), enabling views to observe only the worktree they render.
@MainActor
final class WorktreeStatusStore {
    private var cellsByWorktreePath: [String: WorktreeStatusCell] = [:]

    func cell(forWorktreePath path: String) -> WorktreeStatusCell {
        if let existing = cellsByWorktreePath[path] {
            return existing
        }
        let created = WorktreeStatusCell()
        cellsByWorktreePath[path] = created
        return created
    }

    func value(forWorktreePath path: String) -> WorktreeStatus? {
        cellsByWorktreePath[path]?.value
    }

    func set(_ value: WorktreeStatus?, forWorktreePath path: String) {
        cell(forWorktreePath: path).set(value)
    }

    func removeCell(forWorktreePath path: String) {
        cellsByWorktreePath[path] = nil
    }
}
