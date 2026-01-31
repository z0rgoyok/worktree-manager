import Foundation
@testable import WorktreeManager

final class FakeFileSystem: FileSystemHandling {
    private(set) var existingPaths: Set<String>
    private(set) var directoryPaths: Set<String>
    private(set) var createdDirectories: [String] = []
    private(set) var copiedItems: [(source: String, destination: String)] = []
    var fileSizes: [String: Int64] = [:]

    init(existingPaths: Set<String> = [], directoryPaths: Set<String> = []) {
        self.existingPaths = existingPaths
        self.directoryPaths = directoryPaths
    }

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }

    func isDirectory(atPath path: String) -> Bool {
        directoryPaths.contains(path)
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws {
        createdDirectories.append(path)
        existingPaths.insert(path)
        directoryPaths.insert(path)
    }

    func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        copiedItems.append((source: srcPath, destination: dstPath))
        existingPaths.insert(dstPath)
    }

    func fileSize(atPath path: String) -> Int64? {
        fileSizes[path]
    }

    func directorySize(atPath path: String) -> Int64? {
        guard directoryPaths.contains(path) else { return nil }
        return fileSizes[path] ?? 0
    }
}

