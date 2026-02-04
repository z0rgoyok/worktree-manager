import SwiftUI

// MARK: - Worktree Commands

struct WorktreeCommands: Commands {
    @ObservedObject var root: RootComponent

    private var workspace: WorkspaceComponent {
        root.workspace
    }

    var body: some Commands {
        CommandMenu("Worktree") {
            WorktreeMenuItems(root: root, workspace: workspace, worktree: workspace.state.selectedWorktree, includeNewWorktree: true)
        }

        CommandMenu("Repository") {
            Section {
                Button("Add Repository...") {
                    root.send(.presentSheet(.addRepository))
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Show in Finder") {
                    if let repo = workspace.state.selectedRepository {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repo.path)
                    }
                }
                .disabled(workspace.state.selectedRepository == nil)
            }

            Section {
                if let repo = workspace.state.selectedRepository {
                    if repo.isArchived {
                        Button("Restore Project") {
                            Task { await workspace.restoreRepository(repo) }
                        }
                    } else {
                        Button("Archive Project") {
                            Task { await workspace.archiveRepository(repo) }
                        }
                    }
                } else {
                    Button("Archive Project") {}
                        .disabled(true)
                }
            }

            Section {
                Button("Refresh All") {
                    workspace.send(.refresh, root: root)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(workspace.state.selectedRepository == nil)
            }
        }
    }
}
