import Foundation

protocol EditorOpening {
    func open(path: String, with editor: Editor) throws
    func availableEditors() -> [Editor]
}

