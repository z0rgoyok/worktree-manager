import Foundation
import Combine

/// Central application state and use cases
@MainActor
final class AppStore: ObservableObject {
    // MARK: - Published State

    @Published var repositories: [Repository] = []
    @Published var selectedRepository: Repository?
    @Published var worktrees: [Worktree] = []
    @Published var worktreeStatuses: [String: WorktreeStatus] = [:]  // path -> status
    @Published var branches: [String] = []
    @Published var worktreeBasePath: String
    @Published var defaultEditorId: String
    @Published var defaultCopyPatterns: [CopyPattern]
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    @Published var lastCopyResult: CopyResult?

    // MARK: - Dependencies

    private let git: GitClient
    private var preferences: PreferencesStore
    private let editorOpener: EditorOpening
    private let fileSystemWatcher: FileSystemWatching
    private let fileSystem: FileSystemHandling
    private let system: SystemOpening

    private let ioQueue = DispatchQueue(label: "worktree-manager.io", qos: .userInitiated)

    // MARK: - Initialization

    init(
        git: GitClient = GitService.shared,
        preferences: PreferencesStore = StorageService.shared,
        editorOpener: EditorOpening = EditorService.shared,
        fileSystemWatcher: FileSystemWatching = FileSystemWatcher(),
        fileSystem: FileSystemHandling = FileSystemService.shared,
        system: SystemOpening = SystemService.shared,
        loadOnInit: Bool = true
    ) {
        self.git = git
        self.preferences = preferences
        self.editorOpener = editorOpener
        self.fileSystemWatcher = fileSystemWatcher
        self.fileSystem = fileSystem
        self.system = system
        self.worktreeBasePath = preferences.worktreeBasePath
        self.defaultEditorId = preferences.defaultEditorId
        self.defaultCopyPatterns = preferences.defaultCopyPatterns

        if loadOnInit {
            setupFileSystemWatcher()
            Task { await loadRepositories() }
        }
    }

    private func setupFileSystemWatcher() {
        fileSystemWatcher.setChangeHandler { [weak self] changedPaths in
            guard let self else { return }
            Task { await self.handleFileSystemChange(changedPaths) }
        }
    }

    private func updateWatchedPaths() {
        var paths = Set<String>()

        let basePath = worktreeBasePath

        // Always watch the worktree base path if it exists
        if fileSystem.fileExists(atPath: basePath) {
            paths.insert(basePath)
        }

        // Watch .git/worktrees directory in the repository itself
        if let repo = selectedRepository {
            let gitWorktreesPath = "\(repo.path)/.git/worktrees"
            if fileSystem.fileExists(atPath: gitWorktreesPath) {
                paths.insert(gitWorktreesPath)
            }
        }

        fileSystemWatcher.updateWatchedPaths(paths)
    }

    // MARK: - Repository Use Cases

    func loadRepositories() async {
        repositories = preferences.loadRepositories()
        // Auto-select first repository
        if selectedRepository == nil, let first = repositories.first {
            await selectRepository(first)
        }
    }

    func addRepository(at path: String) async {
        do {
            let rootPath = try await runIO { try self.git.getRepositoryRoot(at: path) }

            // Check if already added
            guard !repositories.contains(where: { $0.path == rootPath }) else {
                showError(message: "Repository already added")
                return
            }

            let repo = Repository(path: rootPath)
            repositories.append(repo)
            preferences.saveRepositories(repositories)

            await selectRepository(repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func removeRepository(_ repo: Repository) async {
        repositories.removeAll { $0.id == repo.id }
        preferences.saveRepositories(repositories)

        if selectedRepository?.id == repo.id {
            if let selected = repositories.first {
                await selectRepository(selected)
            } else {
                selectedRepository = nil
                worktrees = []
                branches = []
            }
        }
    }

    func selectRepository(_ repo: Repository) async {
        selectedRepository = repo
        await refreshWorktrees(for: repo)
        await loadBranches(for: repo)
    }

    /// Load worktrees for a repository without changing selection
    /// Returns the loaded worktrees directly
    func loadWorktreesOnly(for repo: Repository) async -> [Worktree] {
        do {
            let listedWorktrees = try await runIO { try self.git.listWorktrees(at: repo.path) }
            let enrichedWorktrees = listedWorktrees.map { worktree in
                let baseBranch = preferences.worktreeBaseBranch(forWorktreePath: worktree.path)
                return worktree.withBaseBranch(baseBranch)
            }
            return enrichedWorktrees
        } catch {
            return []
        }
    }

    // MARK: - Worktree Use Cases

    func refreshWorktrees(for repo: Repository? = nil) async {
        guard let repo = repo ?? selectedRepository else {
            worktrees = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let listedWorktrees = try await runIO { try self.git.listWorktrees(at: repo.path) }
            let enrichedWorktrees = listedWorktrees.map { worktree in
                let baseBranch = preferences.worktreeBaseBranch(forWorktreePath: worktree.path)
                return worktree.withBaseBranch(baseBranch)
            }
            if enrichedWorktrees != worktrees {
                worktrees = enrichedWorktrees
            }
        } catch {
            showError(message: error.localizedDescription)
            worktrees = []
        }

        updateWatchedPaths()
        await refreshAllStatuses()
    }

    func loadBranches(for repo: Repository? = nil) async {
        guard let repo = repo ?? selectedRepository else {
            branches = []
            return
        }

        do {
            branches = try await runIO { try self.git.listBranches(at: repo.path) }
        } catch {
            branches = []
        }
    }

    func createWorktree(
        name: String,
        branch: String,
        createNewBranch: Bool,
        baseBranch: String?,
        copyPatterns: [CopyPattern]? = nil
    ) async {
        guard let repo = selectedRepository else { return }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(message: "Worktree name is required")
            return
        }
        guard !branch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(message: "Branch name is required")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let basePath = worktreeBasePath
            let repoName = repo.name
            let parentPath = "\(basePath)/\(repoName)"
            let worktreePath = "\(parentPath)/\(name)"

            try await runIO { try self.fileSystem.createDirectory(atPath: parentPath, withIntermediateDirectories: true) }
            try await runIO {
                try self.git.createWorktree(
                    at: repo.path,
                    worktreePath: worktreePath,
                    branch: branch,
                    createBranch: createNewBranch,
                    baseBranch: baseBranch
                )
            }

            if let baseBranch {
                preferences.setWorktreeBaseBranch(baseBranch, forWorktreePath: worktreePath)
            }

            // Copy files from main worktree
            let patterns = copyPatterns ?? effectiveCopyPatterns(for: repo)
            if !patterns.isEmpty {
                let result = await copyFiles(patterns: patterns, from: repo.path, to: worktreePath)
                lastCopyResult = result
            }

            await refreshWorktrees(for: repo)
            await loadBranches(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func branchExists(_ branch: String) -> Bool {
        guard let repo = selectedRepository else { return false }
        return git.branchExists(at: repo.path, branch: branch)
    }

    func recreateBranchAndWorktree(name: String, branch: String, baseBranch: String, copyPatterns: [CopyPattern]? = nil) async {
        guard let repo = selectedRepository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await runIO { try self.git.deleteBranch(at: repo.path, branch: branch, force: true) }

            let basePath = worktreeBasePath
            let repoName = repo.name
            let parentPath = "\(basePath)/\(repoName)"
            let worktreePath = "\(parentPath)/\(name)"

            try await runIO { try self.fileSystem.createDirectory(atPath: parentPath, withIntermediateDirectories: true) }
            try await runIO {
                try self.git.createWorktree(
                    at: repo.path,
                    worktreePath: worktreePath,
                    branch: branch,
                    createBranch: true,
                    baseBranch: baseBranch
                )
            }

            preferences.setWorktreeBaseBranch(baseBranch, forWorktreePath: worktreePath)

            // Copy files from main worktree
            let patterns = copyPatterns ?? effectiveCopyPatterns(for: repo)
            if !patterns.isEmpty {
                let result = await copyFiles(patterns: patterns, from: repo.path, to: worktreePath)
                lastCopyResult = result
            }

            await refreshWorktrees(for: repo)
            await loadBranches(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func removeWorktree(_ worktree: Worktree, force: Bool = false, deleteBranch: Bool = false) async {
        guard let repo = selectedRepository else { return }
        guard !worktree.isMain else {
            showError(message: GitError.cannotRemoveMainWorktree.localizedDescription)
            return
        }

        isLoading = true
        let branchToDelete = deleteBranch ? worktree.branch : nil
        defer { isLoading = false }

        do {
            try await runIO { try self.git.removeWorktree(at: repo.path, worktreePath: worktree.path, force: force) }

            preferences.removeWorktreeBaseBranch(forWorktreePath: worktree.path)

            if let branch = branchToDelete, !branch.isEmpty && branch != "detached HEAD" {
                try? await runIO { try self.git.deleteBranch(at: repo.path, branch: branch, force: force) }
            }

            await refreshWorktrees(for: repo)
            await loadBranches(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    /// Complete worktree with all cleanup options
    func completeWorktree(_ worktree: Worktree, options: CompleteWorktreeOptions) async {
        guard let repo = selectedRepository else { return }
        guard !worktree.isMain else {
            showError(message: GitError.cannotRemoveMainWorktree.localizedDescription)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Step 1: Merge into target branch if requested
            if options.mergeIntoTarget {
                try await runIO { try self.git.mergeBranch(at: repo.path, source: worktree.branch, into: options.targetBranch) }
            }

            // Step 2: Pull latest changes to target branch if requested
            if options.pullTargetFirst {
                // Find worktree for target branch to pull there
                let worktrees = try await runIO { try self.git.listWorktrees(at: repo.path) }
                if let targetWorktree = worktrees.first(where: { $0.branch == options.targetBranch }) {
                    try await runIO { try self.git.pull(at: targetWorktree.path) }
                }
            }

            // Step 3: Remove the worktree directory
            try await runIO { try self.git.removeWorktree(at: repo.path, worktreePath: worktree.path, force: options.force) }

            preferences.removeWorktreeBaseBranch(forWorktreePath: worktree.path)

            // Step 4: Delete local branch if requested
            if options.deleteLocalBranch && !worktree.branch.isEmpty && worktree.branch != "detached HEAD" {
                try? await runIO { try self.git.deleteBranch(at: repo.path, branch: worktree.branch, force: options.force) }
            }

            // Step 5: Delete remote branch if requested
            if options.deleteRemoteBranch && !worktree.branch.isEmpty {
                try? await runIO { try self.git.deleteRemoteBranch(at: repo.path, branch: worktree.branch) }
            }

            await refreshWorktrees(for: repo)
            await loadBranches(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    /// Check if remote branch exists for a worktree
    func hasRemoteBranch(for worktree: Worktree) -> Bool {
        guard let repo = selectedRepository else { return false }
        return git.hasRemoteBranch(at: repo.path, branch: worktree.branch)
    }

    func lockWorktree(_ worktree: Worktree) async {
        guard let repo = selectedRepository else { return }

        do {
            try await runIO { try self.git.lockWorktree(at: repo.path, worktreePath: worktree.path, reason: nil) }
            await refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func unlockWorktree(_ worktree: Worktree) async {
        guard let repo = selectedRepository else { return }

        do {
            try await runIO { try self.git.unlockWorktree(at: repo.path, worktreePath: worktree.path) }
            await refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func pruneWorktrees() async {
        guard let repo = selectedRepository else { return }

        do {
            try await runIO { try self.git.pruneWorktrees(at: repo.path) }
            await refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    // MARK: - Editor Use Cases

    func openInEditor(_ worktree: Worktree, editor: Editor) {
        do {
            try editorOpener.open(path: worktree.path, with: editor)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func openInFinder(_ worktree: Worktree) {
        system.revealInFinder(path: worktree.path)
    }

    func openInTerminal(_ worktree: Worktree) {
        system.openTerminal(atPath: worktree.path)
    }

    func availableEditors() -> [Editor] {
        editorOpener.availableEditors()
    }

    // MARK: - Status Use Cases

    func refreshWorktreeStatus(_ worktree: Worktree) async {
        guard !worktree.isPrunable else {
            worktreeStatuses[worktree.path] = nil
            return
        }

        let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
        if let existing = worktreeStatuses[worktree.path], existing == status {
            return
        }
        worktreeStatuses[worktree.path] = status
    }

    func refreshAllStatuses() async {
        await withTaskGroup(of: Void.self) { group in
            for worktree in worktrees where !worktree.isPrunable {
                group.addTask { [weak self] in
                    await self?.refreshWorktreeStatus(worktree)
                }
            }
        }
    }

    func getStatus(for worktree: Worktree) -> WorktreeStatus? {
        worktreeStatuses[worktree.path]
    }

    // MARK: - Git Actions

    func push(_ worktree: Worktree) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
            try await runIO { try self.git.push(at: worktree.path, setUpstream: !status.hasRemote) }
            await refreshWorktreeStatus(worktree)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func createPR(_ worktree: Worktree, title: String, body: String, baseBranch: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let status = await runIO { self.git.getWorktreeStatus(at: worktree.path) }
            if status.hasUnpushedCommits || !status.hasRemote {
                try await runIO { try self.git.push(at: worktree.path, setUpstream: !status.hasRemote) }
            }

            let prUrl = try await runIO { try self.git.createPR(at: worktree.path, title: title, body: body, baseBranch: baseBranch) }
            await refreshWorktreeStatus(worktree)

            if let url = URL(string: prUrl) {
                system.openURL(url)
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func openPR(_ worktree: Worktree) {
        guard let status = worktreeStatuses[worktree.path],
              let prStatus = status.prStatus,
              let url = URL(string: prStatus.url) else {
            return
        }
        system.openURL(url)
    }

    func mergeBranch(_ worktree: Worktree, into targetBranch: String) async {
        guard let repo = selectedRepository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await runIO { try self.git.mergeBranch(at: repo.path, source: worktree.branch, into: targetBranch) }
            await refreshWorktrees(for: repo)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    // MARK: - Settings Use Cases

    func setWorktreeBasePath(_ path: String) {
        worktreeBasePath = path
        preferences.worktreeBasePath = path
        updateWatchedPaths()
    }

    func setDefaultEditorId(_ id: String) {
        defaultEditorId = id
        preferences.defaultEditorId = id
    }

    func preferredBaseBranch() -> String? {
        guard let repo = selectedRepository else { return nil }
        return preferences.preferredBaseBranch(forRepositoryId: repo.id)
    }

    func setPreferredBaseBranch(_ branch: String) {
        guard let repo = selectedRepository else { return }
        preferences.setPreferredBaseBranch(branch, forRepositoryId: repo.id)
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

    // MARK: - Private

    private func runIO<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            ioQueue.async {
                do {
                    continuation.resume(returning: try work())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func runIO<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            ioQueue.async {
                continuation.resume(returning: work())
            }
        }
    }

    private func handleFileSystemChange(_ changedPaths: Set<String>) async {
        guard let repo = selectedRepository else { return }
        guard !changedPaths.isEmpty else {
            await refreshWorktrees(for: repo)
            return
        }

        let gitWorktreesPath = "\(repo.path)/.git/worktrees"
        let touchesGitWorktrees = changedPaths.contains { $0.hasPrefix(gitWorktreesPath) }

        if touchesGitWorktrees {
            await refreshWorktrees(for: repo)
        } else {
            await refreshAllStatuses()
        }
    }

    // MARK: - Copy Patterns

    func effectiveCopyPatterns(for repo: Repository) -> [CopyPattern] {
        preferences.effectiveCopyPatterns(forRepositoryId: repo.id)
    }

    func copyPatterns(for repo: Repository) -> [CopyPattern]? {
        preferences.copyPatterns(forRepositoryId: repo.id)
    }

    func setCopyPatterns(_ patterns: [CopyPattern], for repo: Repository) {
        preferences.setCopyPatterns(patterns, forRepositoryId: repo.id)
    }

    func removeCopyPatterns(for repo: Repository) {
        preferences.removeCopyPatterns(forRepositoryId: repo.id)
    }

    func setDefaultCopyPatterns(_ patterns: [CopyPattern]) {
        defaultCopyPatterns = patterns
        preferences.defaultCopyPatterns = patterns
    }

    func getCopyPreview(for repo: Repository, patterns: [CopyPattern]? = nil) -> [CopyPreviewItem] {
        let effectivePatterns = patterns ?? effectiveCopyPatterns(for: repo)
        return effectivePatterns.map { pattern in
            let fullPath = (repo.path as NSString).appendingPathComponent(pattern.pattern)
            let exists = fileSystem.fileExists(atPath: fullPath)
            let isDir = fileSystem.isDirectory(atPath: fullPath)
            let size: Int64?
            if exists {
                size = isDir ? fileSystem.directorySize(atPath: fullPath) : fileSystem.fileSize(atPath: fullPath)
            } else {
                size = nil
            }
            return CopyPreviewItem(pattern: pattern.pattern, exists: exists, size: size, isDirectory: isDir)
        }
    }

    private func copyFiles(patterns: [CopyPattern], from sourcePath: String, to destinationPath: String) async -> CopyResult {
        var copied: [String] = []
        var skipped: [String] = []
        var failed: [(path: String, error: String)] = []

        for pattern in patterns {
            let srcPath = (sourcePath as NSString).appendingPathComponent(pattern.pattern)
            let dstPath = (destinationPath as NSString).appendingPathComponent(pattern.pattern)

            guard fileSystem.fileExists(atPath: srcPath) else {
                skipped.append(pattern.pattern)
                continue
            }

            do {
                try await runIO { try self.fileSystem.copyItem(atPath: srcPath, toPath: dstPath) }
                copied.append(pattern.pattern)
            } catch {
                failed.append((pattern.pattern, error.localizedDescription))
            }
        }

        return CopyResult(copied: copied, skipped: skipped, failed: failed)
    }
}
