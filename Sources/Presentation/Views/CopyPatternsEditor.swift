import SwiftUI

/// Reusable editor for copy patterns, used in both global settings and per-repo configuration
struct CopyPatternsEditor: View {
    @Binding var patterns: [CopyPattern]
    var showHeader: Bool = true

    @State private var newPattern = ""
    @State private var editingPattern: CopyPattern?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showHeader {
                Text("Files to Copy")
                    .font(.headline)
            }

            if patterns.isEmpty {
                Text("No patterns configured")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(patterns) { pattern in
                    HStack {
                        Image(systemName: pattern.pattern.hasSuffix("/") ? "folder" : "doc")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        Text(pattern.pattern)
                            .font(.system(.body, design: .monospaced))

                        Spacer()

                        Button {
                            removePattern(pattern)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove pattern")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
            }

            HStack {
                TextField("Add pattern (e.g. .env, .venv/)", text: $newPattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        addPattern()
                    }

                Button("Add") {
                    addPattern()
                }
                .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Text("Use trailing / for directories (e.g. .venv/)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func addPattern() {
        let trimmed = newPattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !patterns.contains(where: { $0.pattern == trimmed }) else {
            newPattern = ""
            return
        }

        patterns.append(CopyPattern(pattern: trimmed))
        newPattern = ""
    }

    private func removePattern(_ pattern: CopyPattern) {
        patterns.removeAll { $0.id == pattern.id }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var patterns: [CopyPattern] = [
            CopyPattern(pattern: ".env"),
            CopyPattern(pattern: ".venv/"),
            CopyPattern(pattern: "config.local.json")
        ]

        var body: some View {
            CopyPatternsEditor(patterns: $patterns)
                .padding()
                .frame(width: 400)
        }
    }

    return PreviewWrapper()
}
