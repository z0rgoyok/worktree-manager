import SwiftUI

struct AddTaskSheet: View {
    let column: KanbanColumnType
    let onAdd: (String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            HStack {
                Image(systemName: column.icon)
                    .foregroundStyle(columnColor)
                Text("New Task in \(column.rawValue)")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                TextField("Task title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTitleFocused)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text("Description (optional)")
                        .font(.caption)
                        .foregroundStyle(DS.Colors.textSecondary)

                    TextEditor(text: $description)
                        .font(.body)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .stroke(DS.Colors.border, lineWidth: 1)
                        )
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add Task") {
                    onAdd(title, description.isEmpty ? nil : description)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(DS.Spacing.xl)
        .frame(width: 360)
        .onAppear {
            isTitleFocused = true
        }
    }

    private var columnColor: Color {
        switch column {
        case .todo: return DS.Colors.statusTodo
        case .inProgress: return DS.Colors.statusInProgress
        case .review: return DS.Colors.statusReview
        case .done: return DS.Colors.statusDone
        }
    }
}

