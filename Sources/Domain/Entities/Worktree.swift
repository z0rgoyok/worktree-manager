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
