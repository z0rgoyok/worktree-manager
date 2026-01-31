import SwiftUI

struct OpenEditorMenu: View {
    @ObservedObject var workspace: WorkspaceComponent
    let worktree: Worktree

    private var preferredEditor: Editor? {
        workspace.preferredEditor(for: worktree)
    }

    var body: some View {
        Menu {
            ForEach(workspace.configuredEditors()) { editor in
                Button {
                    workspace.openInEditorAndRemember(worktree, editor: editor)
                } label: {
                    HStack {
                        Text(editor.name)
                        if workspace.rememberEditorChoice && preferredEditor?.id == editor.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
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
