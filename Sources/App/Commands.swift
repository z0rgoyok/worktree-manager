import SwiftUI

// MARK: - Worktree Commands

struct WorktreeCommands: Commands {
    @ObservedObject var store: AppStore

    var body: some Commands {
        CommandMenu("Worktree") {
            WorktreeMenuItems(store: store, worktree: store.selectedWorktree, includeNewWorktree: true)
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
    static let showHelp = Notification.Name("showHelp")
}
