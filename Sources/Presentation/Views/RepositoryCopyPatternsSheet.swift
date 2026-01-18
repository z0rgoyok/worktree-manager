import SwiftUI

/// Sheet for configuring copy patterns for a specific repository
struct RepositoryCopyPatternsSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let repository: Repository

    @State private var useCustomPatterns: Bool
    @State private var patterns: [CopyPattern]

    init(repository: Repository, store: AppStore) {
        self.repository = repository
        let customPatterns = store.copyPatterns(for: repository)
        _useCustomPatterns = State(initialValue: customPatterns != nil)
        _patterns = State(initialValue: customPatterns ?? store.defaultCopyPatterns)
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Copy Files Settings")
                    .font(.headline)
                Spacer()
                Text(repository.name)
                    .foregroundStyle(.secondary)
            }

            Toggle("Use custom patterns for this repository", isOn: $useCustomPatterns)
                .onChange(of: useCustomPatterns) { _, newValue in
                    if !newValue {
                        patterns = store.defaultCopyPatterns
                    }
                }

            if useCustomPatterns {
                CopyPatternsEditor(patterns: $patterns, showHeader: false)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Using global defaults:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if store.defaultCopyPatterns.isEmpty {
                        Text("No default patterns configured")
                            .foregroundStyle(.tertiary)
                            .font(.subheadline)
                    } else {
                        ForEach(store.defaultCopyPatterns) { pattern in
                            HStack {
                                Image(systemName: pattern.pattern.hasSuffix("/") ? "folder" : "doc")
                                    .foregroundStyle(.secondary)
                                Text(pattern.pattern)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }

                    Text("Configure defaults in Settings → Copy Files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }

    private func save() {
        if useCustomPatterns {
            store.setCopyPatterns(patterns, for: repository)
        } else {
            store.removeCopyPatterns(for: repository)
        }
    }
}

#Preview {
    RepositoryCopyPatternsSheet(
        repository: Repository(path: "/path/to/repo", name: "my-repo"),
        store: AppStore()
    )
    .environmentObject(AppStore())
}
