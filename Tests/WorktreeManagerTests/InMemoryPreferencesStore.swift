import Foundation
@testable import WorktreeManager

final class InMemoryPreferencesStore: PreferencesStore {
    var repositories: [Repository]
    var worktreeBasePath: String
    var defaultEditorId: String
    var defaultCopyPatterns: [CopyPattern] = []
    private var preferredBaseBranches: [UUID: String] = [:]
    private var worktreeBaseBranches: [String: String] = [:]
    private var repoCopyPatterns: [UUID: [CopyPattern]] = [:]

    private(set) var saveRepositoriesCalls: [[Repository]] = []

    init(
        repositories: [Repository] = [],
        worktreeBasePath: String = "/worktrees",
        defaultEditorId: String = "",
        defaultCopyPatterns: [CopyPattern] = []
    ) {
        self.repositories = repositories
        self.worktreeBasePath = worktreeBasePath
        self.defaultEditorId = defaultEditorId
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
}

