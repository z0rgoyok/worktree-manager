import SwiftUI

/// A single task card in the Kanban board
struct KanbanCard: View {
    let task: KanbanTask
    let isDragging: Bool
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showActions = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Title row with menu
            HStack(alignment: .top, spacing: DS.Spacing.xs) {
                Text(task.title)
                    .font(DS.Typography.cardTitle)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: DS.Spacing.xxs)

                // Actions menu (visible on hover)
                if isHovered || showActions {
                    Menu {
                        Button("Edit") {
                            // TODO: Edit action
                        }

                        Divider()

                        Button("Delete", role: .destructive) {
                            onDelete()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Colors.textSecondary)
                            .frame(width: 20, height: 20)
                            .background(
                                showActions ? DS.Colors.surfaceSecondary : Color.clear
                            )
                            .cornerRadius(DS.Radius.xs)
                    }
                    .buttonStyle(.plain)
                    .onTapGesture {
                        showActions.toggle()
                    }
                    .transition(.opacity)
                }
            }

            // Description (if present)
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(DS.Typography.cardSubtitle)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            // Footer with metadata
            HStack(spacing: DS.Spacing.sm) {
                // Creation date (relative)
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(relativeTime)
                        .font(.system(size: 10))
                }
                .foregroundStyle(DS.Colors.textTertiary)

                Spacer()

                // Drag handle indicator (subtle)
                if isHovered {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Colors.textQuaternary)
                        .transition(.opacity)
                }
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(isHovered: isHovered, isDragging: isDragging)
        .opacity(isDragging ? 0.5 : 1)
        .scaleEffect(isDragging ? 1.02 : 1)
        .animation(DS.Animation.quick, value: isDragging)
        .animation(DS.Animation.quick, value: isHovered)
        .onHover { hovering in
            withAnimation(DS.Animation.quick) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Edit") {
                // TODO: Edit action
            }

            Menu("Move to") {
                ForEach(KanbanColumnType.allCases) { column in
                    if column != task.columnId {
                        Button(column.rawValue) {
                            // Movement handled by drag-drop
                        }
                    }
                }
            }

            Divider()

            Button("Duplicate") {
                // TODO: Duplicate action
            }

            Divider()

            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: task.createdAt, relativeTo: Date())
    }
}

// MARK: - Previews

#Preview("Card - Default") {
    VStack(spacing: DS.Spacing.md) {
        KanbanCard(
            task: KanbanTask(
                title: "Implement authentication flow",
                description: "Add login/logout functionality with OAuth2 support",
                columnId: .inProgress
            ),
            isDragging: false,
            onDelete: {}
        )

        KanbanCard(
            task: KanbanTask(
                title: "Fix navigation bug",
                columnId: .todo
            ),
            isDragging: false,
            onDelete: {}
        )

        KanbanCard(
            task: KanbanTask(
                title: "Dragging card",
                description: "This card is being dragged",
                columnId: .review
            ),
            isDragging: true,
            onDelete: {}
        )
    }
    .padding()
    .frame(width: 300)
    .background(DS.Colors.surfaceTertiary)
}

#Preview("Card - Compact") {
    VStack(spacing: DS.Spacing.sm) {
        KanbanCardCompact(
            task: KanbanTask(title: "Task 1", columnId: .todo),
            isDragging: false
        )

        KanbanCardCompact(
            task: KanbanTask(title: "Task 2", columnId: .inProgress),
            isDragging: false
        )

        KanbanCardCompact(
            task: KanbanTask(title: "Task 3", columnId: .done),
            isDragging: true
        )
    }
    .padding()
    .frame(width: 280)
    .background(DS.Colors.surfaceTertiary)
}

#Preview("Card - Skeleton") {
    VStack(spacing: DS.Spacing.md) {
        KanbanCardSkeleton()
        KanbanCardSkeleton()
        KanbanCardSkeleton()
    }
    .padding()
    .frame(width: 300)
    .background(DS.Colors.surfaceTertiary)
}
