import Foundation

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

