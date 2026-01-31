import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            GeneralSettingsView(
                worktreeBasePath: Binding(
                    get: { store.worktreeBasePath },
                    set: { store.setWorktreeBasePath($0) }
                ),
                defaultEditorId: Binding(
                    get: { store.defaultEditorId },
                    set: { store.setDefaultEditorId($0) }
                ),
                availableEditors: store.availableEditors()
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            CopyPatternsSettingsView(
                patterns: Binding(
                    get: { store.defaultCopyPatterns },
                    set: { store.setDefaultCopyPatterns($0) }
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
        .environmentObject(AppStore.makeDefault())
}
