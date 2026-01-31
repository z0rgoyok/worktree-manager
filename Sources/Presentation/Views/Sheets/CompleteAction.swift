import SwiftUI

/// Action to perform with worktree changes
enum CompleteAction: String, CaseIterable {
    case prMerged = "PR was merged"
    case mergeLocally = "Merge locally"
    case discard = "Just delete"

    var description: String {
        switch self {
        case .prMerged: "Work was merged via PR on GitHub. Just clean up."
        case .mergeLocally: "Merge branch into target locally, then clean up."
        case .discard: "Discard this work without merging."
        }
    }

    var icon: String {
        switch self {
        case .prMerged: "checkmark.circle.fill"
        case .mergeLocally: "arrow.triangle.merge"
        case .discard: "trash"
        }
    }

    var color: Color {
        switch self {
        case .prMerged: .green
        case .mergeLocally: .blue
        case .discard: .red
        }
    }
}

