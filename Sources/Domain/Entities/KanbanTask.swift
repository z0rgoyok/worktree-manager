import Foundation

/// Represents a task on the Kanban board
struct KanbanTask: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var columnId: KanbanColumnType
    var worktreePath: String?  // nil means it's a project-level task
    var createdAt: Date
    var order: Int

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        columnId: KanbanColumnType = .todo,
        worktreePath: String? = nil,
        createdAt: Date = Date(),
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.columnId = columnId
        self.worktreePath = worktreePath
        self.createdAt = createdAt
        self.order = order
    }
}

/// Column types for the Kanban board
enum KanbanColumnType: String, CaseIterable, Codable, Identifiable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case review = "Review"
    case done = "Done"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "play.circle.fill"
        case .review: return "eye.circle.fill"
        case .done: return "checkmark.circle.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .todo: return "gray"
        case .inProgress: return "blue"
        case .review: return "orange"
        case .done: return "green"
        }
    }
}

/// Represents a selection target in the sidebar
enum SidebarSelection: Hashable {
    case repository(Repository)
    case worktree(Worktree, inRepository: Repository)

    var repository: Repository {
        switch self {
        case .repository(let repo): return repo
        case .worktree(_, let repo): return repo
        }
    }

    var worktree: Worktree? {
        switch self {
        case .repository: return nil
        case .worktree(let wt, _): return wt
        }
    }

    var displayName: String {
        switch self {
        case .repository(let repo): return repo.name
        case .worktree(let wt, _): return wt.name
        }
    }
}
