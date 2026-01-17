import Foundation

final class FileSystemService: FileSystemHandling {
    static let shared = FileSystemService()

    private init() {}

    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws {
        try FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }
}

