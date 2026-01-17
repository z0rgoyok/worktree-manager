import Foundation
import SwiftUI

/// Central application state and use cases
@MainActor
final class AppStore: ObservableObject {
    // MARK: - Published State

    @Published var repositories: [Repository] = []
    @Published var selectedRepository: Repository?
    @Published var worktrees: [Worktree] = []
    @Published var branches: [String] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false

    // MARK: - Services

    private let git = GitService.shared
    private let storage = StorageService.shared
    private let editorService = EditorService.shared
    private let watcher = FileSystemWatcher()

    // MARK: - Initialization

    init() {
        setupFileSystemWatcher()
        loadRepositories()
    }

    private func setupFileSystemWatcher() {
        watcher.setChangeHandler { [weak self] in
            self?.refreshWorktrees()
        }
    }

    private func updateWatchedPaths() {
        var paths = Set<String>()

        let basePath = storage.worktreeBasePath

        // Always watch the worktree base path if it exists
        if FileManager.default.fileExists(atPath: basePath) {
            paths.insert(basePath)
        }

        // Watch .git/worktrees directory in the repository itself
        if let repo = selectedRepository {
            let gitWorktreesPath = "\(repo.path)/.git/worktrees"
            if FileManager.default.fileExists(atPath: gitWorktreesPath) {
                paths.insert(gitWorktreesPath)
            }
        }

        watcher.updateWatchedPaths(paths)
    }

    // MARK: - Repository Use Cases

    func loadRepositories() {
        repositories = storage.loadRepositories()
        // Auto-select first repository
        if selectedRepository == nil, let first = repositories.first {
            selectRepository(first)
        }
    }

    func addRepository(at path: String) {
        do {
            let rootPath = try git.getRepositoryRoot(at: path)

            // Check if already added
            guard !repositories.contains(where: { $0.path == rootPath }) else {
                showError(message: "Repository already added")
                return
            }

            let repo = Repository(path: rootPath)
            repositories.append(repo)
            storage.saveRepositories(repositories)

            selectRepository(repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func removeRepository(_ repo: Repository) {
        repositories.removeAll { $0.id == repo.id }
        storage.saveRepositories(repositories)

        if selectedRepository?.id == repo.id {
            selectedRepository = repositories.first
            if let selected = selectedRepository {
                refreshWorktrees(for: selected)
            } else {
                worktrees = []
                branches = []
            }
        }
    }

    func selectRepository(_ repo: Repository) {
        selectedRepository = repo
        refreshWorktrees(for: repo)
        loadBranches(for: repo)
    }

    // MARK: - Worktree Use Cases

    func refreshWorktrees(for repo: Repository? = nil) {
        guard let repo = repo ?? selectedRepository else {
            worktrees = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            worktrees = try git.listWorktrees(at: repo.path)
        } catch {
            showError(message: error.localizedDescription)
            worktrees = []
        }

        updateWatchedPaths()
    }

    func loadBranches(for repo: Repository? = nil) {
        guard let repo = repo ?? selectedRepository else {
            branches = []
            return
        }

        do {
            branches = try git.listBranches(at: repo.path)
        } catch {
            branches = []
        }
    }

    func createWorktree(
        name: String,
        branch: String,
        createNewBranch: Bool,
        baseBranch: String?
    ) {
        guard let repo = selectedRepository else { return }

        isLoading = true

        Task {
            defer {
                Task { @MainActor in
                    isLoading = false
                }
            }

            do {
                // Determine worktree path
                let basePath = storage.worktreeBasePath
                let repoName = repo.name
                let worktreePath = "\(basePath)/\(repoName)/\(name)"

                // Create base directory if needed
                try FileManager.default.createDirectory(
                    atPath: "\(basePath)/\(repoName)",
                    withIntermediateDirectories: true
                )

                try git.createWorktree(
                    at: repo.path,
                    worktreePath: worktreePath,
                    branch: branch,
                    createBranch: createNewBranch,
                    baseBranch: baseBranch
                )

                await MainActor.run {
                    refreshWorktrees(for: repo)
                }
            } catch {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }

    func branchExists(_ branch: String) -> Bool {
        guard let repo = selectedRepository else { return false }
        return git.branchExists(at: repo.path, branch: branch)
    }

    func recreateBranchAndWorktree(name: String, branch: String, baseBranch: String) {
        guard let repo = selectedRepository else { return }

        isLoading = true

        Task {
            defer {
                Task { @MainActor in
                    isLoading = false
                }
            }

            do {
                // Delete existing branch first
                try git.deleteBranch(at: repo.path, branch: branch, force: true)

                // Determine worktree path
                let basePath = storage.worktreeBasePath
                let repoName = repo.name
                let worktreePath = "\(basePath)/\(repoName)/\(name)"

                // Create base directory if needed
                try FileManager.default.createDirectory(
                    atPath: "\(basePath)/\(repoName)",
                    withIntermediateDirectories: true
                )

                // Create worktree with new branch
                try git.createWorktree(
                    at: repo.path,
                    worktreePath: worktreePath,
                    branch: branch,
                    createBranch: true,
                    baseBranch: baseBranch
                )

                await MainActor.run {
                    refreshWorktrees(for: repo)
                    loadBranches(for: repo)
                }
            } catch {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }

    func removeWorktree(_ worktree: Worktree, force: Bool = false, deleteBranch: Bool = false) {
        guard let repo = selectedRepository else { return }
        guard !worktree.isMain else {
            showError(message: "Cannot remove the main worktree")
            return
        }

        isLoading = true
        let branchToDelete = deleteBranch ? worktree.branch : nil

        Task {
            defer {
                Task { @MainActor in
                    isLoading = false
                }
            }

            do {
                try git.removeWorktree(at: repo.path, worktreePath: worktree.path, force: force)

                // Delete branch if requested
                if let branch = branchToDelete, !branch.isEmpty && branch != "detached HEAD" {
                    try? git.deleteBranch(at: repo.path, branch: branch, force: force)
                }

                await MainActor.run {
                    refreshWorktrees(for: repo)
                    loadBranches(for: repo)
                }
            } catch {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }

    func lockWorktree(_ worktree: Worktree) {
        guard let repo = selectedRepository else { return }

        do {
            try git.lockWorktree(at: repo.path, worktreePath: worktree.path)
            refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func unlockWorktree(_ worktree: Worktree) {
        guard let repo = selectedRepository else { return }

        do {
            try git.unlockWorktree(at: repo.path, worktreePath: worktree.path)
            refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func pruneWorktrees() {
        guard let repo = selectedRepository else { return }

        do {
            try git.pruneWorktrees(at: repo.path)
            refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    // MARK: - Editor Use Cases

    func openInEditor(_ worktree: Worktree, editor: Editor) {
        do {
            try editorService.open(path: worktree.path, with: editor)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func openInFinder(_ worktree: Worktree) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: worktree.path)
    }

    func openInTerminal(_ worktree: Worktree) {
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(worktree.path)'"
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    func availableEditors() -> [Editor] {
        editorService.availableEditors()
    }

    // MARK: - Error Handling

    private func showError(message: String) {
        error = message
        showError = true
    }

    func clearError() {
        error = nil
        showError = false
    }
}
