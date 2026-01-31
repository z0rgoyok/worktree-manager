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
    @Published var worktreeStatuses: [String: WorktreeStatus] = [:]  // path -> status
    @Published var branches: [String] = []
    @Published var worktreeBasePath: String
    @Published var defaultEditorId: String
    @Published var defaultCopyPatterns: [CopyPattern]
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    @Published var lastCopyResult: CopyResult?

    // MARK: - Dependencies (internal for extensions)

    let git: GitClient
    var preferences: PreferencesStore
    let editorOpener: EditorOpening
    let fileSystemWatcher: FileSystemWatching
    let fileSystem: FileSystemHandling
    let system: SystemOpening

    private let ioQueue = DispatchQueue(label: "worktree-manager.io", qos: .userInitiated)

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

    // MARK: - Error Handling

    func showError(message: String) {
        error = message
        showError = true
    }

    func clearError() {
        error = nil
        showError = false
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
}
