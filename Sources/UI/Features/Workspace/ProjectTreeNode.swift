import SwiftUI

struct ProjectTreeNode: View {
    @EnvironmentObject var workspace: WorkspaceComponent
    let repository: Repository
    @Binding var selection: SidebarSelection?
    @Binding var isExpanded: Bool
    let worktrees: [Worktree]
    let isLoadingWorktrees: Bool
    let onCopySettings: () -> Void

    @State private var isHovered = false

    private var repositorySnapshot: Repository {
        workspace.state.repositories.first(where: { $0.id == repository.id }) ?? repository
    }
    
    private var isArchived: Bool {
        repositorySnapshot.isArchived
    }

    private var isRepoSelected: Bool {
        if case .repository(let r) = selection, r.id == repository.id {
            return true
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Repository row
            HStack(spacing: DS.Spacing.xs) {
                // Disclosure indicator
                Button {
                    withAnimation(DS.Animation.quick) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .frame(width: DS.Sizes.treeIconSize, height: DS.Sizes.treeIconSize)
                }
                .buttonStyle(.plain)

                // Folder icon
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isArchived ? DS.Colors.textTertiary : .blue)
                    .frame(width: DS.Sizes.treeIconSize)

                // Name and path
                VStack(alignment: .leading, spacing: 1) {
                    Text(repositorySnapshot.name)
                        .font(DS.Typography.treeItem)
                        .foregroundStyle(isArchived ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                        .lineLimit(1)

                    Text(repositorySnapshot.path)
                        .font(DS.Typography.treeItemSecondary)
                        .foregroundStyle(isArchived ? DS.Colors.textQuaternary : DS.Colors.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .help(repositorySnapshot.path)

                Spacer()

                // Worktree count badge
                if !isArchived, !worktrees.isEmpty {
                    Text("\(worktrees.count)")
                        .font(DS.Typography.badge)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .padding(.horizontal, DS.Spacing.xs)
                        .padding(.vertical, DS.Spacing.xxxs)
                        .background(DS.Colors.surfaceSecondary)
                        .cornerRadius(DS.Radius.xs)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .frame(height: DS.Sizes.treeRowHeight + 8)
            .background(
                isRepoSelected ? DS.Colors.sidebarSelected :
                isHovered ? DS.Colors.sidebarHover : Color.clear
            )
            .cornerRadius(DS.Radius.sm)
            .padding(.horizontal, DS.Spacing.xs)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture {
                if isExpanded && isRepoSelected {
                    // Already selected and expanded — collapse
                    withAnimation(DS.Animation.quick) {
                        isExpanded = false
                    }
                } else {
                    // Select and expand
                    selection = .repository(repositorySnapshot)
                    if !isExpanded {
                        withAnimation(DS.Animation.quick) {
                            isExpanded = true
                        }
                    }
                }
            }
            .contextMenu {
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repository.path)
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(repository.path, forType: .string)
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }

                Button {
                    onCopySettings()
                } label: {
                    Label("Copy Files Settings...", systemImage: "doc.on.doc")
                }

                Divider()

                if isArchived {
                    Button {
                        Task { await workspace.restoreRepository(repositorySnapshot) }
                    } label: {
                        Label("Restore Project", systemImage: "arrow.uturn.left")
                    }
                } else {
                    Button {
                        Task { await workspace.archiveRepository(repositorySnapshot) }
                    } label: {
                        Label("Archive Project", systemImage: "archivebox")
                    }
                }

                Divider()

                Button("Remove from List", role: .destructive) {
                    Task { await workspace.removeRepository(repositorySnapshot) }
                }
            }

            // Worktrees (children)
            if isExpanded {
                Group {
                    if isLoadingWorktrees {
                        loadingView
                            .transition(.opacity)
                    } else {
                        worktreeList
                            .transition(.opacity)
                    }
                }
                .animation(DS.Animation.quick, value: isLoadingWorktrees)
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.6)
            Spacer()
        }
        .padding(.vertical, DS.Spacing.sm)
    }

    private var worktreeList: some View {
        VStack(spacing: 0) {
            ForEach(sortedWorktrees) { worktree in
                WorktreeTreeRow(
                    worktree: worktree,
                    repository: repository,
                    selection: $selection,
                    statusCell: workspace.statusCell(for: worktree.path)
                )
                .id(AnyHashable(worktree.id))
            }
        }
    }

    private var sortedWorktrees: [Worktree] {
        // Main worktree first, then alphabetically
        worktrees.sorted { lhs, rhs in
            if lhs.isMain && !rhs.isMain { return true }
            if !lhs.isMain && rhs.isMain { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
