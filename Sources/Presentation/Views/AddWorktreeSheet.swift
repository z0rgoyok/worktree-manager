import SwiftUI

struct AddWorktreeSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var worktreeName = ""
    @State private var branchName = ""
    @State private var createNewBranch = true
    @State private var selectedExistingBranch = ""
    @State private var baseBranch = "main"
    @State private var showBranchConflict = false
    @State private var enabledCopyPatterns: Set<String> = []
    @State private var copyPreview: [CopyPreviewItem] = []

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

                    Picker("Based on", selection: $baseBranch) {
                        ForEach(mainBranches, id: \.self) { branch in
                            Text(branch).tag(branch)
                        }
                    }
                } else {
                    Picker("Branch", selection: $selectedExistingBranch) {
                        ForEach(store.branches, id: \.self) { branch in
                            Text(branch).tag(branch)
                        }
                    }
                }

                if let repo = store.selectedRepository {
                    let previewPath = "\(store.worktreeBasePath)/\(repo.name)/\(worktreeName)"

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
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            if let firstBranch = store.branches.first {
                selectedExistingBranch = firstBranch
            }
            if let preferred = store.preferredBaseBranch(), store.branches.contains(preferred) {
                baseBranch = preferred
            } else if let main = store.branches.first(where: { $0 == "main" || $0 == "master" }) {
                baseBranch = main
            } else if let first = store.branches.first {
                baseBranch = first
            }

            // Load copy preview
            if let repo = store.selectedRepository {
                copyPreview = store.getCopyPreview(for: repo)
                enabledCopyPatterns = Set(copyPreview.filter { $0.exists }.map { $0.pattern })
            }
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
                        await store.createWorktree(
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
                        await store.recreateBranchAndWorktree(
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
        let priority = store.branches.filter { priorityBranches.contains($0) }
        let others = store.branches.filter { !priorityBranches.contains($0) && !$0.contains("/") }
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
            if store.branchExists(branchName) {
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
            store.setPreferredBaseBranch(baseBranch)
        }

        Task {
            await store.createWorktree(
                name: worktreeName,
                branch: branch,
                createNewBranch: createNewBranch,
                baseBranch: base,
                copyPatterns: selectedCopyPatterns.isEmpty ? nil : selectedCopyPatterns
            )
        }

        dismiss()
    }
}

struct BranchConflictSheet: View {
    let branchName: String
    let worktreeName: String
    let onUseExisting: () -> Void
    let onRecreate: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Branch Already Exists")
                .font(.headline)

            Text("Branch '\(branchName)' already exists.\nHow would you like to proceed?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button {
                    onUseExisting()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        VStack(alignment: .leading) {
                            Text("Use existing branch")
                                .fontWeight(.medium)
                            Text("Create worktree using the existing '\(branchName)' branch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button {
                    onRecreate()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        VStack(alignment: .leading) {
                            Text("Recreate branch")
                                .fontWeight(.medium)
                            Text("Delete existing branch and create fresh from base")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 360)
    }
}

#Preview {
    AddWorktreeSheet()
        .environmentObject(AppStore())
}
