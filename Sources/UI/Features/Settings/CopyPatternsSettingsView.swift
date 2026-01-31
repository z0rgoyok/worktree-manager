import SwiftUI

struct CopyPatternsSettingsView: View {
    @Binding var patterns: [CopyPattern]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Default Copy Patterns")
                .font(.headline)

            Text("Files and directories matching these patterns will be copied from the main worktree when creating new worktrees. Individual repositories can override these defaults.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            CopyPatternsEditor(patterns: $patterns, showHeader: false)

            Spacer()
        }
        .padding()
    }
}

