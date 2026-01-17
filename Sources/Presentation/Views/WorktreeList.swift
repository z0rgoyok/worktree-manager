import SwiftUI

struct WorktreeList: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if let repo = store.selectedRepository {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(repo.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(repo.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(store.worktrees.count) worktree\(store.worktrees.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.bar)
            }

            Divider()

            // Worktree list
            if store.worktrees.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)

                    Text("No worktrees found")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.worktrees) { worktree in
                            WorktreeCard(worktree: worktree)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct WorktreeCard: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    @State private var showDeleteConfirm = false
    @State private var showEditorPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(worktree.name)
                            .font(.headline)

                        if worktree.isMain {
                            HStack(spacing: 2) {
                                Badge(text: "primary", color: .blue)
                                InfoButton(message: "This is the primary worktree created with the repository. It cannot be removed.")
                            }
                        }

                        if worktree.isLocked {
                            Badge(text: "locked", color: .orange)
                        }

                        if worktree.isPrunable {
                            Badge(text: "prunable", color: .red)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption)

                        Text(worktree.branch)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Quick actions
                HStack(spacing: 8) {
                    Button {
                        showEditorPicker = true
                    } label: {
                        Label("Open", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.borderedProminent)

                    Menu {
                        Button {
                            store.openInFinder(worktree)
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                        }

                        Button {
                            store.openInTerminal(worktree)
                        } label: {
                            Label("Open in Terminal", systemImage: "terminal")
                        }

                        Divider()

                        if worktree.isLocked {
                            Button {
                                store.unlockWorktree(worktree)
                            } label: {
                                Label("Unlock", systemImage: "lock.open")
                            }
                        } else {
                            Button {
                                store.lockWorktree(worktree)
                            } label: {
                                Label("Lock", systemImage: "lock")
                            }
                        }

                        if !worktree.isMain {
                            Divider()

                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("Remove Worktree", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                }
            }

            // Path
            HStack {
                Image(systemName: "folder")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text(worktree.path)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button {
                    copyToClipboard(worktree.path)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Copy path")
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .sheet(isPresented: $showEditorPicker) {
            EditorPickerSheet(worktree: worktree)
        }
        .confirmationDialog(
            "Remove Worktree",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                store.removeWorktree(worktree)
            }

            Button("Force Remove", role: .destructive) {
                store.removeWorktree(worktree, force: true)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the worktree at '\(worktree.name)'. The files will be deleted.")
        }
    }

    private func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}

struct InfoButton: View {
    let message: String
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            Text(message)
                .font(.caption)
                .padding(8)
                .frame(maxWidth: 200)
        }
    }
}

struct EditorPickerSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let worktree: Worktree

    var body: some View {
        VStack(spacing: 16) {
            Text("Open in...")
                .font(.headline)

            let editors = store.availableEditors()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(editors) { editor in
                    Button {
                        store.openInEditor(worktree, editor: editor)
                        dismiss()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: editor.icon)
                                .font(.title)
                                .frame(height: 32)

                            Text(editor.name)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 320)
    }
}

#Preview {
    WorktreeList()
        .environmentObject(AppStore())
}
