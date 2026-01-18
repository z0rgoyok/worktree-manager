import Foundation

/// Represents a file or directory pattern to copy when creating a new worktree
struct CopyPattern: Codable, Hashable, Identifiable {
    var id: String { pattern }

    /// The relative path pattern (e.g. ".env", ".venv/", "config/*.local")
    let pattern: String

    init(pattern: String) {
        self.pattern = pattern
    }
}

/// Result of copying files to a new worktree
struct CopyResult {
    let copied: [String]
    let skipped: [String]  // not found in source
    let failed: [(path: String, error: String)]

    var isEmpty: Bool {
        copied.isEmpty && skipped.isEmpty && failed.isEmpty
    }

    var summary: String {
        var parts: [String] = []
        if !copied.isEmpty {
            parts.append("Copied: \(copied.joined(separator: ", "))")
        }
        if !skipped.isEmpty {
            parts.append("Skipped (not found): \(skipped.joined(separator: ", "))")
        }
        if !failed.isEmpty {
            let failedNames = failed.map { $0.path }
            parts.append("Failed: \(failedNames.joined(separator: ", "))")
        }
        return parts.joined(separator: ". ")
    }
}

/// Information about a file/directory to be copied (for preview)
struct CopyPreviewItem: Identifiable {
    var id: String { pattern }

    let pattern: String
    let exists: Bool
    let size: Int64?  // in bytes, nil if doesn't exist or is directory
    let isDirectory: Bool

    var sizeFormatted: String? {
        guard let size else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
