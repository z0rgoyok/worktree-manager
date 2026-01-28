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
                    Text(task.createdAt, style: .relative)
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
}

// MARK: - Card Variants

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

/// Skeleton loading card
struct KanbanCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Title skeleton
            RoundedRectangle(cornerRadius: DS.Radius.xs)
                .fill(DS.Colors.surfaceSecondary)
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .opacity(isAnimating ? 0.5 : 1)

            // Description skeleton
            RoundedRectangle(cornerRadius: DS.Radius.xs)
                .fill(DS.Colors.surfaceSecondary)
                .frame(height: 12)
                .frame(width: 180)
                .opacity(isAnimating ? 0.5 : 1)

            // Footer skeleton
            HStack {
                RoundedRectangle(cornerRadius: DS.Radius.xs)
                    .fill(DS.Colors.surfaceSecondary)
                    .frame(width: 60, height: 10)
                    .opacity(isAnimating ? 0.5 : 1)

                Spacer()
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
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
