import Foundation

/// Decompose-inspired "slot": at most one active child at a time (e.g., a sheet).
public struct ChildSlot<Child> {
    public var child: Child?

    public init(child: Child? = nil) {
        self.child = child
    }
}
