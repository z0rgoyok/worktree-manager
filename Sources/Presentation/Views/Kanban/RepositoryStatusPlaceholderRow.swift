import SwiftUI

struct RepositoryStatusPlaceholderRow: View {
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Label("Select a worktree to see status", systemImage: "info.circle")
                .foregroundStyle(DS.Colors.textTertiary)
        }
        .font(.caption)
    }
}

