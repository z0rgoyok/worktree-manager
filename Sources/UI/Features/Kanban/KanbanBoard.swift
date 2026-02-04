import SwiftUI

/// Main Kanban board view showing task columns
struct KanbanBoard: View {
    @EnvironmentObject var workspace: WorkspaceComponent
    let selection: SidebarSelection?
    @State private var tasks: [KanbanTask] = []
    @State private var draggedTask: KanbanTask?
    @State private var showAddTask = false
    @State private var addTaskColumn: KanbanColumnType = .todo

    var body: some View {
        VStack(spacing: 0) {
            // Detail header with actions
            if let selection = selection {
                switch selection {
                case .repository(let repo):
                    RepositoryDetailHeader(repository: repo)
                case .worktree(let worktree, let repo):
                    WorktreeDetailHeader(
                        worktree: worktree,
                        repository: repo,
                        statusCell: workspace.statusCell(for: worktree.path)
                    )
                }
            }

            // Kanban section header
            if selection != nil {
                KanbanSectionHeader {
                    addTaskColumn = .todo
                    showAddTask = true
                }
            }

            // Columns
            if selection != nil {
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: DS.Spacing.md) {
                            ForEach(KanbanColumnType.allCases) { columnType in
                                KanbanColumn(
                                    type: columnType,
                                    tasks: tasks(for: columnType),
                                    draggedTask: $draggedTask,
                                    onAddTask: {
                                        addTaskColumn = columnType
                                        showAddTask = true
                                    },
                                    onMoveTask: { task, newColumn in
                                        moveTask(task, to: newColumn)
                                    },
                                    onDeleteTask: { task in
                                        deleteTask(task)
                                    },
                                    onReorderTask: { task, newIndex in
                                        reorderTask(task, to: newIndex)
                                    }
                                )
                            }
                        }
                        .padding(DS.Spacing.lg)
                        .frame(minWidth: geometry.size.width, alignment: .topLeading)
                    }
                    .background(DS.Colors.surfaceTertiary)
                }
            } else {
                KanbanEmptyState()
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(column: addTaskColumn) { title, description in
                addTask(title: title, description: description, to: addTaskColumn)
            }
        }
        .onAppear {
            loadMockTasks()
        }
        .onChange(of: selection) { _, _ in
            loadMockTasks()
        }
    }

    // MARK: - Data Helpers

    private func tasks(for column: KanbanColumnType) -> [KanbanTask] {
        tasks
            .filter { $0.columnId == column }
            .sorted { $0.order < $1.order }
    }

    private func moveTask(_ task: KanbanTask, to newColumn: KanbanColumnType) {
        withAnimation(DS.Animation.spring) {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].columnId = newColumn
                // Update order to be at the end of new column
                let maxOrder = tasks.filter { $0.columnId == newColumn }.map(\.order).max() ?? 0
                tasks[index].order = maxOrder + 1
            }
        }
    }

    private func reorderTask(_ task: KanbanTask, to newIndex: Int) {
        guard let currentIndex = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        withAnimation(DS.Animation.spring) {
            let columnTasks = tasks(for: task.columnId)
            guard newIndex >= 0 && newIndex <= columnTasks.count else { return }

            // Update orders
            var updatedTasks = tasks
            let movedTask = updatedTasks.remove(at: currentIndex)

            // Calculate new order based on surrounding tasks
            let columnTasksSorted = columnTasks.filter { $0.id != task.id }.sorted { $0.order < $1.order }

            let newOrder: Int
            if newIndex == 0 {
                newOrder = (columnTasksSorted.first?.order ?? 1) - 1
            } else if newIndex >= columnTasksSorted.count {
                newOrder = (columnTasksSorted.last?.order ?? 0) + 1
            } else {
                let prev = columnTasksSorted[newIndex - 1].order
                let next = columnTasksSorted[newIndex].order
                newOrder = (prev + next) / 2
            }

            var movedTaskUpdated = movedTask
            movedTaskUpdated.order = newOrder
            updatedTasks.append(movedTaskUpdated)
            tasks = updatedTasks
        }
    }

    private func addTask(title: String, description: String?, to column: KanbanColumnType) {
        let worktreePath: String? = if case .worktree(let wt, _) = selection {
            wt.path
        } else {
            nil
        }

        let maxOrder = tasks.filter { $0.columnId == column }.map(\.order).max() ?? 0
        let task = KanbanTask(
            title: title,
            description: description,
            columnId: column,
            worktreePath: worktreePath,
            order: maxOrder + 1
        )

        withAnimation(DS.Animation.spring) {
            tasks.append(task)
        }
    }

    private func deleteTask(_ task: KanbanTask) {
        withAnimation(DS.Animation.standard) {
            tasks.removeAll { $0.id == task.id }
        }
    }

    // MARK: - Mock Data

    private func loadMockTasks() {
        guard let selection = selection else {
            tasks = []
            return
        }

        // Generate mock tasks based on selection
        let worktreePath: String? = selection.worktree?.path

        tasks = [
            KanbanTask(
                title: "Implement authentication flow",
                description: "Add login/logout functionality with OAuth2",
                columnId: .done,
                worktreePath: worktreePath,
                order: 1
            ),
            KanbanTask(
                title: "Fix navigation bug",
                description: "Back button not working on detail screen",
                columnId: .inProgress,
                worktreePath: worktreePath,
                order: 1
            ),
            KanbanTask(
                title: "Review PR #42",
                description: nil,
                columnId: .review,
                worktreePath: worktreePath,
                order: 1
            ),
            KanbanTask(
                title: "Add unit tests",
                description: "Cover UserService with tests",
                columnId: .todo,
                worktreePath: worktreePath,
                order: 1
            ),
            KanbanTask(
                title: "Update README",
                description: "Add setup instructions for new developers",
                columnId: .todo,
                worktreePath: worktreePath,
                order: 2
            ),
            KanbanTask(
                title: "Refactor data layer",
                description: nil,
                columnId: .todo,
                worktreePath: worktreePath,
                order: 3
            )
        ]
    }
}

#Preview {
    KanbanBoard(selection: nil)
        .frame(width: 1000, height: 600)
}
