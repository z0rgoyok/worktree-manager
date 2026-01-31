import SwiftUI

struct ConfigureEditorsSheet: View {
    @EnvironmentObject private var workspace: WorkspaceComponent
    @Environment(\.dismiss) private var dismiss

    @State private var editorStates: [EditorState] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(width: 400, height: 500)
        .task {
            await loadEditors()
        }
    }

    private var header: some View {
        HStack {
            Text("Configure Editors")
                .font(.headline)
            Spacer()
            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack {
                Spacer()
                ProgressView("Checking installed editors...")
                Spacer()
            }
        } else {
            List {
                Section {
                    ForEach($editorStates) { $state in
                        EditorRow(state: $state, onToggle: { enabled in
                            workspace.setEditorEnabled(state.editor, enabled: enabled)
                        })
                    }
                } footer: {
                    Text("Disabled editors won't appear in the Open menu.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.inset)
        }
    }

    private func loadEditors() async {
        let editors = workspace.allEditors()
        var states: [EditorState] = []

        for editor in editors {
            let isInstalled = workspace.isEditorInstalled(editor)
            let isEnabled = workspace.isEditorEnabled(editor)
            states.append(EditorState(editor: editor, isInstalled: isInstalled, isEnabled: isEnabled))
        }

        editorStates = states
        isLoading = false
    }
}

private struct EditorState: Identifiable {
    let editor: Editor
    let isInstalled: Bool
    var isEnabled: Bool

    var id: String { editor.id }
}

private struct EditorRow: View {
    @Binding var state: EditorState
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Image(systemName: state.editor.icon)
                .frame(width: 24)
                .foregroundStyle(state.isInstalled ? .primary : .tertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.editor.name)
                    .foregroundStyle(state.isInstalled ? .primary : .secondary)

                if state.isInstalled {
                    Text("Installed")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Text("Not installed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $state.isEnabled)
                .labelsHidden()
                .onChange(of: state.isEnabled) { _, newValue in
                    onToggle(newValue)
                }
        }
        .contentShape(Rectangle())
    }
}
