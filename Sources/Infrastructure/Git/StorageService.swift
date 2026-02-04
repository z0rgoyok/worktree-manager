import Foundation

/// Service for persisting app data
final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let repositoriesKey = "savedRepositories"
    private let worktreeBasePathKey = "worktreeBasePath"
    private let preferredBaseBranchesKey = "preferredBaseBranches"
    private let worktreeBaseBranchesKey = "worktreeBaseBranches"
    private let expandedRepositoriesKey = "expandedRepositories"
    private let lastSelectedRepositoryIdKey = "lastSelectedRepositoryId"
    private let lastSelectedWorktreePathKey = "lastSelectedWorktreePath"
    private let rememberEditorChoiceKey = "rememberEditorChoice"
    private let repositoryPreferredEditorsKey = "repositoryPreferredEditors"
    private let enabledEditorIdsKey = "enabledEditorIds"

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

    // MARK: - Remember Editor Choice (per repository)

    var rememberEditorChoice: Bool {
        get { defaults.bool(forKey: rememberEditorChoiceKey) }
        set { defaults.set(newValue, forKey: rememberEditorChoiceKey) }
    }

    func preferredEditorId(forRepositoryId id: UUID) -> String? {
        let dict = defaults.dictionary(forKey: repositoryPreferredEditorsKey) as? [String: String] ?? [:]
        return dict[id.uuidString]
    }

    func setPreferredEditorId(_ editorId: String, forRepositoryId id: UUID) {
        var dict = defaults.dictionary(forKey: repositoryPreferredEditorsKey) as? [String: String] ?? [:]
        dict[id.uuidString] = editorId
        defaults.set(dict, forKey: repositoryPreferredEditorsKey)
    }

    func removePreferredEditorId(forRepositoryId id: UUID) {
        var dict = defaults.dictionary(forKey: repositoryPreferredEditorsKey) as? [String: String] ?? [:]
        dict.removeValue(forKey: id.uuidString)
        defaults.set(dict, forKey: repositoryPreferredEditorsKey)
    }

    // MARK: - Enabled Editors

    /// Returns nil if never configured (means all enabled), or the set of enabled IDs
    var enabledEditorIds: Set<String>? {
        get {
            guard let array = defaults.array(forKey: enabledEditorIdsKey) as? [String] else {
                return nil
            }
            return Set(array)
        }
        set {
            if let ids = newValue {
                defaults.set(Array(ids).sorted(), forKey: enabledEditorIdsKey)
            } else {
                defaults.removeObject(forKey: enabledEditorIdsKey)
            }
        }
    }

    func isEditorEnabled(_ editorId: String) -> Bool {
        guard let enabled = enabledEditorIds else {
            return true // All enabled by default
        }
        return enabled.contains(editorId)
    }

    func setEditorEnabled(_ editorId: String, enabled: Bool, allEditorIds: [String]) {
        var current = enabledEditorIds ?? Set(allEditorIds)
        if enabled {
            current.insert(editorId)
        } else {
            current.remove(editorId)
        }
        enabledEditorIds = current
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

    // MARK: - Sidebar Expansion (UI)

    var expandedRepositoryIds: Set<UUID> {
        get {
            let strings = defaults.array(forKey: expandedRepositoriesKey) as? [String] ?? []
            let ids = strings.compactMap(UUID.init(uuidString:))
            return Set(ids)
        }
        set {
            let strings = newValue.map(\.uuidString).sorted()
            defaults.set(strings, forKey: expandedRepositoriesKey)
        }
    }

    // MARK: - Sidebar Selection (UI)

    var lastSelectedRepositoryId: UUID? {
        get {
            guard let value = defaults.string(forKey: lastSelectedRepositoryIdKey) else { return nil }
            return UUID(uuidString: value)
        }
        set {
            if let id = newValue {
                defaults.set(id.uuidString, forKey: lastSelectedRepositoryIdKey)
            } else {
                defaults.removeObject(forKey: lastSelectedRepositoryIdKey)
            }
        }
    }

    var lastSelectedWorktreePath: String? {
        get { defaults.string(forKey: lastSelectedWorktreePathKey) }
        set {
            if let path = newValue, !path.isEmpty {
                defaults.set(path, forKey: lastSelectedWorktreePathKey)
            } else {
                defaults.removeObject(forKey: lastSelectedWorktreePathKey)
            }
        }
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
