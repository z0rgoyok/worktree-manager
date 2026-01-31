import SwiftUI

// MARK: - Worktree Commands

struct WorktreeCommands: Commands {
    @ObservedObject var store: AppStore

    var body: some Commands {
        CommandMenu("Worktree") {
            Section {
                Button("Open in Editor") {
                    if let worktree = store.selectedWorktree {
                        store.openInEditor(worktree)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(store.selectedWorktree == nil)

                Menu("Open in...") {
                    ForEach(store.configuredEditors) { editor in
                        Button(editor.name) {
                            if let worktree = store.selectedWorktree {
                                store.openInEditor(worktree, editor: editor)
                            }
                        }
                    }
                }
                .disabled(store.selectedWorktree == nil)
            }

            Section {
                Button("Show in Finder") {
                    if let worktree = store.selectedWorktree {
                        store.openInFinder(worktree)
                    }
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(store.selectedWorktree == nil)

                Button("Open in Terminal") {
                    if let worktree = store.selectedWorktree {
                        store.openInTerminal(worktree)
                    }
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(store.selectedWorktree == nil)

                Button("Copy Path") {
                    if let worktree = store.selectedWorktree {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(worktree.path, forType: .string)
                    }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(store.selectedWorktree == nil)
            }

            Section {
                Button("Push") {
                    if let worktree = store.selectedWorktree {
                        Task { await store.push(worktree) }
                    }
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(store.selectedWorktree == nil || store.selectedWorktree?.isMain == true)

                Button("Pull") {
                    if let worktree = store.selectedWorktree {
                        Task { await store.pull(worktree) }
                    }
                }
                .keyboardShortcut("p", modifiers: [.command, .option])
                .disabled(store.selectedWorktree == nil)
            }

            Section {
                Button("Refresh Status") {
                    if let worktree = store.selectedWorktree {
                        Task { await store.refreshWorktreeStatus(worktree) }
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.selectedWorktree == nil)
            }

            Section {
                Button("New Worktree...") {
                    NotificationCenter.default.post(name: .showAddWorktree, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(store.selectedRepository == nil)
            }
        }

        CommandMenu("Repository") {
            Section {
                Button("Add Repository...") {
                    NotificationCenter.default.post(name: .showAddRepository, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Show in Finder") {
                    if let repo = store.selectedRepository {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repo.path)
                    }
                }
                .disabled(store.selectedRepository == nil)
            }

            Section {
                Button("Refresh All") {
                    Task { await store.refreshWorktrees() }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(store.selectedRepository == nil)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showAddWorktree = Notification.Name("showAddWorktree")
    static let showAddRepository = Notification.Name("showAddRepository")
    static let showCreatePR = Notification.Name("showCreatePR")
    static let showFinishWorktree = Notification.Name("showFinishWorktree")
}
