import Foundation
import Combine

/// Per-worktree observable cell to allow fine-grained UI updates without invalidating the whole AppStore.
@MainActor
final class WorktreeStatusCell: ObservableObject {
    @Published private(set) var value: WorktreeStatus?

    init(value: WorktreeStatus? = nil) {
        self.value = value
    }

    func set(_ newValue: WorktreeStatus?) {
        value = newValue
    }
}

