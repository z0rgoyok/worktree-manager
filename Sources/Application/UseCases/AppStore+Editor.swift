import Foundation

// MARK: - Editor Use Cases

extension AppStore {
    /// Editors configured in preferences
    var configuredEditors: [Editor] {
        editorOpener.availableEditors()
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

    // MARK: - Remember Editor Choice (per repository)

    var rememberEditorChoice: Bool {
        get { preferences.rememberEditorChoice }
        set { preferences.rememberEditorChoice = newValue }
    }

    func preferredEditor(for repository: Repository) -> Editor? {
        guard let editorId = preferences.preferredEditorId(forRepositoryId: repository.id) else {
            return nil
        }
        return configuredEditors.first { $0.id == editorId }
    }

    func setPreferredEditor(_ editor: Editor, for repository: Repository) {
        preferences.setPreferredEditorId(editor.id, forRepositoryId: repository.id)
    }

    func clearPreferredEditor(for repository: Repository) {
        preferences.removePreferredEditorId(forRepositoryId: repository.id)
    }
}
