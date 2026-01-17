import SwiftUI

struct AddWorktreeSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var worktreeName = ""
    @State private var branchName = ""
    @State private var createNewBranch = true
    @State private var selectedExistingBranch = ""
    @State private var baseBranch = "main"

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
                    let previewPath = "\(StorageService.shared.worktreeBasePath)/\(repo.name)/\(worktreeName)"

                    LabeledContent("Location") {
                        Text(previewPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
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
                    createWorktree()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            // Set default branch name based on worktree name
            if let firstBranch = store.branches.first {
                selectedExistingBranch = firstBranch
            }
            // Try to find main/master branch
            if let main = store.branches.first(where: { $0 == "main" || $0 == "master" }) {
                baseBranch = main
            } else if let first = store.branches.first {
                baseBranch = first
            }
        }
        .onChange(of: branchName) { oldValue, newValue in
            // Sync branch name to worktree name if worktree is empty or was auto-filled
            if createNewBranch && (worktreeName.isEmpty || worktreeName == oldValue) {
                worktreeName = newValue
            }
        }
    }

    private var mainBranches: [String] {
        // Show main/master first, then other local branches
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

    private func createWorktree() {
        let branch = createNewBranch ? branchName : selectedExistingBranch
        let base = createNewBranch ? baseBranch : nil

        store.createWorktree(
            name: worktreeName,
            branch: branch,
            createNewBranch: createNewBranch,
            baseBranch: base
        )

        dismiss()
    }

    private func slugify(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}

#Preview {
    AddWorktreeSheet()
        .environmentObject(AppStore())
}
