import Foundation

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

