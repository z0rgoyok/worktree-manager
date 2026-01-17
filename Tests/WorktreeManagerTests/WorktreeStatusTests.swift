import XCTest
@testable import WorktreeManager

final class WorktreeStatusTests: XCTestCase {
    func test_statusSummary_clean() {
        let status = WorktreeStatus(isDirty: false, hasRemote: true, ahead: 0, behind: 0, prStatus: nil)
        XCTAssertEqual(status.statusSummary, "Clean")
    }

    func test_statusSummary_combinesSignals() {
        let status = WorktreeStatus(
            isDirty: true,
            hasRemote: true,
            ahead: 2,
            behind: 1,
            prStatus: PRStatus(number: 10, state: "OPEN", url: "https://example.test/pr/10", title: nil)
        )
        XCTAssertEqual(status.statusSummary, "uncommitted changes · 2 unpushed · 1 behind · PR #10 open")
        XCTAssertTrue(status.hasUnpushedCommits)
        XCTAssertTrue(status.needsPull)
        XCTAssertTrue(status.hasPR)
    }
}

