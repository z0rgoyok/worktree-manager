import XCTest
@testable import WorktreeManager

final class SidebarAutoExpansionPolicyTests: XCTestCase {
    func test_shouldAutoExpandRepository_whenSelectionIsNil_isFalse() {
        XCTAssertFalse(SidebarAutoExpansionPolicy.shouldAutoExpandRepository(for: nil))
    }

    func test_shouldAutoExpandRepository_whenSelectionIsRepository_isFalse() {
        let repo = Repository(path: "/repo")
        XCTAssertFalse(SidebarAutoExpansionPolicy.shouldAutoExpandRepository(for: .repository(repo)))
    }

    func test_shouldAutoExpandRepository_whenSelectionIsWorktree_isTrue() {
        let repo = Repository(path: "/repo")
        let worktree = Worktree(path: "/worktrees/feature", branch: "feature", isMain: false)
        XCTAssertTrue(SidebarAutoExpansionPolicy.shouldAutoExpandRepository(for: .worktree(worktree, inRepository: repo)))
    }
}

