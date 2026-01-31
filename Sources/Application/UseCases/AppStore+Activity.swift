import Foundation

extension AppStore {
    func withGlobalActivity<T>(
        kind: AppActivity.Kind,
        message: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        let token = activityCenter.beginGlobal(kind: kind, message: message)
        defer { activityCenter.end(token) }
        return try await operation()
    }

    func withWorktreeActivity<T>(
        worktreePath: String,
        kind: AppActivity.Kind,
        message: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        let token = activityCenter.beginWorktree(path: worktreePath, kind: kind, message: message)
        defer { activityCenter.end(token) }
        return try await operation()
    }
}

