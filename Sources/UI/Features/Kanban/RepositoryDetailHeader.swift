import SwiftUI

/// Repository Header (when project is selected)
struct RepositoryDetailHeader: View {
    @EnvironmentObject var workspace: WorkspaceComponent
    let repository: Repository

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        Text(repository.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    HStack(spacing: DS.Spacing.lg) {
                        Text(repository.path)
                            .font(.subheadline)
                            .foregroundStyle(DS.Colors.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text("\(workspace.state.worktrees.count) worktree\(workspace.state.worktrees.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textTertiary)
                    }

                    RepositoryStatusPlaceholderRow()
                }

                Spacer()
            }
            .padding(DS.Spacing.lg)
            .background(.bar)

            Divider()
        }
    }
}
