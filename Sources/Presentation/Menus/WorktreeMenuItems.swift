import SwiftUI

struct WorktreeMenuItems: View {
    @ObservedObject var store: AppStore
    let worktree: Worktree?
    let includeNewWorktree: Bool

    init(store: AppStore, worktree: Worktree?, includeNewWorktree: Bool) {
        self.store = store
        self.worktree = worktree
        self.includeNewWorktree = includeNewWorktree
    }

    var body: some View {
        Group {
            if let worktree {
                WorktreeBoundMenuItems(store: store, worktree: worktree)

                if includeNewWorktree {
                    Divider()
                    Button("New Worktree...") {
                        NotificationCenter.default.post(name: .showAddWorktree, object: nil)
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    .disabled(store.selectedRepository == nil)
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
        @ObservedObject var store: AppStore
        let worktree: Worktree
        @ObservedObject var statusCell: WorktreeStatusCell

        init(store: AppStore, worktree: Worktree) {
            self.store = store
            self.worktree = worktree
            self.statusCell = store.statusStore.cell(forWorktreePath: worktree.path)
        }

        var body: some View {
            Section {
                Button("Open in Editor") {
                    store.openInEditor(worktree)
                }
                .keyboardShortcut("o", modifiers: .command)

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
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Open in Terminal") {
                    store.openInTerminal(worktree)
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
                        Task { await store.push(worktree) }
                    }
                    .keyboardShortcut("p", modifiers: [.command, .shift])

                    Button("Pull") {
                        Task { await store.pull(worktree) }
                    }
                    .keyboardShortcut("p", modifiers: [.command, .option])
                }

                Section {
                    if let pr = statusCell.value?.prStatus {
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

            Section {
                Button("Refresh Status") {
                    Task { await store.refreshWorktreeStatus(worktree) }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}

