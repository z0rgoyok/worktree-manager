import SwiftUI

struct WorktreeTreeRow: View {
    @EnvironmentObject var store: AppStore
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
        .onTapGesture {
            selection = .worktree(worktree, inRepository: repository)
        }
        .contextMenu {
            // Open actions
            Section {
                Button("Open in Editor") {
                    store.openInEditor(worktree)
                }

                Menu("Open in...") {
                    ForEach(store.configuredEditors) { editor in
                        Button(editor.name) {
                            store.openInEditor(worktree, editor: editor)
                        }
                    }
                }
            }

            Section {
                Button("Show in Finder") {
                    store.openInFinder(worktree)
                }

                Button("Open in Terminal") {
                    store.openInTerminal(worktree)
                }

                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(worktree.path, forType: .string)
                }
            }

            // Git actions (non-main only)
            if !worktree.isMain {
                Section {
                    Button("Push") {
                        Task { await store.push(worktree) }
                    }

                    Button("Pull") {
                        Task { await store.pull(worktree) }
                    }
                }

                // PR actions
                Section {
                    if let status = statusCell.value, let pr = status.prStatus {
                        Button(pr.isMerged ? "View Merged PR" : "View PR #\(pr.number)") {
                            store.openPR(worktree)
                        }
                    } else {
                        Button("Create Pull Request...") {
                            store.selectedWorktree = worktree
                            NotificationCenter.default.post(name: .showCreatePR, object: nil)
                        }
                    }
                }

                Section {
                    if worktree.isLocked {
                        Button("Unlock") {
                            Task { await store.unlockWorktree(worktree) }
                        }
                    } else {
                        Button("Lock") {
                            Task { await store.lockWorktree(worktree) }
                        }
                    }
                }

                Section {
                    Button("Finish Worktree...") {
                        store.selectedWorktree = worktree
                        NotificationCenter.default.post(name: .showFinishWorktree, object: nil)
                    }
                }
            }
        }
    }
}

