import SwiftUI

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

