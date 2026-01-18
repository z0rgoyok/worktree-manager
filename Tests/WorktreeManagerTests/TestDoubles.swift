import Foundation
@testable import WorktreeManager

final class InMemoryPreferencesStore: PreferencesStore {
    var repositories: [Repository]
    var worktreeBasePath: String
    var defaultEditorId: String
    private var preferredBaseBranches: [UUID: String] = [:]
    private var worktreeBaseBranches: [String: String] = [:]

    private(set) var saveRepositoriesCalls: [[Repository]] = []

    init(
        repositories: [Repository] = [],
        worktreeBasePath: String = "/worktrees",
        defaultEditorId: String = ""
    ) {
        self.repositories = repositories
        self.worktreeBasePath = worktreeBasePath
        self.defaultEditorId = defaultEditorId
    }

    func loadRepositories() -> [Repository] {
        repositories
    }

    func saveRepositories(_ repositories: [Repository]) {
        self.repositories = repositories
        saveRepositoriesCalls.append(repositories)
    }

    func preferredBaseBranch(forRepositoryId id: UUID) -> String? {
        preferredBaseBranches[id]
    }

    func setPreferredBaseBranch(_ branch: String, forRepositoryId id: UUID) {
        preferredBaseBranches[id] = branch
    }

    func worktreeBaseBranch(forWorktreePath path: String) -> String? {
        worktreeBaseBranches[path]
    }

    func setWorktreeBaseBranch(_ branch: String, forWorktreePath path: String) {
        worktreeBaseBranches[path] = branch
    }

    func removeWorktreeBaseBranch(forWorktreePath path: String) {
        worktreeBaseBranches.removeValue(forKey: path)
    }
}

final class FakeGitClient: GitClient {
    struct CreateWorktreeCall: Equatable {
        let repoPath: String
        let worktreePath: String
        let branch: String
        let createBranch: Bool
        let baseBranch: String?
    }

    struct RemoveWorktreeCall: Equatable {
        let repoPath: String
        let worktreePath: String
        let force: Bool
    }

    struct DeleteBranchCall: Equatable {
        let repoPath: String
        let branch: String
        let force: Bool
    }

    struct PushCall: Equatable {
        let worktreePath: String
        let setUpstream: Bool
    }

    var getRepositoryRootHandler: (String) throws -> String = { $0 }
    var listBranchesHandler: (String) throws -> [String] = { _ in [] }
    var branchExistsHandler: (String, String) -> Bool = { _, _ in false }
    var deleteBranchHandler: (String, String, Bool) throws -> Void = { _, _, _ in }

    var listWorktreesHandler: (String) throws -> [Worktree] = { _ in [] }
    var createWorktreeHandler: (CreateWorktreeCall) throws -> Void = { _ in }
    var removeWorktreeHandler: (RemoveWorktreeCall) throws -> Void = { _ in }
    var lockWorktreeHandler: (String, String) throws -> Void = { _, _ in }
    var unlockWorktreeHandler: (String, String) throws -> Void = { _, _ in }
    var pruneWorktreesHandler: (String) throws -> Void = { _ in }

    var getWorktreeStatusHandler: (String) -> WorktreeStatus = { _ in
        WorktreeStatus(isDirty: false, hasRemote: true, ahead: 0, behind: 0, prStatus: nil)
    }

    var pushHandler: (PushCall) throws -> Void = { _ in }
    var createPRHandler: (String, String, String, String?) throws -> String = { _, _, _, _ in "https://example.test/pr/1" }
    var mergeBranchHandler: (String, String, String) throws -> Void = { _, _, _ in }

    private(set) var createWorktreeCalls: [CreateWorktreeCall] = []
    private(set) var removeWorktreeCalls: [RemoveWorktreeCall] = []
    private(set) var deleteBranchCalls: [DeleteBranchCall] = []
    private(set) var pushCalls: [PushCall] = []
    private(set) var createdPRs: [(worktreePath: String, title: String, body: String, baseBranch: String?)] = []
    private(set) var mergedBranches: [(repoPath: String, source: String, target: String)] = []

    func getRepositoryRoot(at path: String) throws -> String {
        try getRepositoryRootHandler(path)
    }

    func listBranches(at repoPath: String) throws -> [String] {
        try listBranchesHandler(repoPath)
    }

    func branchExists(at repoPath: String, branch: String) -> Bool {
        branchExistsHandler(repoPath, branch)
    }

    func deleteBranch(at repoPath: String, branch: String, force: Bool) throws {
        deleteBranchCalls.append(DeleteBranchCall(repoPath: repoPath, branch: branch, force: force))
        try deleteBranchHandler(repoPath, branch, force)
    }

    func listWorktrees(at repoPath: String) throws -> [Worktree] {
        try listWorktreesHandler(repoPath)
    }

    func createWorktree(
        at repoPath: String,
        worktreePath: String,
        branch: String,
        createBranch: Bool,
        baseBranch: String?
    ) throws {
        let call = CreateWorktreeCall(
            repoPath: repoPath,
            worktreePath: worktreePath,
            branch: branch,
            createBranch: createBranch,
            baseBranch: baseBranch
        )
        createWorktreeCalls.append(call)
        try createWorktreeHandler(call)
    }

    func removeWorktree(at repoPath: String, worktreePath: String, force: Bool) throws {
        let call = RemoveWorktreeCall(repoPath: repoPath, worktreePath: worktreePath, force: force)
        removeWorktreeCalls.append(call)
        try removeWorktreeHandler(call)
    }

    func lockWorktree(at repoPath: String, worktreePath: String, reason: String?) throws {
        try lockWorktreeHandler(repoPath, worktreePath)
    }

    func unlockWorktree(at repoPath: String, worktreePath: String) throws {
        try unlockWorktreeHandler(repoPath, worktreePath)
    }

    func pruneWorktrees(at repoPath: String) throws {
        try pruneWorktreesHandler(repoPath)
    }

    func getWorktreeStatus(at worktreePath: String) -> WorktreeStatus {
        getWorktreeStatusHandler(worktreePath)
    }

    func push(at worktreePath: String, setUpstream: Bool) throws {
        let call = PushCall(worktreePath: worktreePath, setUpstream: setUpstream)
        pushCalls.append(call)
        try pushHandler(call)
    }

    func createPR(at worktreePath: String, title: String, body: String, baseBranch: String?) throws -> String {
        createdPRs.append((worktreePath: worktreePath, title: title, body: body, baseBranch: baseBranch))
        return try createPRHandler(worktreePath, title, body, baseBranch)
    }

    func mergeBranch(at repoPath: String, source: String, into target: String) throws {
        mergedBranches.append((repoPath: repoPath, source: source, target: target))
        try mergeBranchHandler(repoPath, source, target)
    }

    var pullHandler: (String) throws -> Void = { _ in }
    func pull(at worktreePath: String) throws {
        try pullHandler(worktreePath)
    }

    var deleteRemoteBranchHandler: (String, String) throws -> Void = { _, _ in }
    func deleteRemoteBranch(at repoPath: String, branch: String) throws {
        try deleteRemoteBranchHandler(repoPath, branch)
    }

    var hasRemoteBranchResult: Bool = true
    func hasRemoteBranch(at repoPath: String, branch: String) -> Bool {
        hasRemoteBranchResult
    }
}

final class SpyEditorOpener: EditorOpening {
    private(set) var openCalls: [(path: String, editor: Editor)] = []
    var availableEditorsResult: [Editor] = Editor.builtIn
    var openError: Error?

    func open(path: String, with editor: Editor) throws {
        openCalls.append((path: path, editor: editor))
        if let openError { throw openError }
    }

    func availableEditors() -> [Editor] {
        availableEditorsResult
    }
}

final class SpySystemOpener: SystemOpening {
    private(set) var openedURLs: [URL] = []
    private(set) var revealedPaths: [String] = []
    private(set) var openedTerminals: [String] = []

    func openURL(_ url: URL) {
        openedURLs.append(url)
    }

    func revealInFinder(path: String) {
        revealedPaths.append(path)
    }

    func openTerminal(atPath path: String) {
        openedTerminals.append(path)
    }
}

final class SpyFileSystemWatcher: FileSystemWatching {
    private var handler: ((Set<String>) -> Void)?
    private(set) var updatedPathSets: [Set<String>] = []

    func setChangeHandler(_ handler: @escaping (Set<String>) -> Void) {
        self.handler = handler
    }

    func updateWatchedPaths(_ paths: Set<String>) {
        updatedPathSets.append(paths)
    }

    func triggerChange(paths: Set<String> = []) {
        handler?(paths)
    }
}

final class FakeFileSystem: FileSystemHandling {
    private(set) var existingPaths: Set<String>
    private(set) var createdDirectories: [String] = []

    init(existingPaths: Set<String> = []) {
        self.existingPaths = existingPaths
    }

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws {
        createdDirectories.append(path)
        existingPaths.insert(path)
    }
}
