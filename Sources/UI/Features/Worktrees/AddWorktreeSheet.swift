import SwiftUI

struct AddWorktreeSheet: View {
    @EnvironmentObject var workspace: WorkspaceComponent
    @Environment(\.dismiss) var dismiss

    @State private var worktreeName = ""
    @State private var branchName = ""
    @State private var createNewBranch = true
    @State private var selectedExistingBranch = ""
    @State private var baseBranch = "main"
    @State private var showBranchConflict = false
    @State private var enabledCopyPatterns: Set<String> = []
    @State private var copyPreview: [CopyPreviewItem] = []
    @State private var isPreparing = false
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Worktree")
                .font(.headline)

            Form {
                TextField("Worktree Name", text: $worktreeName)
                    .textFieldStyle(.roundedBorder)

                Picker("Branch", selection: $createNewBranch) {
                    Text("Create new branch").tag(true)
                    Text("Use existing branch").tag(false)
                }
                .pickerStyle(.segmented)

                if createNewBranch {
                    TextField("New Branch Name", text: $branchName)
                        .textFieldStyle(.roundedBorder)

                    Group {
                        if workspace.state.branches.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading branches…")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Picker("Based on", selection: $baseBranch) {
                                ForEach(mainBranches, id: \.self) { branch in
                                    Text(branch).tag(branch)
                                }
                            }
                        }
                    }
                } else {
                    Group {
                        if workspace.state.branches.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading branches…")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Picker("Branch", selection: $selectedExistingBranch) {
                                ForEach(workspace.state.branches, id: \.self) { branch in
                                    Text(branch).tag(branch)
                                }
                            }
                        }
                    }
                }

                if let repo = workspace.state.selectedRepository {
                    let previewPath = "\(workspace.state.worktreeBasePath)/\(repo.name)/\(worktreeName)"

                    LabeledContent("Location") {
                        Text(previewPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                if !copyPreview.isEmpty {
                    Section {
                        ForEach(copyPreview) { item in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { enabledCopyPatterns.contains(item.pattern) },
                                    set: { enabled in
                                        if enabled {
                                            enabledCopyPatterns.insert(item.pattern)
                                        } else {
                                            enabledCopyPatterns.remove(item.pattern)
                                        }
                                    }
                                )) {
                                    HStack {
                                        Image(systemName: item.isDirectory ? "folder" : "doc")
                                            .foregroundStyle(item.exists ? .secondary : .tertiary)

                                        Text(item.pattern)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(item.exists ? .primary : .tertiary)

                                        if !item.exists {
                                            Text("(not found)")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        } else if let size = item.sizeFormatted {
                                            Text(size)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .toggleStyle(.checkbox)
                                .disabled(!item.exists)
                            }
                        }
                    } header: {
                        Text("Copy from main worktree")
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    attemptCreate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid || workspace.state.branches.isEmpty || isPreparing || isSubmitting)
            }
        }
        .padding()
        .frame(width: 400)
        .overlay {
            if isPreparing {
                BlockingProgressOverlay(title: "Preparing…")
            } else if isSubmitting {
                BlockingProgressOverlay(title: "Creating worktree…")
            }
        }
        .task {
            await prepare()
        }
        .onChange(of: branchName) { oldValue, newValue in
            if createNewBranch && (worktreeName.isEmpty || worktreeName == oldValue) {
                worktreeName = newValue
            }
        }
        .sheet(isPresented: $showBranchConflict) {
            let patterns = selectedCopyPatterns.isEmpty ? nil : selectedCopyPatterns
            BranchConflictSheet(
                branchName: branchName,
                worktreeName: worktreeName,
                onUseExisting: {
                    // Use existing branch without creating new
                    Task {
                        await workspace.createWorktree(
                            name: worktreeName,
                            branch: branchName,
                            createNewBranch: false,
                            baseBranch: nil,
                            copyPatterns: patterns
                        )
                    }
                    dismiss()
                },
                onRecreate: {
                    // Delete branch and create new
                    Task {
                        await workspace.recreateBranchAndWorktree(
                            name: worktreeName,
                            branch: branchName,
                            baseBranch: baseBranch,
                            copyPatterns: patterns
                        )
                    }
                    dismiss()
                }
            )
        }
    }

    private var mainBranches: [String] {
        let priorityBranches = ["main", "master", "develop", "development"]
        let priority = workspace.state.branches.filter { priorityBranches.contains($0) }
        let others = workspace.state.branches.filter { !priorityBranches.contains($0) && !$0.contains("/") }
        return priority + others
    }

    private var isValid: Bool {
        guard !worktreeName.isEmpty else { return false }

        if createNewBranch {
            return !branchName.isEmpty
        } else {
            return !selectedExistingBranch.isEmpty
        }
    }

    private func attemptCreate() {
        if createNewBranch {
            // Check if branch already exists
            if workspace.branchExists(branchName) {
                showBranchConflict = true
                return
            }
        }

        createWorktree()
    }

    private var selectedCopyPatterns: [CopyPattern] {
        enabledCopyPatterns.map { CopyPattern(pattern: $0) }
    }

    private func createWorktree() {
        let branch = createNewBranch ? branchName : selectedExistingBranch
        let base = createNewBranch ? baseBranch : nil

        if createNewBranch {
            workspace.setPreferredBaseBranch(baseBranch)
        }

        Task {
            isSubmitting = true
            await workspace.createWorktree(
                name: worktreeName,
                branch: branch,
                createNewBranch: createNewBranch,
                baseBranch: base,
                copyPatterns: selectedCopyPatterns.isEmpty ? nil : selectedCopyPatterns
            )
            isSubmitting = false
            dismiss()
        }
    }

    private func prepare() async {
        guard !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }

        if workspace.state.branches.isEmpty {
            await workspace.loadBranches()
        }

        if selectedExistingBranch.isEmpty, let firstBranch = workspace.state.branches.first {
            selectedExistingBranch = firstBranch
        }

        if let preferred = workspace.preferredBaseBranch(), workspace.state.branches.contains(preferred) {
            baseBranch = preferred
        } else if let main = workspace.state.branches.first(where: { $0 == "main" || $0 == "master" }) {
            baseBranch = main
        } else if let first = workspace.state.branches.first {
            baseBranch = first
        }

        if let repo = workspace.state.selectedRepository {
            copyPreview = await workspace.loadCopyPreview(for: repo)
            enabledCopyPatterns = Set(copyPreview.filter { $0.exists }.map { $0.pattern })
        }
    }
}

#Preview {
    AddWorktreeSheet()
        .environmentObject(WorkspaceComponent(store: AppStore.makeDefault(loadOnInit: false)))
}
