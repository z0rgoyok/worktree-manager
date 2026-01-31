import SwiftUI

struct WorktreeStatusIndicators: View {
    let status: WorktreeStatus

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            if status.isDirty {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
                    .help("Uncommitted changes")
            }

            if status.ahead > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(status.ahead)")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.blue)
                .help("\(status.ahead) commits to push")
            }

            if status.behind > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(status.behind)")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.purple)
                .help("\(status.behind) commits behind")
            }

            if let pr = status.prStatus {
                Image(systemName: pr.isMerged ? "checkmark.circle.fill" : "arrow.triangle.pull")
                    .font(.system(size: 9))
                    .foregroundStyle(pr.isMerged ? .purple : .green)
                    .help(pr.isMerged ? "PR merged" : "PR #\(pr.number)")
            }
        }
    }
}

