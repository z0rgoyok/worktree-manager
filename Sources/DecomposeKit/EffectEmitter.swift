import Foundation

@MainActor
public final class EffectEmitter<Effect> {
    private var continuation: AsyncStream<Effect>.Continuation?

    public let stream: AsyncStream<Effect>

    public init() {
        var captured: AsyncStream<Effect>.Continuation?
        self.stream = AsyncStream { continuation in
            captured = continuation
        }
        self.continuation = captured
    }

    public func emit(_ effect: Effect) {
        continuation?.yield(effect)
    }
}
