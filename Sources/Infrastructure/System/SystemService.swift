import AppKit
import Foundation

final class SystemService: SystemOpening {
    static let shared = SystemService()

    private init() {}

    func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func revealInFinder(path: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }

    func openTerminal(atPath path: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(path)'"
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}

