import XCTest
@testable import WorktreeManager

final class SidebarKeyboardNavigationTests: XCTestCase {
    func test_down_movesThroughVisibleItems_includingExpandedWorktrees() {
        let repoA = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, path: "/repo-a", name: "A")
        let repoB = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, path: "/repo-b", name: "B")

        let main = Worktree(path: "/worktrees/main", branch: "main", isMain: true)
        let feature = Worktree(path: "/worktrees/feature", branch: "feature", isMain: false)

        let repositories = [repoA, repoB]
        let expanded: Set<UUID> = [repoA.id]
        let worktreesByRepoId: [UUID: [Worktree]] = [
            repoA.id: [feature, main]
        ]

        var out = SidebarKeyboardNavigation.handle(
            key: .down,
            selection: nil,
            repositories: repositories,
            expandedRepositoryIds: expanded,
            worktreesByRepositoryId: worktreesByRepoId
        )
        XCTAssertEqual(out.selection, .repository(repoA))

        out = SidebarKeyboardNavigation.handle(
            key: .down,
            selection: out.selection,
            repositories: repositories,
            expandedRepositoryIds: out.expandedRepositoryIds,
            worktreesByRepositoryId: worktreesByRepoId
        )
        XCTAssertEqual(out.selection, .worktree(main, inRepository: repoA))

        out = SidebarKeyboardNavigation.handle(
            key: .down,
            selection: out.selection,
            repositories: repositories,
            expandedRepositoryIds: out.expandedRepositoryIds,
            worktreesByRepositoryId: worktreesByRepoId
        )
        XCTAssertEqual(out.selection, .worktree(feature, inRepository: repoA))

        out = SidebarKeyboardNavigation.handle(
            key: .down,
            selection: out.selection,
            repositories: repositories,
            expandedRepositoryIds: out.expandedRepositoryIds,
            worktreesByRepositoryId: worktreesByRepoId
        )
        XCTAssertEqual(out.selection, .repository(repoB))
    }

    func test_up_fromNil_selectsLastVisibleItem() {
        let repoA = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, path: "/repo-a", name: "A")
        let repoB = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, path: "/repo-b", name: "B")

        let out = SidebarKeyboardNavigation.handle(
            key: .up,
            selection: nil,
            repositories: [repoA, repoB],
            expandedRepositoryIds: [],
            worktreesByRepositoryId: [:]
        )

        XCTAssertEqual(out.selection, .repository(repoB))
    }

    func test_left_onWorktree_selectsParentRepository() {
        let repo = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, path: "/repo", name: "Repo")
        let worktree = Worktree(path: "/worktrees/feature", branch: "feature", isMain: false)

        let out = SidebarKeyboardNavigation.handle(
            key: .left,
            selection: .worktree(worktree, inRepository: repo),
            repositories: [repo],
            expandedRepositoryIds: [repo.id],
            worktreesByRepositoryId: [repo.id: [worktree]]
        )

        XCTAssertEqual(out.selection, .repository(repo))
    }

    func test_left_onExpandedRepository_collapsesIt() {
        let repo = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, path: "/repo", name: "Repo")

        let out = SidebarKeyboardNavigation.handle(
            key: .left,
            selection: .repository(repo),
            repositories: [repo],
            expandedRepositoryIds: [repo.id],
            worktreesByRepositoryId: [:]
        )

        XCTAssertFalse(out.expandedRepositoryIds.contains(repo.id))
        XCTAssertEqual(out.selection, .repository(repo))
    }

    func test_right_onCollapsedRepository_expandsAndRequestsLoadWhenMissingWorktrees() {
        let repo = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, path: "/repo", name: "Repo")

        let out = SidebarKeyboardNavigation.handle(
            key: .right,
            selection: .repository(repo),
            repositories: [repo],
            expandedRepositoryIds: [],
            worktreesByRepositoryId: [:]
        )

        XCTAssertTrue(out.expandedRepositoryIds.contains(repo.id))
        XCTAssertEqual(out.repositoryIdsToLoadWorktrees, [repo.id])
    }

    func test_space_togglesRepositoryExpansion() {
        let repo = Repository(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, path: "/repo", name: "Repo")

        var out = SidebarKeyboardNavigation.handle(
            key: .space,
            selection: .repository(repo),
            repositories: [repo],
            expandedRepositoryIds: [],
            worktreesByRepositoryId: [:]
        )
        XCTAssertTrue(out.expandedRepositoryIds.contains(repo.id))

        out = SidebarKeyboardNavigation.handle(
            key: .space,
            selection: .repository(repo),
            repositories: [repo],
            expandedRepositoryIds: out.expandedRepositoryIds,
            worktreesByRepositoryId: [:]
        )
        XCTAssertFalse(out.expandedRepositoryIds.contains(repo.id))
    }
}

