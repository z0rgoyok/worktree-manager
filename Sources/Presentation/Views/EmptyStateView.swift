import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Repository Selected")
                .font(.title2)
                .fontWeight(.medium)

            Text("Add a repository from the sidebar to manage its worktrees")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

