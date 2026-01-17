import Foundation

protocol PreferencesStore {
    func loadRepositories() -> [Repository]
    func saveRepositories(_ repositories: [Repository])

    var worktreeBasePath: String { get set }
    var defaultEditorId: String { get set }
}

