import Foundation

/// Application-level errors surfaced by `AppStore` use cases.
enum AppStoreError: LocalizedError, Equatable {
    case validation(message: String)
    case repositoryAlreadyAdded
    case noEditorConfigured
    case invalidURL(urlString: String)
    case cannotRemoveMainWorktree

    var errorDescription: String? {
        switch self {
        case .validation(let message):
            return message
        case .repositoryAlreadyAdded:
            return "Repository already added"
        case .noEditorConfigured:
            return "No editor configured"
        case .invalidURL(let urlString):
            return "Invalid URL: \(urlString)"
        case .cannotRemoveMainWorktree:
            return GitError.cannotRemoveMainWorktree.localizedDescription
        }
    }
}

