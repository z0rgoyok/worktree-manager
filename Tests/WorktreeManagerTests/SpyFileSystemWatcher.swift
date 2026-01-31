import Foundation
@testable import WorktreeManager

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

