import Foundation

/// Service for executing git commands
final class GitService {
    static let shared = GitService()

    private init() {}

    // MARK: - Repository Operations

    /// Check if path is a git repository
    func isRepository(at path: String) -> Bool {
        let result = run("git", args: ["-C", path, "rev-parse", "--git-dir"])
        return result.exitCode == 0
    }

    /// Get the root directory of a repository
    func getRepositoryRoot(at path: String) throws -> String {
        let result = run("git", args: ["-C", path, "rev-parse", "--show-toplevel"])
        guard result.exitCode == 0, let root = result.output.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            throw GitError.notARepository(path: path)
        }
        return root
    }

    // MARK: - Branch Operations

    /// Get list of all branches
    func listBranches(at repoPath: String) throws -> [String] {
        let result = run("git", args: ["-C", repoPath, "branch", "-a", "--format=%(refname:short)"])
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
        return result.output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.contains("HEAD") }
    }

    /// Get current branch name
    func currentBranch(at repoPath: String) throws -> String {
        let result = run("git", args: ["-C", repoPath, "branch", "--show-current"])
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Delete a branch
    func deleteBranch(at repoPath: String, branch: String, force: Bool = false) throws {
        let flag = force ? "-D" : "-d"
        let result = run("git", args: ["-C", repoPath, "branch", flag, branch])
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
    }

    /// Check if a branch exists
    func branchExists(at repoPath: String, branch: String) -> Bool {
        let result = run("git", args: ["-C", repoPath, "show-ref", "--verify", "--quiet", "refs/heads/\(branch)"])
        return result.exitCode == 0
    }

    // MARK: - Worktree Operations

    /// List all worktrees for a repository
    func listWorktrees(at repoPath: String) throws -> [Worktree] {
        let result = run("git", args: ["-C", repoPath, "worktree", "list", "--porcelain"])
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }

        return parseWorktrees(from: result.output, mainRepoPath: repoPath)
    }

    /// Create a new worktree
    func createWorktree(
        at repoPath: String,
        worktreePath: String,
        branch: String,
        createBranch: Bool = false,
        baseBranch: String? = nil
    ) throws {
        var args = ["-C", repoPath, "worktree", "add"]

        if createBranch {
            args.append("-b")
            args.append(branch)
            args.append(worktreePath)
            if let base = baseBranch {
                args.append(base)
            }
        } else {
            args.append(worktreePath)
            args.append(branch)
        }

        let result = run("git", args: args)
        guard result.exitCode == 0 else {
            let error = result.error.lowercased()
            if error.contains("already exists") {
                if error.contains("branch") {
                    throw GitError.branchAlreadyExists(name: branch)
                } else {
                    throw GitError.worktreeAlreadyExists(name: worktreePath)
                }
            }
            throw GitError.commandFailed(message: result.error)
        }
    }

    /// Remove a worktree
    func removeWorktree(at repoPath: String, worktreePath: String, force: Bool = false) throws {
        var args = ["-C", repoPath, "worktree", "remove"]
        if force {
            args.append("--force")
        }
        args.append(worktreePath)

        let result = run("git", args: args)
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
    }

    /// Lock a worktree
    func lockWorktree(at repoPath: String, worktreePath: String, reason: String? = nil) throws {
        var args = ["-C", repoPath, "worktree", "lock"]
        if let reason = reason {
            args.append("--reason")
            args.append(reason)
        }
        args.append(worktreePath)

        let result = run("git", args: args)
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
    }

    /// Unlock a worktree
    func unlockWorktree(at repoPath: String, worktreePath: String) throws {
        let result = run("git", args: ["-C", repoPath, "worktree", "unlock", worktreePath])
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
    }

    /// Prune stale worktree information
    func pruneWorktrees(at repoPath: String) throws {
        let result = run("git", args: ["-C", repoPath, "worktree", "prune"])
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
    }

    // MARK: - Status Operations

    /// Get worktree status (ahead/behind, dirty, remote tracking)
    func getWorktreeStatus(at worktreePath: String) -> WorktreeStatus {
        // Check if dirty (uncommitted changes)
        let statusResult = run("git", args: ["-C", worktreePath, "status", "--porcelain"])
        let isDirty = !statusResult.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Get current branch
        let branchResult = run("git", args: ["-C", worktreePath, "branch", "--show-current"])
        let branch = branchResult.output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if has remote tracking branch
        let trackingResult = run("git", args: ["-C", worktreePath, "rev-parse", "--abbrev-ref", "\(branch)@{upstream}"])
        let hasRemote = trackingResult.exitCode == 0

        var ahead = 0
        var behind = 0

        if hasRemote {
            // Get ahead/behind counts
            let revListResult = run("git", args: ["-C", worktreePath, "rev-list", "--left-right", "--count", "\(branch)@{upstream}...\(branch)"])
            if revListResult.exitCode == 0 {
                let parts = revListResult.output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t")
                if parts.count == 2 {
                    behind = Int(parts[0]) ?? 0
                    ahead = Int(parts[1]) ?? 0
                }
            }
        }

        // Check for PR status
        let prStatus = getPRStatus(at: worktreePath, branch: branch)

        return WorktreeStatus(
            isDirty: isDirty,
            hasRemote: hasRemote,
            ahead: ahead,
            behind: behind,
            prStatus: prStatus
        )
    }

    /// Get PR status for a branch
    func getPRStatus(at worktreePath: String, branch: String) -> PRStatus? {
        let result = run("gh", args: ["pr", "view", branch, "--json", "number,state,url,title", "-R", "."], workingDirectory: worktreePath)

        guard result.exitCode == 0 else { return nil }

        // Parse JSON response
        guard let data = result.output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let number = json["number"] as? Int,
              let state = json["state"] as? String,
              let url = json["url"] as? String else {
            return nil
        }

        return PRStatus(
            number: number,
            state: state,
            url: url,
            title: json["title"] as? String
        )
    }

    // MARK: - Push/PR/Merge Operations

    /// Push current branch to remote
    func push(at worktreePath: String, setUpstream: Bool = false) throws {
        var args = ["-C", worktreePath, "push"]
        if setUpstream {
            args.append("-u")
            args.append("origin")
            args.append("HEAD")
        }

        let result = run("git", args: args)
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
    }

    /// Create a pull request using gh CLI
    func createPR(at worktreePath: String, title: String, body: String, baseBranch: String?) throws -> String {
        var args = ["pr", "create", "--title", title, "--body", body]
        if let base = baseBranch {
            args.append("--base")
            args.append(base)
        }

        let result = run("gh", args: args, workingDirectory: worktreePath)
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error.isEmpty ? result.output : result.error)
        }

        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Merge a branch into another
    func mergeBranch(at repoPath: String, source: String, into target: String) throws {
        // First checkout target
        let checkoutResult = run("git", args: ["-C", repoPath, "checkout", target])
        guard checkoutResult.exitCode == 0 else {
            throw GitError.commandFailed(message: checkoutResult.error)
        }

        // Then merge source
        let mergeResult = run("git", args: ["-C", repoPath, "merge", source, "--no-edit"])
        guard mergeResult.exitCode == 0 else {
            throw GitError.commandFailed(message: mergeResult.error)
        }
    }

    /// Fetch from remote
    func fetch(at worktreePath: String) throws {
        let result = run("git", args: ["-C", worktreePath, "fetch"])
        guard result.exitCode == 0 else {
            throw GitError.commandFailed(message: result.error)
        }
    }

    // MARK: - Private Helpers

    private func run(_ command: String, args: [String], workingDirectory: String? = nil) -> ProcessResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + args
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        if let wd = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: wd)
        }

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            return ProcessResult(
                exitCode: process.terminationStatus,
                output: String(data: outputData, encoding: .utf8) ?? "",
                error: String(data: errorData, encoding: .utf8) ?? ""
            )
        } catch {
            return ProcessResult(exitCode: -1, output: "", error: error.localizedDescription)
        }
    }

    private func parseWorktrees(from output: String, mainRepoPath: String) -> [Worktree] {
        var worktrees: [Worktree] = []
        var currentPath: String?
        var currentBranch: String = ""
        var currentCommit: String?
        var isLocked = false
        var isPrunable = false

        let lines = output.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            let lineStr = String(line)

            if lineStr.hasPrefix("worktree ") {
                // Save previous worktree if exists
                if let path = currentPath {
                    let isMain = path == mainRepoPath || URL(fileURLWithPath: path).standardized == URL(fileURLWithPath: mainRepoPath).standardized
                    worktrees.append(Worktree(
                        path: path,
                        branch: currentBranch,
                        isMain: isMain,
                        commitHash: currentCommit,
                        isLocked: isLocked,
                        isPrunable: isPrunable
                    ))
                }
                // Start new worktree
                currentPath = String(lineStr.dropFirst("worktree ".count))
                currentBranch = ""
                currentCommit = nil
                isLocked = false
                isPrunable = false
            } else if lineStr.hasPrefix("HEAD ") {
                currentCommit = String(lineStr.dropFirst("HEAD ".count))
            } else if lineStr.hasPrefix("branch ") {
                let branch = String(lineStr.dropFirst("branch ".count))
                // Remove refs/heads/ prefix
                currentBranch = branch.replacingOccurrences(of: "refs/heads/", with: "")
            } else if lineStr == "detached" {
                currentBranch = "detached HEAD"
            } else if lineStr == "locked" {
                isLocked = true
            } else if lineStr == "prunable" {
                isPrunable = true
            }
        }

        // Don't forget the last one
        if let path = currentPath {
            let isMain = path == mainRepoPath || URL(fileURLWithPath: path).standardized == URL(fileURLWithPath: mainRepoPath).standardized
            worktrees.append(Worktree(
                path: path,
                branch: currentBranch,
                isMain: isMain,
                commitHash: currentCommit,
                isLocked: isLocked,
                isPrunable: isPrunable
            ))
        }

        // Sort for stable UI order: main first, then alphabetically by name
        return worktrees.sorted { lhs, rhs in
            if lhs.isMain != rhs.isMain {
                return lhs.isMain
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

// MARK: - Helper Types

private struct ProcessResult {
    let exitCode: Int32
    let output: String
    let error: String
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
