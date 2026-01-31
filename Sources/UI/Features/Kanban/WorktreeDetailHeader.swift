import SwiftUI

/// Header showing worktree details when a worktree is selected (info-only, actions via menu/context menu)
struct WorktreeDetailHeader: View {
    let worktree: Worktree
    let repository: Repository
    @ObservedObject var statusCell: WorktreeStatusCell

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: DS.Spacing.lg) {
                // Left: Info
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    // Name + badges
                    HStack(spacing: DS.Spacing.sm) {
                        Text(worktree.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if worktree.isMain {
                            StatusBadge(text: "main", color: .blue)
                        }
                        if worktree.isLocked {
                            StatusBadge(text: "locked", color: .orange)
                        }
                    }

                    // Branch + path
                    HStack(spacing: DS.Spacing.lg) {
                        HStack(spacing: DS.Spacing.xs) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption)
                            Text(worktree.branch)
                                .font(.subheadline)
                        }
                        .foregroundStyle(DS.Colors.textSecondary)

                        HStack(spacing: DS.Spacing.xs) {
                            Image(systemName: "folder")
                                .font(.caption)
                            Text(worktree.path)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(worktree.path, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .help("Copy path")
                        }
                        .foregroundStyle(DS.Colors.textTertiary)
                    }

                    WorktreeStatusRow(status: statusCell.value)
                        .opacity(worktree.isPrunable ? 0 : 1)
                        .accessibilityHidden(worktree.isPrunable)
                }

                Spacer()
            }
            .padding(DS.Spacing.lg)
            .background(.bar)

            Divider()
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        WorktreeDetailHeader(
            worktree: Worktree(
                path: "/Users/test/worktrees/feature-branch",
                branch: "feature/new-feature",
                isMain: false,
                commitHash: "abc123",
                isLocked: false,
                isPrunable: false,
                baseBranch: "main"
            ),
            repository: Repository(path: "/Users/test/repo"),
            statusCell: WorktreeStatusCell(
                value: WorktreeStatus(isDirty: false, hasRemote: true, ahead: 1, behind: 0, prStatus: nil)
            )
        )

        Spacer()
    }
}
