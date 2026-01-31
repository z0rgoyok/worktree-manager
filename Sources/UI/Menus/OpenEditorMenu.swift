import SwiftUI

struct OpenEditorMenu: View {
    @ObservedObject var workspace: WorkspaceComponent
    let worktree: Worktree

    private var selectedEditorId: String {
        workspace.preferredEditor(for: worktree)?.id ?? ""
    }

    var body: some View {
        Menu {
            Picker("", selection: Binding(
                get: { selectedEditorId },
                set: { newId in
                    if let editor = workspace.configuredEditors().first(where: { $0.id == newId }) {
                        workspace.openInEditorAndRemember(worktree, editor: editor)
                    }
                }
            )) {
                ForEach(workspace.configuredEditors()) { editor in
                    Text(editor.name).tag(editor.id)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Divider()
            Button(workspace.rememberEditorChoice ? "Forget Editor Choice" : "Remember Editor Choice") {
                workspace.rememberEditorChoice.toggle()
                if !workspace.rememberEditorChoice {
                    workspace.clearPreferredEditor(for: worktree)
                }
            }
        } label: {
            Label("Open", systemImage: "arrow.up.forward.app")
        } primaryAction: {
            workspace.smartOpenInEditor(worktree)
        }
    }
}
