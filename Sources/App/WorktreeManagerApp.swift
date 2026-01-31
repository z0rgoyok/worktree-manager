import SwiftUI

@main
struct WorktreeManagerApp: App {
    @StateObject private var store = AppStore.makeDefault()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(store.activityCenter)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            WorktreeCommands(store: store)

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
                .environmentObject(store)
                .environmentObject(store.activityCenter)
        }
    }
}
