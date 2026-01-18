import Foundation

protocol GitClient {
    func getRepositoryRoot(at path: String) throws -> String

    func listBranches(at repoPath: String) throws -> [String]
    func branchExists(at repoPath: String, branch: String) -> Bool
    func deleteBranch(at repoPath: String, branch: String, force: Bool) throws

    func listWorktrees(at repoPath: String) throws -> [Worktree]
    func createWorktree(
        at repoPath: String,
        worktreePath: String,
        branch: String,
        createBranch: Bool,
        baseBranch: String?
    ) throws
    func removeWorktree(at repoPath: String, worktreePath: String, force: Bool) throws
    func lockWorktree(at repoPath: String, worktreePath: String, reason: String?) throws
    func unlockWorktree(at repoPath: String, worktreePath: String) throws
    func pruneWorktrees(at repoPath: String) throws

    func getWorktreeStatus(at worktreePath: String) -> WorktreeStatus

    func push(at worktreePath: String, setUpstream: Bool) throws
    func pull(at worktreePath: String) throws
    func createPR(at worktreePath: String, title: String, body: String, baseBranch: String?) throws -> String
    func mergeBranch(at repoPath: String, source: String, into target: String) throws
    func deleteRemoteBranch(at repoPath: String, branch: String) throws
    func hasRemoteBranch(at repoPath: String, branch: String) -> Bool
}

