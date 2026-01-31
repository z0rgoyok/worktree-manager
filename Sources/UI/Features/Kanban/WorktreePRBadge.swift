import SwiftUI

struct WorktreePRBadge: View {
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

