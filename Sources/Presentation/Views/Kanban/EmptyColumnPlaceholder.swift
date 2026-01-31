import SwiftUI

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

