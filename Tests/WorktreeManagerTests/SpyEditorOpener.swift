import Foundation
@testable import WorktreeManager

final class SpyEditorOpener: EditorOpening {
    private(set) var openCalls: [(path: String, editor: Editor)] = []
    var availableEditorsResult: [Editor] = Editor.builtIn
    var openError: Error?

    func open(path: String, with editor: Editor) throws {
        openCalls.append((path: path, editor: editor))
        if let openError { throw openError }
    }

    func availableEditors() -> [Editor] {
        availableEditorsResult
    }
}

