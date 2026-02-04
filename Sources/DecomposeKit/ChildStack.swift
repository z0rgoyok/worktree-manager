import Foundation

/// Decompose-inspired stack: allows a simple back stack of children (e.g., screens).
public struct ChildStack<Child> {
    public var items: [Child]

    public init(root: Child) {
        self.items = [root]
    }

    public var active: Child {
        items[items.count - 1]
    }

    public mutating func push(_ child: Child) {
        items.append(child)
    }

    public mutating func pop() {
        guard items.count > 1 else { return }
        items.removeLast()
    }
}
