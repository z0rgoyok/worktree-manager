import Foundation

/// Represents a git repository that can have worktrees
struct Repository: Identifiable, Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id
        case path
        case name
        case isArchived
    }

    let id: UUID
    let path: String
    var name: String
    var isArchived: Bool

    var url: URL {
        URL(fileURLWithPath: path)
    }

    init(id: UUID = UUID(), path: String, name: String? = nil, isArchived: Bool = false) {
        self.id = id
        self.path = path
        self.name = name ?? URL(fileURLWithPath: path).lastPathComponent
        self.isArchived = isArchived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        path = try container.decode(String.self, forKey: .path)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? URL(fileURLWithPath: path).lastPathComponent
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(path, forKey: .path)
        try container.encode(name, forKey: .name)
        try container.encode(isArchived, forKey: .isArchived)
    }
}
