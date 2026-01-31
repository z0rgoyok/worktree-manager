import Foundation
import Combine

/// Central application state and use cases coordinator
@MainActor
final class AppStore: ObservableObject {
    // MARK: - Published State

    @Published var repositories: [Repository] = []
    @Published var selectedRepository: Repository?
    @Published var selectedWorktree: Worktree?
    @Published var worktrees: [Worktree] = []
    @Published var branches: [String] = []
    @Published var worktreeBasePath: String
    @Published var defaultCopyPatterns: [CopyPattern]
    @Published var isLoading = false

    // MARK: - Dependencies (internal for extensions)

    let git: GitClient
    var preferences: PreferencesStore
    let editorOpener: EditorOpening
    let fileSystemWatcher: FileSystemWatching
    let fileSystem: FileSystemHandling
    let system: SystemOpening
    let statusStore: WorktreeStatusStore
    let activityCenter: ActivityCenter

    private let ioQueue = DispatchQueue(label: "worktree-manager.io", qos: .userInitiated)
    var statusRefreshSuppressionUntilByWorktreePath: [String: Date] = [:]

    // MARK: - Initialization

    /// Factory method for creating AppStore with default dependencies
    /// This method belongs in the composition root but is provided here for convenience
    static func makeDefault(loadOnInit: Bool = true) -> AppStore {
        AppStore(
            git: GitService.shared,
            preferences: StorageService.shared,
            editorOpener: EditorService.shared,
            fileSystemWatcher: FileSystemWatcher(),
            fileSystem: FileSystemService.shared,
            system: SystemService.shared,
            loadOnInit: loadOnInit
        )
    }

    init(
        git: GitClient,
        preferences: PreferencesStore,
        editorOpener: EditorOpening,
        fileSystemWatcher: FileSystemWatching,
        fileSystem: FileSystemHandling,
        system: SystemOpening,
        statusStore: WorktreeStatusStore? = nil,
        activityCenter: ActivityCenter? = nil,
        loadOnInit: Bool = true
    ) {
        self.git = git
        self.preferences = preferences
        self.editorOpener = editorOpener
        self.fileSystemWatcher = fileSystemWatcher
        self.fileSystem = fileSystem
        self.system = system
        self.statusStore = statusStore ?? WorktreeStatusStore()
        self.activityCenter = activityCenter ?? ActivityCenter()
        self.worktreeBasePath = preferences.worktreeBasePath
        self.defaultCopyPatterns = preferences.defaultCopyPatterns

        if loadOnInit {
            setupFileSystemWatcher()

            // Bootstrap repositories synchronously to avoid a transient empty UI state on app launch.
            repositories = preferences.loadRepositories()
            if selectedRepository == nil {
                selectedRepository = repositories.first
            }
            updateWatchedPaths()

            // Kick off initial data loading without blocking init.
            Task {
                guard selectedRepository != nil else { return }
                let token = self.activityCenter.beginGlobal(kind: .initialLoad, message: "Loading workspace…")
                defer { self.activityCenter.end(token) }
                try? await refreshWorktrees()
                await loadBranches()
            }
        }
    }

    // MARK: - Internal Helpers

    func runIO<T>(_ work: @escaping () throws -> T) async throws -> T {
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

    func runIO<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            ioQueue.async {
                continuation.resume(returning: work())
            }
        }
    }

    func updateWatchedPaths() {
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

    // MARK: - Private

    private func setupFileSystemWatcher() {
        fileSystemWatcher.setChangeHandler { [weak self] changedPaths in
            guard let self else { return }
            Task { await self.handleFileSystemChange(changedPaths) }
        }
    }

    private func handleFileSystemChange(_ changedPaths: Set<String>) async {
        guard let repo = selectedRepository else { return }
        guard !changedPaths.isEmpty else {
            try? await refreshWorktrees(for: repo)
            return
        }

        let gitWorktreesPath = "\(repo.path)/.git/worktrees"
        let gitWorktreeChanges = changedPaths.filter { $0.hasPrefix(gitWorktreesPath) }
        let nonGitWorktreeChanges = changedPaths.subtracting(gitWorktreeChanges)

        // 1) Changes under `.git/worktrees` are usually status-related (index/refs) and must not force-refresh the whole worktree list.
        //    We map them to affected worktrees by name and refresh only those statuses.
        if !gitWorktreeChanges.isEmpty {
            let names = Set(gitWorktreeChanges.compactMap { Self.extractWorktreeName(fromGitWorktreesPath: $0, gitWorktreesRoot: gitWorktreesPath) })
            var matched: [Worktree] = []
            var hasUnknown = false

            for name in names {
                if let worktree = worktrees.first(where: { $0.name == name }) {
                    matched.append(worktree)
                } else {
                    hasUnknown = true
                }
            }

            // If we see a worktree name we don't recognize (created/removed externally), refresh the list once.
            if hasUnknown || gitWorktreeChanges.contains(gitWorktreesPath) {
                try? await refreshWorktrees(for: repo)
                return
            }

            let filtered = matched.filter { !shouldSuppressStatusRefresh(forWorktreePath: $0.path) }
            if !filtered.isEmpty {
                await refreshStatuses(for: filtered)
            }
        }

        // 2) Changes outside `.git/worktrees` are mapped by path containment and refresh only affected worktrees.
        if !nonGitWorktreeChanges.isEmpty {
            let affected = worktrees.filter { worktree in
                nonGitWorktreeChanges.contains { changed in
                    Self.pathTouchesWorktree(changedPath: changed, worktreePath: worktree.path)
                }
            }
            let filtered = affected.filter { !shouldSuppressStatusRefresh(forWorktreePath: $0.path) }
            if !filtered.isEmpty {
                await refreshStatuses(for: filtered)
            }
        }
    }

    private static func pathTouchesWorktree(changedPath: String, worktreePath: String) -> Bool {
        if changedPath == worktreePath { return true }
        if changedPath.hasPrefix(worktreePath + "/") { return true }
        if worktreePath.hasPrefix(changedPath + "/") { return true }
        return false
    }

    private static func extractWorktreeName(fromGitWorktreesPath path: String, gitWorktreesRoot: String) -> String? {
        guard path.hasPrefix(gitWorktreesRoot) else { return nil }
        let suffix = path.dropFirst(gitWorktreesRoot.count)
        let trimmed = suffix.hasPrefix("/") ? suffix.dropFirst() : suffix[...]
        guard !trimmed.isEmpty else { return nil }
        return trimmed.split(separator: "/").first.map(String.init)
    }
}
