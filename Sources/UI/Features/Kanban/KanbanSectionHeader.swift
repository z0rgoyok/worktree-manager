import SwiftUI

struct KanbanSectionHeader: View {
    let onAddTask: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Colors.textSecondary)

                Text("Tasks")
                    .font(DS.Typography.sectionHeader)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .textCase(.uppercase)
            }

            Spacer()

            Button {
                onAddTask()
            } label: {
                Label("Add Task", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.surfaceTertiary)
    }
}

