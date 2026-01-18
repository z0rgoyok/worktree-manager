import Foundation

final class FileSystemService: FileSystemHandling {
    static let shared = FileSystemService()

    private let fm = FileManager.default

    private init() {}

    func fileExists(atPath path: String) -> Bool {
        fm.fileExists(atPath: path)
    }

    func isDirectory(atPath path: String) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws {
        try fm.createDirectory(
            atPath: path,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }

    func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        // Ensure parent directory exists
        let parentPath = (dstPath as NSString).deletingLastPathComponent
        if !fm.fileExists(atPath: parentPath) {
            try fm.createDirectory(atPath: parentPath, withIntermediateDirectories: true)
        }
        try fm.copyItem(atPath: srcPath, toPath: dstPath)
    }

    func fileSize(atPath path: String) -> Int64? {
        guard let attrs = try? fm.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return size
    }

    func directorySize(atPath path: String) -> Int64? {
        guard isDirectory(atPath: path) else { return nil }

        var totalSize: Int64 = 0
        guard let enumerator = fm.enumerator(atPath: path) else { return nil }

        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            if let size = fileSize(atPath: fullPath) {
                totalSize += size
            }
        }
        return totalSize
    }
}

