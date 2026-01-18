import XCTest
@testable import WorktreeManager

final class CommandEnvironmentTests: XCTestCase {
    func test_forCommandExecution_whenPathMissing_appendsFallbackAndPackageManagerPaths() {
        let environment = CommandEnvironment.forCommandExecution(base: [:])
        let path = environment["PATH"] ?? ""

        XCTAssertTrue(path.contains("/usr/bin"))
        XCTAssertTrue(path.contains("/bin"))
        XCTAssertTrue(path.contains("/opt/homebrew/bin"))
        XCTAssertTrue(path.contains("/usr/local/bin"))
    }

    func test_forCommandExecution_preservesExistingPathAndAppendsMissingPieces() {
        let base = ["PATH": "/custom/bin:/usr/bin"]
        let environment = CommandEnvironment.forCommandExecution(base: base)
        XCTAssertEqual(environment["PATH"]?.hasPrefix("/custom/bin:/usr/bin"), true)

        let components = (environment["PATH"] ?? "")
            .split(separator: ":", omittingEmptySubsequences: true)
            .map(String.init)

        XCTAssertTrue(components.contains("/opt/homebrew/bin"))
        XCTAssertTrue(components.contains("/bin"))
    }
}

