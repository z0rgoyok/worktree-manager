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

    // MARK: - Private Helpers

    private func run(_ command: String, args: [String]) -> ProcessResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + args
        process.standardOutput = outputPipe
        process.standardError = errorPipe

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

        return worktrees
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
