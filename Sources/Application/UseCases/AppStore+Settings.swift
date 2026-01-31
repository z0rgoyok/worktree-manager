import Foundation

// MARK: - Settings Use Cases

extension AppStore {
    func setWorktreeBasePath(_ path: String) {
        worktreeBasePath = path
        preferences.worktreeBasePath = path
        updateWatchedPaths()
    }

    func preferredBaseBranch() -> String? {
        guard let repo = selectedRepository else { return nil }
        return preferences.preferredBaseBranch(forRepositoryId: repo.id)
    }

    func setPreferredBaseBranch(_ branch: String) {
        guard let repo = selectedRepository else { return }
        preferences.setPreferredBaseBranch(branch, forRepositoryId: repo.id)
    }
}
