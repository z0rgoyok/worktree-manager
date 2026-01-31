import SwiftUI

/// Header showing worktree details when a worktree is selected (info-only, actions via menu/context menu)
struct WorktreeDetailHeader: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    let repository: Repository
    @ObservedObject var statusCell: WorktreeStatusCell

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: DS.Spacing.lg) {
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

                    // Status row
                    if !worktree.isPrunable {
                        WorktreeStatusRow(status: statusCell.value)
                    }
                }

                Spacer()
            }
            .padding(DS.Spacing.lg)
            .background(.bar)

            Divider()
        }
    }
}

// MARK: - Worktree Status Row

struct WorktreeStatusRow: View {
    let status: WorktreeStatus?

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            if let status = status {
                if status.isDirty {
                    Label("Modified", systemImage: "pencil.circle.fill")
                        .foregroundStyle(.orange)
                }

                if status.ahead > 0 {
                    Label("\(status.ahead) to push", systemImage: "arrow.up.circle.fill")
                        .foregroundStyle(.blue)
                }

                if status.behind > 0 {
                    Label("\(status.behind) behind", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.purple)
                }

                if let pr = status.prStatus {
                    WorktreePRBadge(pr: pr)
                } else if !status.hasRemote {
                    Label("Not pushed", systemImage: "icloud.slash")
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Loading status...")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}

struct WorktreePRBadge: View {
    let pr: PRStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: prIcon)
            Text("PR #\(pr.number)")
        }
        .foregroundStyle(prColor)
    }

    private var prIcon: String {
        switch pr.state.uppercased() {
        case "MERGED": return "checkmark.circle.fill"
        case "CLOSED": return "xmark.circle.fill"
        default: return "arrow.triangle.pull"
        }
    }

    private var prColor: Color {
        switch pr.state.uppercased() {
        case "MERGED": return .purple
        case "CLOSED": return .red
        default: return .green
        }
    }
}

// MARK: - Repository Header (when project is selected)

struct RepositoryDetailHeader: View {
    @EnvironmentObject var store: AppStore
    let repository: Repository

    var body: some View {
        VStack(spacing: 0) {
            HStack {
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

                        Text("\(store.worktrees.count) worktree\(store.worktrees.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textTertiary)
                    }
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
        .environmentObject(AppStore.makeDefault(loadOnInit: false))

        Spacer()
    }
}
