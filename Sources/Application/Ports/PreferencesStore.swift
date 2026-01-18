import Foundation

protocol PreferencesStore {
    func loadRepositories() -> [Repository]
    func saveRepositories(_ repositories: [Repository])

    var worktreeBasePath: String { get set }
    var defaultEditorId: String { get set }

    func preferredBaseBranch(forRepositoryId id: UUID) -> String?
    func setPreferredBaseBranch(_ branch: String, forRepositoryId id: UUID)

    func worktreeBaseBranch(forWorktreePath path: String) -> String?
    func setWorktreeBaseBranch(_ branch: String, forWorktreePath path: String)
    func removeWorktreeBaseBranch(forWorktreePath path: String)

    // MARK: - Copy Patterns

    /// Global default patterns to copy when creating worktrees
    var defaultCopyPatterns: [CopyPattern] { get set }

    /// Per-repository copy patterns (overrides defaults if set)
    func copyPatterns(forRepositoryId id: UUID) -> [CopyPattern]?
    func setCopyPatterns(_ patterns: [CopyPattern], forRepositoryId id: UUID)
    func removeCopyPatterns(forRepositoryId id: UUID)

    /// Effective patterns for a repository (per-repo if set, otherwise defaults)
    func effectiveCopyPatterns(forRepositoryId id: UUID) -> [CopyPattern]
}

