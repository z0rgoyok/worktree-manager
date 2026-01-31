import Foundation

/// Information about a file/directory to be copied (for preview)
struct CopyPreviewItem: Identifiable {
    var id: String { pattern }

    let pattern: String
    let exists: Bool
    let size: Int64?  // in bytes, nil if doesn't exist or is directory
    let isDirectory: Bool
}
