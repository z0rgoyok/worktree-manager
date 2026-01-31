import SwiftUI

@main
struct WorktreeManagerApp: App {
    @StateObject private var root = RootComponent.makeDefault()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(root)
                .environmentObject(root.workspace)
                .environmentObject(root.settings)
                .environmentObject(root.activityCenter)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            WorktreeCommands(root: root)

            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(
                        #selector(NSSplitViewController.toggleSidebar(_:)),
                        with: nil
                    )
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(root.settings)
        }
    }
}
