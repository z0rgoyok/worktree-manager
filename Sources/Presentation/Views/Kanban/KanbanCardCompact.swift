import SwiftUI

/// Compact card variant for dense views
struct KanbanCardCompact: View {
    let task: KanbanTask
    let isDragging: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // Title
            Text(task.title)
                .font(DS.Typography.cardTitle)
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Drag handle
            if isHovered {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Colors.textQuaternary)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(
            isHovered ? DS.Colors.cardBackgroundHover : DS.Colors.cardBackground
        )
        .cornerRadius(DS.Radius.sm)
        .opacity(isDragging ? 0.5 : 1)
        .onHover { isHovered = $0 }
    }

    private var statusColor: Color {
        switch task.columnId {
        case .todo: return DS.Colors.statusTodo
        case .inProgress: return DS.Colors.statusInProgress
        case .review: return DS.Colors.statusReview
        case .done: return DS.Colors.statusDone
        }
    }
}

