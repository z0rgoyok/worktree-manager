import Foundation

/// Service for opening paths in external editors
final class EditorService {
    static let shared = EditorService()

    private init() {}

    /// Open a path in the specified editor
    func open(path: String, with editor: Editor) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        let command: String
        if editor.command == "open -a Terminal" {
            command = "open -a Terminal '\(path)'"
        } else if editor.command == "open" {
            command = "open '\(path)'"
        } else if isCommandAvailable(editor.command) {
            command = "\(editor.command) '\(path)'"
        } else if let appName = editor.appName {
            command = "open -a '\(appName)' '\(path)'"
        } else {
            command = "\(editor.command) '\(path)'"
        }

        process.arguments = ["-c", command]

        do {
            try process.run()
        } catch {
            throw EditorError.failedToOpen(editor: editor.name, error: error.localizedDescription)
        }
    }

    /// Check if an editor is available
    func isAvailable(editor: Editor) -> Bool {
        if editor.id == "finder" || editor.id == "terminal" {
            return true
        }

        if isCommandAvailable(editor.command) {
            return true
        }

        if let appName = editor.appName, isAppInstalled(appName) {
            return true
        }

        return false
    }

    private func isCommandAvailable(_ command: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func isAppInstalled(_ appName: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemKind == 'Application' && kMDItemDisplayName == '\(appName)'"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }

    func availableEditors() -> [Editor] {
        Editor.builtIn
    }
}

enum EditorError: LocalizedError {
    case failedToOpen(editor: String, error: String)

    var errorDescription: String? {
        switch self {
        case .failedToOpen(let editor, let error):
            return "Failed to open in \(editor): \(error)"
        }
    }
}
