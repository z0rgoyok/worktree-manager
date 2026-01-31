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
