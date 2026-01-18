import Foundation

/// Represents an external editor/IDE
struct Editor: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let command: String
    let icon: String
    /// Optional app name for fallback via `open -a "AppName"`
    let appName: String?

    init(id: String, name: String, command: String, icon: String, appName: String? = nil) {
        self.id = id
        self.name = name
        self.command = command
        self.icon = icon
        self.appName = appName
    }

    static let builtIn: [Editor] = [
        Editor(id: "vscode", name: "VS Code", command: "code", icon: "chevron.left.forwardslash.chevron.right", appName: "Visual Studio Code"),
        Editor(id: "cursor", name: "Cursor", command: "cursor", icon: "cursorarrow.rays", appName: "Cursor"),
        Editor(id: "idea", name: "IntelliJ IDEA", command: "idea", icon: "hammer", appName: "IntelliJ IDEA"),
        Editor(id: "android-studio", name: "Android Studio", command: "studio", icon: "iphone", appName: "Android Studio"),
        Editor(id: "webstorm", name: "WebStorm", command: "webstorm", icon: "globe", appName: "WebStorm"),
        Editor(id: "pycharm", name: "PyCharm", command: "pycharm", icon: "sparkle", appName: "PyCharm"),
        Editor(id: "goland", name: "GoLand", command: "goland", icon: "hare", appName: "GoLand"),
        Editor(id: "sublime", name: "Sublime Text", command: "subl", icon: "text.alignleft", appName: "Sublime Text"),
        Editor(id: "zed", name: "Zed", command: "zed", icon: "bolt", appName: "Zed"),
        Editor(id: "xcode", name: "Xcode", command: "xed", icon: "swift", appName: "Xcode"),
        Editor(id: "finder", name: "Finder", command: "open", icon: "folder"),
        Editor(id: "terminal", name: "Terminal", command: "open -a Terminal", icon: "terminal"),
    ]
}
