import SwiftUI

struct RightClickHandlerView: NSViewRepresentable {
    let onLeftClick: () -> Void
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        HandlerView(onLeftClick: onLeftClick, onRightClick: onRightClick)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? HandlerView else { return }
        view.onLeftClick = onLeftClick
        view.onRightClick = onRightClick
    }

    private final class HandlerView: NSView {
        var onLeftClick: () -> Void
        var onRightClick: () -> Void

        init(onLeftClick: @escaping () -> Void, onRightClick: @escaping () -> Void) {
            self.onLeftClick = onLeftClick
            self.onRightClick = onRightClick
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func rightMouseDown(with event: NSEvent) {
            onRightClick()
            super.rightMouseDown(with: event)
        }

        override func mouseDown(with event: NSEvent) {
            if event.modifierFlags.contains(.control) {
                onRightClick()
            } else {
                onLeftClick()
            }
            super.mouseDown(with: event)
        }
    }
}
