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
    func openInEditor(_ worktree: Worktree) {
        guard let editor = defaultEditor else {
            showError(message: "No editor configured")
            return
        }
        openInEditor(worktree, editor: editor)
    }

    func openInEditor(_ worktree: Worktree, editor: Editor) {
        do {
            try editorOpener.open(path: worktree.path, with: editor)
        } catch {
            showError(message: error.localizedDescription)
        }
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
