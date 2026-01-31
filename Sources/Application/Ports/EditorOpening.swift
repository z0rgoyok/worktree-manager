import Foundation

protocol EditorOpening {
    func open(path: String, with editor: Editor) throws
    func availableEditors() -> [Editor]
    func allEditors() -> [Editor]
    func isInstalled(_ editor: Editor) -> Bool
}

