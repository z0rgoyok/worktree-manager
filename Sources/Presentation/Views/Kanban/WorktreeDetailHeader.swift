import SwiftUI

/// Header showing worktree details and actions when a worktree is selected
struct WorktreeDetailHeader: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    let repository: Repository

    @State private var showEditorPicker = false
    @State private var showCreatePR = false
    @State private var showFinishSheet = false

    private var status: WorktreeStatus? {
        store.getStatus(for: worktree)
    }

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

                    // Status row
                    if !worktree.isPrunable {
                        WorktreeStatusRow(status: status)
                    }
                }

                Spacer()

                // Right: Actions
                if !worktree.isPrunable {
                    WorktreeActions(
                        worktree: worktree,
                        status: status,
                        showEditorPicker: $showEditorPicker,
                        showCreatePR: $showCreatePR,
                        showFinishSheet: $showFinishSheet
                    )
                }
            }
            .padding(DS.Spacing.lg)
            .background(.bar)

            Divider()
        }
        .sheet(isPresented: $showEditorPicker) {
            EditorPickerSheet(worktree: worktree)
        }
        .sheet(isPresented: $showCreatePR) {
            CreatePRSheet(worktree: worktree)
        }
        .sheet(isPresented: $showFinishSheet) {
            CompleteWorktreeSheet(worktree: worktree)
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

// MARK: - Worktree Actions

struct WorktreeActions: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    let status: WorktreeStatus?

    @Binding var showEditorPicker: Bool
    @Binding var showCreatePR: Bool
    @Binding var showFinishSheet: Bool

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            if !worktree.isMain {
                // Push button
                Button {
                    Task { await store.push(worktree) }
                } label: {
                    Label("Push", systemImage: "arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(status?.ahead == 0 && status?.hasRemote == true)
                .help("Push commits to remote")

                // PR button
                if let status = status, let pr = status.prStatus {
                    Button {
                        store.openPR(worktree)
                    } label: {
                        Label(pr.isMerged ? "Merged" : "PR #\(pr.number)", systemImage: "arrow.triangle.pull")
                    }
                    .buttonStyle(.bordered)
                    .tint(pr.isMerged ? .purple : .green)
                } else {
                    Button {
                        showCreatePR = true
                    } label: {
                        Label("Create PR", systemImage: "arrow.triangle.pull")
                    }
                    .buttonStyle(.bordered)
                }

                // Finish button (when PR is merged)
                if status?.prStatus?.isMerged == true {
                    Button {
                        showFinishSheet = true
                    } label: {
                        Label("Finish", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }

            // Open button
            Button {
                showEditorPicker = true
            } label: {
                Label("Open", systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(.borderedProminent)

            // More menu
            WorktreeMoreMenu(
                worktree: worktree,
                status: status,
                showFinishSheet: $showFinishSheet
            )
        }
    }
}

// MARK: - More Menu

struct WorktreeMoreMenu: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    let status: WorktreeStatus?

    @Binding var showFinishSheet: Bool

    var body: some View {
        Menu {
            Section {
                Button {
                    store.openInFinder(worktree)
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }

                Button {
                    store.openInTerminal(worktree)
                } label: {
                    Label("Open in Terminal", systemImage: "terminal")
                }
            }

            Section {
                Button {
                    Task { await store.refreshWorktreeStatus(worktree) }
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }

                if let pr = status?.prStatus {
                    Button {
                        store.openPR(worktree)
                    } label: {
                        Label("View PR #\(pr.number)", systemImage: "safari")
                    }
                }
            }

            if !worktree.isMain {
                Section {
                    if worktree.isLocked {
                        Button {
                            Task { await store.unlockWorktree(worktree) }
                        } label: {
                            Label("Unlock", systemImage: "lock.open")
                        }
                    } else {
                        Button {
                            Task { await store.lockWorktree(worktree) }
                        } label: {
                            Label("Lock", systemImage: "lock")
                        }
                    }
                }

                Section {
                    Button {
                        showFinishSheet = true
                    } label: {
                        Label("Complete Worktree...", systemImage: "checkmark.circle")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 28)
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

                Button {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repository.path)
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
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
            repository: Repository(path: "/Users/test/repo")
        )
        .environmentObject(AppStore(loadOnInit: false))

        Spacer()
    }
}
