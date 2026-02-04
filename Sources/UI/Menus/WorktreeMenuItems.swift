import SwiftUI

struct WorktreeMenuItems: View {
    @ObservedObject var root: RootComponent
    @ObservedObject var workspace: WorkspaceComponent
    let worktree: Worktree?
    let includeNewWorktree: Bool

    init(root: RootComponent, workspace: WorkspaceComponent, worktree: Worktree?, includeNewWorktree: Bool) {
        self.root = root
        self.workspace = workspace
        self.worktree = worktree
        self.includeNewWorktree = includeNewWorktree
    }

    var body: some View {
        Group {
            if let worktree {
                WorktreeBoundMenuItems(root: root, workspace: workspace, worktree: worktree)

                if includeNewWorktree {
                    Divider()
                    Button("New Worktree...") {
                        root.send(.presentSheet(.addWorktree))
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    .disabled(workspace.state.selectedRepository == nil)
                }
            } else {
                WorktreeUnboundMenuItems()
            }
        }
    }

    private struct WorktreeUnboundMenuItems: View {
        var body: some View {
            Section {
                Button("Open in Editor") {}
                    .keyboardShortcut("o", modifiers: .command)
                    .disabled(true)

                Menu("Open in...") {}
                    .disabled(true)
            }

            Section {
                Button("Show in Finder") {}
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                    .disabled(true)

                Button("Open in Terminal") {}
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                    .disabled(true)

                Button("Copy Path") {}
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .disabled(true)
            }

            Section {
                Button("Push") {}
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                    .disabled(true)

                Button("Pull") {}
                    .keyboardShortcut("p", modifiers: [.command, .option])
                    .disabled(true)
            }

            Section {
                Button("Refresh Status") {}
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(true)
            }
        }
    }

    private struct WorktreeBoundMenuItems: View {
        @ObservedObject var root: RootComponent
        @ObservedObject var workspace: WorkspaceComponent
        let worktree: Worktree
        @ObservedObject var statusCell: WorktreeStatusCell

        init(root: RootComponent, workspace: WorkspaceComponent, worktree: Worktree) {
            self.root = root
            self.workspace = workspace
            self.worktree = worktree
            self.statusCell = workspace.statusCell(for: worktree.path)
        }

        private var selectedEditorId: String {
            workspace.preferredEditor()?.id ?? ""
        }

        var body: some View {
            Section {
                Button("Open in Editor") {
                    workspace.smartOpenInEditor(worktree)
                }
                .keyboardShortcut("o", modifiers: .command)

                Menu("Open in...") {
                    Picker("", selection: Binding(
                        get: { selectedEditorId },
                        set: { newId in
                            if let editor = workspace.configuredEditors().first(where: { $0.id == newId }) {
                                workspace.openInEditorAndRemember(worktree, editor: editor)
                            }
                        }
                    )) {
                        ForEach(workspace.configuredEditors()) { editor in
                            Text(editor.name).tag(editor.id)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    Divider()
                    Button(workspace.rememberEditorChoice ? "Forget Editor Choice" : "Remember Editor Choice") {
                        workspace.rememberEditorChoice.toggle()
                        if !workspace.rememberEditorChoice {
                            workspace.clearPreferredEditor()
                        }
                    }
                    Button("Configure Editors...") {
                        root.send(.presentSheet(.configureEditors))
                    }
                }
            }

            Section {
                Button("Show in Finder") {
                    workspace.openInFinder(worktree)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Open in Terminal") {
                    workspace.openInTerminal(worktree)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(worktree.path, forType: .string)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            if !worktree.isMain {
                Section {
                    Button("Push") {
                        Task { await workspace.push(worktree) }
                    }
                    .keyboardShortcut("p", modifiers: [.command, .shift])

                    Button("Pull") {
                        Task { await workspace.pull(worktree) }
                    }
                    .keyboardShortcut("p", modifiers: [.command, .option])
                }

                Section {
                    if let pr = statusCell.value?.prStatus {
                        Button(pr.isMerged ? "View Merged PR" : "View PR #\(pr.number)") {
                            workspace.openPR(worktree)
                        }
                    } else {
                        Button("Create Pull Request...") {
                            workspace.selectWorktree(worktree)
                            root.send(.presentSheet(.createPR(worktreePath: worktree.path)))
                        }
                    }
                }

                Section {
                    if worktree.isLocked {
                        Button("Unlock") {
                            Task { await workspace.unlockWorktree(worktree) }
                        }
                    } else {
                        Button("Lock") {
                            Task { await workspace.lockWorktree(worktree) }
                        }
                    }
                }

                Section {
                    Button("Finish Worktree...") {
                        workspace.selectWorktree(worktree)
                        root.send(.presentSheet(.completeWorktree(worktreePath: worktree.path)))
                    }
                }
            }

            Section {
                Button("Refresh Status") {
                    Task { await workspace.refreshWorktreeStatus(worktree) }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
