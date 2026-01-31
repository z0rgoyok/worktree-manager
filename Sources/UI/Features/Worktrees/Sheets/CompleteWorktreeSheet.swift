import SwiftUI

struct CompleteWorktreeSheet: View {
    @EnvironmentObject var workspace: WorkspaceComponent
    @Environment(\.dismiss) var dismiss
    let worktree: Worktree
    @ObservedObject var statusCell: WorktreeStatusCell

    @State private var selectedAction: CompleteAction = .prMerged
    @State private var deleteLocalBranch = true
    @State private var deleteRemoteBranch = false
    @State private var pullTargetFirst = true
    @State private var forceDelete = false
    @State private var hasRemoteBranch = false
    @State private var isPreparing = false
    @State private var isSubmitting = false

    private var status: WorktreeStatus? {
        statusCell.value
    }

    private var hasMergedPR: Bool {
        status?.prStatus?.isMerged == true
    }

    private var hasOpenPR: Bool {
        if let pr = status?.prStatus {
            return !pr.isMerged
        }
        return false
    }

    private var isDirty: Bool {
        status?.isDirty == true
    }

    private var hasUnpushed: Bool {
        status?.hasUnpushedCommits == true
    }

    private var targetBranch: String {
        worktree.baseBranch ?? workspace.preferredBaseBranch() ?? "main"
    }

    private var canDeleteBranch: Bool {
        !worktree.branch.isEmpty && worktree.branch != "detached HEAD"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Image(systemName: selectedAction.icon)
                .font(.system(size: 48))
                .foregroundStyle(selectedAction.color)

            Text("Complete Worktree")
                .font(.headline)

            Text("Clean up '\(worktree.name)'")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Warnings
            if isDirty || hasUnpushed || hasOpenPR {
                VStack(alignment: .leading, spacing: 6) {
                    if isDirty {
                        Label("Uncommitted changes", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    if hasUnpushed {
                        Label("Unpushed commits (\(status?.ahead ?? 0))", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    if hasOpenPR {
                        Label("PR is still open", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Action selection
            VStack(alignment: .leading, spacing: 8) {
                Text("What happened with this work?")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(CompleteAction.allCases, id: \.self) { action in
                    HStack(spacing: 10) {
                        Image(systemName: selectedAction == action ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selectedAction == action ? action.color : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.rawValue)
                                .fontWeight(selectedAction == action ? .medium : .regular)
                            Text(action.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAction = action
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Cleanup options
            VStack(alignment: .leading, spacing: 12) {
                Text("Cleanup options")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if canDeleteBranch {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Delete local branch", isOn: $deleteLocalBranch)
                        Text("Removes '\(worktree.branch)' from local repository")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if hasRemoteBranch {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Delete remote branch", isOn: $deleteRemoteBranch)
                            Text("Removes '\(worktree.branch)' from origin")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if selectedAction != .discard {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Update \(targetBranch) from remote first", isOn: $pullTargetFirst)
                        Text("Pulls latest changes before cleanup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if isDirty {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Force delete", isOn: $forceDelete)
                            .foregroundStyle(.red)
                        Text("Discard uncommitted changes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(selectedAction == .discard ? "Delete" : "Complete") {
                    complete()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(selectedAction.color)
                .disabled((isDirty && !forceDelete) || isPreparing || isSubmitting)
            }
        }
        .padding(24)
        .frame(width: 420)
        .overlay {
            if isPreparing {
                BlockingProgressOverlay(title: "Preparing…")
            } else if isSubmitting {
                BlockingProgressOverlay(title: "Completing worktree…")
            }
        }
        .task {
            await prepare()
        }
    }

    private func complete() {
        let options = CompleteWorktreeOptions(
            targetBranch: targetBranch,
            mergeIntoTarget: selectedAction == .mergeLocally,
            pullTargetFirst: pullTargetFirst && selectedAction != .discard,
            deleteLocalBranch: deleteLocalBranch && canDeleteBranch,
            deleteRemoteBranch: deleteRemoteBranch && hasRemoteBranch,
            force: forceDelete
        )
        Task {
            isSubmitting = true
            await workspace.completeWorktree(worktree, options: options)
            isSubmitting = false
            dismiss()
        }
    }

    private func prepare() async {
        guard !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }

        if hasMergedPR {
            selectedAction = .prMerged
        } else if hasOpenPR {
            selectedAction = .prMerged
        }

        hasRemoteBranch = await workspace.loadHasRemoteBranch(for: worktree)
    }
}
