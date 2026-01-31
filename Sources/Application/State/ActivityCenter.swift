import Foundation
import Combine

@MainActor
final class ActivityCenter: ObservableObject {
    struct Token: Hashable {
        enum Scope: Hashable {
            case global
            case worktree(path: String)
        }

        let id: UUID
        let scope: Scope
    }

    @Published private(set) var currentGlobal: AppActivity?
    @Published private(set) var currentByWorktreePath: [String: AppActivity] = [:]

    private var globalStack: [AppActivity] = []
    private var worktreeStacks: [String: [AppActivity]] = [:]

    func beginGlobal(kind: AppActivity.Kind, message: String) -> Token {
        let activity = AppActivity(scope: .global, kind: kind, message: message)
        globalStack.append(activity)
        currentGlobal = globalStack.last
        return Token(id: activity.id, scope: .global)
    }

    func beginWorktree(path: String, kind: AppActivity.Kind, message: String) -> Token {
        let activity = AppActivity(scope: .worktree(path: path), kind: kind, message: message)
        var stack = worktreeStacks[path, default: []]
        stack.append(activity)
        worktreeStacks[path] = stack
        currentByWorktreePath[path] = stack.last
        return Token(id: activity.id, scope: .worktree(path: path))
    }

    func end(_ token: Token) {
        switch token.scope {
        case .global:
            globalStack.removeAll { $0.id == token.id }
            currentGlobal = globalStack.last
        case .worktree(let path):
            var stack = worktreeStacks[path, default: []]
            stack.removeAll { $0.id == token.id }
            worktreeStacks[path] = stack.isEmpty ? nil : stack
            currentByWorktreePath[path] = stack.last
            if stack.isEmpty {
                currentByWorktreePath.removeValue(forKey: path)
            }
        }
    }

    func currentActivity(forWorktreePath path: String) -> AppActivity? {
        currentByWorktreePath[path]
    }
}

