import Foundation

// MARK: - Copy Patterns Use Cases

extension AppStore {
    func effectiveCopyPatterns(for repo: Repository) -> [CopyPattern] {
        preferences.effectiveCopyPatterns(forRepositoryId: repo.id)
    }

    func copyPatterns(for repo: Repository) -> [CopyPattern]? {
        preferences.copyPatterns(forRepositoryId: repo.id)
    }

    func setCopyPatterns(_ patterns: [CopyPattern], for repo: Repository) {
        preferences.setCopyPatterns(patterns, forRepositoryId: repo.id)
    }

    func removeCopyPatterns(for repo: Repository) {
        preferences.removeCopyPatterns(forRepositoryId: repo.id)
    }

    func setDefaultCopyPatterns(_ patterns: [CopyPattern]) {
        defaultCopyPatterns = patterns
        preferences.defaultCopyPatterns = patterns
    }

    func getCopyPreview(for repo: Repository, patterns: [CopyPattern]? = nil) -> [CopyPreviewItem] {
        let effectivePatterns = patterns ?? effectiveCopyPatterns(for: repo)
        return effectivePatterns.map { pattern in
            let fullPath = (repo.path as NSString).appendingPathComponent(pattern.pattern)
            let exists = fileSystem.fileExists(atPath: fullPath)
            let isDir = fileSystem.isDirectory(atPath: fullPath)
            let size: Int64?
            if exists {
                size = isDir ? fileSystem.directorySize(atPath: fullPath) : fileSystem.fileSize(atPath: fullPath)
            } else {
                size = nil
            }
            return CopyPreviewItem(pattern: pattern.pattern, exists: exists, size: size, isDirectory: isDir)
        }
    }

    func loadCopyPreview(for repo: Repository, patterns: [CopyPattern]? = nil) async -> [CopyPreviewItem] {
        await runIO {
            self.getCopyPreview(for: repo, patterns: patterns)
        }
    }

    func copyFiles(patterns: [CopyPattern], from sourcePath: String, to destinationPath: String) async -> CopyResult {
        var copied: [String] = []
        var skipped: [String] = []
        var failed: [(path: String, error: String)] = []

        for pattern in patterns {
            let srcPath = (sourcePath as NSString).appendingPathComponent(pattern.pattern)
            let dstPath = (destinationPath as NSString).appendingPathComponent(pattern.pattern)

            guard fileSystem.fileExists(atPath: srcPath) else {
                skipped.append(pattern.pattern)
                continue
            }

            do {
                try await runIO { try self.fileSystem.copyItem(atPath: srcPath, toPath: dstPath) }
                copied.append(pattern.pattern)
            } catch {
                failed.append((pattern.pattern, error.localizedDescription))
            }
        }

        return CopyResult(copied: copied, skipped: skipped, failed: failed)
    }
}
