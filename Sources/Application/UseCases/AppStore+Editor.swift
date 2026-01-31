import Foundation

// MARK: - Editor Use Cases

extension AppStore {
    /// Editors configured in preferences
    var configuredEditors: [Editor] {
        editorOpener.availableEditors()
    }

    /// Default editor from preferences
    var defaultEditor: Editor? {
        configuredEditors.first { $0.id == defaultEditorId } ?? configuredEditors.first
    }

    /// Open worktree in the default editor
    func openInEditor(_ worktree: Worktree) throws {
        guard let editor = defaultEditor else {
            throw AppStoreError.noEditorConfigured
        }
        try openInEditor(worktree, editor: editor)
    }

    func openInEditor(_ worktree: Worktree, editor: Editor) throws {
        try editorOpener.open(path: worktree.path, with: editor)
    }

    func openInFinder(_ worktree: Worktree) {
        system.revealInFinder(path: worktree.path)
    }

    func openInTerminal(_ worktree: Worktree) {
        system.openTerminal(atPath: worktree.path)
    }

    func availableEditors() -> [Editor] {
        editorOpener.availableEditors()
    }
}
