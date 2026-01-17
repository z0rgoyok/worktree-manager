import Foundation

/// Service for persisting app data
final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let repositoriesKey = "savedRepositories"
    private let defaultEditorKey = "defaultEditor"
    private let defaultEditorIdKey = "defaultEditorId"
    private let worktreeBasePathKey = "worktreeBasePath"

    private init() {}

    // MARK: - Repositories

    func loadRepositories() -> [Repository] {
        guard let data = defaults.data(forKey: repositoriesKey),
              let repos = try? JSONDecoder().decode([Repository].self, from: data) else {
            return []
        }
        return repos
    }

    func saveRepositories(_ repositories: [Repository]) {
        guard let data = try? JSONEncoder().encode(repositories) else { return }
        defaults.set(data, forKey: repositoriesKey)
    }

    // MARK: - Default Editor

    var defaultEditor: Editor? {
        get {
            guard let data = defaults.data(forKey: defaultEditorKey),
                  let editor = try? JSONDecoder().decode(Editor.self, from: data) else {
                return nil
            }
            return editor
        }
        set {
            if let editor = newValue,
               let data = try? JSONEncoder().encode(editor) {
                defaults.set(data, forKey: defaultEditorKey)
            } else {
                defaults.removeObject(forKey: defaultEditorKey)
            }
        }
    }

    var defaultEditorId: String {
        get {
            if let id = defaults.string(forKey: defaultEditorIdKey) {
                return id
            }
            return defaultEditor?.id ?? ""
        }
        set {
            defaults.set(newValue, forKey: defaultEditorIdKey)
        }
    }

    // MARK: - Worktree Base Path

    var worktreeBasePath: String {
        get {
            defaults.string(forKey: worktreeBasePathKey) ?? defaultWorktreeBasePath
        }
        set {
            defaults.set(newValue, forKey: worktreeBasePathKey)
        }
    }

    private var defaultWorktreeBasePath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/worktrees"
    }
}
