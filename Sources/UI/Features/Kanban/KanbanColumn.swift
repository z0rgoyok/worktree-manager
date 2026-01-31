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
        .frame(minWidth: DS.Sizes.columnMinWidth, maxWidth: .infinity)
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
