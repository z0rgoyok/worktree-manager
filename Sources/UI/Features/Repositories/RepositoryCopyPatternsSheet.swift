import SwiftUI

/// Sheet for configuring copy patterns for a specific repository
struct RepositoryCopyPatternsSheet: View {
    @EnvironmentObject var settings: SettingsComponent
    @Environment(\.dismiss) var dismiss

    let repository: Repository

    @State private var useCustomPatterns = false
    @State private var patterns: [CopyPattern] = []

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
                        patterns = settings.state.defaultCopyPatterns
                    }
                }

            if useCustomPatterns {
                CopyPatternsEditor(patterns: $patterns, showHeader: false)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Using global defaults:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if settings.state.defaultCopyPatterns.isEmpty {
                        Text("No default patterns configured")
                            .foregroundStyle(.tertiary)
                            .font(.subheadline)
                    } else {
                        ForEach(settings.state.defaultCopyPatterns) { pattern in
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
        .onAppear {
            let customPatterns = settings.copyPatterns(for: repository)
            useCustomPatterns = customPatterns != nil
            patterns = customPatterns ?? settings.state.defaultCopyPatterns
        }
    }

    private func save() {
        if useCustomPatterns {
            settings.setCopyPatterns(patterns, for: repository)
        } else {
            settings.removeCopyPatterns(for: repository)
        }
    }
}

#Preview {
    RepositoryCopyPatternsSheet(
        repository: Repository(path: "/path/to/repo", name: "my-repo")
    )
    .environmentObject(SettingsComponent(store: AppStore.makeDefault(loadOnInit: false)))
}
