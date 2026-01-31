import Foundation
@testable import WorktreeManager

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

