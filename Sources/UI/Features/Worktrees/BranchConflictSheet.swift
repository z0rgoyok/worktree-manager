import SwiftUI

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

