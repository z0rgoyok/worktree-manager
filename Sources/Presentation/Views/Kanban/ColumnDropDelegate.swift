import SwiftUI

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

