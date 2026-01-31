import SwiftUI

struct WorktreeStatusRow: View {
    let status: WorktreeStatus?

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            if let status = status {
                let hasAnySignal = status.isDirty || status.ahead > 0 || status.behind > 0 || status.prStatus != nil || !status.hasRemote

                if !hasAnySignal {
                    Label("Clean", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }

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
                    WorktreePRBadge(pr: pr)
                } else if !status.hasRemote {
                    Label("Not pushed", systemImage: "icloud.slash")
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Loading status...")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}
