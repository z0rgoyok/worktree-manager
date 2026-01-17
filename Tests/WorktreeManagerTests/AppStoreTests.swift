import XCTest
@testable import WorktreeManager

final class AppStoreTests: XCTestCase {
    @MainActor
    func test_loadRepositories_autoSelectsFirst_andLoadsBranchesAndWorktrees() async {
        let repo = Repository(path: "/repo")
        let preferences = InMemoryPreferencesStore(
            repositories: [repo],
            worktreeBasePath: "/worktrees"
        )

        let git = FakeGitClient()
        git.listWorktreesHandler = { repoPath in
            XCTAssertEqual(repoPath, "/repo")
            return [
                Worktree(path: "/repo", branch: "main", isMain: true)
            ]
        }
        git.listBranchesHandler = { repoPath in
            XCTAssertEqual(repoPath, "/repo")
            return ["main", "feature"]
        }

        let fileSystem = FakeFileSystem(existingPaths: ["/worktrees", "/repo/.git/worktrees"])
        let watcher = SpyFileSystemWatcher()

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: watcher,
            fileSystem: fileSystem,
            system: SpySystemOpener(),
            loadOnInit: false
        )

        await store.loadRepositories()

        XCTAssertEqual(store.repositories, [repo])
        XCTAssertEqual(store.selectedRepository, repo)
        XCTAssertEqual(store.worktrees.count, 1)
        XCTAssertEqual(store.branches, ["main", "feature"])
        XCTAssertEqual(watcher.updatedPathSets.last, Set(["/worktrees", "/repo/.git/worktrees"]))
    }

    @MainActor
    func test_addRepository_savesAndSelects() async {
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
        let git = FakeGitClient()
        git.getRepositoryRootHandler = { path in
            XCTAssertEqual(path, "/repo/subdir")
            return "/repo"
        }
        git.listBranchesHandler = { _ in ["main"] }
        git.listWorktreesHandler = { _ in [] }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        await store.addRepository(at: "/repo/subdir")

        XCTAssertEqual(store.repositories.map(\.path), ["/repo"])
        XCTAssertEqual(preferences.repositories.map(\.path), ["/repo"])
        XCTAssertEqual(preferences.saveRepositoriesCalls.count, 1)
        XCTAssertEqual(store.selectedRepository?.path, "/repo")
    }

    @MainActor
    func test_addRepository_whenAlreadyAdded_setsError_andDoesNotSaveDuplicate() async {
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
        let git = FakeGitClient()
        git.getRepositoryRootHandler = { _ in "/repo" }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        store.repositories = [Repository(path: "/repo")]

        await store.addRepository(at: "/repo")

        XCTAssertTrue(store.showError)
        XCTAssertEqual(store.repositories.count, 1)
        XCTAssertEqual(preferences.saveRepositoriesCalls.count, 0)
    }

    @MainActor
    func test_createWorktree_buildsPath_createsDirectory_andCallsGit() async {
        let repo = Repository(path: "/repo", name: "repo")
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
        let git = FakeGitClient()
        git.listWorktreesHandler = { _ in [] }
        git.listBranchesHandler = { _ in ["main"] }

        let fileSystem = FakeFileSystem(existingPaths: ["/worktrees", "/repo/.git/worktrees"])

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: fileSystem,
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo

        await store.createWorktree(
            name: "feature-1",
            branch: "feature-1",
            createNewBranch: true,
            baseBranch: "main"
        )

        XCTAssertEqual(fileSystem.createdDirectories, ["/worktrees/repo"])
        XCTAssertEqual(git.createWorktreeCalls, [
            FakeGitClient.CreateWorktreeCall(
                repoPath: "/repo",
                worktreePath: "/worktrees/repo/feature-1",
                branch: "feature-1",
                createBranch: true,
                baseBranch: "main"
            )
        ])
    }

    @MainActor
    func test_removeWorktree_rejectsMainWorktree() async {
        let repo = Repository(path: "/repo")
        let store = AppStore(
            git: FakeGitClient(),
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo

        await store.removeWorktree(Worktree(path: "/repo", branch: "main", isMain: true))

        XCTAssertTrue(store.showError)
    }

    @MainActor
    func test_removeWorktree_deletesBranchWhenRequested() async {
        let repo = Repository(path: "/repo")
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
        let git = FakeGitClient()
        git.listWorktreesHandler = { _ in [] }
        git.listBranchesHandler = { _ in [] }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo

        let worktree = Worktree(path: "/worktrees/repo/feature", branch: "feature", isMain: false)

        await store.removeWorktree(worktree, force: true, deleteBranch: true)

        XCTAssertEqual(git.removeWorktreeCalls, [
            FakeGitClient.RemoveWorktreeCall(repoPath: "/repo", worktreePath: "/worktrees/repo/feature", force: true)
        ])
        XCTAssertEqual(git.deleteBranchCalls, [
            FakeGitClient.DeleteBranchCall(repoPath: "/repo", branch: "feature", force: true)
        ])
    }

    @MainActor
    func test_lockUnlockAndPrune_delegateToGit() async {
        let repo = Repository(path: "/repo")
        let worktree = Worktree(path: "/worktrees/repo/feature", branch: "feature")

        let git = FakeGitClient()
        git.listWorktreesHandler = { _ in [] }

        var locked: (String, String)?
        git.lockWorktreeHandler = { repoPath, path in locked = (repoPath, path) }

        var unlocked: (String, String)?
        git.unlockWorktreeHandler = { repoPath, path in unlocked = (repoPath, path) }

        var prunedRepoPath: String?
        git.pruneWorktreesHandler = { repoPath in prunedRepoPath = repoPath }

        let store = AppStore(
            git: git,
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo

        await store.lockWorktree(worktree)
        await store.unlockWorktree(worktree)
        await store.pruneWorktrees()

        XCTAssertEqual(locked?.0, "/repo")
        XCTAssertEqual(locked?.1, "/worktrees/repo/feature")
        XCTAssertEqual(unlocked?.0, "/repo")
        XCTAssertEqual(unlocked?.1, "/worktrees/repo/feature")
        XCTAssertEqual(prunedRepoPath, "/repo")
    }

    @MainActor
    func test_openingActions_delegateToPorts() {
        let editorOpener = SpyEditorOpener()
        let system = SpySystemOpener()
        let store = AppStore(
            git: FakeGitClient(),
            preferences: InMemoryPreferencesStore(),
            editorOpener: editorOpener,
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: system,
            loadOnInit: false
        )

        let worktree = Worktree(path: "/wt/feature", branch: "feature")
        let editor = Editor(id: "vscode", name: "VS Code", command: "code", icon: "x")

        store.openInEditor(worktree, editor: editor)
        store.openInFinder(worktree)
        store.openInTerminal(worktree)

        XCTAssertEqual(editorOpener.openCalls.count, 1)
        XCTAssertEqual(editorOpener.openCalls.first?.path, "/wt/feature")
        XCTAssertEqual(system.revealedPaths, ["/wt/feature"])
        XCTAssertEqual(system.openedTerminals, ["/wt/feature"])
    }

    @MainActor
    func test_refreshWorktreeStatus_setsNilThenPopulates() async {
        let repo = Repository(path: "/repo")
        let worktree = Worktree(path: "/wt/feature", branch: "feature")

        let git = FakeGitClient()
        git.getWorktreeStatusHandler = { _ in
            WorktreeStatus(isDirty: true, hasRemote: true, ahead: 2, behind: 0, prStatus: nil)
        }

        let store = AppStore(
            git: git,
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo
        store.worktrees = [worktree]

        await store.refreshWorktreeStatus(worktree)

        XCTAssertEqual(store.getStatus(for: worktree)?.ahead, 2)
        XCTAssertEqual(store.getStatus(for: worktree)?.isDirty, true)
    }

    @MainActor
    func test_push_setsUpstreamWhenNoRemote() async {
        let git = FakeGitClient()
        git.getWorktreeStatusHandler = { _ in
            WorktreeStatus(isDirty: false, hasRemote: false, ahead: 1, behind: 0, prStatus: nil)
        }

        let store = AppStore(
            git: git,
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        let worktree = Worktree(path: "/wt/feature", branch: "feature")
        await store.push(worktree)

        XCTAssertEqual(git.pushCalls, [
            FakeGitClient.PushCall(worktreePath: "/wt/feature", setUpstream: true)
        ])
    }

    @MainActor
    func test_createPR_pushesWhenNeeded_thenOpensURL() async {
        let git = FakeGitClient()
        git.getWorktreeStatusHandler = { _ in
            WorktreeStatus(isDirty: false, hasRemote: true, ahead: 1, behind: 0, prStatus: nil)
        }
        git.createPRHandler = { worktreePath, title, _, baseBranch in
            XCTAssertEqual(worktreePath, "/wt/feature")
            XCTAssertEqual(title, "Feature PR")
            XCTAssertEqual(baseBranch, "main")
            return "https://example.test/pr/123"
        }

        let system = SpySystemOpener()
        let store = AppStore(
            git: git,
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: system,
            loadOnInit: false
        )

        let worktree = Worktree(path: "/wt/feature", branch: "feature")
        await store.createPR(worktree, title: "Feature PR", body: "Body", baseBranch: "main")

        XCTAssertEqual(git.pushCalls, [
            FakeGitClient.PushCall(worktreePath: "/wt/feature", setUpstream: false)
        ])
        XCTAssertEqual(system.openedURLs, [URL(string: "https://example.test/pr/123")!])
    }

    @MainActor
    func test_openPR_opensURLWhenPresent() {
        let system = SpySystemOpener()
        let store = AppStore(
            git: FakeGitClient(),
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: system,
            loadOnInit: false
        )

        let worktree = Worktree(path: "/wt/feature", branch: "feature")
        store.worktreeStatuses[worktree.path] = WorktreeStatus(
            isDirty: false,
            hasRemote: true,
            ahead: 0,
            behind: 0,
            prStatus: PRStatus(number: 1, state: "OPEN", url: "https://example.test/pr/1", title: nil)
        )

        store.openPR(worktree)

        XCTAssertEqual(system.openedURLs, [URL(string: "https://example.test/pr/1")!])
    }

    @MainActor
    func test_mergeBranch_delegatesToGit_andRefreshesWorktrees() async {
        let repo = Repository(path: "/repo")
        let git = FakeGitClient()
        git.listWorktreesHandler = { _ in [] }
        git.listBranchesHandler = { _ in [] }

        let store = AppStore(
            git: git,
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo

        await store.mergeBranch(Worktree(path: "/wt/feature", branch: "feature"), into: "main")

        XCTAssertEqual(git.mergedBranches.count, 1)
        XCTAssertEqual(git.mergedBranches.first?.repoPath, "/repo")
        XCTAssertEqual(git.mergedBranches.first?.source, "feature")
        XCTAssertEqual(git.mergedBranches.first?.target, "main")
    }

    @MainActor
    func test_settings_writeThroughToPreferences() {
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees", defaultEditorId: "")
        let fileSystem = FakeFileSystem(existingPaths: ["/new-worktrees"])
        let watcher = SpyFileSystemWatcher()

        let store = AppStore(
            git: FakeGitClient(),
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: watcher,
            fileSystem: fileSystem,
            system: SpySystemOpener(),
            loadOnInit: false
        )

        store.setWorktreeBasePath("/new-worktrees")
        store.setDefaultEditorId("vscode")

        XCTAssertEqual(preferences.worktreeBasePath, "/new-worktrees")
        XCTAssertEqual(preferences.defaultEditorId, "vscode")
        XCTAssertEqual(store.worktreeBasePath, "/new-worktrees")
        XCTAssertEqual(store.defaultEditorId, "vscode")
        XCTAssertEqual(watcher.updatedPathSets.last, Set(["/new-worktrees"]))
    }
}

