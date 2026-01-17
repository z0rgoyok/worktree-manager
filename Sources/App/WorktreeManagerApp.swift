import SwiftUI

@main
struct WorktreeManagerApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Repository...") {
                    NSApp.sendAction(#selector(AppCommands.addRepository), to: nil, from: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

@objc protocol AppCommands {
    func addRepository()
}
