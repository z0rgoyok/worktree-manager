import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsComponent

    var body: some View {
        TabView {
            GeneralSettingsView(
                worktreeBasePath: Binding(
                    get: { settings.state.worktreeBasePath },
                    set: { settings.setWorktreeBasePath($0) }
                )
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            CopyPatternsSettingsView(
                patterns: Binding(
                    get: { settings.state.defaultCopyPatterns },
                    set: { settings.setDefaultCopyPatterns($0) }
                )
            )
            .tabItem {
                Label("Copy Files", systemImage: "doc.on.doc")
            }
        }
        .frame(width: 450, height: 350)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsComponent(store: AppStore.makeDefault(loadOnInit: false)))
}
