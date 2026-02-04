import SwiftUI

struct OpenEditorMenu: View {
    @ObservedObject var root: RootComponent
    @ObservedObject var workspace: WorkspaceComponent
    let worktree: Worktree

    private var selectedEditorId: String {
        workspace.preferredEditor()?.id ?? ""
    }

    private var hasRememberedEditor: Bool {
        workspace.rememberEditorChoice && workspace.preferredEditor() != nil
    }

    var body: some View {
        if hasRememberedEditor {
            menuWithPrimaryAction
        } else {
            menuWithoutPrimaryAction
        }
    }

    private var menuWithPrimaryAction: some View {
        Menu {
            menuContent
        } label: {
            Label("Open", systemImage: "arrow.up.forward.app")
        } primaryAction: {
            workspace.smartOpenInEditor(worktree)
        }
    }

    private var menuWithoutPrimaryAction: some View {
        Menu {
            menuContent
        } label: {
            Label("Open", systemImage: "arrow.up.forward.app")
        }
    }

    @ViewBuilder
    private var menuContent: some View {
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
                workspace.clearPreferredEditor()
            }
        }
        Button("Configure Editors...") {
            root.send(.presentSheet(.configureEditors))
        }
    }
}
