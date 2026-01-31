import Foundation

// MARK: - Editor Use Cases

extension AppStore {
    /// Editors enabled by user (filtered from all available)
    var configuredEditors: [Editor] {
        editorOpener.allEditors().filter { preferences.isEditorEnabled($0.id) }
    }

    /// All editors (for configuration UI)
    var allEditors: [Editor] {
        editorOpener.allEditors()
    }

    func isEditorInstalled(_ editor: Editor) -> Bool {
        editorOpener.isInstalled(editor)
    }

    func isEditorEnabled(_ editor: Editor) -> Bool {
        preferences.isEditorEnabled(editor.id)
    }

    func setEditorEnabled(_ editor: Editor, enabled: Bool) {
        let allIds = allEditors.map(\.id)
        preferences.setEditorEnabled(editor.id, enabled: enabled, allEditorIds: allIds)
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
        configuredEditors
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
