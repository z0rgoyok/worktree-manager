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

// MARK: - WorktreeCard

struct WorktreeCard: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree

    @State private var showEditorPicker = false
    @State private var showCreatePR = false
    @State private var showFinishSheet = false
    @State private var showDeleteSheet = false

    private var status: WorktreeStatus? {
        store.getStatus(for: worktree)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Name + badges
                    HStack(spacing: 8) {
                        Text(worktree.name)
                            .font(.headline)

                        if worktree.isMain {
                            Badge(text: "main", color: .blue)
                        }
                        if worktree.isLocked {
                            Badge(text: "locked", color: .orange)
                        }
                        if worktree.isPrunable {
                            Badge(text: "prunable", color: .red)
                        }
                    }

                    // Branch
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption)
                        Text(worktree.branch)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Status indicators
                    if !worktree.isPrunable {
                        StatusRow(status: status)
                    }
                }

                Spacer()

                // Action buttons
                ActionButtons(
                    worktree: worktree,
                    status: status,
                    showEditorPicker: $showEditorPicker,
                    showCreatePR: $showCreatePR,
                    showFinishSheet: $showFinishSheet,
                    showDeleteSheet: $showDeleteSheet
                )
            }

            // Path row
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
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(worktree.path, forType: .string)
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
        .sheet(isPresented: $showCreatePR) {
            CreatePRSheet(worktree: worktree)
        }
        .sheet(isPresented: $showFinishSheet) {
            FinishWorktreeSheet(worktree: worktree)
        }
        .sheet(isPresented: $showDeleteSheet) {
            DeleteWorktreeSheet(worktree: worktree)
        }
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let status: WorktreeStatus?

    var body: some View {
        HStack(spacing: 10) {
            if let status = status {
                if status.isDirty {
                    Label("Modified", systemImage: "pencil.circle.fill")
                        .foregroundStyle(.orange)
                }

                if status.ahead > 0 {
                    Label("\(status.ahead) to push", systemImage: "arrow.up.circle.fill")
                        .foregroundStyle(.blue)
                }

                if status.behind > 0 {
                    Label("\(status.behind) behind", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.purple)
                }

                if let pr = status.prStatus {
                    PRBadge(pr: pr)
                } else if !status.hasRemote {
                    Label("Not pushed", systemImage: "icloud.slash")
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}

struct PRBadge: View {
    let pr: PRStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: prIcon)
            Text("PR #\(pr.number)")
        }
        .foregroundStyle(prColor)
    }

    private var prIcon: String {
        switch pr.state.uppercased() {
        case "MERGED": return "checkmark.circle.fill"
        case "CLOSED": return "xmark.circle.fill"
        default: return "arrow.triangle.pull"
        }
    }

    private var prColor: Color {
        switch pr.state.uppercased() {
        case "MERGED": return .purple
        case "CLOSED": return .red
        default: return .green
        }
    }
}

// MARK: - Action Buttons

struct ActionButtons: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    let status: WorktreeStatus?

    @Binding var showEditorPicker: Bool
    @Binding var showCreatePR: Bool
    @Binding var showFinishSheet: Bool
    @Binding var showDeleteSheet: Bool

    var body: some View {
        HStack(spacing: 8) {
            if !worktree.isMain && !worktree.isPrunable {
                // Push button
                Button {
                    Task { await store.push(worktree) }
                } label: {
                    Label("Push", systemImage: "arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(status?.ahead == 0 && status?.hasRemote == true)

                // PR button
                if let status = status, let pr = status.prStatus {
                    Button {
                        store.openPR(worktree)
                    } label: {
                        Label(pr.isMerged ? "Merged" : "PR #\(pr.number)", systemImage: "arrow.triangle.pull")
                    }
                    .buttonStyle(.bordered)
                    .tint(pr.isMerged ? .purple : .green)
                } else {
                    Button {
                        showCreatePR = true
                    } label: {
                        Label("Create PR", systemImage: "arrow.triangle.pull")
                    }
                    .buttonStyle(.bordered)
                }

                // Finish button (when PR is merged or for local-only cleanup)
                if status?.prStatus?.isMerged == true {
                    Button {
                        showFinishSheet = true
                    } label: {
                        Label("Finish", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }

            // Open button
            Button {
                showEditorPicker = true
            } label: {
                Label("Open", systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(.borderedProminent)

            // More menu
            MoreMenu(
                worktree: worktree,
                status: status,
                showFinishSheet: $showFinishSheet,
                showDeleteSheet: $showDeleteSheet
            )
        }
    }
}

// MARK: - More Menu

struct MoreMenu: View {
    @EnvironmentObject var store: AppStore
    let worktree: Worktree
    let status: WorktreeStatus?

    @Binding var showFinishSheet: Bool
    @Binding var showDeleteSheet: Bool

    var body: some View {
        Menu {
            Section {
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
            }

            Section {
                Button {
                    Task { await store.refreshWorktreeStatus(worktree) }
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }

                if let pr = status?.prStatus {
                    Button {
                        store.openPR(worktree)
                    } label: {
                        Label("View PR #\(pr.number)", systemImage: "safari")
                    }
                }
            }

            if !worktree.isMain {
                Section {
                    if worktree.isLocked {
                        Button {
                            Task { await store.unlockWorktree(worktree) }
                        } label: {
                            Label("Unlock", systemImage: "lock.open")
                        }
                    } else {
                        Button {
                            Task { await store.lockWorktree(worktree) }
                        } label: {
                            Label("Lock", systemImage: "lock")
                        }
                    }
                }

                Section {
                    Button {
                        showFinishSheet = true
                    } label: {
                        Label("Complete Worktree...", systemImage: "checkmark.circle")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 28)
    }
}

// MARK: - Sheets

/// Action to perform with worktree changes
enum CompleteAction: String, CaseIterable {
    case prMerged = "PR was merged"
    case mergeLocally = "Merge locally"
    case discard = "Just delete"

    var description: String {
        switch self {
        case .prMerged: "Work was merged via PR on GitHub. Just clean up."
        case .mergeLocally: "Merge branch into target locally, then clean up."
        case .discard: "Discard this work without merging."
        }
    }

    var icon: String {
        switch self {
        case .prMerged: "checkmark.circle.fill"
        case .mergeLocally: "arrow.triangle.merge"
        case .discard: "trash"
        }
    }

    var color: Color {
        switch self {
        case .prMerged: .green
        case .mergeLocally: .blue
        case .discard: .red
        }
    }
}

struct CompleteWorktreeSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let worktree: Worktree

    @State private var selectedAction: CompleteAction = .prMerged
    @State private var deleteLocalBranch = true
    @State private var deleteRemoteBranch = false
    @State private var pullTargetFirst = true
    @State private var forceDelete = false
    @State private var hasRemoteBranch = false

    private var status: WorktreeStatus? {
        store.getStatus(for: worktree)
    }

    private var hasMergedPR: Bool {
        status?.prStatus?.isMerged == true
    }

    private var hasOpenPR: Bool {
        if let pr = status?.prStatus {
            return !pr.isMerged
        }
        return false
    }

    private var isDirty: Bool {
        status?.isDirty == true
    }

    private var hasUnpushed: Bool {
        status?.hasUnpushedCommits == true
    }

    private var targetBranch: String {
        worktree.baseBranch ?? store.preferredBaseBranch() ?? "main"
    }

    private var canDeleteBranch: Bool {
        !worktree.branch.isEmpty && worktree.branch != "detached HEAD"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Image(systemName: selectedAction.icon)
                .font(.system(size: 48))
                .foregroundStyle(selectedAction.color)

            Text("Complete Worktree")
                .font(.headline)

            Text("Clean up '\(worktree.name)'")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Warnings
            if isDirty || hasUnpushed || hasOpenPR {
                VStack(alignment: .leading, spacing: 6) {
                    if isDirty {
                        Label("Uncommitted changes", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    if hasUnpushed {
                        Label("Unpushed commits (\(status?.ahead ?? 0))", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    if hasOpenPR {
                        Label("PR is still open", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Action selection
            VStack(alignment: .leading, spacing: 8) {
                Text("What happened with this work?")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(CompleteAction.allCases, id: \.self) { action in
                    HStack(spacing: 10) {
                        Image(systemName: selectedAction == action ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selectedAction == action ? action.color : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.rawValue)
                                .fontWeight(selectedAction == action ? .medium : .regular)
                            Text(action.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAction = action
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Cleanup options
            VStack(alignment: .leading, spacing: 12) {
                Text("Cleanup options")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if canDeleteBranch {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Delete local branch", isOn: $deleteLocalBranch)
                        Text("Removes '\(worktree.branch)' from local repository")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if hasRemoteBranch {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Delete remote branch", isOn: $deleteRemoteBranch)
                            Text("Removes '\(worktree.branch)' from origin")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if selectedAction != .discard {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Update \(targetBranch) from remote first", isOn: $pullTargetFirst)
                        Text("Pulls latest changes before cleanup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if isDirty {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Force delete", isOn: $forceDelete)
                            .foregroundStyle(.red)
                        Text("Discard uncommitted changes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(selectedAction == .discard ? "Delete" : "Complete") {
                    complete()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(selectedAction.color)
                .disabled(isDirty && !forceDelete)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            // Set initial action based on PR status
            if hasMergedPR {
                selectedAction = .prMerged
            } else if hasOpenPR {
                selectedAction = .prMerged // User might want to finish after merging PR
            }
            // Check for remote branch
            hasRemoteBranch = store.hasRemoteBranch(for: worktree)
        }
    }

    private func complete() {
        let options = CompleteWorktreeOptions(
            targetBranch: targetBranch,
            mergeIntoTarget: selectedAction == .mergeLocally,
            pullTargetFirst: pullTargetFirst && selectedAction != .discard,
            deleteLocalBranch: deleteLocalBranch && canDeleteBranch,
            deleteRemoteBranch: deleteRemoteBranch && hasRemoteBranch,
            force: forceDelete
        )
        Task { await store.completeWorktree(worktree, options: options) }
        dismiss()
    }
}

// Keep for backward compatibility if needed elsewhere
struct FinishWorktreeSheet: View {
    let worktree: Worktree
    var body: some View {
        CompleteWorktreeSheet(worktree: worktree)
    }
}

struct DeleteWorktreeSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let worktree: Worktree

    @State private var deleteBranch = false
    @State private var forceDelete = false

    private var canDeleteBranch: Bool {
        !worktree.branch.isEmpty && worktree.branch != "detached HEAD"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text("Remove Worktree")
                .font(.headline)

            Text("This will remove the worktree '\(worktree.name)'.\nThe directory will be deleted.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Force remove (ignore uncommitted changes)", isOn: $forceDelete)

                if canDeleteBranch {
                    Toggle("Also delete branch '\(worktree.branch)'", isOn: $deleteBranch)
                }
            }
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Remove") {
                    Task { await store.removeWorktree(worktree, force: forceDelete, deleteBranch: deleteBranch) }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

struct CreatePRSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let worktree: Worktree

    @State private var title: String = ""
    @State private var prDescription: String = ""
    @State private var baseBranch: String = "main"

    private var baseBranches: [String] {
        let common = ["main", "master", "develop"]
        let available = store.branches.filter { common.contains($0) }
        return available.isEmpty ? common : available
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.pull")
                    .foregroundStyle(.green)
                Text("Create Pull Request")
                    .font(.headline)
            }

            Form {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $prDescription)
                        .frame(height: 80)
                        .font(.body)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        )
                }

                Picker("Base branch", selection: $baseBranch) {
                    ForEach(baseBranches, id: \.self) { branch in
                        Text(branch).tag(branch)
                    }
                }
            }
            .formStyle(.grouped)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create PR") {
                    Task {
                        await store.createPR(
                            worktree,
                            title: title.isEmpty ? worktree.branch : title,
                            body: prDescription,
                            baseBranch: baseBranch
                        )
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            title = worktree.branch
            if let main = baseBranches.first {
                baseBranch = main
            }
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

// MARK: - Supporting Views

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

struct WorktreeInfoButton: View {
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Worktree Status Guide")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Modified — uncommitted changes", systemImage: "pencil.circle.fill")
                        .foregroundStyle(.orange)
                    Label("To push — commits not pushed", systemImage: "arrow.up.circle.fill")
                        .foregroundStyle(.blue)
                    Label("Behind — remote has new commits", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.purple)
                    Label("PR Open — pull request is open", systemImage: "arrow.triangle.pull")
                        .foregroundStyle(.green)
                    Label("PR Merged — ready to cleanup", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.purple)
                }
                .font(.caption)
            }
            .padding(12)
            .frame(width: 260)
        }
    }
}

#Preview {
    WorktreeList()
        .environmentObject(AppStore())
}
