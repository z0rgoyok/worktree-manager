import Foundation

/// Represents a file or directory pattern to copy when creating a new worktree
struct CopyPattern: Codable, Hashable, Identifiable {
    var id: String { pattern }

    /// The relative path pattern (e.g. ".env", ".venv/", "config/*.local")
    let pattern: String

    init(pattern: String) {
        self.pattern = pattern
    }
}
