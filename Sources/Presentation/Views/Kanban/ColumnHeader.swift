import SwiftUI

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

