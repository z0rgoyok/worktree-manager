import SwiftUI

struct KanbanEmptyState: View {
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 56))
                .foregroundStyle(DS.Colors.textQuaternary)

            VStack(spacing: DS.Spacing.sm) {
                Text("Select a Project or Worktree")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Choose an item from the sidebar to view and manage its tasks")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colors.surfaceTertiary)
    }
}

