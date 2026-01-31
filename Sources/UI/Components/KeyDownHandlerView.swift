import SwiftUI
import AppKit

struct KeyDownHandlerView: NSViewRepresentable {
    let isActive: Bool
    let onKeyDown: (NSEvent) -> Bool

    func makeNSView(context: Context) -> NSView {
        HandlerView(isActive: isActive, onKeyDown: onKeyDown)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? HandlerView else { return }
        view.onKeyDown = onKeyDown
        view.setActive(isActive)
    }

    private final class HandlerView: NSView {
        var onKeyDown: (NSEvent) -> Bool
        private var isActive: Bool

        init(isActive: Bool, onKeyDown: @escaping (NSEvent) -> Bool) {
            self.isActive = isActive
            self.onKeyDown = onKeyDown
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var acceptsFirstResponder: Bool { true }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }

        func setActive(_ active: Bool) {
            let shouldRequestFocus = active && !isActive
            isActive = active

            guard shouldRequestFocus else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                _ = self.window?.makeFirstResponder(self)
            }
        }

        override func keyDown(with event: NSEvent) {
            if onKeyDown(event) {
                return
            }
            super.keyDown(with: event)
        }
    }
}
