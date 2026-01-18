import Foundation

/// Represents a git worktree
struct Worktree: Identifiable, Hashable {
    let id: String
    let path: String
    let branch: String
    let isMain: Bool
    let commitHash: String?
    let isLocked: Bool
    let isPrunable: Bool
    let baseBranch: String?

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }

    init(
        path: String,
        branch: String,
        isMain: Bool = false,
        commitHash: String? = nil,
        isLocked: Bool = false,
        isPrunable: Bool = false,
        baseBranch: String? = nil
    ) {
        self.id = path
        self.path = path
        self.branch = branch
        self.isMain = isMain
        self.commitHash = commitHash
        self.isLocked = isLocked
        self.isPrunable = isPrunable
        self.baseBranch = baseBranch
    }

    func withBaseBranch(_ baseBranch: String?) -> Worktree {
        Worktree(
            path: path,
            branch: branch,
            isMain: isMain,
            commitHash: commitHash,
            isLocked: isLocked,
            isPrunable: isPrunable,
            baseBranch: baseBranch
        )
    }
}

/// Options for completing/removing a worktree
struct CompleteWorktreeOptions {
    /// The target branch to merge into (e.g., main, master)
    let targetBranch: String

    /// Whether to merge the worktree branch into target before deleting
    let mergeIntoTarget: Bool

    /// Whether to pull latest changes to target branch first
    let pullTargetFirst: Bool

    /// Whether to delete the local branch after removing worktree
    let deleteLocalBranch: Bool

    /// Whether to delete the remote branch
    let deleteRemoteBranch: Bool

    /// Whether to force delete (ignores uncommitted changes)
    let force: Bool

    init(
        targetBranch: String,
        mergeIntoTarget: Bool = false,
        pullTargetFirst: Bool = false,
        deleteLocalBranch: Bool = true,
        deleteRemoteBranch: Bool = false,
        force: Bool = false
    ) {
        self.targetBranch = targetBranch
        self.mergeIntoTarget = mergeIntoTarget
        self.pullTargetFirst = pullTargetFirst
        self.deleteLocalBranch = deleteLocalBranch
        self.deleteRemoteBranch = deleteRemoteBranch
        self.force = force
    }
}
