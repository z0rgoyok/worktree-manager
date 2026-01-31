import SwiftUI

struct WorktreeTreeRow: View {
    @EnvironmentObject var root: RootComponent
    @EnvironmentObject var workspace: WorkspaceComponent
    @EnvironmentObject var activityCenter: ActivityCenter
    let worktree: Worktree
    let repository: Repository
    @Binding var selection: SidebarSelection?
    @ObservedObject var statusCell: WorktreeStatusCell

    @State private var isHovered = false

    private var isSelected: Bool {
        if case .worktree(let wt, _) = selection, wt.id == worktree.id {
            return true
        }
        return false
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Indent space for tree hierarchy
            Color.clear
                .frame(width: DS.Sizes.treeIndent + DS.Sizes.treeIconSize)

            // Branch icon
            Image(systemName: worktree.isMain ? "house.fill" : "arrow.triangle.branch")
                .font(.system(size: 12))
                .foregroundStyle(worktree.isMain ? .orange : DS.Colors.textSecondary)
                .frame(width: DS.Sizes.treeIconSize)

            // Name and branch
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: DS.Spacing.xs) {
                    Text(worktree.name)
                        .font(DS.Typography.treeItem)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .lineLimit(1)

                    if worktree.isMain {
                        StatusBadge(text: worktree.branch, color: .blue)
                    }

                    if worktree.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: DS.Spacing.xs) {
                    Text(worktree.branch)
                        .font(DS.Typography.treeItemSecondary)
                        .foregroundStyle(DS.Colors.textTertiary)
                        .lineLimit(1)

                    // Status indicators
                    if let status = statusCell.value {
                        WorktreeStatusIndicators(status: status)
                    }
                }
            }
            .help(worktree.path)

            Spacer()

            if activityCenter.currentActivity(forWorktreePath: worktree.path) != nil {
                ProgressView()
                    .controlSize(.mini)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .frame(minHeight: DS.Sizes.treeRowHeight)
        .background(
            isSelected ? DS.Colors.sidebarSelected :
            isHovered ? DS.Colors.sidebarHover : Color.clear
        )
        .cornerRadius(DS.Radius.sm)
        .padding(.horizontal, DS.Spacing.xs)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .overlay {
            RightClickHandlerView(
                onLeftClick: {
                    selection = .worktree(worktree, inRepository: repository)
                    workspace.selectWorktree(worktree)
                },
                onRightClick: {
                    selection = .worktree(worktree, inRepository: repository)
                    workspace.selectWorktree(worktree)
                }
            )
            .allowsHitTesting(true)
            .accessibilityHidden(true)
        }
        .contextMenu {
            WorktreeMenuItems(root: root, workspace: workspace, worktree: worktree, includeNewWorktree: false)
        }
        .animation(DS.Animation.quick, value: activityCenter.currentActivity(forWorktreePath: worktree.path) != nil)
    }
}
