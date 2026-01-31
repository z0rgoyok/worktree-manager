import Foundation
@testable import WorktreeManager

final class InMemoryPreferencesStore: PreferencesStore {
    var repositories: [Repository]
    var worktreeBasePath: String
    var expandedRepositoryIds: Set<UUID> = []
    var lastSelectedRepositoryId: UUID?
    var lastSelectedWorktreePath: String?
    var defaultCopyPatterns: [CopyPattern] = []
    var rememberEditorChoice: Bool = false
    var enabledEditorIds: Set<String>? = nil
    private var preferredBaseBranches: [UUID: String] = [:]
    private var worktreeBaseBranches: [String: String] = [:]
    private var repoCopyPatterns: [UUID: [CopyPattern]] = [:]
    private var preferredEditorIdsByRepositoryId: [UUID: String] = [:]

    private(set) var saveRepositoriesCalls: [[Repository]] = []

    init(
        repositories: [Repository] = [],
        worktreeBasePath: String = "/worktrees",
        defaultCopyPatterns: [CopyPattern] = []
    ) {
        self.repositories = repositories
        self.worktreeBasePath = worktreeBasePath
        self.defaultCopyPatterns = defaultCopyPatterns
    }

    func loadRepositories() -> [Repository] {
        repositories
    }

    func saveRepositories(_ repositories: [Repository]) {
        self.repositories = repositories
        saveRepositoriesCalls.append(repositories)
    }

    func preferredBaseBranch(forRepositoryId id: UUID) -> String? {
        preferredBaseBranches[id]
    }

    func setPreferredBaseBranch(_ branch: String, forRepositoryId id: UUID) {
        preferredBaseBranches[id] = branch
    }

    func worktreeBaseBranch(forWorktreePath path: String) -> String? {
        worktreeBaseBranches[path]
    }

    func setWorktreeBaseBranch(_ branch: String, forWorktreePath path: String) {
        worktreeBaseBranches[path] = branch
    }

    func removeWorktreeBaseBranch(forWorktreePath path: String) {
        worktreeBaseBranches.removeValue(forKey: path)
    }

    func copyPatterns(forRepositoryId id: UUID) -> [CopyPattern]? {
        repoCopyPatterns[id]
    }

    func setCopyPatterns(_ patterns: [CopyPattern], forRepositoryId id: UUID) {
        repoCopyPatterns[id] = patterns
    }

    func removeCopyPatterns(forRepositoryId id: UUID) {
        repoCopyPatterns.removeValue(forKey: id)
    }

    func effectiveCopyPatterns(forRepositoryId id: UUID) -> [CopyPattern] {
        repoCopyPatterns[id] ?? defaultCopyPatterns
    }

    // MARK: - Preferred Editor (per repository)

    func preferredEditorId(forRepositoryId id: UUID) -> String? {
        preferredEditorIdsByRepositoryId[id]
    }

    func setPreferredEditorId(_ editorId: String, forRepositoryId id: UUID) {
        preferredEditorIdsByRepositoryId[id] = editorId
    }

    func removePreferredEditorId(forRepositoryId id: UUID) {
        preferredEditorIdsByRepositoryId.removeValue(forKey: id)
    }

    // MARK: - Enabled Editors

    func isEditorEnabled(_ editorId: String) -> Bool {
        guard let enabledEditorIds else { return true }
        return enabledEditorIds.contains(editorId)
    }

    func setEditorEnabled(_ editorId: String, enabled: Bool, allEditorIds: [String]) {
        var current = enabledEditorIds ?? Set(allEditorIds)
        if enabled {
            current.insert(editorId)
        } else {
            current.remove(editorId)
        }
        self.enabledEditorIds = current
    }
}
