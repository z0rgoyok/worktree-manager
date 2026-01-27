import SwiftUI

/// A single column in the Kanban board
struct KanbanColumn: View {
    let type: KanbanColumnType
    let tasks: [KanbanTask]
    @Binding var draggedTask: KanbanTask?
    let onAddTask: () -> Void
    let onMoveTask: (KanbanTask, KanbanColumnType) -> Void
    let onDeleteTask: (KanbanTask) -> Void
    let onReorderTask: (KanbanTask, Int) -> Void

    @State private var isTargeted = false
    @State private var dropIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Column header
            ColumnHeader(
                type: type,
                count: tasks.count,
                onAdd: onAddTask
            )

            // Cards
            ScrollView {
                LazyVStack(spacing: DS.Spacing.sm) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        // Drop indicator above card
                        if dropIndex == index {
                            DropIndicator()
                        }

                        KanbanCard(
                            task: task,
                            isDragging: draggedTask?.id == task.id,
                            onDelete: { onDeleteTask(task) }
                        )
                        .onDrag {
                            draggedTask = task
                            return NSItemProvider(object: task.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: CardDropDelegate(
                                task: task,
                                index: index,
                                column: type,
                                tasks: tasks,
                                draggedTask: $draggedTask,
                                dropIndex: $dropIndex,
                                onMove: onMoveTask,
                                onReorder: onReorderTask
                            )
                        )
                    }

                    // Drop indicator at end
                    if dropIndex == tasks.count {
                        DropIndicator()
                    }

                    // Empty state / add button
                    if tasks.isEmpty {
                        EmptyColumnPlaceholder(onAdd: onAddTask)
                    } else {
                        // Quick add button at bottom
                        Button {
                            onAddTask()
                        } label: {
                            HStack(spacing: DS.Spacing.xs) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Add task")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(DS.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.sm)
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                .foregroundStyle(DS.Colors.borderSubtle)
                        )
                    }
                }
                .padding(DS.Spacing.sm)
            }
        }
        .frame(width: DS.Sizes.columnIdealWidth)
        .columnStyle()
        .dropTargetStyle(isTargeted: isTargeted && draggedTask != nil)
        .onDrop(
            of: [.text],
            delegate: ColumnDropDelegate(
                column: type,
                draggedTask: $draggedTask,
                isTargeted: $isTargeted,
                dropIndex: $dropIndex,
                tasksCount: tasks.count,
                onMove: onMoveTask
            )
        )
    }
}

// MARK: - Column Header

struct ColumnHeader: View {
    let type: KanbanColumnType
    let count: Int
    let onAdd: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Status icon
            Image(systemName: type.icon)
                .font(.system(size: 14))
                .foregroundStyle(statusColor)

            // Title
            Text(type.rawValue)
                .font(DS.Typography.columnHeader)
                .foregroundStyle(DS.Colors.textPrimary)

            // Count badge
            Text("\(count)")
                .font(DS.Typography.columnCount)
                .foregroundStyle(DS.Colors.textSecondary)
                .padding(.horizontal, DS.Spacing.xs)
                .padding(.vertical, DS.Spacing.xxxs)
                .background(DS.Colors.surfaceSecondary)
                .cornerRadius(DS.Radius.pill)

            Spacer()

            // Add button
            Button {
                onAdd()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(isHovered ? DS.Colors.surfaceSecondary : Color.clear)
                    .cornerRadius(DS.Radius.sm)
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }

    private var statusColor: Color {
        switch type {
        case .todo: return DS.Colors.statusTodo
        case .inProgress: return DS.Colors.statusInProgress
        case .review: return DS.Colors.statusReview
        case .done: return DS.Colors.statusDone
        }
    }
}

// MARK: - Empty Column Placeholder

struct EmptyColumnPlaceholder: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundStyle(DS.Colors.textQuaternary)

            Text("No tasks")
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textTertiary)

            Button {
                onAdd()
            } label: {
                Label("Add task", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xxl)
    }
}

// MARK: - Drop Indicator

struct DropIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(DS.Colors.accent)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(DS.Colors.accent)
                .frame(height: 2)

            Circle()
                .fill(DS.Colors.accent)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, DS.Spacing.xxs)
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
}

// MARK: - Drop Delegates

struct CardDropDelegate: DropDelegate {
    let task: KanbanTask
    let index: Int
    let column: KanbanColumnType
    let tasks: [KanbanTask]
    @Binding var draggedTask: KanbanTask?
    @Binding var dropIndex: Int?
    let onMove: (KanbanTask, KanbanColumnType) -> Void
    let onReorder: (KanbanTask, Int) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask, dragged.id != task.id else { return }

        withAnimation(DS.Animation.quick) {
            // Set drop index at the current card position
            _ = info.location  // Location available for future position-based logic
            dropIndex = index
        }
    }

    func dropExited(info: DropInfo) {
        withAnimation(DS.Animation.quick) {
            if dropIndex == index {
                dropIndex = nil
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let dragged = draggedTask else { return false }

        if dragged.columnId != column {
            onMove(dragged, column)
        }

        if let dropIdx = dropIndex {
            onReorder(dragged, dropIdx)
        }

        draggedTask = nil
        dropIndex = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

struct ColumnDropDelegate: DropDelegate {
    let column: KanbanColumnType
    @Binding var draggedTask: KanbanTask?
    @Binding var isTargeted: Bool
    @Binding var dropIndex: Int?
    let tasksCount: Int
    let onMove: (KanbanTask, KanbanColumnType) -> Void

    func dropEntered(info: DropInfo) {
        withAnimation(DS.Animation.quick) {
            isTargeted = true
            if dropIndex == nil {
                dropIndex = tasksCount
            }
        }
    }

    func dropExited(info: DropInfo) {
        withAnimation(DS.Animation.quick) {
            isTargeted = false
            dropIndex = nil
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let dragged = draggedTask else { return false }

        if dragged.columnId != column {
            onMove(dragged, column)
        }

        draggedTask = nil
        isTargeted = false
        dropIndex = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

#Preview {
    HStack {
        KanbanColumn(
            type: .todo,
            tasks: [
                KanbanTask(title: "Task 1", order: 1),
                KanbanTask(title: "Task 2", description: "With description", order: 2)
            ],
            draggedTask: .constant(nil),
            onAddTask: {},
            onMoveTask: { _, _ in },
            onDeleteTask: { _ in },
            onReorderTask: { _, _ in }
        )

        KanbanColumn(
            type: .inProgress,
            tasks: [],
            draggedTask: .constant(nil),
            onAddTask: {},
            onMoveTask: { _, _ in },
            onDeleteTask: { _ in },
            onReorderTask: { _, _ in }
        )
    }
    .padding()
    .background(DS.Colors.surfaceTertiary)
}
