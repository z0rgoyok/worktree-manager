import Foundation

/// Service for persisting app data
final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let repositoriesKey = "savedRepositories"
    private let defaultEditorKey = "defaultEditor"
    private let defaultEditorIdKey = "defaultEditorId"
    private let worktreeBasePathKey = "worktreeBasePath"
    private let preferredBaseBranchesKey = "preferredBaseBranches"
    private let worktreeBaseBranchesKey = "worktreeBaseBranches"

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

    // MARK: - Preferred Base Branches

    func preferredBaseBranch(forRepositoryId id: UUID) -> String? {
        let dict = defaults.dictionary(forKey: preferredBaseBranchesKey) as? [String: String] ?? [:]
        return dict[id.uuidString]
    }

    func setPreferredBaseBranch(_ branch: String, forRepositoryId id: UUID) {
        var dict = defaults.dictionary(forKey: preferredBaseBranchesKey) as? [String: String] ?? [:]
        dict[id.uuidString] = branch
        defaults.set(dict, forKey: preferredBaseBranchesKey)
    }

    // MARK: - Worktree Base Branches

    func worktreeBaseBranch(forWorktreePath path: String) -> String? {
        let dict = defaults.dictionary(forKey: worktreeBaseBranchesKey) as? [String: String] ?? [:]
        return dict[path]
    }

    func setWorktreeBaseBranch(_ branch: String, forWorktreePath path: String) {
        var dict = defaults.dictionary(forKey: worktreeBaseBranchesKey) as? [String: String] ?? [:]
        dict[path] = branch
        defaults.set(dict, forKey: worktreeBaseBranchesKey)
    }

    func removeWorktreeBaseBranch(forWorktreePath path: String) {
        var dict = defaults.dictionary(forKey: worktreeBaseBranchesKey) as? [String: String] ?? [:]
        dict.removeValue(forKey: path)
        defaults.set(dict, forKey: worktreeBaseBranchesKey)
    }

    // MARK: - Copy Patterns

    private let defaultCopyPatternsKey = "defaultCopyPatterns"
    private let repoCopyPatternsKey = "repositoryCopyPatterns"

    var defaultCopyPatterns: [CopyPattern] {
        get {
            guard let data = defaults.data(forKey: defaultCopyPatternsKey),
                  let patterns = try? JSONDecoder().decode([CopyPattern].self, from: data) else {
                return []
            }
            return patterns
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: defaultCopyPatternsKey)
        }
    }

    func copyPatterns(forRepositoryId id: UUID) -> [CopyPattern]? {
        guard let data = defaults.data(forKey: repoCopyPatternsKey),
              let dict = try? JSONDecoder().decode([String: [CopyPattern]].self, from: data) else {
            return nil
        }
        return dict[id.uuidString]
    }

    func setCopyPatterns(_ patterns: [CopyPattern], forRepositoryId id: UUID) {
        var dict: [String: [CopyPattern]] = [:]
        if let data = defaults.data(forKey: repoCopyPatternsKey),
           let existing = try? JSONDecoder().decode([String: [CopyPattern]].self, from: data) {
            dict = existing
        }
        dict[id.uuidString] = patterns
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: repoCopyPatternsKey)
        }
    }

    func removeCopyPatterns(forRepositoryId id: UUID) {
        var dict: [String: [CopyPattern]] = [:]
        if let data = defaults.data(forKey: repoCopyPatternsKey),
           let existing = try? JSONDecoder().decode([String: [CopyPattern]].self, from: data) {
            dict = existing
        }
        dict.removeValue(forKey: id.uuidString)
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: repoCopyPatternsKey)
        }
    }

    func effectiveCopyPatterns(forRepositoryId id: UUID) -> [CopyPattern] {
        copyPatterns(forRepositoryId: id) ?? defaultCopyPatterns
    }
}
