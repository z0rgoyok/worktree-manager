import Foundation

struct AppActivity: Identifiable, Equatable {
    enum Scope: Equatable {
        case global
        case worktree(path: String)
    }

    enum Kind: Equatable {
        case initialLoad
        case refresh
        case createWorktree
        case completeWorktree
        case createPR
        case push
        case pull
        case merge
        case lock
        case unlock
        case prune
        case misc
    }

    let id: UUID
    let scope: Scope
    let kind: Kind
    let message: String
    let startedAt: Date

    init(id: UUID = UUID(), scope: Scope, kind: Kind, message: String, startedAt: Date = Date()) {
        self.id = id
        self.scope = scope
        self.kind = kind
        self.message = message
        self.startedAt = startedAt
    }
}

