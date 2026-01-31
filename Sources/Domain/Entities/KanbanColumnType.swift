import Foundation

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

