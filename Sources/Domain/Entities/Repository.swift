import Foundation

/// Represents a git repository that can have worktrees
struct Repository: Identifiable, Codable, Hashable {
    let id: UUID
    let path: String
    var name: String

    var url: URL {
        URL(fileURLWithPath: path)
    }

    init(id: UUID = UUID(), path: String, name: String? = nil) {
        self.id = id
        self.path = path
        self.name = name ?? URL(fileURLWithPath: path).lastPathComponent
    }
}
