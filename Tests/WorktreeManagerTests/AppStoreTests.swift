import XCTest
@testable import WorktreeManager

final class AppStoreTests: XCTestCase {
    @MainActor
    func test_loadRepositories_restoresLastSelectedRepositoryAndWorktree_whenStillPresent() async throws {
        let repo1 = Repository(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, path: "/repo-1")
        let repo2 = Repository(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, path: "/repo-2")

        let preferences = InMemoryPreferencesStore(repositories: [repo1, repo2], worktreeBasePath: "/worktrees")
        preferences.lastSelectedRepositoryId = repo2.id
        preferences.lastSelectedWorktreePath = "/worktrees/repo-2/feature-1"

        let git = FakeGitClient()
        git.listWorktreesHandler = { repoPath in
            if repoPath == "/repo-1" { return [Worktree(path: "/repo-1", branch: "main", isMain: true)] }
            if repoPath == "/repo-2" { return [Worktree(path: "/worktrees/repo-2/feature-1", branch: "feature-1")] }
            XCTFail("Unexpected repo path: \(repoPath)")
            return []
        }
        git.listBranchesHandler = { _ in [] }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        try await store.loadRepositories()

        XCTAssertEqual(store.selectedRepository, repo2)
        XCTAssertEqual(store.selectedWorktree?.path, "/worktrees/repo-2/feature-1")
        XCTAssertEqual(preferences.lastSelectedRepositoryId, repo2.id)
        XCTAssertEqual(preferences.lastSelectedWorktreePath, "/worktrees/repo-2/feature-1")
    }

    @MainActor
    func test_loadRepositories_clearsLastSelectedWorktree_whenMissing() async throws {
        let repo = Repository(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, path: "/repo")

        let preferences = InMemoryPreferencesStore(repositories: [repo], worktreeBasePath: "/worktrees")
        preferences.lastSelectedRepositoryId = repo.id
        preferences.lastSelectedWorktreePath = "/worktrees/repo/missing"

        let git = FakeGitClient()
        git.listWorktreesHandler = { _ in [Worktree(path: "/repo", branch: "main", isMain: true)] }
        git.listBranchesHandler = { _ in [] }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        try await store.loadRepositories()

        XCTAssertEqual(store.selectedRepository, repo)
        XCTAssertNil(store.selectedWorktree)
        XCTAssertEqual(preferences.lastSelectedRepositoryId, repo.id)
        XCTAssertNil(preferences.lastSelectedWorktreePath)
    }

    @MainActor
    func test_loadRepositories_autoSelectsFirst_andLoadsBranchesAndWorktrees() async throws {
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

        try await store.loadRepositories()

        XCTAssertEqual(store.repositories, [repo])
        XCTAssertEqual(store.selectedRepository, repo)
        XCTAssertEqual(store.worktrees.count, 1)
        XCTAssertEqual(store.branches, ["main", "feature"])
        XCTAssertEqual(watcher.updatedPathSets.last, Set(["/worktrees", "/repo/.git/worktrees"]))
    }

    @MainActor
    func test_addRepository_savesAndSelects() async throws {
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

        try await store.addRepository(at: "/repo/subdir")

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

        do {
            try await store.addRepository(at: "/repo")
            XCTFail("Expected addRepository to throw for duplicate repo")
        } catch let error as AppStoreError {
            XCTAssertEqual(error, .repositoryAlreadyAdded)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(store.repositories.count, 1)
        XCTAssertEqual(preferences.saveRepositoriesCalls.count, 0)
    }

    @MainActor
    func test_archiveRepository_marksRepositoryArchived_andSelectsNextActiveWhenArchivingSelection() async {
        let repo1 = Repository(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!, path: "/repo-1", name: "Repo 1")
        let repo2 = Repository(id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!, path: "/repo-2", name: "Repo 2")

        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
        let store = AppStore(
            git: FakeGitClient(),
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.repositories = [repo1, repo2]
        store.selectedRepository = repo1

        await store.archiveRepository(repo1)

        XCTAssertEqual(store.repositories.first(where: { $0.id == repo1.id })?.isArchived, true)
        XCTAssertEqual(preferences.saveRepositoriesCalls.count, 1)
        XCTAssertEqual(store.selectedRepository?.id, repo2.id)
    }

    @MainActor
    func test_archiveRepository_whenNoActiveRepositories_keepsSelectionButUpdatesItsArchivedState() async {
        let repo = Repository(id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!, path: "/repo", name: "Repo")
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
        let store = AppStore(
            git: FakeGitClient(),
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.repositories = [repo]
        store.selectedRepository = repo

        await store.archiveRepository(repo)

        XCTAssertEqual(store.repositories.first?.isArchived, true)
        XCTAssertEqual(store.selectedRepository?.id, repo.id)
        XCTAssertEqual(store.selectedRepository?.isArchived, true)
    }

    @MainActor
    func test_restoreRepository_updatesRepositoryAndSelectionState() async {
        let repo = Repository(
            id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
            path: "/repo",
            name: "Repo",
            isArchived: true
        )

        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
        let store = AppStore(
            git: FakeGitClient(),
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.repositories = [repo]
        store.selectedRepository = repo

        await store.restoreRepository(repo)

        XCTAssertEqual(store.repositories.first?.isArchived, false)
        XCTAssertEqual(store.selectedRepository?.id, repo.id)
        XCTAssertEqual(store.selectedRepository?.isArchived, false)
    }

    @MainActor
    func test_createWorktree_buildsPath_createsDirectory_andCallsGit() async throws {
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

        try await store.createWorktree(
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

        do {
            try await store.removeWorktree(Worktree(path: "/repo", branch: "main", isMain: true))
            XCTFail("Expected removeWorktree to throw for main worktree")
        } catch let error as AppStoreError {
            XCTAssertEqual(error, .cannotRemoveMainWorktree)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    @MainActor
    func test_removeWorktree_deletesBranchWhenRequested() async throws {
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

        try await store.removeWorktree(worktree, force: true, deleteBranch: true)

        XCTAssertEqual(git.removeWorktreeCalls, [
            FakeGitClient.RemoveWorktreeCall(repoPath: "/repo", worktreePath: "/worktrees/repo/feature", force: true)
        ])
        XCTAssertEqual(git.deleteBranchCalls, [
            FakeGitClient.DeleteBranchCall(repoPath: "/repo", branch: "feature", force: true)
        ])
    }

    @MainActor
    func test_lockUnlockAndPrune_delegateToGit() async throws {
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

        try await store.lockWorktree(worktree)
        try await store.unlockWorktree(worktree)
        try await store.pruneWorktrees()

        XCTAssertEqual(locked?.0, "/repo")
        XCTAssertEqual(locked?.1, "/worktrees/repo/feature")
        XCTAssertEqual(unlocked?.0, "/repo")
        XCTAssertEqual(unlocked?.1, "/worktrees/repo/feature")
        XCTAssertEqual(prunedRepoPath, "/repo")
    }

    @MainActor
    func test_openingActions_delegateToPorts() throws {
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

        try store.openInEditor(worktree, editor: editor)
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
    func test_push_setsUpstreamWhenNoRemote() async throws {
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
        try await store.push(worktree)

        XCTAssertEqual(git.pushCalls, [
            FakeGitClient.PushCall(worktreePath: "/wt/feature", setUpstream: true)
        ])
    }

    @MainActor
    func test_createPR_pushesWhenNeeded_thenOpensURL() async throws {
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
        let url = try await store.createPR(worktree, title: "Feature PR", body: "Body", baseBranch: "main")

        XCTAssertEqual(git.pushCalls, [
            FakeGitClient.PushCall(worktreePath: "/wt/feature", setUpstream: false)
        ])
        XCTAssertEqual(url, URL(string: "https://example.test/pr/123")!)
        XCTAssertEqual(system.openedURLs, [])
    }

    @MainActor
    func test_openPR_opensURLWhenPresent() {
        let store = AppStore(
            git: FakeGitClient(),
            preferences: InMemoryPreferencesStore(),
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        let worktree = Worktree(path: "/wt/feature", branch: "feature")
        store.statusStore.set(WorktreeStatus(
            isDirty: false,
            hasRemote: true,
            ahead: 0,
            behind: 0,
            prStatus: PRStatus(number: 1, state: "OPEN", url: "https://example.test/pr/1", title: nil)
        ), forWorktreePath: worktree.path)

        XCTAssertEqual(store.openPRURL(worktree), URL(string: "https://example.test/pr/1")!)
    }

    @MainActor
    func test_mergeBranch_delegatesToGit_andRefreshesWorktrees() async throws {
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

        try await store.mergeBranch(Worktree(path: "/wt/feature", branch: "feature"), into: "main")

        XCTAssertEqual(git.mergedBranches.count, 1)
        XCTAssertEqual(git.mergedBranches.first?.repoPath, "/repo")
        XCTAssertEqual(git.mergedBranches.first?.source, "feature")
        XCTAssertEqual(git.mergedBranches.first?.target, "main")
    }

    @MainActor
    func test_settings_writeThroughToPreferences() {
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")
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
        store.rememberEditorChoice = true

        XCTAssertEqual(preferences.worktreeBasePath, "/new-worktrees")
        XCTAssertEqual(store.worktreeBasePath, "/new-worktrees")
        XCTAssertEqual(preferences.rememberEditorChoice, true)
        XCTAssertEqual(store.rememberEditorChoice, true)
        XCTAssertEqual(watcher.updatedPathSets.last, Set(["/new-worktrees"]))
    }

    @MainActor
    func test_refreshWorktrees_doesNotOverwriteSelectedRepository_whenSelectionChangesMidFlight() async throws {
        let repo1 = Repository(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!, path: "/repo-1")
        let repo2 = Repository(id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!, path: "/repo-2")

        let preferences = InMemoryPreferencesStore(repositories: [repo1, repo2], worktreeBasePath: "/worktrees")
        let repo1Started = XCTestExpectation(description: "repo1 listWorktrees started")

        let git = FakeGitClient()
        git.listWorktreesHandler = { repoPath in
            if repoPath == repo1.path {
                repo1Started.fulfill()
                Thread.sleep(forTimeInterval: 0.2)
                return [Worktree(path: "/worktrees/repo-1/feature-1", branch: "feature-1")]
            }
            if repoPath == repo2.path {
                return [Worktree(path: "/worktrees/repo-2/feature-2", branch: "feature-2")]
            }
            XCTFail("Unexpected repo path: \(repoPath)")
            return []
        }
        git.listBranchesHandler = { _ in [] }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        store.selectedRepository = repo1
        let task = Task { try await store.refreshWorktrees(for: repo1) }

        await fulfillment(of: [repo1Started], timeout: 1.0)

        store.selectedRepository = repo2
        try await store.refreshWorktrees(for: repo2)
        XCTAssertEqual(store.worktrees.map(\.path), ["/worktrees/repo-2/feature-2"])

        try await task.value

        XCTAssertEqual(store.worktrees.map(\.path), ["/worktrees/repo-2/feature-2"])
    }

    @MainActor
    func test_loadBranches_doesNotOverwriteSelectedRepository_whenSelectionChangesMidFlight() async {
        let repo1 = Repository(id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!, path: "/repo-1")
        let repo2 = Repository(id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!, path: "/repo-2")

        let preferences = InMemoryPreferencesStore(repositories: [repo1, repo2], worktreeBasePath: "/worktrees")

        let repo1Started = XCTestExpectation(description: "repo1 listBranches started")

        let git = FakeGitClient()
        git.listWorktreesHandler = { _ in [] }
        git.listBranchesHandler = { repoPath in
            if repoPath == repo1.path {
                repo1Started.fulfill()
                Thread.sleep(forTimeInterval: 0.2)
                return ["main-1"]
            }
            if repoPath == repo2.path {
                return ["main-2", "feature-2"]
            }
            XCTFail("Unexpected repo path: \(repoPath)")
            return []
        }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )

        store.selectedRepository = repo1
        let task = Task { await store.loadBranches(for: repo1) }

        await fulfillment(of: [repo1Started], timeout: 1.0)

        store.selectedRepository = repo2
        await store.loadBranches(for: repo2)
        XCTAssertEqual(store.branches, ["main-2", "feature-2"])

        _ = await task.value

        XCTAssertEqual(store.branches, ["main-2", "feature-2"])
    }

    @MainActor
    func test_handleFileSystemChange_gitWorktreesRootOnly_doesNotForceRefreshLoop() async {
        let repo = Repository(path: "/repo", name: "repo")
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")

        let git = FakeGitClient()
        var listWorktreesCalls = 0
        var statusCalls = 0
        git.listWorktreesHandler = { _ in
            listWorktreesCalls += 1
            return []
        }
        git.getWorktreeStatusHandler = { path in
            statusCalls += 1
            return WorktreeStatus(isDirty: false, hasRemote: true, ahead: 0, behind: 0, prStatus: nil)
        }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees", "/repo/.git/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo
        store.worktrees = [Worktree(path: "/worktrees/repo/feature", branch: "feature")]

        await store.handleFileSystemChange(["/repo/.git/worktrees"])

        XCTAssertEqual(listWorktreesCalls, 0)
        XCTAssertEqual(statusCalls, 0)
    }

    @MainActor
    func test_handleFileSystemChange_gitWorktreesUnknownName_refreshesWorktrees() async {
        let repo = Repository(path: "/repo", name: "repo")
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")

        let git = FakeGitClient()
        var listWorktreesCalls = 0
        git.listWorktreesHandler = { _ in
            listWorktreesCalls += 1
            return []
        }
        git.listBranchesHandler = { _ in [] }

        let store = AppStore(
            git: git,
            preferences: preferences,
            editorOpener: SpyEditorOpener(),
            fileSystemWatcher: SpyFileSystemWatcher(),
            fileSystem: FakeFileSystem(existingPaths: ["/worktrees", "/repo/.git/worktrees"]),
            system: SpySystemOpener(),
            loadOnInit: false
        )
        store.selectedRepository = repo
        store.worktrees = [Worktree(path: "/worktrees/repo/known", branch: "known")]

        await store.handleFileSystemChange(["/repo/.git/worktrees/unknown/HEAD"])

        XCTAssertEqual(listWorktreesCalls, 1)
    }

    @MainActor
    func test_handleFileSystemChange_gitWorktreesKnownName_missingWorktreePath_refreshesWorktrees() async {
        let repo = Repository(path: "/repo", name: "repo")
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")

        let git = FakeGitClient()
        var listWorktreesCalls = 0
        git.listWorktreesHandler = { _ in
            listWorktreesCalls += 1
            return []
        }
        git.listBranchesHandler = { _ in [] }

        let fileSystem = FakeFileSystem(existingPaths: ["/worktrees", "/repo/.git/worktrees"])
        fileSystem.textFiles["/repo/.git/worktrees/feature/gitdir"] = "/worktrees/repo/feature/.git\n"
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
        store.worktrees = [Worktree(path: "/worktrees/repo/feature", branch: "feature")]

        await store.handleFileSystemChange(["/repo/.git/worktrees/feature/HEAD"])

        XCTAssertEqual(listWorktreesCalls, 1)
    }

    @MainActor
    func test_handleFileSystemChange_gitWorktreesKnownName_existingWorktreePath_refreshesStatusOnly() async {
        let repo = Repository(path: "/repo", name: "repo")
        let preferences = InMemoryPreferencesStore(worktreeBasePath: "/worktrees")

        let git = FakeGitClient()
        var listWorktreesCalls = 0
        var statusCalls = 0
        git.listWorktreesHandler = { _ in
            listWorktreesCalls += 1
            return []
        }
        git.getWorktreeStatusHandler = { _ in
            statusCalls += 1
            return WorktreeStatus(isDirty: true, hasRemote: true, ahead: 1, behind: 0, prStatus: nil)
        }

        let fileSystem = FakeFileSystem(existingPaths: ["/worktrees", "/repo/.git/worktrees", "/worktrees/repo/feature"])
        fileSystem.textFiles["/repo/.git/worktrees/feature/gitdir"] = "/worktrees/repo/feature/.git\n"
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
        let worktree = Worktree(path: "/worktrees/repo/feature", branch: "feature")
        store.worktrees = [worktree]

        await store.handleFileSystemChange(["/repo/.git/worktrees/feature/HEAD"])

        XCTAssertEqual(listWorktreesCalls, 0)
        XCTAssertEqual(statusCalls, 1)
        XCTAssertEqual(store.getStatus(for: worktree)?.ahead, 1)
    }
}
