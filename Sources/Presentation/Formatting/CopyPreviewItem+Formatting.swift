import Foundation

extension CopyPreviewItem {
    /// Human-readable file size for UI.
    ///
    /// Kept out of `Domain` to avoid embedding formatting decisions in the domain model.
    var sizeFormatted: String? {
        guard let size else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
